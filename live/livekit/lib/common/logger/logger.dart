import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';

import '../constants/constants.dart';

enum LiveKitLoggerLevel { info, warning, error }

class LiveKitLogger {
  static const String moduleName = Constants.liveKitLog;

  static void info(String message) async {
    await _log(LiveKitLoggerLevel.info, message);
  }

  static void warning(String message) async {
    await _log(LiveKitLoggerLevel.warning, message);
  }

  static void error(String message) async {
    await _log(LiveKitLoggerLevel.error, message);
  }

  static Future<void> _log(LiveKitLoggerLevel level, String message) async {
    var chain = Chain.current();
    chain = chain.foldFrames((frame) => frame.isCore || frame.package == "flutter");
    final frames = chain.toTrace().frames;
    final index = frames.indexWhere((frame) => frame.member == 'LiveKitLogger._log');
    if (index == -1 || index + 2 >= frames.length) return;

    final frame = frames[index + 2];
    final file = frame.uri.toString().split('/').last;
    final line = frame.line ?? 0;

    final Map<String, dynamic> jsonObject = {
      'api': 'TuikitLog',
      'params': {'module': moduleName, 'level': level.index, 'message': message, 'file': file, 'line': line}
    };
    final jsonString = jsonEncode(jsonObject);
    TRTCCloud.sharedInstance().then((trtcCloud) => trtcCloud.callExperimentalAPI(jsonString));
  }
}
