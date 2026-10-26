import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';

import '../common/screen/screen_adapter.dart';
import '../common/widget/global.dart';

typedef SeatWidgetBuilder = Widget Function(
    BuildContext context, ValueNotifier<SeatInfo> seatInfoNotifier, ValueNotifier<int> volumeNotifier);
typedef OnSeatWidgetTap = void Function(SeatInfo);

enum LayoutMode {
  focus,
  grid,
  vertical,
  free,
}

enum SeatWidgetLayoutRowAlignment {
  spaceAround,
  spaceBetween,
  spaceEvenly,
  start,
  end,
  center,
}

class SeatWidgetLayoutRowConfig {
  final int count;
  final double seatSpacing;
  final Size seatSize;
  final SeatWidgetLayoutRowAlignment alignment;

  SeatWidgetLayoutRowConfig({
    this.count = 5,
    double? seatSpacing,
    Size? seatSize,
    this.alignment = SeatWidgetLayoutRowAlignment.spaceEvenly,
  })  : seatSpacing = seatSpacing ?? ScreenAdapter.getWidth(Global.appContext(), 20.0),
        seatSize = seatSize ??
            Size(
              ScreenAdapter.getWidth(Global.appContext(), 50.0),
              ScreenAdapter.getWidth(Global.appContext(), 72.0),
            );

  @override
  String toString() {
    return 'SeatWidgetLayoutRowConfig{count:$count, seatSpacing:$seatSpacing, seatSize:(width:${seatSize.width}, height:${seatSize.height}), alignment:$alignment}';
  }
}

class SeatWidgetLayoutConfig {
  final List<SeatWidgetLayoutRowConfig> rowConfigs;
  final double rowSpacing;

  SeatWidgetLayoutConfig({List<SeatWidgetLayoutRowConfig>? rowConfigs, double? rowSpacing})
      : rowSpacing = rowSpacing ?? ScreenAdapter.getWidth(Global.appContext(), 22.0),
        rowConfigs = rowConfigs ?? [SeatWidgetLayoutRowConfig(), SeatWidgetLayoutRowConfig()];

  @override
  String toString() {
    return 'SeatWidgetLayoutConfig{rowConfigs:$rowConfigs, rowSpacing:$rowSpacing}';
  }
}