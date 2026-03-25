import 'package:flutter/cupertino.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';

class LSMediaState {
  final ValueNotifier<bool> isAudioLocked = ValueNotifier(false);
  final ValueNotifier<bool> isVideoLocked = ValueNotifier(false);
  final ValueNotifier<TUIVideoQuality?> playbackQuality = ValueNotifier(null);
  final ValueNotifier<List<TUIVideoQuality>> playbackQualityList = ValueNotifier([]);
  final ValueNotifier<bool> isRemoteVideoStreamPaused = ValueNotifier(false);
  final ValueNotifier<int> currentPlayoutVolume = ValueNotifier(100);
  final ValueNotifier<bool> isScreenCaptured = ValueNotifier(false);// only ios
}