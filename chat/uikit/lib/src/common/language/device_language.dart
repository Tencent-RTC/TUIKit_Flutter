import 'package:flutter/material.dart';

import 'gen/chat_localizations.dart';

/// Helper for resolving the current device language code for ChatKit.
class ChatDeviceLanguage {
  static String getCurrentLanguageCode(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final scriptCode = Localizations.localeOf(context).scriptCode;
    if (languageCode == 'zh' && scriptCode == 'Hant') {
      return 'zh-Hant';
    }
    if (languageCode == 'zh') {
      return 'zh-Hans';
    }
    return languageCode;
  }

  static bool checkLocale(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    return ChatLocalizations.delegate.isSupported(locale);
  }
}
