import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Localization manager
/// Supports switching between Simplified Chinese and English
/// Follows the system language by default: use zh on Simplified Chinese systems, and English on all others
class LocalizedManager {
  static final LocalizedManager shared = LocalizedManager._internal();

  static const String _userDefaultsKey = 'SelectedLanguage';

  /// Current language code
  String? _savedLanguage;

  /// Locale change notifier that `MaterialApp` listens to for reactive locale updates
  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  LocalizedManager._internal();

  // MARK: - Public Properties

  /// Current language, following the system language by default
  String get currentLanguage {
    // If the user has selected a language, use the user's selection
    if (_savedLanguage != null) {
      return _savedLanguage!;
    }
    // Otherwise follow the system language by default
    return defaultLanguage;
  }

  /// Default language: use zh on Simplified Chinese systems, and English on all others
  String get defaultLanguage {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode == 'zh' ? 'zh' : 'en';
  }

  bool get isChinese {
    return currentLanguage == 'zh';
  }

  Locale get currentLocale {
    return Locale(currentLanguage);
  }

  // MARK: - Public Methods

  /// Load the saved language setting from SharedPreferences during initialization
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _savedLanguage = prefs.getString(_userDefaultsKey);
    // Sync the notifier value during initialization
    localeNotifier.value = currentLocale;
  }

  /// Switch the current language
  void switchLanguage(BuildContext context) {
    if (currentLanguage == 'zh') {
      _setLanguage('en');
    } else {
      _setLanguage('zh');
    }
  }

  void showLanguageSwitchAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('简体中文', textAlign: TextAlign.center),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _setLanguage('zh');
                },
              ),
              ListTile(
                title: const Text('English', textAlign: TextAlign.center),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _setLanguage('en');
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.commonCancel, textAlign: TextAlign.center),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  // MARK: - Private Methods

  Future<void> _setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDefaultsKey, language);
    _savedLanguage = language;
    // Notify `MaterialApp` to rebuild via `ValueNotifier` and trigger a locale change
    localeNotifier.value = Locale(language);
  }
}
