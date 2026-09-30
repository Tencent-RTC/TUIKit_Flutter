// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   MusicStoreImpl @ AtomicXCore
// Function: MusicStore 主动接口与被动事件/State 实现，通过 EngineBridge 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/device/music_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/store_factory.dart';

class _MusicStateImpl implements MusicState {
  @override
  final ValueNotifier<String?> playURL = ValueNotifier<String?>(null);

  @override
  final ValueNotifier<MusicPlayStatus> playStatus = ValueNotifier<MusicPlayStatus>(MusicPlayStatus.idle);

  @override
  final ValueNotifier<int> playProgress = ValueNotifier<int>(0);

  @override
  final ValueNotifier<int> totalDuration = ValueNotifier<int>(0);

  @override
  final ValueNotifier<int> musicVolume = ValueNotifier<int>(60);
}

// API keys
const String _kStartPlay = 'MusicModule.startPlay';
const String _kPausePlay = 'MusicModule.pausePlay';
const String _kResumePlay = 'MusicModule.resumePlay';
const String _kStopPlay = 'MusicModule.stopPlay';
const String _kSeek = 'MusicModule.seek';
const String _kSetMusicVolume = 'MusicModule.setMusicVolume';
const String _kSetPitch = 'MusicModule.setPitch';
const String _kCreateModule = 'MusicModule.createModule';
const String _kDestroyModule = 'MusicModule.destroyModule';

const String _eventChannel = 'MusicModule.event';
const String _stateChannel = 'MusicModule.stateChanged';

class MusicStoreImpl extends MusicStore implements IStore {
  MusicStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _MusicStateImpl _state = _MusicStateImpl();
  final Set<MusicListener> _listeners = <MusicListener>{};

  @override
  MusicState get musicState => _state;

  // MARK: - Active APIs

  @override
  Future<CompletionHandler> startPlay(AudioMusicParam param) {
    final musicParam = jsonEncode(<String, Object>{
      'id': param.id,
      'path': param.path ?? '',
      'loopCount': param.loopCount,
    });
    return EngineBridge.invoke(_kStartPlay, musicParam, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void pausePlay() {
    unawaited(EngineBridge.invoke(_kPausePlay, '{}', id: _liveID));
  }

  @override
  void resumePlay() {
    unawaited(EngineBridge.invoke(_kResumePlay, '{}', id: _liveID));
  }

  @override
  void stopPlay() {
    unawaited(EngineBridge.invoke(_kStopPlay, '{}', id: _liveID));
  }

  @override
  void seek(int ms) {
    final param = jsonEncode(<String, Object>{'ms': ms});
    unawaited(EngineBridge.invoke(_kSeek, param, id: _liveID));
  }

  @override
  void setMusicVolume(int volume) {
    final param = jsonEncode(<String, Object>{'volume': volume});
    unawaited(EngineBridge.invoke(_kSetMusicVolume, param, id: _liveID));
  }

  @override
  void setPitch(double pitch) {
    final param = jsonEncode(<String, Object>{'pitch': pitch});
    unawaited(EngineBridge.invoke(_kSetPitch, param, id: _liveID));
  }

  @override
  void addMusicListener(MusicListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeMusicListener(MusicListener listener) {
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
    _state.playURL.value = null;
    _state.playStatus.value = MusicPlayStatus.idle;
    _state.playProgress.value = 0;
    _state.totalDuration.value = 0;
    _state.musicVolume.value = 60;
  }

  // MARK: - Passive Event dispatcher (type 判别)

  void _onModuleEvent(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final type = dict['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'onPlayCompleted':
        final playURL = (dict['playURL'] as String?) ?? '';
        for (final l in _listeners) {
          l.onPlayCompleted(playURL);
        }
        break;
      case 'onPlayError':
        final playURL = (dict['playURL'] as String?) ?? '';
        final code = (dict['code'] as int?) ?? 0;
        for (final l in _listeners) {
          l.onPlayError(playURL, code);
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property 判别)

  void _onModuleStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'] as String?;
    if (property == null) return;

    switch (property) {
      case 'playURL':
        _state.playURL.value = dict['playURL'] as String?;
        break;
      case 'playStatus':
        final raw = (dict['playStatus'] as int?) ?? 0;
        _state.playStatus.value = MusicPlayStatus.values.firstWhere(
          (e) => e.value == raw,
          orElse: () => MusicPlayStatus.idle,
        );
        break;
      case 'playProgress':
        _state.playProgress.value = (dict['playProgress'] as int?) ?? 0;
        break;
      case 'totalDuration':
        _state.totalDuration.value = (dict['totalDuration'] as int?) ?? 0;
        break;
      case 'musicVolume':
        _state.musicVolume.value = (dict['musicVolume'] as int?) ?? 60;
        break;
    }
  }

  static Map<String, dynamic>? _parseJSON(String json) {
    if (json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }
}
