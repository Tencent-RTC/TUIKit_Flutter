import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'live_kit_localizations.dart';

/// Hosts pass it to MaterialApp:
/// `ValueListenableBuilder(valueListenable: LanguageStore.locale, builder: (_, l, __) => MaterialApp(locale: l))`.
class LanguageStore {
  LanguageStore._();

  /// Uses PlatformDispatcher: WidgetsBinding.instance throws before ensureInitialized.
  static Locale resolveDefaultLocale() {
    final system = PlatformDispatcher.instance.locale;
    return system.languageCode == 'zh'
        ? const Locale('zh')
        : const Locale('en');
  }

  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(resolveDefaultLocale());
}

LiveKitLocalizations currentLiveKitStrings() =>
    lookupLiveKitLocalizations(LanguageStore.locale.value);
