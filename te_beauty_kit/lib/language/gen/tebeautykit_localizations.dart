import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'tebeautykit_localizations_en.dart';
import 'tebeautykit_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of TEBeautyKitLocalizations
/// returned by `TEBeautyKitLocalizations.of(context)`.
///
/// Applications need to include `TEBeautyKitLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/tebeautykit_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TEBeautyKitLocalizations.localizationsDelegates,
///   supportedLocales: TEBeautyKitLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the TEBeautyKitLocalizations.supportedLocales
/// property.
abstract class TEBeautyKitLocalizations {
  static TEBeautyKitLocalizations? defaultLocalizations;
  TEBeautyKitLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TEBeautyKitLocalizations? of(BuildContext context) {
    TEBeautyKitLocalizations? localizations = Localizations.of<TEBeautyKitLocalizations>(context, TEBeautyKitLocalizations,);
    if (localizations == null) {
      if (defaultLocalizations == null) {
        defaultLocalizations = TEBeautyKitLocalizationsEn();
      }
      return defaultLocalizations;
    }
    return localizations;
  }

  static const LocalizationsDelegate<TEBeautyKitLocalizations> delegate =
      _TEBeautyKitLocalizationsDelegate();

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

  /// No description provided for @beauty_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get beauty_cancel;

  /// No description provided for @beauty_reset_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the effects?'**
  String get beauty_reset_title;

  /// No description provided for @beauty_reset_content.
  ///
  /// In en, this message translates to:
  /// **'The action will reset all effects and cannot be undone'**
  String get beauty_reset_content;

  /// No description provided for @beauty_reset_confirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get beauty_reset_confirm;

  /// No description provided for @beauty_import_image.
  ///
  /// In en, this message translates to:
  /// **'Upload background image'**
  String get beauty_import_image;

  /// No description provided for @beauty_import_image_tip.
  ///
  /// In en, this message translates to:
  /// **'Please stand in front of a xxx and upload an image you want to use as the background'**
  String get beauty_import_image_tip;

  /// No description provided for @beauty_pick_image.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get beauty_pick_image;

  /// No description provided for @beauty_green_screen.
  ///
  /// In en, this message translates to:
  /// **'green screen'**
  String get beauty_green_screen;

  /// No description provided for @beauty_blue_screen.
  ///
  /// In en, this message translates to:
  /// **'blue screen'**
  String get beauty_blue_screen;
}

class _TEBeautyKitLocalizationsDelegate
    extends LocalizationsDelegate<TEBeautyKitLocalizations> {
  const _TEBeautyKitLocalizationsDelegate();

  @override
  Future<TEBeautyKitLocalizations> load(Locale locale) {
    return SynchronousFuture<TEBeautyKitLocalizations>(
      lookupTEBeautyKitLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_TEBeautyKitLocalizationsDelegate old) => false;
}

TEBeautyKitLocalizations lookupTEBeautyKitLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TEBeautyKitLocalizationsEn();
    case 'zh':
      return TEBeautyKitLocalizationsZh();
  }

  throw FlutterError(
    'TEBeautyKitLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
