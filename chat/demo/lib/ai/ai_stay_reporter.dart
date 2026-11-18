import 'dart:async';

import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

/// Reports how long the user stays on the AI tab: 10221 / 10222 / 10223 once
/// the continuous stay passes 5s / 10s / 30s.
///
/// Leaving the tab or sending the app to the background cancels the pending
/// timers, so a stay is never summed across visits. Every visit is counted on
/// its own: each value is reported at most once per visit.
class AIStayReporter {
  AIStayReporter({void Function(int type)? report})
      : _report = report ?? reportFeatureUsage;

  static const List<(Duration, int)> thresholds = [
    (Duration(seconds: 5), 10221),
    (Duration(seconds: 10), 10222),
    (Duration(seconds: 30), 10223),
  ];

  final void Function(int type) _report;
  final List<Timer> _timers = [];
  bool _staying = false;

  /// The AI tab became visible to the user.
  void onEnter() {
    if (_staying) return;
    _staying = true;
    for (final (duration, type) in thresholds) {
      _timers.add(Timer(duration, () => _report(type)));
    }
  }

  /// The AI tab was hidden, or the app left the foreground.
  void onLeave() {
    _staying = false;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  static void reportFeatureUsage(int type) {
    TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
      api: 'report_tuifeature_usage',
      param: {'report_tuifeature_usage_uicomponent_type': type},
    );
  }
}
