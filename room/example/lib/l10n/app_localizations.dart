import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get userName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @userIdInputHint.
  ///
  /// In en, this message translates to:
  /// **'Please input userId'**
  String get userIdInputHint;

  /// No description provided for @userNameInputHint.
  ///
  /// In en, this message translates to:
  /// **'Please input userName'**
  String get userNameInputHint;

  /// No description provided for @userNameTips.
  ///
  /// In en, this message translates to:
  /// **'Only Chinese, letters, numbers and underscores'**
  String get userNameTips;

  /// No description provided for @userIdIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'userId is empty'**
  String get userIdIsEmpty;

  /// No description provided for @userNameIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'userName is empty'**
  String get userNameIsEmpty;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'login error,code:{code},msg:{message}'**
  String loginError(String code, String message);

  /// No description provided for @custom_name_1.
  ///
  /// In en, this message translates to:
  /// **'Martijn'**
  String get custom_name_1;

  /// No description provided for @custom_name_2.
  ///
  /// In en, this message translates to:
  /// **'irfan'**
  String get custom_name_2;

  /// No description provided for @custom_name_3.
  ///
  /// In en, this message translates to:
  /// **'Rosanna'**
  String get custom_name_3;

  /// No description provided for @custom_name_4.
  ///
  /// In en, this message translates to:
  /// **'Franklyn'**
  String get custom_name_4;

  /// No description provided for @custom_name_5.
  ///
  /// In en, this message translates to:
  /// **'Maren'**
  String get custom_name_5;

  /// No description provided for @custom_name_6.
  ///
  /// In en, this message translates to:
  /// **'Bartel'**
  String get custom_name_6;

  /// No description provided for @custom_name_7.
  ///
  /// In en, this message translates to:
  /// **'Marianita'**
  String get custom_name_7;

  /// No description provided for @custom_name_8.
  ///
  /// In en, this message translates to:
  /// **'Anneke'**
  String get custom_name_8;

  /// No description provided for @custom_name_9.
  ///
  /// In en, this message translates to:
  /// **'Elmira'**
  String get custom_name_9;

  /// No description provided for @custom_name_10.
  ///
  /// In en, this message translates to:
  /// **'Ivet'**
  String get custom_name_10;

  /// No description provided for @custom_name_11.
  ///
  /// In en, this message translates to:
  /// **'Clinton'**
  String get custom_name_11;

  /// No description provided for @custom_name_12.
  ///
  /// In en, this message translates to:
  /// **'Virelai'**
  String get custom_name_12;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
