// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:flutter/material.dart';

import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:atomic_x_core/impl/view/live/item/video_widget.dart';
import 'package:atomic_x_core/impl/view/live/layer/seat_layout_mixin.dart';
import 'package:atomic_x_core/impl/view/live/layer/template_layout_delegate.dart';

class MultiStreamLayer extends StatelessWidget with SeatLayoutMixin {
  final LiveCoreControllerImpl controller;
  final Size layoutSize;

  const MultiStreamLayer({super.key, required this.controller, required this.layoutSize});

  @override
  Widget build(BuildContext context) {
    final InternalState internalState = controller.getInternalState();
    return ListenableBuilder(
      listenable: Listenable.merge([internalState.hasVideoStreamUserList, internalState.seatList]),
      builder: (context, _) {
        final userIds = internalState.hasVideoStreamUserList.value;
        var mixUserId = userIds.firstWhere((userId) => userId.contains("_feedback_"), orElse: () => "");
        if (mixUserId.isNotEmpty) {
          return const SizedBox.shrink();
        }

        InternalSeatLayout seatLayout = InternalSeatLayout(
            internalState.seatList.value.where((seat) => seat.region.w != 0 && seat.region.h != 0).toList(),
            internalState.canvas.value);
        if (seatLayout.seatList.isEmpty || seatLayout.canvas.w <= 0 || seatLayout.canvas.h <= 0) {
          return const SizedBox.shrink();
        }
        Size size = calculateSizeBySeatLayout(seatLayout, layoutSize);
        return CustomMultiChildLayout(
          delegate:
              TemplateLayoutDelegate(seatLayout: seatLayout, layoutSize: size, scaleXRatio: getScaleXRatio(context)),
          children: <Widget>[
            for (final seat in seatLayout.seatList)
              LayoutId(
                  id: "${seat.userInfo.liveID}_${seat.index}",
                  child: VideoWidget(controller: controller, userId: seat.userInfo.userID)),
          ],
        );
      },
    );
  }
}
