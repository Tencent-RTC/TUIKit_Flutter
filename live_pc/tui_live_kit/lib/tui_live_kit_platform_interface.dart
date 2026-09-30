import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tui_live_kit_method_channel.dart';

abstract class TuiLiveKitPlatform extends PlatformInterface {
  /// Constructs a TuiLiveKitPlatform.
  TuiLiveKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static TuiLiveKitPlatform _instance = MethodChannelTuiLiveKit();

  /// The default instance of [TuiLiveKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelTuiLiveKit].
  static TuiLiveKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TuiLiveKitPlatform] when
  /// they register themselves.
  static set instance(TuiLiveKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
