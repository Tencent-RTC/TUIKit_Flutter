import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';

import '../live_define.dart';

class LSRoomState {
  String roomId = '';
  LiveInfo liveInfo = LiveInfo();
  int createTime = 0;
  String roomName = '';
  final ValueNotifier<String> coverUrl = ValueNotifier('');
  int userCount = 0;
  final ValueNotifier<LiveStatus> liveStatus = ValueNotifier(LiveStatus.none);
  LiveExtraInfo liveExtraInfo = LiveExtraInfo();
  final ValueNotifier<bool> roomVideoStreamIsLandscape = ValueNotifier(false);
}

class LiveExtraInfo {
  LiveStreamPrivacyStatus liveMode = LiveStreamPrivacyStatus.public;
  int maxAudienceCount = 0;
  int messageCount = 0;
  int giftIncome = 0;
  Set<String> giftPeopleSet = {};
  int likeCount = 0;
  int activeStatus = 0;
}
