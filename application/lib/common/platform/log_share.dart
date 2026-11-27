import 'package:flutter/services.dart';

/// App-owned SDK log files only. iOS 15+: FileManager + UIActivityViewController;
/// Android 24+: File + FileProvider + ACTION_SEND. No files returns an empty list.
/// Other platforms are outside this application's supported targets.
class LogShare {
  static const _channel = MethodChannel('com.tencent.app_uikit/logs');
  static Future<List<Map<String, String>>> files() async {
    final result = await _channel.invokeListMethod<dynamic>('list');
    return (result ?? []).map((value) => Map<String, String>.from(value as Map)).toList();
  }

  static Future<void> share(String path) => _channel.invokeMethod<void>('share', path);
}
