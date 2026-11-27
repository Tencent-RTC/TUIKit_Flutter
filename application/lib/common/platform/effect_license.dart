import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_effect_player/ftceffect_player.dart';
import '../../debug/generate_test_user_sig.dart';

/// Uses the Live plugin's existing TEBeautyKit license command (iOS 15+, Android 24+)
/// followed by FTCMediaXBase. Missing configuration skips authorization; the SDK's
/// basic beauty remains available. Completion means submission, not authorization success.
class AppEffectLicense {
  static const _beauty = MethodChannel('tui_live_kit/advanced_beauty');
  static Future<void>? _pending;
  static Future<void> initialize() => _pending ??= _submit().whenComplete(() => _pending = null);
  static Future<void> _submit() async {
    const url = GenerateTestUserSig.effectLicenseUrl;
    const key = GenerateTestUserSig.effectLicenseKey;
    if (url.isEmpty || key.isEmpty) return;
    try {
      final result = await _beauty
          .invokeMethod<int>('setLicense', {'url': url, 'key': key})
          .timeout(const Duration(seconds: 10), onTimeout: () => -1);
      debugPrint('[AppUIKit] beauty license result=$result');
      await FTCMediaXBase.instance.setLicense(
        url,
        key,
        (code, message) => debugPrint('[AppUIKit] effect license result=$code'),
      );
    } catch (error) {
      debugPrint(
        '[AppUIKit] effect license submission failed: ${error is PlatformException ? error.code : error.runtimeType}',
      );
    }
  }
}
