import 'package:flutter/services.dart';

class DeviceChannel {
  static const MethodChannel _channel = MethodChannel('atomic_x/device_info');

  static Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getDeviceInfo');
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Failed to get device info: ${e.toString()}');
      return null;
    }
  }
}