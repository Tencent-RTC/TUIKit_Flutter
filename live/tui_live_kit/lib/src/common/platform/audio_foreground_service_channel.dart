import 'dart:async';

import 'package:flutter/services.dart';

import '../live_kit_resources.dart';

/// 观众上麦开麦期间的后台保活入口。
///
/// | 平台 | 实现方式 |
/// |---|---|
/// | Android | `tui_live_kit` 插件内的 microphone 类型前台服务，经 MethodChannel 启停 |
/// | iOS | 宿主 App 在 `Info.plist` 声明 `UIBackgroundModes = audio`，不启动任何服务 |
///
/// 与 Android `tuilivekit` 的 `AudioForegroundService` 语义一致：只保证开麦期间
/// 进程不被后台挂起，不保证网络永不断或进程被系统杀死后恢复。启动失败不改变
/// 连麦业务状态，回到前台可再次尝试。
abstract final class AudioForegroundServiceChannel {
  static const MethodChannel _channel =
      MethodChannel('tui_live_kit/audio_foreground_service');

  /// 启动前台服务。
  ///
  /// 返回 false 表示原生侧未启动（未授权麦克风、系统拒绝或平台不支持），
  /// 调用方不因失败改变连麦状态。iOS 恒为 true：其保活由宿主声明提供。
  static Future<bool> start() async {
    try {
      final bool? started = await _channel.invokeMethod<bool>('start', <String, String>{
        'title': LiveKitResources
            .localizedString('tuilivekit.player.coguest.service_title'),
        'description': LiveKitResources
            .localizedString('tuilivekit.player.coguest.service_description'),
      });
      return started ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
