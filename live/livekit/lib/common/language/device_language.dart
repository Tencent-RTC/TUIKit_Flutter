import 'package:flutter/material.dart';

import '../logger/logger.dart';
import 'gen/livekit_localizations.dart';

class DeviceLanguage {
  static String getCurrentLanguageCode(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final scriptCode = Localizations.localeOf(context).scriptCode;
    LiveKitLogger.info(
        'getLanguageCode languageCode:$languageCode, scriptCode:$scriptCode');
    if (languageCode == 'zh' && scriptCode == 'Hans') {
      return 'zh-Hans';
    }
    if (languageCode == 'zh' && scriptCode == 'Hant') {
      return 'zh-Hant';
    }
    return 'en';
  }

  static bool checkLocale(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    bool isSupportedLocale = LiveKitLocalizations.delegate.isSupported(locale);
    if (!isSupportedLocale) LiveKitLogger.error("LiveKit not support the locale: $locale");
    LiveKitLocalizations? localizations = LiveKitLocalizations.of(context);
    if (localizations == null) LiveKitLogger.error("LiveKitLocalizations is null!");
    return isSupportedLocale && localizations != null;
  }
}