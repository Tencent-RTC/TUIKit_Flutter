import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

class AudioValueProbe<T> extends ValueNotifier<T> {
  AudioValueProbe(super.value);
  bool get isObserved => hasListeners;
}

class AudioEffectStoreProbe implements AudioEffectStore, AudioEffectState {
  @override
  AudioEffectState get audioEffectState => this;
  @override
  final AudioValueProbe<AudioChangerType> audioChangerType =
      AudioValueProbe(AudioChangerType.none);
  @override
  final AudioValueProbe<AudioReverbType> audioReverbType =
      AudioValueProbe(AudioReverbType.none);
  @override
  final AudioValueProbe<bool> isEarMonitorOpened = AudioValueProbe(false);
  @override
  final AudioValueProbe<int> earMonitorVolume = AudioValueProbe(100);
  final calls = <String>[];

  @override
  void setAudioChangerType(AudioChangerType type) {
    calls.add('changer:$type');
    audioChangerType.value = type;
  }

  @override
  void setAudioReverbType(AudioReverbType type) {
    calls.add('reverb:$type');
    audioReverbType.value = type;
  }

  @override
  void setVoiceEarMonitorEnable(bool enable) {
    calls.add('ear:$enable');
    isEarMonitorOpened.value = enable;
  }

  @override
  void setVoiceEarMonitorVolume(int volume) {
    calls.add('earVolume:$volume');
    earMonitorVolume.value = volume;
  }

  @override
  void reset() {}
}
