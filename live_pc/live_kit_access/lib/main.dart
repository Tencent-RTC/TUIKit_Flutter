import 'package:flutter/material.dart';
import 'package:tencent_live_kit_desktop/l10n/language_store.dart';
import 'package:tencent_live_kit_desktop/l10n/live_kit_localizations.dart';
import 'package:tencent_live_kit_desktop/pusher/pusher_style.dart';

import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiveKitAccessApp());
}

class LiveKitAccessApp extends StatelessWidget {
  const LiveKitAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 语言切换入口（推流页 header 地球图标）写入 LanguageStore.locale，
    // 此处监听并覆盖 MaterialApp.locale；null = 跟随系统。
    return ValueListenableBuilder<Locale?>(
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
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: PusherStyle.brand,
      surface: PusherStyle.bgBase2,
      onSurface: PusherStyle.textPrimary,
    ),
    scaffoldBackgroundColor: PusherStyle.bgBase1,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: PusherStyle.white5,
      hintStyle: TextStyle(color: PusherStyle.textHint),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
