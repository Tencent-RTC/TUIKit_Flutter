// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   AudioEffectStore @ AtomicXCore
// Function: Audio effect setting related interfaces, managing voice changer, reverb, and ear monitor features for anchors.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
// <docgen-keep-end>

/// Voice changer effect type.
///
/// Voice changer effects can be applied to human voice, and the voice is processed secondarily through acoustic algorithms to obtain a timbre different from the original sound.
///
/// > **Note**: The set effect will automatically become invalid after leaving the room. If you need the corresponding effect for the next room entry, you need to call the setting interface again.
///
/// ### Voice Changer Effect List
///
/// | Effect | Value | Description |
/// |------|------|-----------|
/// | [none] | 0 | Disable effect |
/// | [child] | 1 | Child |
/// | [littleGirl] | 2 | Little girl |
/// | [man] | 3 | Uncle |
/// | [heavyMetal] | 4 | Heavy metal |
/// | [cold] | 5 | Cold |
/// | [foreigner] | 6 | Foreign accent |
/// | [trappedBeast] | 7 | Trapped beast |
/// | [fatso] | 8 | Otaku |
/// | [strongCurrent] | 9 | Strong current |
/// | [heavyMachinery] | 10 | Heavy machinery |
/// | [ethereal] | 11 | Ethereal |
enum AudioChangerType {
  /// Disable effect.
  none(0),

  /// Child.
  child(1),

  /// Little girl.
  littleGirl(2),

  /// Uncle.
  man(3),

  /// Heavy metal.
  heavyMetal(4),

  /// Cold.
  cold(5),

  /// Foreign accent.
  foreigner(6),

  /// Trapped beast.
  trappedBeast(7),

  /// Otaku.
  fatso(8),

  /// Strong current.
  strongCurrent(9),

  /// Heavy machinery.
  heavyMachinery(10),

  /// Ethereal.
  ethereal(11);

  final int value;

  const AudioChangerType(this.value);
}

/// Reverb effect type.
///
/// Reverb effects can be applied to human voice, and the sound is processed through acoustic algorithms to simulate the presence in various different environments.
///
/// > **Note**: The set effect will automatically become invalid after leaving the room. If you need the corresponding effect for the next room entry, you need to call the setting interface again.
///
/// ### Reverb Effect List
///
/// | Effect | Value | Description |
/// |------|------|-----------|
/// | [none] | 0 | Disable effect |
/// | [ktv] | 1 | KTV |
/// | [smallRoom] | 2 | Small room |
/// | [auditorium] | 3 | Auditorium |
/// | [deep] | 4 | Deep |
/// | [loud] | 5 | Loud |
/// | [metallic] | 6 | Metallic |
/// | [magnetic] | 7 | Magnetic |
enum AudioReverbType {
  /// Disable effect.
  none(0),

  /// KTV.
  ktv(1),

  /// Small room.
  smallRoom(2),

  /// Auditorium.
  auditorium(3),

  /// Deep.
  deep(4),

  /// Loud.
  loud(5),

  /// Metallic.
  metallic(6),

  /// Magnetic.
  magnetic(7);

  final int value;

  const AudioReverbType(this.value);
}

/// Audio effect related state data provided by AudioEffectStore.
///
/// A comprehensive snapshot of the current audio effect session state. This structure contains all relevant information about voice changer effects, reverb effects, and ear monitor state.
///
/// > **Note**: The state is updated automatically when audio effect settings change. Subscribe to [audioEffectState] to receive real-time updates.
/// ### Usage Example
///
/// ```dart
/// // Update voice changer UI
/// store.audioEffectState.audioChangerType.addListener(() {
///     updateChangerTypeUI(store.audioEffectState.audioChangerType.value);
/// });
///
/// // Update reverb UI
/// store.audioEffectState.audioReverbType.addListener(() {
///     updateReverbTypeUI(store.audioEffectState.audioReverbType.value);
/// });
///
/// // Update ear monitor UI
/// store.audioEffectState.isEarMonitorOpened.addListener(() {
///     updateEarMonitorUI(store.audioEffectState.isEarMonitorOpened.value);
/// });
/// ```
///
/// ### State Property Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [audioChangerType] | `ValueListenable<AudioChangerType>` | Current voice changer effect type |
/// | [audioReverbType] | `ValueListenable<AudioReverbType>` | Current reverb effect type |
/// | [isEarMonitorOpened] | `ValueListenable<bool>` | Whether ear monitor is enabled |
/// | [earMonitorVolume] | `ValueListenable<int>` | Ear monitor volume, with a value range from 0 to 100 |
abstract class AudioEffectState {
  /// Voice changer state.
  ValueListenable<AudioChangerType> get audioChangerType;

  /// Reverb state.
  ValueListenable<AudioReverbType> get audioReverbType;

