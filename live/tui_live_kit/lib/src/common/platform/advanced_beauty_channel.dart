import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

/// Native TEBeautyKit + TRTC shared camera processing (iOS 12+, Android 21+).
/// Unsupported platforms or missing plugins retain the basic beauty panel.
/// Only commands and lifecycle events cross this channel, never video frames.
class AdvancedBeautyChannel {
  static const _channel = MethodChannel('tui_live_kit/advanced_beauty');
  static final _events = StreamController<MethodCall>.broadcast();
  static bool _initialized = false;
  static bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  static Stream<MethodCall> get events {
    _initialize();
    return _events.stream;
  }

  static void _initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async => _events.add(call));
  }

  static Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    if (!supported) return null;
    _initialize();
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      debugPrint('TUILiveKit beauty: native plugin missing for $method; rebuild the app after pod install/pub get.');
      return null;
    } on PlatformException catch (error) {
      debugPrint('TUILiveKit beauty: $method failed (${error.code}).');
      return null;
    }
  }

  static Future<void> setLicense(String url, String key) async {
    if (!supported) return;
    final code = await _invoke<int>('setLicense', {'url': url, 'key': key})
        .timeout(const Duration(seconds: 10), onTimeout: () => -1);
    if (code != null && code != 0) debugPrint('TUILiveKit beauty: license result=$code');
  }

  static Future<void> configure({required String? key, required int generation, required bool enabled}) async {
    await _invoke<void>('configure', {'key': key, 'generation': generation, 'enabled': enabled});
  }

  static Future<bool> show(int presentation) async =>
      await _invoke<bool>('show', {'presentation': presentation}) ?? false;

  /// Wait for the native processor to finish authorization/GL setup before falling back.
  /// A fresh command after readiness also checks that the native host is attached.
  static Future<bool> showWhenReady(int presentation, {required bool Function() isCurrent}) async {
    if (!supported) return false;
    final ready = Completer<void>();
    final subscription = events.listen((call) {
      if (call.method == 'processing' &&
          call.arguments is Map &&
          (call.arguments as Map)['ready'] == true &&
          !ready.isCompleted) ready.complete();
    });
    try {
      if (await show(presentation)) return true;
      if (!isCurrent()) return false;
      final status = await _invoke<String>('status');
      if (status != 'pending' && status != 'ready') return false;
      if (status == 'pending') {
        await ready.future.timeout(const Duration(seconds: 4), onTimeout: () {});
      }
      return isCurrent() && await show(presentation);
    } finally {
      unawaited(subscription.cancel());
    }
  }

  static Future<void> dismiss(int presentation) async {
    await _invoke<void>('dismiss', {'presentation': presentation});
  }
}
