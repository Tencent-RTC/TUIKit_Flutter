// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   CoGuestStoreImpl @ AtomicXCore
// Function: CoGuestStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/device/device_store.dart';
import '../../api/live/co_guest_store.dart';
import '../../api/live/live_audience_store.dart';
import '../../api/live/live_seat_store.dart';
import '../../engine/engine_bridge.dart';
import 'live_audience_store_define.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _CoGuestStateImpl implements CoGuestState {
  @override
  final ValueNotifier<List<SeatUserInfo>> connected =
      ValueNotifier<List<SeatUserInfo>>(const <SeatUserInfo>[]);

  @override
  final ValueNotifier<List<LiveUserInfo>> invitees =
      ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);

  @override
  final ValueNotifier<List<LiveUserInfo>> applicants =
      ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);

  @override
  final ValueNotifier<List<LiveUserInfo>> candidates =
      ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);
}

// API keys
const String _kApplyForSeat = 'CoGuestModule.applyForSeat';
const String _kCancelApplication = 'CoGuestModule.cancelApplication';
const String _kAcceptApplication = 'CoGuestModule.acceptApplication';
const String _kRejectApplication = 'CoGuestModule.rejectApplication';
const String _kInviteToSeat = 'CoGuestModule.inviteToSeat';
const String _kCancelInvitation = 'CoGuestModule.cancelInvitation';
const String _kAcceptInvitation = 'CoGuestModule.acceptInvitation';
const String _kRejectInvitation = 'CoGuestModule.rejectInvitation';
const String _kDisconnect = 'CoGuestModule.disconnect';
const String _kSetLayoutTemplate = 'CoGuestModule.setLayoutTemplate';
const String _kCreateModule = 'CoGuestModule.createModule';
const String _kDestroyModule = 'CoGuestModule.destroyModule';

const String _eventChannel = 'CoGuestModule.event';
const String _stateChannel = 'CoGuestModule.stateChanged';

class CoGuestStoreImpl extends CoGuestStore implements IStore {
  CoGuestStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _CoGuestStateImpl _state = _CoGuestStateImpl();
  final Set<HostListener> _hostListeners = <HostListener>{};
  final Set<GuestListener> _guestListeners = <GuestListener>{};

  @override
  CoGuestState get coGuestState => _state;

