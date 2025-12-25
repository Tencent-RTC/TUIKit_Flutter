import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';

class Global {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  static final GlobalKey<NavigatorState> secondaryNavigatorKey = GlobalKey();

  static BuildContext appContext() {
    return TUILiveKitNavigatorObserver.instance.getContext();
  }
}
