import 'dart:convert';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/foundation.dart';

import '../constants/index.dart';

class LiveDataReporter {
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
}

enum LiveComponentType { liveRoom, voiceRoom }
