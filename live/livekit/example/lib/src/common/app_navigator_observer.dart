import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../view/index.dart';

class AppNavigatorObserver extends RouteObserver {
  static final AppNavigatorObserver instance = AppNavigatorObserver._internal();

  factory AppNavigatorObserver() {
    return instance;
  }

  AppNavigatorObserver._internal() {
    debugPrint("AppNavigatorObserver init");
    LoginStore.shared.loginEventStream.listen((event) {
      switch (event) {
        case LoginEvent.kickedOffline:
        case LoginEvent.loginExpired:
          debugPrint("LoginEvent => $event");
          _pushLoginWidget();
          break;
      }
    });
  }

  BuildContext getContext() {
    return navigator!.context;
  }

  void _pushLoginWidget() {
    NavigatorState navigatorState = Navigator.of(getContext());
    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (widget) => const LoginWidget()),
      (route) => false,
    );
  }
}
