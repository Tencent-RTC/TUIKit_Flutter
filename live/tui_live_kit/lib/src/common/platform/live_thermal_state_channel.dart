/// 系统热状态。
///
/// AtomicXCore 未提供该能力，由 `tui_live_kit` 自己的 plugin 层封装：
///
/// | 平台 | 原生 API | 最低可用版本 | 不可用时的取值 |
/// |---|---|---|---|
/// | iOS | `ProcessInfo.processInfo.thermalState` + `thermalStateDidChangeNotification` | iOS 11 | — |
/// | Android | `PowerManager.getCurrentThermalStatus()` + `addThermalStatusListener()` | API 29 | [LiveThermalState.normal] |
///
/// Android API 29 以下没有等价系统能力，插件固定上报 [LiveThermalState.normal]，
/// 因此低版本机型的温度行始终显示正常。
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// 归一化后的热状态档位。取值与原生侧上报的整数一一对应。
enum LiveThermalState {
  /// iOS `nominal`；Android `THERMAL_STATUS_NONE`。
  normal,

  /// iOS `fair`；Android `THERMAL_STATUS_LIGHT`、`THERMAL_STATUS_MODERATE`。
  fair,

  /// iOS `serious`、`critical`；Android `THERMAL_STATUS_SEVERE` 及以上。
  serious,
}

/// 系统热状态订阅入口。
///
/// 仅供组件库内的入口级 Store 使用；Widget 与页面不直接访问平台通道。
abstract final class LiveThermalStateChannel {
  static const EventChannel _channel =
      EventChannel('tui_live_kit/thermal_state');

  static Stream<LiveThermalState>? _states;

  /// 当前热状态流。订阅后原生侧会立即推送一次当前值。
  ///
  /// 平台通道异常时按 [LiveThermalState.normal] 处理，不向调用方抛错：
  /// 温度行只是状态展示，不应因此中断直播状态面板。
  static Stream<LiveThermalState> get states {
    return _states ??= _channel
        .receiveBroadcastStream()
        .transform(StreamTransformer<dynamic, LiveThermalState>.fromHandlers(
          handleData: (value, sink) => sink.add(_fromPlatformValue(value)),
          handleError: (error, stackTrace, sink) =>
              sink.add(LiveThermalState.normal),
        ));
  }

  static LiveThermalState _fromPlatformValue(dynamic value) {
    switch (value) {
      case 1:
        return LiveThermalState.fair;
      case 2:
        return LiveThermalState.serious;
      default:
        return LiveThermalState.normal;
    }
  }
}
