import 'package:flutter/cupertino.dart';

class AppNavigatorObserver extends RouteObserver {
  static final AppNavigatorObserver instance = AppNavigatorObserver._internal();

  factory AppNavigatorObserver() {
    return instance;
  }

  AppNavigatorObserver._internal() {
    debugPrint("AppNavigatorObserver init");
  }
}