import 'dart:io';

import 'package:flutter/services.dart';

import 'device_channel.dart';

enum DevicePlatform {
  unknown,
  android,
  ios,
  ohos,
  windows,
  macos
}

class Device {
  final DevicePlatform _platform;
  final String _model;
  final String _manufacturer;
  final String _version;
  final int? _sdkInt;

  Device({
    required DevicePlatform platform,
    required String model,
    required String manufacturer,
    required String version,
    int? sdkInt,
  }) : _platform = platform,
       _model = model,
       _manufacturer = manufacturer,
       _version = version,
       _sdkInt = sdkInt;

  static Device? _info;

  static Future<Device> get _instance async {
    if (_info != null) {
      return _info!;
    }
    
    try {
      final deviceInfo = await DeviceChannel.getDeviceInfo();
      
      DevicePlatform platform = _DevicePlatformExt._getDevicePlatform();
      
      _info = Device(
        platform: platform,
        model: deviceInfo?['model'] as String? ?? 'Unknown',
        manufacturer: deviceInfo?['manufacturer'] as String? ?? 'Unknown',
        version: deviceInfo?['version'] as String? ?? 'Unknown',
        sdkInt: deviceInfo?['sdkInt'] as int?,
      );
      
      return _info!;
    } on PlatformException catch (e) {
      print('Failed to get device info: ${e.message}');
      _info = Device(
        platform: DevicePlatform.unknown,
        model: 'Error',
        manufacturer: 'Error',
        version: 'Error',
      );
      return _info!;
    }
  }

  static Future<DevicePlatform> get platform async => (await _instance)._platform;
  static Future<String> get model async => (await _instance)._model;
  static Future<String> get manufacturer async => (await _instance)._manufacturer;
  static Future<String> get version async => (await _instance)._version;
  static Future<int?> get sdkInt async => (await _instance)._sdkInt;
}

extension _DevicePlatformExt on DevicePlatform {
  static DevicePlatform _getDevicePlatform() {
    if (Platform.isAndroid) return DevicePlatform.android;
    if (Platform.isIOS) return DevicePlatform.ios;
    if (Platform.isMacOS) return DevicePlatform.macos;
    if (Platform.isWindows) return DevicePlatform.windows;
    return DevicePlatform.unknown;
  }
}