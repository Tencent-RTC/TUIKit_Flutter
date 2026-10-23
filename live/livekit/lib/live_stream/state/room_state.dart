import 'package:atomic_x_core/api/live/live_list_store.dart' hide LiveStatus;
import 'package:flutter/material.dart';

import '../live_define.dart';

class LSRoomState {
  VideoStreamSource videoStreamSource = VideoStreamSource.camera;
  String roomId = '';
  LiveInfo liveInfo = LiveInfo();
  String roomName = '';
  final ValueNotifier<String> coverUrl = ValueNotifier('');
  final ValueNotifier<LiveStatus> liveStatus = ValueNotifier(LiveStatus.none);
  final ValueNotifier<bool> roomVideoStreamIsLandscape = ValueNotifier(false);
}
