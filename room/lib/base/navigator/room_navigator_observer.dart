import 'package:flutter/material.dart';

class RoomNavigatorObserver extends RouteObserver {
  static final RoomNavigatorObserver instance = RoomNavigatorObserver._internal();

  factory RoomNavigatorObserver() {
    return instance;
  }

  RoomNavigatorObserver._internal();

  BuildContext getContext() {
    return navigator!.context;
  }
}
