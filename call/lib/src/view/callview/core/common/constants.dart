import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

class Constants {
  static const int groupCallMaxUserCount = 9;
  static const int roomIdMaxValue = 2147483647; // 2^31 - 1
  static const String spKeyEnableMuteMode = "enableMuteMode";
  static const String defaultAvatar =
      "https://dldir1.qq.com/hudongzhibo/TUIKit/resource/picture/user_default_icon.png";

  static const int blurLevelHigh = 3;
  static const int blurLevelClose = 0;

  static final Image defaultAvatarImage = Image.network(defaultAvatar, fit: BoxFit.cover,);
  static final Image loading = Image.asset('call_assets/loading.gif', package: 'tuikit_atomic_x');
  static final Map<VolumeLevel, Image> volumeIcons = {
    VolumeLevel.mute  : Image.asset('call_assets/audio_unavailable.png', package: 'tuikit_atomic_x'),
    VolumeLevel.medium: Image.asset('call_assets/speaking.png', package: 'tuikit_atomic_x'),
    VolumeLevel.high  : Image.asset('call_assets/speaking.png', package: 'tuikit_atomic_x'),
    VolumeLevel.peak  : Image.asset('call_assets/speaking.png', package: 'tuikit_atomic_x'),
  };
  static final Map<NetworkQuality, Image> networkQualityIcons = {
    NetworkQuality.bad      : Image.asset('call_assets/network_bad.png', package: 'tuikit_atomic_x'),
    NetworkQuality.veryBad  : Image.asset('call_assets/network_bad.png', package: 'tuikit_atomic_x'),
    NetworkQuality.down     : Image.asset('call_assets/network_bad.png', package: 'tuikit_atomic_x'),
  };
}