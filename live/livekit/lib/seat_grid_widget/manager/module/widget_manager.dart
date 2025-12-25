import 'dart:math';

import 'package:atomic_x_core/api/live/live_seat_store.dart';

import '../../index.dart';

class WidgetManager {
  final String liveID;
  final WidgetState widgetState = WidgetState();

  LiveSeatStore get _seatStore => LiveSeatStore.create(liveID);

  WidgetManager({required this.liveID});
}

extension WidgetManagerCallback on WidgetManager {
  void onSeatCountChanged(int seatCount) {
    SeatWidgetLayoutConfig layoutConfig = widgetState.layoutConfig.value;
    switch (widgetState.layoutMode.value) {
      case LayoutMode.focus:
        layoutConfig = _getFocusLayoutConfig(seatCount);
        break;
      case LayoutMode.grid:
        layoutConfig = _getGridLayoutConfig(seatCount);
        break;
      case LayoutMode.vertical:
        layoutConfig = _getVerticalLayoutConfig(seatCount);
        break;
      default:
        break;
    }
    widgetState.layoutConfig.value = layoutConfig;
  }
}

extension WidgetManagerStateOperation on WidgetManager {
  void setLayoutMode(LayoutMode layoutMode, SeatWidgetLayoutConfig? layoutConfig) {
    final config = (layoutMode == LayoutMode.free) ? layoutConfig : _getBuiltInLayoutConfig(layoutMode);

    widgetState.layoutMode.value = layoutMode;
    if (config != null) {
      widgetState.layoutConfig.value = config;
    }
  }
}

extension on WidgetManager {
  SeatWidgetLayoutConfig? _getBuiltInLayoutConfig(LayoutMode layoutMode) {
    SeatWidgetLayoutConfig? config;

    final seatCount =
        _seatStore.liveSeatState.seatList.value.length;

    switch (layoutMode) {
      case LayoutMode.focus:
        config = _getFocusLayoutConfig(seatCount);
        break;
      case LayoutMode.grid:
        config = _getGridLayoutConfig(seatCount);
        break;
      case LayoutMode.vertical:
        config = _getVerticalLayoutConfig(seatCount);
        break;
      default:
        break;
    }
    return config;
  }

  SeatWidgetLayoutConfig _getFocusLayoutConfig(int seatCount) {
    List<SeatWidgetLayoutRowConfig> rowConfigs = [];
    int countOfFirstRow = 1;
    int remainingSeats = seatCount - 1;
    int countOfOtherRows = _getSeatCountPerRow(remainingSeats);

    rowConfigs.add(SeatWidgetLayoutRowConfig(count: countOfFirstRow, alignment: SeatWidgetLayoutRowAlignment.center));

    int currentCount = 0;
    while (currentCount < remainingSeats) {
      int count = min(countOfOtherRows, remainingSeats - currentCount);
      rowConfigs.add(SeatWidgetLayoutRowConfig(count: count, alignment: SeatWidgetLayoutRowAlignment.spaceBetween));
      currentCount += count;
    }
    return SeatWidgetLayoutConfig(rowConfigs: rowConfigs);
  }

  SeatWidgetLayoutConfig _getGridLayoutConfig(int seatCount) {
    List<SeatWidgetLayoutRowConfig> rowConfigs = [];
    int seatCountPerRow = _getSeatCountPerRow(seatCount);
    int rows = (seatCount + seatCountPerRow - 1) ~/ seatCountPerRow;
    for (int i = 0; i < rows; i++) {
      int count = min(seatCountPerRow, seatCount - (i * seatCountPerRow));
      rowConfigs.add(SeatWidgetLayoutRowConfig(count: count, alignment: SeatWidgetLayoutRowAlignment.center));
    }
    return SeatWidgetLayoutConfig(rowConfigs: rowConfigs);
  }

  SeatWidgetLayoutConfig _getVerticalLayoutConfig(int seatCount) {
    List<SeatWidgetLayoutRowConfig> rowConfigs = [];
    int seatCountPerRow = 1;
    for (int i = 0; i < seatCount; i++) {
      rowConfigs.add(SeatWidgetLayoutRowConfig(count: seatCountPerRow, alignment: SeatWidgetLayoutRowAlignment.end));
    }
    return SeatWidgetLayoutConfig(rowConfigs: rowConfigs);
  }

  int _getSeatCountPerRow(int seatCount) {
    int countPerRow = 5;
    switch (seatCount) {
      case 1:
      case 2:
        countPerRow = 2;
        break;
      case 3:
      case 6:
      case 9:
        countPerRow = 3;
        break;
      case 4:
      case 8:
      case 12:
        countPerRow = 4;
        break;
      default:
        break;
    }
    return countPerRow;
  }
}
