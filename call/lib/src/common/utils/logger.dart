import 'dart:convert';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
class Logger {
  static void info(String message) {
    _log(message, level: 0);
  }

  static void warning(String message) {
    _log(message, level: 1);
  }

  static void error(String message) {
    _log(message, level: 2);
  }

  static void _log(String message, {int level = 0}) async {
    final Map<String, dynamic> dictionary = {
      "api": "TuikitLog",
      "params": {
        "level": level,
        "message": "TUICallKit[Flutter] - $message",
        "file": "/some_path/.../foo.c",
        "line": 90
      }
    };

    try {
      final jsonString = json.encode(dictionary).toString();
      var trtcCloud = await TRTCCloud.sharedInstance();
      trtcCloud.callExperimentalAPI(jsonString);
    } catch (e) {
      print("Error converting map to JSON: $e");
    }
  }
}