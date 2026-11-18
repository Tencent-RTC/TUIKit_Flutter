import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../common/language/gen/demo_localizations.dart';
import 'support_agent_catalog.dart';

/// Subtitle, sample questions and quick questions shown per assistant on the
/// voice home, the call page and the text page.
///
/// Voice samples are plain Chinese where possible, so English terms and model
/// numbers are not misheard by realtime ASR; quick questions are sent with a
/// tap and may carry terms. Built-in demo assistants get their own questions
/// by ID; the user's custom assistant gets generic ones.
class AIAgentProfile {
  const AIAgentProfile({
    required this.subtitle,
    required this.samples,
    required this.quickQuestions,
  });

  /// Built-in Tencent Cloud IM document assistant.
  static const String imDocBotUserID = '@RBT#AIAssistant';

  /// Built-in air conditioner knowledge-base demo assistant.
  static const String airconBotUserID = '@RBT#AIAssistant_air';

  final String subtitle;
  final List<String> samples;
  final List<String> quickQuestions;

  static AIAgentProfile of(DemoLocalizations l10n, AIAssistantAgent? agent) {
    // Logged in to the customer's own app with no assistant yet: do not show
    // the built-in IM document assistant's intro and samples.
    final imUserId =
        agent?.imUserId ?? (SupportAgentCatalog.needsOwnAssistant ? '' : null);
    switch (imUserId) {
      case null:
      case imDocBotUserID:
        return AIAgentProfile(
          subtitle: l10n.aiVoiceSubtitle,
          samples: _lines(l10n.aiVoiceSamples),
          quickQuestions: _lines(l10n.aiQuickQuestions),
        );
      case airconBotUserID:
        return AIAgentProfile(
          subtitle: l10n.aiVoiceSubtitleAircon,
          samples: _lines(l10n.aiVoiceSamplesAircon),
          quickQuestions: _lines(l10n.aiQuickQuestionsAircon),
        );
      default:
        final generic = _lines(l10n.aiVoiceSamplesDefault);
        return AIAgentProfile(
          subtitle: l10n.aiVoiceSubtitleDefault,
          samples: generic,
          quickQuestions: generic,
        );
    }
  }

  static List<String> _lines(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
