// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:atomic_x_core/impl/view/live/layer/seat_layout_mixin.dart';

import '../../../../api/login/login_store.dart';
import '../../../../api/view/camera_view.dart';

class MixStreamLayer extends StatelessWidget with SeatLayoutMixin {
  final LiveCoreControllerImpl controller;
  final Size layoutSize;

  const MixStreamLayer({super.key, required this.controller, required this.layoutSize});

  @override
  Widget build(BuildContext context) {
    // TODO: Windows 端不支持观看直播(拉流走引擎 TRTCPlayer 的子 cloud 实例，atomic_engine 底层私有，无法注册自定义渲染回调)
    if (Platform.isWindows) {
      return Container(color: Colors.black);
    }
    final liveID = controller.getLiveID();
    if (liveID.isEmpty) {
      return CameraView(
        onViewCreated: (viewId) {
          controller.onMixStreamViewCreated(viewId);
        },
        onViewDisposed: (viewId) {
          controller.onMixStreamViewDisposed(viewId);
        },
      );
    }
    final InternalState internalState = controller.getInternalState();
    final mixUserId = "livekit_${LoginStore.shared.sdkAppID}_feedback_${controller.getLiveID()}";
    final videoView = CameraView(
      key: ValueKey(mixUserId),
      onViewCreated: (viewId) {
        controller.onMixStreamViewCreated(viewId);
      },
      onViewDisposed: (viewId) {
        controller.onMixStreamViewDisposed(viewId);
      },
    );
    return ListenableBuilder(
        listenable: Listenable.merge([internalState.seatList]),
        builder: (context, _) {
          InternalSeatLayout seatLayout = InternalSeatLayout(
              internalState.seatList.value.where((seat) => seat.region.w != 0 && seat.region.h != 0).toList(),
              internalState.canvas.value);
          final bool isFullScreen = isFullScreenLayoutBySeatLayout(seatLayout);
          final Size size = isFullScreen ? layoutSize : calculateSizeBySeatLayout(seatLayout, layoutSize);
          return SizedBox(
              width: size.width,
              height: size.height,
              child: ClipRect(
                clipper: _RectangleClipper(seatLayout: seatLayout, fullScreen: isFullScreen),
                child: videoView,
              ));
        });
  }
}

class _RectangleClipper extends CustomClipper<Rect> {
  final InternalSeatLayout seatLayout;
  final bool fullScreen;

  _RectangleClipper({required this.seatLayout, required this.fullScreen});

  @override
  Rect getClip(Size size) {
    if (fullScreen || seatLayout.canvas.h <= 0) {
      return Rect.fromLTRB(0, 0, size.width, size.height);
    }
    var centerTop = double.infinity;
    var centerBottom = 0.0;
    for (SeatInfo seat in seatLayout.seatList) {
      centerTop = min(seat.region.y.toDouble(), centerTop);
      centerBottom = max(seat.region.y.toDouble() + seat.region.h, centerBottom);
    }

    // Center rect of view
    final realRectTop = centerTop / seatLayout.canvas.h * size.height;
    final realRectBottom = centerBottom / seatLayout.canvas.h * size.height;
    return Rect.fromLTRB(0, realRectTop, size.width, realRectBottom);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    if (oldClipper is! _RectangleClipper) return true;
    return oldClipper.fullScreen != fullScreen || oldClipper.seatLayout != seatLayout;
  }
}
