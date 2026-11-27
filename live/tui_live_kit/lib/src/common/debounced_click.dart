import 'package:flutter/foundation.dart';

final class DebouncedClick {
  final Stopwatch _clock = Stopwatch()..start();
  final Map<Object, int> _lastClickTimes = <Object, int>{};

  void perform(Object key, VoidCallback? action,
      {Duration interval = const Duration(seconds: 1)}) {
    final int now = _clock.elapsedMicroseconds;
    final int? lastClick = _lastClickTimes[key];
    if (lastClick != null && now - lastClick < interval.inMicroseconds) return;
    _lastClickTimes[key] = now;
    action?.call();
  }
}
