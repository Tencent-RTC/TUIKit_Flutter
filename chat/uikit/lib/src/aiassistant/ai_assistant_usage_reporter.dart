import '../common/utils/uikit_util.dart';

/// AI assistant usage reporting scoped to one page instance.
class AIAssistantUsageReporter {
  AIAssistantUsageReporter({void Function(int)? report})
      : _report = report ?? UIKitUtil.reportChatFeatureUsage;

  static const int messageUsage = 1022;
  static const int voiceEntry = 1023;

  final void Function(int) _report;
  bool _hasReportedMessageUsage = false;

  void onMessageSent() {
    if (_hasReportedMessageUsage) return;
    _hasReportedMessageUsage = true;
    _report(messageUsage);
  }

  void onVoiceEntered() {
    _report(voiceEntry);
  }
}
