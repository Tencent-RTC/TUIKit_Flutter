import 'package:flutter/widgets.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../utils/language/index.dart';

/// Demo-only helper that pushes a one-off guidance message to the built-in
/// "administrator" conversation the first time the user opens the chat module,
/// mirroring the native demos' first-run hint.
class WelcomeMessageSender {
  WelcomeMessageSender._();

  static const String _administratorConversationID = 'c2c_administrator';
  static const Duration _sendDelay = Duration(seconds: 1);

  /// The chat module is pushed as a fresh route every time the user enters it,
  /// so the hint is gated on this flag to stay a one-off per app launch.
  static bool _scheduled = false;

  /// Schedules the welcome message to be sent after a short delay so it lands
  /// once the conversation list has settled.
  static void scheduleWelcomeMessage() {
    if (_scheduled) return;
    _scheduled = true;
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
      case 'en':
        return const Locale('en');
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
  /// the app has no translation for, hence the explicit fallback to English.
  static String _resolveMessage(Locale locale) {
    final isTranslated = AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
    return lookupAppLocalizations(isTranslated ? locale : const Locale('en')).app_chat_welcome_message;
  }
}
