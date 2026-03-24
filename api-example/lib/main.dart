import 'package:flutter/material.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/localized_manager.dart';
import 'package:atomic_x_core_example/scenes/login/login_page.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved language setting during initialization
  await LocalizedManager.shared.loadSavedLanguage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to `localeNotifier` and rebuild `MaterialApp` automatically when the language changes
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizedManager.shared.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'LiveKit API Example',
          // Configure `SnackBar` globally to use the floating display style by default
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
          ),
          // Localization configuration
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          // Go directly to the login page
          home: const LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
