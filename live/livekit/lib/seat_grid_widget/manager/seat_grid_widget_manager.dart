import '../index.dart';

class SeatGridWidgetManager {
  final String liveID;
  late final WidgetManager widgetManager;

  SeatGridWidgetManager({required this.liveID}) {
    widgetManager = WidgetManager(liveID: liveID);
  }
}

extension SeatGridWidgetManagerWithWidget on SeatGridWidgetManager {
  WidgetState get widgetState => widgetManager.widgetState;

  void setLayoutMode(LayoutMode layoutMode, SeatWidgetLayoutConfig? layoutConfig) {
    return widgetManager.setLayoutMode(layoutMode, layoutConfig);
  }
}