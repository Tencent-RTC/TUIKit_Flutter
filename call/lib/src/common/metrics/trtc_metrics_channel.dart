import 'dart:convert';

import 'package:tencent_calls_uikit/src/common/constants.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'key_metrics.dart';

class TRTCMetricsChannel {
  final String _tag = "TRTCMetrics";

  Future<void> countEvent(EventId eventId) async {
    try {
      final trtcCloud = await TRTCCloud.sharedInstance();

      final paramsJson = {
        "opt": "CountPV",
        "key": eventId.value(),
        "withInstanceTrace": false,
        "version": Constants.pluginVersion,
      };

      final jsonParams = {
        "api": "KeyMetricsStats",
        "params": paramsJson,
      };

      trtcCloud.callExperimentalAPI(jsonEncode(jsonParams));
    } catch (e) {
      print('$_tag: countEvent call exception: eventId=$eventId, error=$e');
    }
    await _flushMetrics();
  }

  Future<void> _flushMetrics() async {
    try {
      final trtcCloud = await TRTCCloud.sharedInstance();

      final paramsJson = {
        "sdkAppId": TUILogin.instance.sdkAppId,
        "report": "report",
      };

      final jsonParams = {
        "api": "KeyMetricsStats",
        "params": paramsJson,
      };

      trtcCloud.callExperimentalAPI(jsonEncode(jsonParams));
    } catch (e) {
      print('$_tag: flushMetrics exception: error=$e');
    }
  }
}
