import 'package:flutter/material.dart';

class DeviceLanguage {
  static String getCurrentLanguageCode(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final scriptCode = Localizations.localeOf(context).scriptCode;

    if (languageCode == 'zh' && scriptCode == 'Hans') {
      return 'zh-Hans';
    }
    if (languageCode == 'zh' && scriptCode == 'Hant') {
      return 'zh-Hant';
    }
    return 'en';
  }
}
