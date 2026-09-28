// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:atomic_x_core/impl/view/live/item/foreground_widget.dart';
import 'package:atomic_x_core/impl/view/live/layer/seat_layout_mixin.dart';
import 'package:atomic_x_core/impl/view/live/layer/template_layout_delegate.dart';
import 'package:flutter/material.dart';

class ForegroundWidgetLayer extends StatelessWidget with SeatLayoutMixin {
  static const int kTemplateID200 = 200;
  final LiveCoreControllerImpl controller;
  final VideoWidgetBuilder? videoWidgetBuilder;
  final Size layoutSize;

  const ForegroundWidgetLayer({super.key, required this.controller, required this.layoutSize, this.videoWidgetBuilder});

  @override
  Widget build(BuildContext context) {
    final InternalState internalState = controller.getInternalState();
    return ListenableBuilder(
      listenable: internalState.seatList,
      builder: (context, _) {
        InternalSeatLayout seatLayout = InternalSeatLayout(
            internalState.seatList.value.where((seat) => seat.region.w != 0 && seat.region.h != 0).toList(),
            internalState.canvas.value);
        if (seatLayout.canvas.templateID == kTemplateID200) {
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
                  child: ForegroundWidget(
                    seatInfo: seat,
                    controller: controller,
                    videoWidgetBuilder: videoWidgetBuilder,
                  )),
          ],
        );
      },
    );
  }
}