  @override
  Future<CompletionHandler> applyForSeat({
    required int seatIndex,
    required int timeout,
    String? extraInfo,
  }) {
    final param = jsonEncode(<String, Object>{
      'seatIndex': seatIndex,
      'timeout': timeout,
      'extraInfo': extraInfo ?? '',
    });
    return EngineBridge.invoke(_kApplyForSeat, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelApplication() {
    return EngineBridge.invoke(_kCancelApplication, '{}', id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptApplication(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kAcceptApplication, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectApplication(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kRejectApplication, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> inviteToSeat({
    required String inviteeID,
    required int seatIndex,
    required int timeout,
    String? extraInfo,
  }) {
    final param = jsonEncode(<String, Object>{
      'inviteeID': inviteeID,
      'seatIndex': seatIndex,
      'timeout': timeout,
      'extraInfo': extraInfo ?? '',
    });
    return EngineBridge.invoke(_kInviteToSeat, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelInvitation(String inviteeID) {
    final param = jsonEncode(<String, Object>{
      'inviteeID': inviteeID,
    });
    return EngineBridge.invoke(_kCancelInvitation, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptInvitation(String inviterID) {
    final param = jsonEncode(<String, Object>{
      'inviterID': inviterID,
    });
    return EngineBridge.invoke(_kAcceptInvitation, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectInvitation(String inviterID) {
    final param = jsonEncode(<String, Object>{
      'inviterID': inviterID,
    });
    return EngineBridge.invoke(_kRejectInvitation, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> disconnect() {
    return EngineBridge.invoke(_kDisconnect, '{}', id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setLayoutTemplate({
    required CoGuestLayoutTemplate template,
  }) {
    final param = jsonEncode(<String, Object>{
      'templateId': template.templateId,
    });
    return EngineBridge.invoke(_kSetLayoutTemplate, param, id: _liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  void addHostListener(HostListener listener) {
    _hostListeners.add(listener);
  }

  @override
  void removeHostListener(HostListener listener) {
    _hostListeners.remove(listener);
  }

  @override
  void addGuestListener(GuestListener listener) {
    _guestListeners.add(listener);
  }

  @override
  void removeGuestListener(GuestListener listener) {
    _guestListeners.remove(listener);
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
    _hostListeners.clear();
    _guestListeners.clear();
    _state.connected.value = const <SeatUserInfo>[];
    _state.invitees.value = const <LiveUserInfo>[];
    _state.applicants.value = const <LiveUserInfo>[];
    _state.candidates.value = const <LiveUserInfo>[];
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
      // ─── Host events ───
      case 'onGuestApplicationReceived':
        for (final l in _hostListeners) {
          l.onGuestApplicationReceived
              ?.call(LiveUserInfoCodec.fromMap(dict['guestUser']));
        }
        break;
      case 'onGuestApplicationCancelled':
        for (final l in _hostListeners) {
          l.onGuestApplicationCancelled
              ?.call(LiveUserInfoCodec.fromMap(dict['guestUser']));
        }
        break;
      case 'onGuestApplicationProcessedByOtherHost':
        for (final l in _hostListeners) {
          l.onGuestApplicationProcessedByOtherHost?.call(
            LiveUserInfoCodec.fromMap(dict['guestUser']),
            LiveUserInfoCodec.fromMap(dict['hostUser']),
          );
        }
        break;
      case 'onHostInvitationResponded':
        for (final l in _hostListeners) {
          l.onHostInvitationResponded?.call(
            (dict['isAccept'] as bool?) ?? false,
            LiveUserInfoCodec.fromMap(dict['guestUser']),
          );
        }
        break;
      case 'onHostInvitationNoResponse':
        for (final l in _hostListeners) {
          l.onHostInvitationNoResponse?.call(
            LiveUserInfoCodec.fromMap(dict['guestUser']),
            _intToNoResponseReason(dict['reason'] as int?),
          );
        }
        break;
      // ─── Guest events ───
      case 'onHostInvitationReceived':
        for (final l in _guestListeners) {
          l.onHostInvitationReceived
              ?.call(LiveUserInfoCodec.fromMap(dict['hostUser']));
        }
        break;
      case 'onHostInvitationCancelled':
        for (final l in _guestListeners) {
          l.onHostInvitationCancelled
              ?.call(LiveUserInfoCodec.fromMap(dict['hostUser']));
        }
        break;
      case 'onGuestApplicationResponded':
        for (final l in _guestListeners) {
          l.onGuestApplicationResponded?.call(
            (dict['isAccept'] as bool?) ?? false,
            LiveUserInfoCodec.fromMap(dict['hostUser']),
          );
        }
        break;
      case 'onGuestApplicationNoResponse':
        for (final l in _guestListeners) {
          l.onGuestApplicationNoResponse?.call(
            _intToNoResponseReason(dict['reason'] as int?),
          );
        }
        break;
      case 'onKickedOffSeat':
        for (final l in _guestListeners) {
          l.onKickedOffSeat?.call(
            (dict['seatIndex'] as int?) ?? 0,
            LiveUserInfoCodec.fromMap(dict['hostUser']),
          );
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
      case 'connected':
        {
          final rawList = (dict['connected'] as List?) ?? const [];
          final items = rawList
              .map((e) => _mapToSeatUserInfo(
                  e is Map ? e.cast<String, dynamic>() : null))
              .toList();
          _state.connected.value = _applyListModify(
              _state.connected.value, modify, items, (e) => e.userID);
          break;
        }
      case 'invitees':
        {
          final rawList = (dict['invitees'] as List?) ?? const [];
          final items = rawList
              .map((e) => LiveUserInfoCodec.fromMap(
                  e is Map ? e.cast<String, dynamic>() : null))
              .toList();
          _state.invitees.value = _applyListModify(
              _state.invitees.value, modify, items, (e) => e.userID);
          break;
        }
      case 'applicants':
        {
          final rawList = (dict['applicants'] as List?) ?? const [];
          final items = rawList
              .map((e) => LiveUserInfoCodec.fromMap(
                  e is Map ? e.cast<String, dynamic>() : null))
              .toList();
          _state.applicants.value = _applyListModify(
              _state.applicants.value, modify, items, (e) => e.userID);
          break;
        }
      case 'candidates':
        {
          final rawList = (dict['candidates'] as List?) ?? const [];
          final items = rawList
              .map((e) => LiveUserInfoCodec.fromMap(
                  e is Map ? e.cast<String, dynamic>() : null))
              .toList();
          _state.candidates.value = _applyListModify(
              _state.candidates.value, modify, items, (e) => e.userID);
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
      userSuspendStatus:
          SuspendStatus.fromValue(map['userSuspendStatus'] as int? ?? 0),
    );
  }

  DeviceStatus _intToDeviceStatus(int? value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == (value ?? DeviceStatus.off.value),
      orElse: () => DeviceStatus.off,
    );
  }

  NoResponseReason _intToNoResponseReason(int? value) {
    return NoResponseReason.values.firstWhere(
      (e) => e.value == (value ?? NoResponseReason.timeout.value),
      orElse: () => NoResponseReason.timeout,
    );
  }
}
