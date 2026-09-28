// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BattleStoreImpl @ AtomicXCore
// Function: BattleStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/device/device_store.dart';
import '../../api/live/battle_store.dart';
import '../../api/live/live_audience_store.dart';
import '../../api/live/live_seat_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _BattleStateImpl implements BattleState {
  @override
  final ValueNotifier<BattleInfo?> currentBattleInfo = ValueNotifier<BattleInfo?>(null);

  @override
  final ValueNotifier<List<SeatUserInfo>> battleUsers = ValueNotifier<List<SeatUserInfo>>(const <SeatUserInfo>[]);

  @override
  final ValueNotifier<Map<String, int>> battleScore = ValueNotifier<Map<String, int>>(const <String, int>{});
}

// API keys
const String _kRequestBattle = 'BattleModule.requestBattle';
const String _kCancelBattleRequest = 'BattleModule.cancelBattleRequest';
const String _kAcceptBattle = 'BattleModule.acceptBattle';
const String _kRejectBattle = 'BattleModule.rejectBattle';
const String _kExitBattle = 'BattleModule.exitBattle';
const String _kCreateModule = 'BattleModule.createModule';
const String _kDestroyModule = 'BattleModule.destroyModule';

const String _eventChannel = 'BattleModule.event';
const String _stateChannel = 'BattleModule.stateChanged';

class BattleStoreImpl extends BattleStore implements IStore {
  BattleStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _BattleStateImpl _state = _BattleStateImpl();
  final Set<BattleListener> _listeners = <BattleListener>{};

  @override
  BattleState get battleState => _state;

