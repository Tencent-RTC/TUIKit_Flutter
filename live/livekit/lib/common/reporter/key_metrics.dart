import 'dart:convert';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../constants/index.dart';


const kDemoLoginSuccess = 1302;
const kDemoClickCall = 1303;
const kDemoClickLive = 1119;
const kDemoClickRoom = 1205;

class KeyMetrics {
  static void reportComponent(LiveComponentType componentType) {
    var component = Constants.dataReportComponentLiveRoom;
    switch (componentType) {
      case LiveComponentType.liveRoom:
        component = Constants.dataReportComponentLiveRoom;
        break;
      case LiveComponentType.voiceRoom:
        component = Constants.dataReportComponentVoiceRoom;
        break;
    }

    try {
      Map<String, dynamic> params = {
        'framework': Constants.dataReportFramework,
        'component': component,
        'language': Constants.dataReportLanguageFlutter,
      };

      Map<String, dynamic> jsonObject = {
        'api': 'setFramework',
        'params': params,
      };

      String jsonString = jsonEncode(jsonObject);
      LiveCoreController.callExperimentalAPI(jsonString);
    } catch (e) {
      debugPrint('Error reporting component');
    }
  }

  static const kLiveIntegrationSuccessful = 1120;

  static void reportKeyMetrics(int keyMetrics) {
    Map<String, dynamic> param = {
      'report_tuifeature_usage_uicomponent_type': keyMetrics,
    };

    TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
      api: 'report_tuifeature_usage',
      param: param,
    );
  }
}

enum LiveComponentType { liveRoom, voiceRoom }
