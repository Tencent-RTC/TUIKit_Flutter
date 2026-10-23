import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/cupertino.dart';

class LSMediaState {
  final ValueNotifier<bool> isAudioLocked = ValueNotifier(false);
  final ValueNotifier<bool> isVideoLocked = ValueNotifier(false);
  final ValueNotifier<VideoQuality?> playbackQuality = ValueNotifier(null);
  final ValueNotifier<List<VideoQuality>> playbackQualityList = ValueNotifier([]);
  final ValueNotifier<bool> isRemoteVideoStreamPaused = ValueNotifier(false);
  final ValueNotifier<int> currentPlayoutVolume = ValueNotifier(100);
  final ValueNotifier<bool> isScreenCaptured = ValueNotifier(false);// only ios
}