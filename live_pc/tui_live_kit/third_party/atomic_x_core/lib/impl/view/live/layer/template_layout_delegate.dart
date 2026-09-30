// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'dart:math';

import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/impl/view/live/layer/seat_layout_mixin.dart';
import 'package:flutter/material.dart';

/// Proxy Implementation Class for Automatic Layout Based on JSON Configuration
/// For a usage demo, refer to the json_widget in the example.
class TemplateLayoutDelegate extends MultiChildLayoutDelegate {
  static const int kDynamicFloatTemplateID601 = 601;
  static const double epsilon = 1e-10;
  final Size layoutSize;
  final InternalSeatLayout seatLayout;
  final double scaleXRatio;
  final Map<String, SeatInfo> seatMap = {};

  TemplateLayoutDelegate({required this.seatLayout, required this.layoutSize, required this.scaleXRatio}) {
    for (SeatInfo seat in seatLayout.seatList) {
      final key = _getKeyOfSeat(seat);
      seatMap[key] = seat;
    }
  }

  String _getKeyOfSeat(SeatInfo seat) {
    return "${seat.userInfo.liveID}_${seat.index}";
  }

  @override
  void performLayout(Size size) {
    List<SeatInfo> seatList = seatLayout.seatList;
    if (seatList.isEmpty) {
      return;
    }

    if (_isSingleVideoLayout(seatList)) {
      final layoutId = _getKeyOfSeat(seatList.first);
      layoutChild(layoutId, BoxConstraints.tight(layoutSize));
      positionChild(layoutId, const Offset(0, 0));
      return;
    }

    bool isSelfInSeat = selfInSeat();
    double scale = calculateScale(seatLayout);
    for (String layoutId in seatMap.keys) {
      var seat = seatMap[layoutId]!;
      Offset offset = calculateOffsetPoint(seatLayout, isSelfInSeat, seat);
      var w = seat.region.w * scale;
      var h = min(seat.region.h * scale, layoutSize.height);
      var x = isOffsetXIn601Template(seatLayout, isSelfInSeat, seat)
          ? (layoutSize.width - w - 12 * scaleXRatio)
          : (seat.region.x * scale - offset.dx);
      var y = seat.region.y * scale - offset.dy;
      layoutChild(layoutId, BoxConstraints.tight(Size(w, h)));
      positionChild(layoutId, Offset(x, y));
    }
  }

  @override
  bool shouldRelayout(covariant TemplateLayoutDelegate oldDelegate) {
    return oldDelegate.layoutSize != layoutSize || oldDelegate.seatLayout != seatLayout;
  }

  double calculateScale(InternalSeatLayout seatLayout) {
    double parentWidth = layoutSize.width;
    double parentHeight = layoutSize.height;
    if (seatLayout.canvas.w <= 0 || seatLayout.canvas.h <= 0) {
      return 1.0;
    }
    double canvasAspectRatio = seatLayout.canvas.w / seatLayout.canvas.h;
    double parentAspectRatio = parentWidth / parentHeight;
    double scale = parentWidth / seatLayout.canvas.w;
    if (canvasAspectRatio >= parentAspectRatio || (canvasAspectRatio - parentAspectRatio).abs() < epsilon) {
      if (kDynamicFloatTemplateID601 == seatLayout.canvas.templateID) {
        scale = parentHeight / seatLayout.canvas.h;
      }
    } else {
      double canvasRealH = seatLayout.canvas.h * parentWidth / seatLayout.canvas.w;
      if (kDynamicFloatTemplateID601 == seatLayout.canvas.templateID) {
        scale = canvasRealH / seatLayout.canvas.h;
      } else {
        scale = parentHeight / seatLayout.canvas.w;
      }
    }
    return scale;
  }

  Offset calculateOffsetPoint(InternalSeatLayout seatLayout, bool isSelfInSeat, SeatInfo seat) {
    Offset offset = const Offset(0, 0);
    if (seatLayout.canvas.w <= 0 || seatLayout.canvas.h <= 0) {
      return offset;
    }
    if (seatLayout.canvas.templateID != kDynamicFloatTemplateID601 ||
        isSelfInSeat ||
        (seat.region.w >= seatLayout.canvas.w || seat.region.h >= seatLayout.canvas.h)) {
      return offset;
    }
    double canvasAspectRatio = seatLayout.canvas.w / seatLayout.canvas.h;
    double parentAspectRatio = layoutSize.width / layoutSize.height;
    double canvasRealW = seatLayout.canvas.w * layoutSize.height / seatLayout.canvas.h;
    double canvasRealH = seatLayout.canvas.h * layoutSize.width / seatLayout.canvas.w;
    if (canvasAspectRatio >= parentAspectRatio || (canvasAspectRatio - parentAspectRatio).abs() < epsilon) {
      return Offset((1 - parentAspectRatio / canvasAspectRatio) * (canvasRealW / 2), 0);
    } else {
      return Offset(0, (1 - canvasAspectRatio / parentAspectRatio) * (canvasRealH / 2));
    }
  }

  bool isOffsetXIn601Template(InternalSeatLayout seatLayout, bool isSelfInSeat, SeatInfo seat) {
    if (kDynamicFloatTemplateID601 != seatLayout.canvas.templateID || !isSelfInSeat) {
      return false;
    }
    return seat.region.h < seatLayout.canvas.h && seat.region.w < seatLayout.canvas.w;
  }

  bool selfInSeat() {
    return seatLayout.seatList.any((seat) =>
    seat.userInfo.userID == LoginStore.shared.loginState.loginUserInfo?.userID);
  }

  bool _isSingleVideoLayout(List<SeatInfo> seatList) {
    return seatList.length == 1;
  }
}
