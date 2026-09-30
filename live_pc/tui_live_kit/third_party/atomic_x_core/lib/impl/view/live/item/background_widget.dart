// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final LiveCoreControllerImpl controller;
  final SeatInfo seatInfo;
  final VideoWidgetBuilder? videoWidgetBuilder;

  const BackgroundWidget({super.key, required this.seatInfo, required this.controller, this.videoWidgetBuilder});

  @override
  Widget build(BuildContext context) {
    final liveID = controller.getLiveID();
    final isSameRoom = seatInfo.userInfo.liveID == liveID;
    final showCoGuestWidget =
        isSameRoom && (seatInfo.userInfo.cameraStatus != DeviceStatus.on || seatInfo.userInfo.userID.isEmpty);
    final showCoHostWidget =
        !isSameRoom && (seatInfo.userInfo.cameraStatus != DeviceStatus.on || seatInfo.userInfo.userID.isEmpty);
    return Stack(children: [
      Visibility(visible: showCoGuestWidget, child: _buildCoGuestWidget(context)),
      Visibility(visible: showCoHostWidget, child: _buildCoHostWidget(context)),
    ]);
  }

  Widget _buildCoGuestWidget(BuildContext context) {
    final coGuestWidgetBuilder = videoWidgetBuilder?.coGuestWidgetBuilder;
    if (coGuestWidgetBuilder == null) {
      return const SizedBox.shrink();
    }
    return coGuestWidgetBuilder(context, seatInfo, ViewLayer.background);
  }

  Widget _buildCoHostWidget(BuildContext context) {
    final coHostWidgetBuilder = videoWidgetBuilder?.coHostWidgetBuilder;
    if (coHostWidgetBuilder == null) {
      return const SizedBox.shrink();
    }
    return coHostWidgetBuilder(context, seatInfo, ViewLayer.background);
  }
}
