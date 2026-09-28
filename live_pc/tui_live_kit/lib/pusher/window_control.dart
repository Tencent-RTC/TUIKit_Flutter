import 'dart:io';
import 'package:flutter/services.dart';

class WindowControl {
  WindowControl._();

  static const MethodChannel _channel = MethodChannel('window_control');

  static Future<void> startDragging() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod<void>('startDragging');
    } catch (_) {
      // 通道未注册 / native 报错时忽略：拖拽仅为辅助操作，失败不影响交互。
    }
  }
}
