import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tencent_conference_uikit_platform_interface.dart';

/// An implementation of [TencentConferenceUikitPlatform] that uses method channels.
class MethodChannelTencentConferenceUikit extends TencentConferenceUikitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tencent_conference_uikit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> enableWakeLock(bool enable) async {
    await methodChannel.invokeMethod('enableWakeLock', {'enable': enable});
  }

  @override
  Future<void> startForegroundService(ForegroundServiceType type, String title, String description) async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod(
          'startForegroundService', {'serviceType': type.index, 'title': title, 'description': description});
    }
  }

  @override
  Future<void> stopForegroundService(ForegroundServiceType type) async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod('stopForegroundService', {'serviceType': type.index});
    }
  }
}
