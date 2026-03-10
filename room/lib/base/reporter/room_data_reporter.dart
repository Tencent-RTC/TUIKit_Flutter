import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../constants/index.dart';

class RoomDataReporter {
  static void reportComponent() {
    try {
      Map<String, dynamic> params = {
        'framework': RoomConstants.dataReportFramework,
        'component': RoomConstants.dataReportRoomComponent,
        'language': RoomConstants.dataReportLanguageFlutter,
      };

      Map<String, dynamic> jsonObject = {
        'api': 'setFramework',
        'params': params,
      };

      String jsonString = jsonEncode(jsonObject);
      TUIRoomEngine.sharedInstance().invokeExperimentalAPI(jsonString);
    } catch (e) {
      debugPrint('Error reporting component');
    }
  }
}
