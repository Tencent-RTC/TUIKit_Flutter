import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLifecycle with WidgetsBindingObserver {
  static final AppLifecycle _instance = AppLifecycle._internal();
  final ValueNotifier<AppLifecycleState?> _currentState = ValueNotifier(null);
  static AppLifecycle instance = _instance;
  
  final List<VoidCallback> _listeners = [];

  AppLifecycle._internal() {
    WidgetsBinding.instance.addObserver(this);
    _currentState.value = WidgetsBinding.instance.lifecycleState;
  }

  bool get isForeground => _currentState.value == AppLifecycleState.resumed;

  bool get isBackground => _currentState.value == AppLifecycleState.paused
      || _currentState.value == AppLifecycleState.inactive
      || _currentState.value == AppLifecycleState.detached;

  ValueListenable<AppLifecycleState?> get currentState => _currentState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _currentState.value = state;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
  }
}
