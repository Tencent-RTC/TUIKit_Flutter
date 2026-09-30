// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   AudioEffectStoreImpl @ AtomicXCore
// Function: AudioEffectStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/device/audio_effect_store.dart';
import '../../engine/engine_bridge.dart';

class _AudioEffectStateImpl implements AudioEffectState {
  @override
  final ValueNotifier<AudioChangerType> audioChangerType = ValueNotifier<AudioChangerType>(AudioChangerType.none);

  @override
  final ValueNotifier<AudioReverbType> audioReverbType = ValueNotifier<AudioReverbType>(AudioReverbType.none);

  @override
  final ValueNotifier<bool> isEarMonitorOpened = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<int> earMonitorVolume = ValueNotifier<int>(100);
}

// API keys
const String _kSetAudioChangerType = 'AudioEffectModule.setAudioChangerType';
const String _kSetAudioReverbType = 'AudioEffectModule.setAudioReverbType';
const String _kSetVoiceEarMonitorEnable = 'AudioEffectModule.setVoiceEarMonitorEnable';
const String _kSetVoiceEarMonitorVolume = 'AudioEffectModule.setVoiceEarMonitorVolume';
const String _kReset = 'AudioEffectModule.reset';

const String _stateChannel = 'AudioEffectModule.stateChanged';

class AudioEffectStoreImpl extends AudioEffectStore {
  AudioEffectStoreImpl._() {
    _subscribePassiveChannels();
  }

  static final AudioEffectStoreImpl shared = AudioEffectStoreImpl._();

  final _AudioEffectStateImpl _state = _AudioEffectStateImpl();

  @override
  AudioEffectState get audioEffectState => _state;

  @override
  void setAudioChangerType(AudioChangerType type) {
    final param = jsonEncode(<String, Object>{'type': type.value});
    unawaited(EngineBridge.invoke(_kSetAudioChangerType, param));
  }

  @override
  void setAudioReverbType(AudioReverbType type) {
    final param = jsonEncode(<String, Object>{'type': type.value});
    unawaited(EngineBridge.invoke(_kSetAudioReverbType, param));
  }

  @override
  void setVoiceEarMonitorEnable(bool enable) {
    final param = jsonEncode(<String, Object>{'enable': enable});
    unawaited(EngineBridge.invoke(_kSetVoiceEarMonitorEnable, param));
  }

  @override
  void setVoiceEarMonitorVolume(int volume) {
    final param = jsonEncode(<String, Object>{'volume': volume});
    unawaited(EngineBridge.invoke(_kSetVoiceEarMonitorVolume, param));
  }

  @override
  void reset() {
    unawaited(EngineBridge.invoke(_kReset, '{}'));
  }

  // MARK: - Passive State dispatcher (property 判别)

  void _subscribePassiveChannels() {
    EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
  }

  void _onModuleStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'] as String?;
    if (property == null) return;

    switch (property) {
      case 'audioChangerType':
        final value = dict['audioChangerType'];
        if (value is! int) return;
        _state.audioChangerType.value = AudioChangerType.values.firstWhere(
          (e) => e.value == value,
          orElse: () => AudioChangerType.none,
        );
        break;
      case 'audioReverbType':
        final value = dict['audioReverbType'];
        if (value is! int) return;
        _state.audioReverbType.value = AudioReverbType.values.firstWhere(
          (e) => e.value == value,
          orElse: () => AudioReverbType.none,
        );
        break;
      case 'isEarMonitorOpened':
        final value = dict['isEarMonitorOpened'];
        if (value is! bool) return;
        _state.isEarMonitorOpened.value = value;
        break;
      case 'earMonitorVolume':
        final value = dict['earMonitorVolume'];
        if (value is! int) return;
        _state.earMonitorVolume.value = value;
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
