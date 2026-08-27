import 'package:flutter/widgets.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import 'language/gen/demo_localizations.dart';

/// Demo-only helper that pushes a one-off guidance message to the built-in
/// "administrator" conversation shortly after the user logs in, mirroring the
/// native demos' first-run hint.
class WelcomeMessageSender {
  WelcomeMessageSender._();

  static const String _administratorConversationID = 'c2c_administrator';
  static const Duration _sendDelay = Duration(seconds: 1);

  /// Schedules the welcome message to be sent after a short delay so it lands
  /// once the conversation list has settled post-login.
  static void scheduleWelcomeMessage() {
    Future.delayed(_sendDelay, _sendWelcomeMessage);
  }

  static Future<void> _sendWelcomeMessage() async {
    final message = _resolveMessage(await _currentLocale());
    final result = await MessageInputStore.create(conversationID: _administratorConversationID)
        .sendMessage(payload: TextSendMessagePayload(text: message));
    if (!result.isSuccess) {
      debugPrint('send welcome message failed: ${result.errorCode}, ${result.errorMessage}');
    }
  }

  /// Resolves the effective locale the same way [LocaleProvider] does: honour
  /// the in-app language override when set, otherwise fall back to the system
  /// locale.
  static Future<Locale> _currentLocale() async {
    final saved = await StorageUtil.get('locale');
    switch (saved) {
      case 'ar':
        return const Locale('ar');
      case 'en':
        return const Locale('en');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'zh':
        return const Locale('zh');
      case 'zh_Hant':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      default:
        return WidgetsBinding.instance.platformDispatcher.locale;
    }
  }

  /// There is no `BuildContext` this early, so the message is read straight off
  /// the generated localizations for [locale]. That lookup throws on a language
  /// the demo has no translation for, hence the explicit fallback to English.
  static String _resolveMessage(Locale locale) {
    final isTranslated = DemoLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
    return lookupDemoLocalizations(isTranslated ? locale : const Locale('en')).welcomeMessage;
  }
}