  /// Ear monitor enabled.
  ValueListenable<bool> get isEarMonitorOpened;

  /// Ear monitor volume, with a value range from 0 to 100.
  /// @note If the volume is still too low after setting it to 100, you can set the volume to a maximum of 150, but a volume exceeding 100 may cause distortion, please operate with caution.
  ValueListenable<int> get earMonitorVolume;
}

/// Audio effect setting related interfaces, managing voice changer, reverb, and ear monitor features for anchors.
///
/// `AudioEffectStore` Audio effect management class for handling anchor audio effect related business.
/// `AudioEffectStore` provides a complete set of audio effect management APIs, including voice changer effects, reverb effects, and ear monitor functionality.
/// Through this class, anchors can adjust their voice effects in real-time during live streaming to enhance the experience.
///
/// ### Key Features
///
/// - **Voice Changer Effects**：Supports multiple voice changer effects such as child, little girl, uncle, etc.
/// - **Reverb Effects**：Supports multiple reverb effects such as KTV, small room, auditorium, etc.
/// - **Ear Monitor**：Anchors can hear their own voice in earphones, suitable for singing scenarios.
/// - **Volume Control**：Supports fine-grained ear monitor volume adjustment.
///
/// > **Important**: Use the [shared] singleton to get the `AudioEffectStore` instance. The set effects will automatically become invalid after leaving the room, and need to be set again for the next room entry.
///
/// > **Note**: Audio effect state updates are delivered through the [audioEffectState] publisher. Subscribe to it to receive real-time updates about voice changer, reverb, and ear monitor states.
///
/// ### Usage Example
///
/// ```dart
/// // Get singleton instance
/// final store = AudioEffectStore.shared;
///
/// // Subscribe to state changes
/// store.audioEffectState.audioChangerType.addListener(() {
///     print("Current voice changer: ${store.audioEffectState.audioChangerType.value}");
/// });
///
/// store.audioEffectState.audioReverbType.addListener(() {
///     print("Current reverb: ${store.audioEffectState.audioReverbType.value}");
/// });
///
/// // Set voice changer effect
/// store.setAudioChangerType(AudioChangerType.littleGirl);
///
/// // Set reverb effect
/// store.setAudioReverbType(AudioReverbType.ktv);
///
/// // Enable ear monitor
/// store.setVoiceEarMonitorEnable(true);
/// store.setVoiceEarMonitorVolume(80);
/// ```
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Get singleton instance.
///
/// ### Observing State
/// - [audioEffectState] : Audio effect state data.
///
/// ### Voice Changer Settings
/// - [setAudioChangerType] : Set voice changer effect.
///
/// ### Reverb Settings
/// - [setAudioReverbType] : Set reverb effect.
///
/// ### Ear Monitor Settings
/// - [setVoiceEarMonitorEnable] : Enable/disable ear monitor.
/// - [setVoiceEarMonitorVolume] : Set ear monitor volume.
///
/// ### Reset
/// - [reset] : Reset to default state.
///
/// ## See Also
///
/// - [AudioChangerType]
/// - [AudioReverbType]
/// - [AudioEffectState]
abstract class AudioEffectStore {
  /// Singleton object
  ///
  /// @param shared Singleton instance.
  static AudioEffectStore get shared => StoreFactory.shared.getStore<AudioEffectStore>();

  /// State
  ///
  /// @param state State.
  AudioEffectState get audioEffectState;

  /// Set voice changer effect
  ///
  /// Through this interface, you can set the voice changer effect for human voice.
  ///
  /// Voice changer effects can be applied to human voice, and the voice is processed secondarily through acoustic algorithms to obtain a timbre different from the original sound.
  ///
  /// - [type] : Voice changer effect type.
  void setAudioChangerType(AudioChangerType type);

  /// Set reverb effect
  ///
  /// Through this interface, you can set the reverb effect for human voice.
  ///
  /// Reverb effects can be applied to human voice, and the sound is processed through acoustic algorithms to simulate the presence in various different environments.
  ///
  /// - [type] : Reverb effect type.
  void setAudioReverbType(AudioReverbType type);

  /// Enable/disable ear monitor
  ///
  /// After the anchor enables ear monitor, they can hear their own voice captured by the microphone in the earphones. This effect is suitable for anchor singing application scenarios.
  ///
  /// - [enable] : Whether to enable ear monitor.
  void setVoiceEarMonitorEnable(bool enable);

  /// Set ear monitor volume
  ///
  /// Through this interface, you can set the volume of the sound in the ear monitor effect.
  ///
  /// - [volume] : Ear monitor volume, with a value range from 0 to 100.
  void setVoiceEarMonitorVolume(int volume);

  /// Reset to default state
  ///
  /// Reset all audio effect settings to default values, including disabling voice changer effect, disabling reverb effect, disabling ear monitor, and resetting ear monitor volume.
  void reset();
}
