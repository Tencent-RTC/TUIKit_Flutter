// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveSeatStoreImpl @ AtomicXCore
// Function: LiveSeatStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/live/live_seat_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/list_modify_type.dart';
import '../common/live_json_util.dart';
import '../common/store_factory.dart';

class _LiveSeatStateImpl implements LiveSeatState {
  @override
  final ValueNotifier<List<SeatInfo>> seatList = ValueNotifier<List<SeatInfo>>(const <SeatInfo>[]);

  @override
  final ValueNotifier<LiveCanvas> canvas = ValueNotifier<LiveCanvas>(LiveCanvas());

  @override
  final ValueNotifier<Map<String, int>> speakingUsers = ValueNotifier<Map<String, int>>(const <String, int>{});

  @override
  final ValueNotifier<List<AVStatistics>> avStatistics = ValueNotifier<List<AVStatistics>>(const <AVStatistics>[]);

  @override
  final ValueNotifier<SeatMode> seatMode = ValueNotifier<SeatMode>(SeatMode.free);
}

// API keys
const String _kTakeSeat = 'SeatModule.takeSeat';
const String _kLeaveSeat = 'SeatModule.leaveSeat';
const String _kMuteMicrophone = 'SeatModule.muteMicrophone';
const String _kUnmuteMicrophone = 'SeatModule.unmuteMicrophone';
const String _kKickUserOutOfSeat = 'SeatModule.kickUserOutOfSeat';
const String _kMoveUserToSeat = 'SeatModule.moveUserToSeat';
const String _kSetSeatMode = 'SeatModule.setSeatMode';
const String _kSetFeaturedHost = 'SeatModule.setFeaturedHost';
const String _kRevokeFeaturedHost = 'SeatModule.revokeFeaturedHost';
const String _kLockSeat = 'SeatModule.lockSeat';
const String _kUnlockSeat = 'SeatModule.unlockSeat';
const String _kOpenRemoteCamera = 'SeatModule.openRemoteCamera';
const String _kCloseRemoteCamera = 'SeatModule.closeRemoteCamera';
const String _kOpenRemoteMicrophone = 'SeatModule.openRemoteMicrophone';
const String _kCloseRemoteMicrophone = 'SeatModule.closeRemoteMicrophone';
const String _kCreateModule = 'SeatModule.createModule';
const String _kDestroyModule = 'SeatModule.destroyModule';

const String _eventChannel = 'SeatModule.event';
const String _stateChannel = 'SeatModule.stateChanged';

class LiveSeatStoreImpl extends LiveSeatStore implements IStore {
  LiveSeatStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _LiveSeatStateImpl _state = _LiveSeatStateImpl();
  final Set<LiveSeatListener> _listeners = <LiveSeatListener>{};
  final Set<String> hasVideoStreamUserList = <String>{};

  @override
  LiveSeatState get liveSeatState => _state;

  @override
  Future<CompletionHandler> takeSeat(int seatIndex) {
    final param = jsonEncode(<String, Object>{
      'seatIndex': seatIndex,
    });
    return EngineBridge.invoke(_kTakeSeat, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> leaveSeat() {
    return EngineBridge.invoke(_kLeaveSeat, '{}', id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void muteMicrophone() {
    unawaited(EngineBridge.invoke(_kMuteMicrophone, '{}', id: _liveID));
  }

  @override
  Future<CompletionHandler> unmuteMicrophone() {
    return EngineBridge.invoke(_kUnmuteMicrophone, '{}', id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> kickUserOutOfSeat(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kKickUserOutOfSeat, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> moveUserToSeat({
    required String userID,
    required int targetIndex,
    MoveSeatPolicy policy = MoveSeatPolicy.abortWhenOccupied,
  }) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
      'targetIndex': targetIndex,
      'policy': policy.value,
    });
    return EngineBridge.invoke(_kMoveUserToSeat, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setSeatMode(SeatMode mode) {
    final param = jsonEncode(<String, Object>{
      'mode': mode.value,
    });
    return EngineBridge.invoke(_kSetSeatMode, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setFeaturedHost(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kSetFeaturedHost, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> revokeFeaturedHost(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kRevokeFeaturedHost, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> lockSeat(int seatIndex) {
    final param = jsonEncode(<String, Object>{
      'seatIndex': seatIndex,
    });
    return EngineBridge.invoke(_kLockSeat, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> unlockSeat(int seatIndex) {
    final param = jsonEncode(<String, Object>{
      'seatIndex': seatIndex,
    });
    return EngineBridge.invoke(_kUnlockSeat, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> openRemoteCamera({
    required String userID,
    required DeviceControlPolicy policy,
  }) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
      'policy': policy.value,
    });
    return EngineBridge.invoke(_kOpenRemoteCamera, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> closeRemoteCamera(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kCloseRemoteCamera, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> openRemoteMicrophone({
    required String userID,
    required DeviceControlPolicy policy,
  }) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
      'policy': policy.value,
    });
    return EngineBridge.invoke(_kOpenRemoteMicrophone, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> closeRemoteMicrophone(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kCloseRemoteMicrophone, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addLiveSeatEventListener(LiveSeatListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeLiveSeatEventListener(LiveSeatListener listener) {
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
    _state.seatList.value = const <SeatInfo>[];
    _state.canvas.value = LiveCanvas();
    _state.speakingUsers.value = const <String, int>{};
    _state.avStatistics.value = const <AVStatistics>[];
    _state.seatMode.value = SeatMode.free;
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
      case 'onLocalCameraOpenedByAdmin':
        for (final l in _listeners) {
          l.onLocalCameraOpenedByAdmin?.call(
            LiveJsonUtil.intToDeviceControlPolicy(dict['policy'] as int?),
          );
        }
        break;
      case 'onLocalCameraClosedByAdmin':
        for (final l in _listeners) {
          l.onLocalCameraClosedByAdmin?.call();
        }
        break;
      case 'onLocalMicrophoneOpenedByAdmin':
        for (final l in _listeners) {
          l.onLocalMicrophoneOpenedByAdmin?.call(
            LiveJsonUtil.intToDeviceControlPolicy(dict['policy'] as int?),
          );
        }
        break;
      case 'onLocalMicrophoneClosedByAdmin':
        for (final l in _listeners) {
          l.onLocalMicrophoneClosedByAdmin?.call();
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
      case 'seatList':
        {
          final rawList = (dict['seatList'] as List?) ?? const [];
          final items =
              rawList.map((e) => LiveJsonUtil.mapToSeatInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.seatList.value = _applyListModify(_state.seatList.value, modify, items, (e) => e.index.toString());
          break;
        }
      case 'speakingUsers':
        {
          final raw = dict['speakingUsers'] as Map<String, dynamic>? ?? const {};
          _state.speakingUsers.value = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
          break;
        }
      case 'avStatistics':
        {
          final rawList = (dict['avStatistics'] as List?) ?? const [];
          final items =
              rawList.map((e) => LiveJsonUtil.mapToAVStatistics(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.avStatistics.value = _applyListModify(_state.avStatistics.value, modify, items, (e) => e.userID);
          break;
        }
      case 'seatMode':
        {
          _state.seatMode.value = SeatMode.fromValue((dict['seatMode'] as num?)?.toInt() ?? SeatMode.free.value);
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
}
