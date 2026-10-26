import 'dart:async';
import 'dart:io';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rtc_room_engine/api/common/tui_common_define.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';
import 'package:rtc_room_engine/api/room/tui_room_engine.dart';
import 'package:tencent_live_uikit/common/logger/index.dart';

import 'index.dart';

/// An implementation of [TUILiveKitPlatform] that uses method channels.
class MethodChannelTUILiveKit extends TUILiveKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tuilivekit');
  static const _thermalEventChannel = EventChannel('tuilivekit_thermal_events');
  static const _networkEventChannel = EventChannel('tuilivekit_network_events');
  static const _pipEventChannel = EventChannel('tuilivekit_pip_events');
  static const _screenCaptureEventChannel = EventChannel('tuilivekit_screen_capture_events');

  static const String stateEnterPip = "state_enter_pip";
  static const String stateLeavePip = "state_leave_pip";

  @override
  Stream<bool> get onPipModeChanged {
    if (Platform.isAndroid) {
      final rawData = _pipEventChannel.receiveBroadcastStream();
      return rawData.map((value) {
        if (value is String) {
          return value == stateEnterPip ? true : false;
        } else {
          return false;
        }
      }).asBroadcastStream();
    } else {
      return Stream<bool>.value(false).asBroadcastStream();
    }
  }

  @override
  Stream<dynamic> get onRawChanged {
    return _thermalEventChannel.receiveBroadcastStream();
  }

  @override
  Stream<ThermalState> get onThermalStateChanged {
    return onRawChanged.map((value) {
      if (value is double) {
        return _mapAndroidTemp(value);
      } else if (value is int) {
        return _mapIOSThermal(value);
      } else {
        return ThermalState.nominal;
      }
    }).asBroadcastStream();
  }

  @override
  Stream<bool> get onNetworkConnectionStateChanged {
    final rawData = _networkEventChannel.receiveBroadcastStream();
    return rawData.map((value) {
      if (value is String) {
        return value == "connected" ? true : false;
      } else {
        return false;
      }
    }).asBroadcastStream();
  }

  @override
  Stream<bool> get onScreenCaptureStateChanged {
    if (Platform.isIOS) {
      final rawData = _screenCaptureEventChannel.receiveBroadcastStream();
      return rawData.map((value) {
        if (value is bool) {
          return value;
        } else {
          return false;
        }
      }).asBroadcastStream();
    } else {
      return Stream<bool>.empty().asBroadcastStream();
    }
  }

  @override
  Future<void> startForegroundService(ForegroundServiceType type, String title, String description) async {
    LiveKitLogger.info("startForegroundService, type=$type");
    if (Platform.isIOS) return;
    await methodChannel.invokeMethod('startForegroundService', {
      'serviceType': type.index,
      'type': type.name,
      'title': title,
      'description': description,
    });
  }

  @override
  Future<void> stopForegroundService(ForegroundServiceType type) async {
    LiveKitLogger.info("stopForegroundService, type=$type");
    if (Platform.isIOS) return;
    await methodChannel.invokeMethod('stopForegroundService', {
      'serviceType': type.index,
      'type': type.name,
    });
  }

  @override
  Future<void> enableWakeLock(bool enable) async {
    await methodChannel.invokeMethod('enableWakeLock', {'enable': enable});
  }

  @override
  Future<void> openWifiSettings() async {
    await methodChannel.invokeMethod('openWifiSettings');
  }

  @override
  Future<void> openAppSettings() async {
    await methodChannel.invokeMethod('openAppSettings');
  }

  @override
  Future<void> openPipSettings() async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod("openPipSettings");
    }
  }

  @override
  Future<bool> hasPipPermission() async {
    if (Platform.isAndroid) {
      final result = await methodChannel.invokeMethod("hasPipPermission");
      return result ?? false;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> isNetworkConnected() async {
    final result = await methodChannel.invokeMethod<String>('getCurrentNetworkStatus');
    if (result == null) return false;
    return result == 'connected';
  }

  @override
  Future<bool> enablePictureInPicture(String params) async {
    if (Platform.isAndroid) {
      final result = await methodChannel.invokeMethod<bool>('enablePictureInPicture', {'params': params});
      return result ?? false;
    } else if (Platform.isIOS) {
      return await _enablePictureInPictureIOS(params);
    } else {
      return false;
    }
  }

  @override
  Future<bool> exitPictureInPicture() async {
    if (Platform.isAndroid) {
      final result = await methodChannel.invokeMethod<bool>('exitPictureInPicture');
      return result ?? false;
    }
    return false;
  }

  Future<bool> _enablePictureInPictureIOS(String params) async {
    try {
      TUIValueCallBack<String> result = await TUIRoomEngine.sharedInstance().invokeExperimentalAPI(params);
      return result.code == TUIError.success;
    } catch (e) {
      return false;
    }
  }

  static ThermalState _mapAndroidTemp(double temp) {
    if (temp < 37) return ThermalState.nominal;
    if (temp < 40) return ThermalState.fair;
    if (temp < 46) return ThermalState.serious;
    return ThermalState.critical;
  }

  static ThermalState _mapIOSThermal(int state) {
    switch (state) {
      case 0:
        return ThermalState.nominal;
      case 1:
        return ThermalState.fair;
      case 2:
        return ThermalState.serious;
      case 3:
        return ThermalState.critical;
      default:
        return ThermalState.nominal;
    }
  }
}
