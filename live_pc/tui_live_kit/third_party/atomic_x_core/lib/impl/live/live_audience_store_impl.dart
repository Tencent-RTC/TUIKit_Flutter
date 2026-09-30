// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveAudienceStoreImpl @ AtomicXCore
// Function: LiveAudienceStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/live/live_audience_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';
import 'live_audience_store_define.dart';

class _LiveAudienceStateImpl implements LiveAudienceState {
  @override
  final ValueNotifier<List<LiveUserInfo>> audienceList = ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);

  @override
  final ValueNotifier<int> audienceCount = ValueNotifier<int>(0);

  @override
  final ValueNotifier<List<LiveUserInfo>> adminList = ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);

  @override
  final ValueNotifier<List<LiveUserInfo>> messageBannedUserList =
      ValueNotifier<List<LiveUserInfo>>(const <LiveUserInfo>[]);
}

// API keys
const String _kFetchAudienceList = 'LiveAudienceModule.fetchAudienceList';
const String _kSetAdministrator = 'LiveAudienceModule.setAdministrator';
const String _kRevokeAdministrator = 'LiveAudienceModule.revokeAdministrator';
const String _kKickUserOutOfRoom = 'LiveAudienceModule.kickUserOutOfRoom';
const String _kDisableSendMessage = 'LiveAudienceModule.disableSendMessage';
const String _kCreateModule = 'LiveAudienceModule.createModule';
const String _kDestroyModule = 'LiveAudienceModule.destroyModule';

const String _eventChannel = 'LiveAudienceModule.event';
const String _stateChannel = 'LiveAudienceModule.stateChanged';

class LiveAudienceStoreImpl extends LiveAudienceStore implements IStore {
  LiveAudienceStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _LiveAudienceStateImpl _state = _LiveAudienceStateImpl();
  final Set<LiveAudienceListener> _listeners = <LiveAudienceListener>{};

  @override
  LiveAudienceState get liveAudienceState => _state;

  @override
  Future<CompletionHandler> fetchAudienceList() {
    return EngineBridge.invoke(_kFetchAudienceList, '{}', id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setAdministrator(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kSetAdministrator, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> revokeAdministrator(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kRevokeAdministrator, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> kickUserOutOfRoom(String userID) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
    });
    return EngineBridge.invoke(_kKickUserOutOfRoom, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> disableSendMessage({
    required String userID,
    required bool isDisable,
  }) {
    final param = jsonEncode(<String, Object>{
      'userID': userID,
      'isDisable': isDisable,
    });
    return EngineBridge.invoke(_kDisableSendMessage, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addLiveAudienceListener(LiveAudienceListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeLiveAudienceListener(LiveAudienceListener listener) {
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
    _state.audienceList.value = const <LiveUserInfo>[];
    _state.audienceCount.value = 0;
    _state.adminList.value = const <LiveUserInfo>[];
    _state.messageBannedUserList.value = const <LiveUserInfo>[];
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
      case 'onOwnerJoined':
        for (final l in _listeners) {
          l.onOwnerJoined?.call(LiveUserInfoCodec.fromMap(dict['owner']));
        }
        break;
      case 'onOwnerLeft':
        for (final l in _listeners) {
          l.onOwnerLeft?.call(LiveUserInfoCodec.fromMap(dict['owner']));
        }
        break;
      case 'onAdminJoined':
        for (final l in _listeners) {
          l.onAdminJoined?.call(LiveUserInfoCodec.fromMap(dict['admin']));
        }
        break;
      case 'onAdminLeft':
        for (final l in _listeners) {
          l.onAdminLeft?.call(LiveUserInfoCodec.fromMap(dict['admin']));
        }
        break;
      case 'onAudienceJoined':
        for (final l in _listeners) {
          l.onAudienceJoined?.call(LiveUserInfoCodec.fromMap(dict['audience']));
        }
        break;
      case 'onAudienceLeft':
        for (final l in _listeners) {
          l.onAudienceLeft?.call(LiveUserInfoCodec.fromMap(dict['audience']));
        }
        break;
      case 'onAudienceMessageDisabled':
        for (final l in _listeners) {
          l.onAudienceMessageDisabled?.call(
            LiveUserInfoCodec.fromMap(dict['audience']),
            (dict['isDisable'] as bool?) ?? false,
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
      case 'audienceList':
        {
          final rawList = (dict['audienceList'] as List?) ?? const [];
          final items = rawList.map((e) => LiveUserInfoCodec.fromMap(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.audienceList.value = _applyListModify(_state.audienceList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'audienceCount':
        _state.audienceCount.value = (dict['audienceCount'] as int?) ?? 0;
        break;
      case 'adminList':
        {
          final rawList = (dict['adminList'] as List?) ?? const [];
          final items = rawList.map((e) => LiveUserInfoCodec.fromMap(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.adminList.value = _applyListModify(_state.adminList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'messageBannedUserList':
        {
          final rawList = (dict['messageBannedUserList'] as List?) ?? const [];
          final items = rawList.map((e) => LiveUserInfoCodec.fromMap(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.messageBannedUserList.value =
              _applyListModify(_state.messageBannedUserList.value, modify, items, (e) => e.userID);
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
