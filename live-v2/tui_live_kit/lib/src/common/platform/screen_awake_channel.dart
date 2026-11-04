import 'package:flutter/services.dart';

/// Pusher 的屏幕常亮租约，不影响推流和设备状态。
/// Android API 1+ 使用 Window.FLAG_KEEP_SCREEN_ON；iOS 2+ 使用
/// UIApplication.isIdleTimerDisabled。最后一个租约释放时恢复原值。
/// 未注册此桥的平台返回 false，保留系统默认息屏行为。
abstract final class ScreenAwakeChannel {
  static const _channel = MethodChannel('tui_live_kit/screen_awake');

  static Future<bool> setEnabled(String owner, bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', {'owner': owner, 'enabled': enabled});
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