  @override
  Future<BattleRequestCompletionHandler> requestBattle({
    required BattleConfig config,
    required List<String> userIDList,
    required int timeout,
  }) async {
    final param = jsonEncode(<String, Object>{
      'config': <String, Object>{
        'duration': config.duration,
        'needResponse': config.needResponse,
        'extensionInfo': config.extensionInfo,
      },
      'userIDList': userIDList,
      'timeout': timeout,
    });
    final result = await EngineBridge.invoke(_kRequestBattle, param, id: _liveID);
    final handler = BattleRequestCompletionHandler();
    handler.errorCode = result.code;
    handler.errorMessage = result.message;
    if (result.isSuccess && result.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(result.data);
        if (decoded is Map<String, dynamic>) {
          final battleInfoMap = (decoded['battleInfo'] as Map?)?.cast<String, dynamic>();
          if (battleInfoMap != null) {
            handler.battleInfo = _mapToBattleInfo(battleInfoMap);
          }
          final resultMapRaw = (decoded['resultMap'] as Map?) ?? const {};
          handler.resultMap = resultMapRaw.map((key, value) {
            final intValue = value is int ? value : int.tryParse('$value') ?? 0;
            return MapEntry(key.toString(), intValue);
          });
        }
      } catch (e) {
        debugPrint('[BattleStoreImpl] decode requestBattle result failed: $e');
      }
    }
    return handler;
  }

  @override
  Future<CompletionHandler> cancelBattleRequest({
    required String battleID,
    required List<String> userIDList,
  }) {
    final param = jsonEncode(<String, Object>{
      'battleID': battleID,
      'userIDList': userIDList,
    });
    return EngineBridge.invoke(_kCancelBattleRequest, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptBattle(String battleID) {
    final param = jsonEncode(<String, Object>{
      'battleID': battleID,
    });
    return EngineBridge.invoke(_kAcceptBattle, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectBattle(String battleID) {
    final param = jsonEncode(<String, Object>{
      'battleID': battleID,
    });
    return EngineBridge.invoke(_kRejectBattle, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> exitBattle(String battleID) {
    final param = jsonEncode(<String, Object>{
      'battleID': battleID,
    });
    return EngineBridge.invoke(_kExitBattle, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addBattleListener(BattleListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeBattleListener(BattleListener listener) {
    _listeners.remove(listener);
  }

  // MARK: - IStore lifecycle

  @override
  void beforeEnterRoom(String roomID) {
    if (_eventToken != null) return;
    _eventToken = EngineBridge.subscribe(_eventChannel, _onModuleEvent);
    _stateToken = EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
  }

  @override
  void afterEnterRoom(dynamic info) {
    unawaited(EngineBridge.invoke(_kCreateModule, '{}', id: _liveID));
  }

  @override
  void didLeaveRoom(String roomID) {
    unawaited(EngineBridge.invoke(_kDestroyModule, '{}', id: roomID));
    final eventToken = _eventToken;
    if (eventToken != null) {
      EngineBridge.unsubscribe(eventToken);
    }
    _eventToken = null;
    final stateToken = _stateToken;
    if (stateToken != null) {
      EngineBridge.unsubscribe(stateToken);
    }
    _stateToken = null;
    _listeners.clear();
    _state.currentBattleInfo.value = null;
    _state.battleUsers.value = const <SeatUserInfo>[];
    _state.battleScore.value = const <String, int>{};
  }

  // MARK: - Passive Event dispatcher (type 判别)

  void _onModuleEvent(String id, String json) {
    if (id != _liveID) return;
    Map<String, dynamic>? dict;
    try {
      final parsed = jsonDecode(json);
      if (parsed is! Map<String, dynamic>) return;
      dict = parsed;
    } catch (_) {
      return;
    }
    final type = dict['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'onBattleStarted':
        for (final l in _listeners) {
          final inviteesRaw = (dict['invitees'] as List?) ?? const [];
          final invitees = inviteesRaw.map((e) => _mapToSeatUserInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          l.onBattleStarted?.call(
            _mapToBattleInfo(dict['battleInfo']),
            _mapToSeatUserInfo(dict['inviter']),
            invitees,
          );
        }
        break;
      case 'onBattleEnded':
        for (final l in _listeners) {
          l.onBattleEnded?.call(
            _mapToBattleInfo(dict['battleInfo']),
            _intToBattleEndedReason(dict['reason'] as int?),
          );
        }
        break;
      case 'onUserJoinBattle':
        for (final l in _listeners) {
          l.onUserJoinBattle?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['battleUser']),
          );
        }
        break;
      case 'onUserExitBattle':
        for (final l in _listeners) {
          l.onUserExitBattle?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['battleUser']),
          );
        }
        break;
      case 'onBattleRequestReceived':
        for (final l in _listeners) {
          l.onBattleRequestReceived?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
      case 'onBattleRequestCancelled':
        for (final l in _listeners) {
          l.onBattleRequestCancelled?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
      case 'onBattleRequestTimeout':
        for (final l in _listeners) {
          l.onBattleRequestTimeout?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
      case 'onBattleRequestAccept':
        for (final l in _listeners) {
          l.onBattleRequestAccept?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
      case 'onBattleRequestReject':
        for (final l in _listeners) {
          l.onBattleRequestReject?.call(
            (dict['battleID'] as String?) ?? '',
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property 判别)

  void _onModuleStateChanged(String id, String json) {
    if (id != _liveID) return;
    Map<String, dynamic>? dict;
    try {
      final parsed = jsonDecode(json);
      if (parsed is! Map<String, dynamic>) return;
      dict = parsed;
    } catch (_) {
      return;
    }
    final property = dict['property'] as String?;
    if (property == null) return;

    final modify = (dict['listModifyType'] as int?) ?? 1;
    switch (property) {
      case 'currentBattleInfo':
        final battleInfoRaw = (dict['currentBattleInfo'] as Map?)?.cast<String, dynamic>();
        _state.currentBattleInfo.value =
            (battleInfoRaw == null || battleInfoRaw.isEmpty) ? null : _mapToBattleInfo(battleInfoRaw);
        break;
      case 'battleUsers':
        {
          final rawList = (dict['battleUsers'] as List?) ?? const [];
          final items =
              rawList.map((e) => _mapToSeatUserInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.battleUsers.value =
              _applyListModify(_state.battleUsers.value, modify, items, (e) => e.userID);
          break;
        }
      case 'battleScore':
        {
          final raw = dict['battleScore'] as Map<String, dynamic>? ?? const {};
          _state.battleScore.value = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
          break;
        }
    }
  }

  List<T> _applyListModify<T>(
    List<T> current,
    int modifyType,
    List<T> payload,
    String Function(T) keyOf,
  ) {
    final type = ListModifyType.fromValue(modifyType);
    switch (type) {
      case ListModifyType.full:
        return payload;
      case ListModifyType.add:
        final map = <String, T>{};
        for (final e in current) {
          map[keyOf(e)] = e;
        }
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return map.values.toList();
      case ListModifyType.remove:
        final removing = payload.map(keyOf).toSet();
        return current.where((e) => !removing.contains(keyOf(e))).toList();
      case ListModifyType.replace:
        final map = <String, T>{};
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return current.map((e) => map[keyOf(e)] ?? e).toList();
      case ListModifyType.none:
        return current;
    }
  }

  // MARK: - Seat user mapper

  SeatUserInfo _mapToSeatUserInfo(Map<String, dynamic>? map) {
    if (map == null) return SeatUserInfo();
    final roleValue = (map['role'] as int?) ?? Role.generalUser.value;
    final role = Role.values.firstWhere(
      (e) => e.value == roleValue,
      orElse: () => Role.generalUser,
    );
    return SeatUserInfo(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
      role: role,
      liveID: (map['liveID'] as String?) ?? '',
      microphoneStatus: _intToDeviceStatus(map['microphoneStatus'] as int?),
      allowOpenMicrophone: (map['allowOpenMicrophone'] as bool?) ?? true,
      cameraStatus: _intToDeviceStatus(map['cameraStatus'] as int?),
      allowOpenCamera: (map['allowOpenCamera'] as bool?) ?? true,
      userSuspendStatus: SuspendStatus.fromValue(map['userSuspendStatus'] as int? ?? 0),
    );
  }

  DeviceStatus _intToDeviceStatus(int? value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == (value ?? DeviceStatus.off.value),
      orElse: () => DeviceStatus.off,
    );
  }

  BattleEndedReason _intToBattleEndedReason(int? value) {
    return BattleEndedReason.values.firstWhere(
      (e) => e.value == (value ?? BattleEndedReason.timeOver.value),
      orElse: () => BattleEndedReason.timeOver,
    );
  }
}

// MARK: - Private helpers (extension)

extension _BattleStoreImplHelpers on BattleStoreImpl {
  BattleInfo _mapToBattleInfo(Map<String, dynamic>? map) {
    if (map == null) return BattleInfo();
    final configMap = (map['config'] as Map?)?.cast<String, dynamic>();
    final config = BattleConfig(
      duration: (configMap?['duration'] as int?) ?? 0,
      needResponse: (configMap?['needResponse'] as bool?) ?? true,
      extensionInfo: (configMap?['extensionInfo'] as String?) ?? '',
    );
    return BattleInfo(
      battleID: (map['battleID'] as String?) ?? '',
      config: config,
      startTime: (map['startTime'] as int?) ?? 0,
      endTime: (map['endTime'] as int?) ?? 0,
    );
  }
}
