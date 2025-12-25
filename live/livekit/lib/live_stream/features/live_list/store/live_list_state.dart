import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class LSLiveListState {
  final ValueNotifier<List<LiveInfo>> liveInfoList =
      ValueNotifier<List<LiveInfo>>([]);
  final ValueNotifier<bool> refreshStatus = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loadStatus = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isHaveMoreData = ValueNotifier<bool>(false);
  String cursor = "";
}
