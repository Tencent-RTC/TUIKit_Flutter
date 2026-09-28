// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:flutter/material.dart';

import 'package:atomic_x_core/api/live/live_seat_store.dart' hide SuspendStatus;

class InternalSeatLayout {
  final List<SeatInfo> seatList;
  final LiveCanvas canvas;

  const InternalSeatLayout(this.seatList, this.canvas);
}

mixin SeatLayoutMixin {
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  double getScaleXRatio(BuildContext context) {
    return MediaQuery.sizeOf(context).width / designWidth;
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

  Size calculateSizeBySeatLayout(InternalSeatLayout seatLayout, Size size) {
    if (isFullScreenLayoutBySeatLayout(seatLayout)) {
      return size;
    } else {
      if (seatLayout.canvas.w <= 0) {
        return size;
      }
      return Size(size.width, size.width * (seatLayout.canvas.h / seatLayout.canvas.w));
    }
  }
}
