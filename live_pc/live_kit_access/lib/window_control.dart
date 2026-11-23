import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// macOS: drag only (system traffic lights); Windows: drag + min/max/close + maximize-state events.
class WindowControl {
  WindowControl._();

  static const MethodChannel _channel = MethodChannel('window_control');

  static final ValueNotifier<bool> isMaximized = ValueNotifier<bool>(false);

  static bool _inited = false;

  /// Registers the maximize-state listener; call before reading
  /// [isMaximized] (the title bar buttons do this in initState).
  static void ensureInitialized() {
    if (_inited || !Platform.isWindows) return;
    _inited = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMaximizedChanged') {
        isMaximized.value = call.arguments == true;
      }
      return null;
    });
  }

  static Future<void> startDragging() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('startDragging');
    } catch (_) {
      // Channel unregistered / native error: dragging is auxiliary only,
      // failures never affect interaction.
    }
  }

  static Future<void> minimize() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('minimize');
    } catch (_) {}
  }

  static Future<void> toggleMaximize() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('toggleMaximize');
    } catch (_) {}
  }

  static Future<void> close() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('close');
    } catch (_) {}
  }
}
