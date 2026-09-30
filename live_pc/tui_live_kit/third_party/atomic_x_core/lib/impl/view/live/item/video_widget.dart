// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'dart:io';

import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/material.dart';

import '../../../../api/view/camera_view.dart';
import '../../../common/log.dart';

final Log _logger = Log.getLiveLog("VideoWidget");

class VideoWidget extends StatelessWidget {
  final LiveCoreControllerImpl controller;
  final String userId;

  const VideoWidget({super.key, required this.controller, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }
    // TODO: windows 端暂不支持连麦，不支持显示远端视频，非本地用户不显示
    if (Platform.isWindows && !_isSelfVideoWidget()) {
      return Container(color: Colors.black);
    }
    final widgetKey = userId;
    return Container(
      color: Colors.transparent,
      child: CameraView(
        key: ValueKey(widgetKey),
        onViewCreated: (id) {
          _onViewCreated(id);
        },
        onViewDisposed: (id) {
          _onViewDisposed(id);
        },
      ),
    );
  }

  bool _isSelfVideoWidget() {
    return userId == LoginStore.shared.loginState.loginUserInfo?.userID;
  }

  void _onViewCreated(int viewID) {
    _logger.info("onViewCreated, userId=$userId, viewID=$viewID");
    controller.setVideoView(userId, viewID);
    if (!_isSelfVideoWidget()) {
      controller.startPlayVideo(userId);
    }
  }

  void _onViewDisposed(int viewID) {
    _logger.info("onViewDisposed, userId=$userId, viewID=$viewID");
    controller.setVideoView(userId, 0);
    if (!_isSelfVideoWidget()) {
      if (controller.getInternalState().hasVideoStreamUserList.value.any((user) => user == userId)) {
        return;
      }
      controller.stopPlayVideo(userId);
    }
  }
}
