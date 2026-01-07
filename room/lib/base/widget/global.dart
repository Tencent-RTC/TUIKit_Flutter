import 'package:flutter/material.dart';
import '../navigator/room_navigator_observer.dart';

class Global {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  static GlobalKey<NavigatorState> secondaryNavigatorKey = GlobalKey();

  static BuildContext appContext() {
    return RoomNavigatorObserver.instance.getContext();
  }
}
