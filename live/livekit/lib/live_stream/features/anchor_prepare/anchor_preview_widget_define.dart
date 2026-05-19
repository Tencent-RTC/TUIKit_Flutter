import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/live_stream/live_define.dart';

import '../../../common/constants/constants.dart';

class EditInfo {
  ValueNotifier<VideoStreamSource> videoStreamSource;
  ValueNotifier<String> roomName;
  ValueNotifier<String> coverUrl;
  ValueNotifier<LiveStreamPrivacyStatus> privacyMode;
  ValueNotifier<LiveTemplateMode> coGuestTemplateMode;
  ValueNotifier<LiveTemplateMode> coHostTemplateMode;

  EditInfo({
    VideoStreamSource videoStreamSource = VideoStreamSource.camera,
    String roomName = '',
    String? coverUrl,
    LiveStreamPrivacyStatus privacyMode = LiveStreamPrivacyStatus.public,
    LiveTemplateMode coGuestTemplateMode = LiveTemplateMode.verticalDynamicGrid,
    LiveTemplateMode coHostTemplateMode = LiveTemplateMode.verticalDynamicGrid,
  })  : videoStreamSource = ValueNotifier(videoStreamSource),
        roomName = ValueNotifier(roomName),
        coverUrl = ValueNotifier(coverUrl ?? _randomCoverUrl()),
        privacyMode = ValueNotifier(privacyMode),
        coGuestTemplateMode = ValueNotifier(coGuestTemplateMode),
        coHostTemplateMode = ValueNotifier(coHostTemplateMode);

  static String _randomCoverUrl() {
    final list = Constants.coverUrlList;
    if (list.isEmpty) {
      return Constants.defaultCoverUrl;
    }
    return list[Random().nextInt(list.length)];
  }
}

enum Feature { beauty, audioEffect, flipCamera }

typedef DidClickBack = VoidCallback;
typedef DidClickStart = Function(EditInfo editInfo);
