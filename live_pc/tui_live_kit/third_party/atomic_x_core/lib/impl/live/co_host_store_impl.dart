// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   CoHostStoreImpl @ AtomicXCore
// Function: CoHostStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/device/device_store.dart';
import '../../api/live/co_host_store.dart';
import '../../api/live/live_audience_store.dart';
import '../../api/live/live_seat_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _CoHostStateImpl implements CoHostState {
  @override
  final ValueNotifier<CoHostStatus> coHostStatus = ValueNotifier<CoHostStatus>(CoHostStatus.disconnected);

  @override
  final ValueNotifier<List<SeatUserInfo>> connected = ValueNotifier<List<SeatUserInfo>>(const <SeatUserInfo>[]);

  @override
  final ValueNotifier<List<SeatUserInfo>> invitees = ValueNotifier<List<SeatUserInfo>>(const <SeatUserInfo>[]);

  @override
  final ValueNotifier<SeatUserInfo?> applicant = ValueNotifier<SeatUserInfo?>(null);

  @override
  final ValueNotifier<String> candidatesCursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<List<SeatUserInfo>> candidates = ValueNotifier<List<SeatUserInfo>>(const <SeatUserInfo>[]);
}

// API keys
const String _kRequestHostConnection = 'CoHostModule.requestHostConnection';
const String _kCancelHostConnection = 'CoHostModule.cancelHostConnection';
const String _kAcceptHostConnection = 'CoHostModule.acceptHostConnection';
const String _kRejectHostConnection = 'CoHostModule.rejectHostConnection';
const String _kExitHostConnection = 'CoHostModule.exitHostConnection';
const String _kGetCoHostCandidates = 'CoHostModule.getCoHostCandidates';
const String _kMuteRemoteHostAudio = 'CoHostModule.muteRemoteHostAudio';
const String _kCreateModule = 'CoHostModule.createModule';
const String _kDestroyModule = 'CoHostModule.destroyModule';

const String _eventChannel = 'CoHostModule.event';
const String _stateChannel = 'CoHostModule.stateChanged';

class CoHostStoreImpl extends CoHostStore implements IStore {
  CoHostStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _CoHostStateImpl _state = _CoHostStateImpl();
  final Set<CoHostListener> _listeners = <CoHostListener>{};

  @override
  CoHostState get coHostState => _state;

  @override
  Future<CompletionHandler> requestHostConnection({
    required String targetHostLiveID,
    required CoHostLayoutTemplate layoutTemplate,
    required int timeout,
    String extraInfo = '',
  }) {
    final param = jsonEncode(<String, Object>{
      'targetHostLiveID': targetHostLiveID,
      'layoutTemplate': layoutTemplate.value,
      'timeout': timeout,
      'extraInfo': extraInfo,
    });
    return EngineBridge.invoke(_kRequestHostConnection, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelHostConnection(String toHostLiveID) {
    final param = jsonEncode(<String, Object>{
      'toHostLiveID': toHostLiveID,
    });
    return EngineBridge.invoke(_kCancelHostConnection, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptHostConnection(String fromHostLiveID) {
    final param = jsonEncode(<String, Object>{
      'fromHostLiveID': fromHostLiveID,
    });
    return EngineBridge.invoke(_kAcceptHostConnection, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectHostConnection(String fromHostLiveID) {
    final param = jsonEncode(<String, Object>{
      'fromHostLiveID': fromHostLiveID,
    });
    return EngineBridge.invoke(_kRejectHostConnection, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> exitHostConnection() {
    return EngineBridge.invoke(_kExitHostConnection, '{}', id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> getCoHostCandidates(String cursor) {
    final param = jsonEncode(<String, Object>{
      'cursor': cursor,
    });
    return EngineBridge.invoke(_kGetCoHostCandidates, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> muteRemoteHostAudio({
    required String liveID,
    required bool isMuted,
  }) {
    final param = jsonEncode(<String, Object>{
      'liveID': liveID,
      'isMuted': isMuted,
    });
    return EngineBridge.invoke(_kMuteRemoteHostAudio, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addCoHostListener(CoHostListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeCoHostListener(CoHostListener listener) {
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
    _state.coHostStatus.value = CoHostStatus.disconnected;
    _state.connected.value = const <SeatUserInfo>[];
    _state.invitees.value = const <SeatUserInfo>[];
    _state.applicant.value = null;
    _state.candidatesCursor.value = '';
    _state.candidates.value = const <SeatUserInfo>[];
  }

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
      case 'onCoHostRequestReceived':
        for (final l in _listeners) {
          l.onCoHostRequestReceived?.call(
            _mapToSeatUserInfo(dict['inviter']),
            (dict['extensionInfo'] as String?) ?? '',
          );
        }
        break;
      case 'onCoHostRequestCancelled':
        for (final l in _listeners) {
          l.onCoHostRequestCancelled?.call(
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfoOrNull(dict['invitee']),
          );
        }
        break;
      case 'onCoHostRequestAccepted':
        for (final l in _listeners) {
          l.onCoHostRequestAccepted?.call(_mapToSeatUserInfo(dict['invitee']));
        }
        break;
      case 'onCoHostRequestRejected':
        for (final l in _listeners) {
          l.onCoHostRequestRejected?.call(_mapToSeatUserInfo(dict['invitee']));
        }
        break;
      case 'onCoHostRequestTimeout':
        for (final l in _listeners) {
          l.onCoHostRequestTimeout?.call(
            _mapToSeatUserInfo(dict['inviter']),
            _mapToSeatUserInfo(dict['invitee']),
          );
        }
        break;
      case 'onCoHostUserJoined':
        for (final l in _listeners) {
          l.onCoHostUserJoined?.call(_mapToSeatUserInfo(dict['userInfo']));
        }
        break;
      case 'onCoHostUserLeft':
        for (final l in _listeners) {
          l.onCoHostUserLeft?.call(_mapToSeatUserInfo(dict['userInfo']));
        }
        break;
    }
  }

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
      case 'coHostStatus':
        {
          final statusValue = (dict['coHostStatus'] as int?) ?? CoHostStatus.disconnected.value;
          _state.coHostStatus.value = CoHostStatus.values.firstWhere(
            (e) => e.value == statusValue,
            orElse: () => CoHostStatus.disconnected,
          );
          break;
        }
      case 'connected':
        {
          final rawList = (dict['connected'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToSeatUserInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.connected.value = _applyListModify(_state.connected.value, modify, items, (e) => e.userID);
          break;
        }
      case 'invitees':
        {
          final rawList = (dict['invitees'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToSeatUserInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.invitees.value = _applyListModify(_state.invitees.value, modify, items, (e) => e.liveID);
          break;
        }
      case 'applicant':
        _state.applicant.value = _mapToSeatUserInfoOrNull(dict['applicant']);
        break;
      case 'candidatesCursor':
        _state.candidatesCursor.value = (dict['candidatesCursor'] as String?) ?? '';
        break;
      case 'candidates':
        {
          final rawList = (dict['candidates'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToSeatUserInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.candidates.value = _applyListModify(_state.candidates.value, modify, items, (e) => e.userID);
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

  // MARK: - Model mappers

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

  SeatUserInfo? _mapToSeatUserInfoOrNull(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    return _mapToSeatUserInfo(map);
  }

  DeviceStatus _intToDeviceStatus(int? value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == (value ?? DeviceStatus.off.value),
      orElse: () => DeviceStatus.off,
    );
  }
}
