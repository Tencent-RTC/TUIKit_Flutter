/// 系统网络类型。
///
/// AtomicXCore 的 `DeviceState` 只提供 `networkInfo`（质量、延时、丢包），
/// 没有 Swift 侧的 `networkType`，因此由 `tui_live_kit` 自己的 plugin 层封装：
///
/// | 平台 | 原生 API | 最低可用版本 | 不可用时的取值 |
/// |---|---|---|---|
/// | iOS | `NWPathMonitor` + `path.usesInterfaceType(.wifi/.cellular)` | iOS 12 | [LiveNetworkType.unknown] |
/// | Android | `ConnectivityManager.getNetworkCapabilities` + `TRANSPORT_WIFI` / `TRANSPORT_CELLULAR` | API 23 | [LiveNetworkType.unknown] |
///
/// Android API 23 以下需要已废弃的 `getActiveNetworkInfo`，本插件不再使用，
/// 统一上报 [LiveNetworkType.unknown]；以太网与其他链路同样归为 unknown，
/// 与 iOS `NetworkKind` 只区分 Wi-Fi、蜂窝、未知的语义一致。
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// 归一化后的网络类型。取值与原生侧上报的整数一一对应。
enum LiveNetworkType {
  /// 无网络、以太网或无法判定。
  unknown,

  /// iOS `.wifi`；Android `TRANSPORT_WIFI`。
  wifi,

  /// iOS `.cellular`；Android `TRANSPORT_CELLULAR`。
  cellular,
}

/// 系统网络类型订阅入口。
///
/// 仅供组件库内的入口级 Store 使用；Widget 与页面不直接访问平台通道。
abstract final class LiveNetworkTypeChannel {
  static const EventChannel _channel =
      EventChannel('tui_live_kit/network_type');

  static Stream<LiveNetworkType>? _types;

  /// 当前网络类型流。订阅后原生侧会立即推送一次当前值。
  ///
  /// 平台通道异常时按 [LiveNetworkType.unknown] 处理，不向调用方抛错：
  /// 网络类型只是状态展示，不应因此中断直播状态面板。
  static Stream<LiveNetworkType> get types {
    return _types ??= _channel
        .receiveBroadcastStream()
        .transform(StreamTransformer<dynamic, LiveNetworkType>.fromHandlers(
          handleData: (value, sink) => sink.add(_fromPlatformValue(value)),
          handleError: (error, stackTrace, sink) =>
              sink.add(LiveNetworkType.unknown),
        ));
  }

  static LiveNetworkType _fromPlatformValue(dynamic value) {
    switch (value) {
      case 1:
        return LiveNetworkType.wifi;
      case 2:
        return LiveNetworkType.cellular;
      default:
        return LiveNetworkType.unknown;
    }
  }
}
