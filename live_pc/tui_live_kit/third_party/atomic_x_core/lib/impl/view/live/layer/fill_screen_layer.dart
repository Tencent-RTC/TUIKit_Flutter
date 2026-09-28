// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'dart:math';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:atomic_x_core/impl/view/live/layer/seat_layout_mixin.dart';
import 'package:flutter/material.dart';

class FillScreenLayer extends StatelessWidget {
  static const int kTemplateID200 = 200;
  final LiveCoreControllerImpl controller;
  final VideoWidgetBuilder? videoWidgetBuilder;
  final Size layoutSize;

  const FillScreenLayer({super.key, required this.controller, required this.layoutSize, this.videoWidgetBuilder});

  @override
  Widget build(BuildContext context) {
    final InternalState internalState = controller.getInternalState();
    return ListenableBuilder(
        listenable: internalState.seatList,
        builder: (context, _) {
          InternalSeatLayout seatLayout = InternalSeatLayout(internalState.seatList.value, internalState.canvas.value);
          if (seatLayout.seatList.length < 2) {
            return const SizedBox.shrink();
          }
          if (seatLayout.canvas.templateID == kTemplateID200) {
            return const SizedBox.shrink();
          }
          if (isFullScreenLayoutBySeatLayout(seatLayout)) {
            return _buildFillScreenWidget(context);
          }
          final w = layoutSize.width;
          final h = layoutSize.width * (seatLayout.canvas.h / seatLayout.canvas.w);
          final rect = _getClip(Size(w, h), seatLayout);
          return Container(
              padding: EdgeInsets.only(top: rect.top),
              child:
                  SizedBox(width: rect.right, height: rect.bottom - rect.top, child: _buildFillScreenWidget(context)));
        });
  }

  Widget _buildFillScreenWidget(BuildContext context) {
    final builder = videoWidgetBuilder?.battleContainerWidgetBuilder;
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(context);
  }

  Rect _getClip(Size size, InternalSeatLayout seatLayout) {
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

  bool isFullScreenLayoutBySeatLayout(InternalSeatLayout seatLayout) {
    if (seatLayout.seatList.length <= 1) {
      return true;
    }
    for (SeatInfo seat in seatLayout.seatList) {
      if (seat.region.w == seatLayout.canvas.w && seat.region.h == seatLayout.canvas.h) {
        return true;
      }
    }
    return false;
  }
}
