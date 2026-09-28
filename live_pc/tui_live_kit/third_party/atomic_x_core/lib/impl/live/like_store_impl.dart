// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LikeStoreImpl @ AtomicXCore
// Function: LikeStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/live/like_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/store_factory.dart';
import 'live_audience_store_define.dart';

class _LikeStateImpl implements LikeState {
  @override
  final ValueNotifier<int> totalLikeCount = ValueNotifier<int>(0);
}

// API keys
const String _kSendLike = 'LikeModule.sendLike';
const String _kCreateModule = 'LikeModule.createModule';
const String _kDestroyModule = 'LikeModule.destroyModule';

const String _eventChannel = 'LikeModule.event';
const String _stateChannel = 'LikeModule.stateChanged';

class LikeStoreImpl extends LikeStore implements IStore {
  LikeStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _LikeStateImpl _state = _LikeStateImpl();
  final Set<LikeListener> _listeners = <LikeListener>{};

  @override
  LikeState get likeState => _state;

  @override
  Future<CompletionHandler> sendLike(int count) {
    final param = jsonEncode(<String, Object>{
      'count': count,
    });
    return EngineBridge.invoke(_kSendLike, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addLikeListener(LikeListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeLikeListener(LikeListener listener) {
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
    _state.totalLikeCount.value = 0;
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
      case 'onReceiveLikesMessage':
        for (final l in _listeners) {
          l.onReceiveLikesMessage?.call(
            (dict['liveID'] as String?) ?? '',
            (dict['totalLikesReceived'] as int?) ?? 0,
            LiveUserInfoCodec.fromMap(dict['sender']),
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

    switch (property) {
      case 'totalLikeCount':
        _state.totalLikeCount.value = (dict['totalLikeCount'] as int?) ?? 0;
        break;
    }
  }
}
