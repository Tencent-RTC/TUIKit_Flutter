// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ForegroundWidget extends StatelessWidget {
  final LiveCoreControllerImpl controller;
  final SeatInfo seatInfo;
  final VideoWidgetBuilder? videoWidgetBuilder;

  const ForegroundWidget({super.key, required this.seatInfo, required this.controller, this.videoWidgetBuilder});

  @override
  Widget build(BuildContext context) {
    final liveID = controller.getLiveID();
    final isSameRoom = seatInfo.userInfo.liveID == liveID;
    return Stack(children: [
      Visibility(visible: isSameRoom, child: _buildCoGuestWidget(context)),
      _buildCoHostWidget(context),
      _buildBattleWidget(context),
    ]);
  }

  Widget _buildCoGuestWidget(BuildContext context) {
    final coGuestWidgetBuilder = videoWidgetBuilder?.coGuestWidgetBuilder;
    if (coGuestWidgetBuilder == null) {
      return const SizedBox.shrink();
    }
    return coGuestWidgetBuilder(context, seatInfo, ViewLayer.foreground);
  }

  Widget _buildCoHostWidget(BuildContext context) {
    final coHostWidgetBuilder = videoWidgetBuilder?.coHostWidgetBuilder;
    if (coHostWidgetBuilder == null) {
      return const SizedBox.shrink();
    }
    return coHostWidgetBuilder(context, seatInfo, ViewLayer.foreground);
  }

  Widget _buildBattleWidget(BuildContext context) {
    final battleWidgetBuilder = videoWidgetBuilder?.battleWidgetBuilder;
    if (battleWidgetBuilder == null) {
      return const SizedBox.shrink();
    }
    return battleWidgetBuilder(context, seatInfo);
  }
}
