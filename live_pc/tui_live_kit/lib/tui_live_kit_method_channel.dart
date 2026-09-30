import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tui_live_kit_platform_interface.dart';

/// An implementation of [TuiLiveKitPlatform] that uses method channels.
class MethodChannelTuiLiveKit extends TuiLiveKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tui_live_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
