import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'demo_localizations_ar.dart';
import 'demo_localizations_en.dart';
import 'demo_localizations_ja.dart';
import 'demo_localizations_ko.dart';
import 'demo_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DemoLocalizations
/// returned by `DemoLocalizations.of(context)`.
///
/// Applications need to include `DemoLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/demo_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DemoLocalizations.localizationsDelegates,
///   supportedLocales: DemoLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the DemoLocalizations.supportedLocales
/// property.
abstract class DemoLocalizations {
  DemoLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DemoLocalizations of(BuildContext context) {
    return Localizations.of<DemoLocalizations>(context, DemoLocalizations)!;
  }

  static const LocalizationsDelegate<DemoLocalizations> delegate =
      _DemoLocalizationsDelegate();

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
    Locale('ar'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @customMessageMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Message'**
  String get customMessageMenuTitle;

  /// No description provided for @customMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Cloud Communication IM family!'**
  String get customMessageContent;

  /// No description provided for @customMessageViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get customMessageViewDetails;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Chat Demo! Send a message to try out the basic chat.\nTo add friends, go to the Contacts page and tap the plus button.\nTo make audio or video calls, tap the plus button below -> Voice Call/Video Call.'**
  String get welcomeMessage;
}

class _DemoLocalizationsDelegate
    extends LocalizationsDelegate<DemoLocalizations> {
  const _DemoLocalizationsDelegate();

  @override
  Future<DemoLocalizations> load(Locale locale) {
    return SynchronousFuture<DemoLocalizations>(
        lookupDemoLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_DemoLocalizationsDelegate old) => false;
}

DemoLocalizations lookupDemoLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return DemoLocalizationsZhHans();
          case 'Hant':
            return DemoLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return DemoLocalizationsAr();
    case 'en':
      return DemoLocalizationsEn();
    case 'ja':
      return DemoLocalizationsJa();
    case 'ko':
      return DemoLocalizationsKo();
    case 'zh':
      return DemoLocalizationsZh();
  }

  throw FlutterError(
      'DemoLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
