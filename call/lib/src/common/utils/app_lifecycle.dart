import 'package:flutter/material.dart';

class AppLifecycle with WidgetsBindingObserver {
  static final AppLifecycle _instance = AppLifecycle._internal();
  AppLifecycleState? _currentState;
  static AppLifecycle instance = _instance;

  AppLifecycle._internal() {
    WidgetsBinding.instance.addObserver(this);
    _currentState = AppLifecycleState.resumed;
  }

  bool get isForeground => _currentState == AppLifecycleState.resumed;

  bool get isBackground => _currentState == AppLifecycleState.paused || _currentState == AppLifecycleState.inactive;

  AppLifecycleState? get currentState => _currentState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _currentState = state;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
