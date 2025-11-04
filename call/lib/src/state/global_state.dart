
class GlobalState {
  static GlobalState instance  =  GlobalState._internal();
  GlobalState._internal(){}

  bool _enableMuteMode = false;
  bool _enableFloatWindow = false;
  bool _enableBlurBackground = false;
  bool _enableIncomingBanner = false;
  String? _callingBellAssetName;

  bool get enableMuteMode => _enableMuteMode;
  bool get enableFloatWindow => _enableFloatWindow;
  bool get enableBlurBackground => _enableBlurBackground;
  bool get enableIncomingBanner => _enableIncomingBanner;
  String? get callingBellAssetName => _callingBellAssetName;

  void setEnableMuteMode(bool enable) {
    _enableMuteMode = enable;
  }

  void setEnableFloatWindow(bool enable) {
    _enableFloatWindow = enable;
  }

  void setEnableBlurBackground(bool enable) {
    _enableBlurBackground = enable;
  }

  void setEnableIncomingBanner(bool enable) {
    _enableIncomingBanner = enable;
  }

  void setCallingBellAssetName(String assetName) {
    _callingBellAssetName = assetName;
  }
}