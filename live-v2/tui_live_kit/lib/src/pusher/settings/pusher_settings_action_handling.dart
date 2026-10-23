import '../../common/beauty/beauty_view.dart';

class PusherSettingsState {
  PusherSettingsState({
    this.isMirrorEnabled = true,
    this.isMuted = false,
    this.captureVolume = 100,
    this.isBeautyEnabled = true,
    this.smoothLevel = 0,
    this.whitenessLevel = 0,
    this.ruddyLevel = 0,
  });

  bool isMirrorEnabled;
  bool isMuted;
  int captureVolume;
  bool isBeautyEnabled;
  BeautyViewState get beauty => BeautyViewState(
      isBeautyEnabled: isBeautyEnabled,
      smoothLevel: smoothLevel,
      whitenessLevel: whitenessLevel,
      ruddyLevel: ruddyLevel);
  double smoothLevel;
  double whitenessLevel;
  double ruddyLevel;
  bool isSameAs(PusherSettingsState other) =>
      isMirrorEnabled == other.isMirrorEnabled &&
      isMuted == other.isMuted &&
      captureVolume == other.captureVolume &&
      isBeautyEnabled == other.isBeautyEnabled &&
      smoothLevel == other.smoothLevel &&
      whitenessLevel == other.whitenessLevel &&
      ruddyLevel == other.ruddyLevel;

  PusherSettingsState copy() => PusherSettingsState(
        isMirrorEnabled: isMirrorEnabled,
        isMuted: isMuted,
        captureVolume: captureVolume,
        isBeautyEnabled: isBeautyEnabled,
        smoothLevel: smoothLevel,
        whitenessLevel: whitenessLevel,
        ruddyLevel: ruddyLevel,
      );
}

abstract interface class PusherSettingsActionHandling {
  void toggleMirror();
  void setCaptureVolume(int volume);
  void setBeautyEnabled(bool enabled);
  void setSmoothLevel(double level);
  void setWhitenessLevel(double level);
  void setRuddyLevel(double level);
}
