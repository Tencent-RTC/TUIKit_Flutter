import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/cupertino.dart';

class NetWorkInfoState {
  ValueNotifier<VideoState> videoState = ValueNotifier(VideoState.normal);
  ValueNotifier<int> videoResolution = ValueNotifier(720);

  ValueNotifier<AudioState> audioState = ValueNotifier(AudioState.normal);

  ValueNotifier<int> rtt = ValueNotifier(0);
  ValueNotifier<int> upLoss = ValueNotifier(9);
  ValueNotifier<int> downLoss = ValueNotifier(0);
  ValueNotifier<int> uploadSpeed = ValueNotifier(0);
  ValueNotifier<NetworkQuality> networkQuality = ValueNotifier(NetworkQuality.excellent);

  ValueNotifier<int> deviceTemperature = ValueNotifier(0);
  ValueNotifier<bool> showToast = ValueNotifier(false);
}

enum AudioState { mute, close, normal, exception }

enum VideoState { close, normal, exception }
