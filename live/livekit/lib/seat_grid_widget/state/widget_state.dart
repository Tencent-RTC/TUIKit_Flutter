import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../seat_grid_define.dart';

class WidgetState {
  ValueNotifier<SeatWidgetLayoutConfig> layoutConfig =
      ValueNotifier(SeatWidgetLayoutConfig());
  ValueNotifier<LayoutMode> layoutMode = ValueNotifier(LayoutMode.grid);
}
