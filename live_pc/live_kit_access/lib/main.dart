import 'package:flutter/material.dart';
import 'package:tencent_live_kit_desktop/tencent_live_kit_desktop.dart';

import 'login_page.dart';
import 'win_clipboard_paste_fix.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // App-lifetime Win+V clipboard-history paste fix (Windows-only inside):
  // covers the login page and every other text field even when the pusher
  // page (which holds its own reference) is not open.
  WinClipboardPasteFix.instance.install();
  runApp(const LiveKitAccessApp());
}

class LiveKitAccessApp extends StatelessWidget {
  const LiveKitAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageStore.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'TUI Live Kit Access',
          debugShowCheckedModeBanner: false,
          theme: _buildAccessTheme(),
          locale: locale,
          localizationsDelegates:
              LiveKitLocalizations.localizationsDelegates,
          supportedLocales: LiveKitLocalizations.supportedLocales,
          home: const LoginPage(),
        );
      },
    );
  }
}

ThemeData _buildAccessTheme() {
  final base = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: LiveKitStyle.brand,
      surface: LiveKitStyle.bgBase2,
      onSurface: LiveKitStyle.textPrimary,
    ),
    scaffoldBackgroundColor: LiveKitStyle.bgBase1,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: LiveKitStyle.white5,
      hintStyle: TextStyle(color: LiveKitStyle.textHint),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamilyFallback: LiveKitStyle.cjkFontFamilyFallback,
    ),
  );
}
