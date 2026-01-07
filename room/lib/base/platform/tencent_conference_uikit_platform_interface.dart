import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tencent_conference_uikit_method_channel.dart';

abstract class TencentConferenceUikitPlatform extends PlatformInterface {
  /// Constructs a TencentConferenceUikitPlatform.
  TencentConferenceUikitPlatform() : super(token: _token);

  static final Object _token = Object();

  static TencentConferenceUikitPlatform _instance = MethodChannelTencentConferenceUikit();

  /// The default instance of [TencentConferenceUikitPlatform] to use.
  ///
  /// Defaults to [MethodChannelTencentConferenceUikit].
  static TencentConferenceUikitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TencentConferenceUikitPlatform] when
  /// they register themselves.
  static set instance(TencentConferenceUikitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> enableWakeLock(bool enable) async {
    await instance.enableWakeLock(enable);
  }

  Future<void> startForegroundService(ForegroundServiceType type, String title, String description) async {
    await instance.startForegroundService(type, title, description);
  }

  Future<void> stopForegroundService(ForegroundServiceType type) async {
    await instance.stopForegroundService(type);
  }
}

enum ForegroundServiceType { video, audio, media }
