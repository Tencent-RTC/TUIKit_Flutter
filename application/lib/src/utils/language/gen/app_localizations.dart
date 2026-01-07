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
/// import 'gen/app_localizations.dart';
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
    Locale('zh')
  ];

  /// No description provided for @app_trtc.
  ///
  /// In en, this message translates to:
  /// **'Tencent RTC'**
  String get app_trtc;

  /// No description provided for @app_user_id.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get app_user_id;

  /// No description provided for @app_enter_user_id.
  ///
  /// In en, this message translates to:
  /// **'Please enter your UserID'**
  String get app_enter_user_id;

  /// No description provided for @app_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get app_login;

  /// No description provided for @app_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get app_logout;

  /// No description provided for @app_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get app_confirm;

  /// No description provided for @app_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get app_cancel;

  /// No description provided for @app_enter_nickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your user nickname'**
  String get app_enter_nickname;

  /// No description provided for @app_tencent_cloud.
  ///
  /// In en, this message translates to:
  /// **'Tencent Cloud'**
  String get app_tencent_cloud;

  /// No description provided for @app_login_fail.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get app_login_fail;

  /// No description provided for @app_next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get app_next;

  /// No description provided for @app_nick_name.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get app_nick_name;

  /// No description provided for @app_room_id.
  ///
  /// In en, this message translates to:
  /// **'Room ID'**
  String get app_room_id;

  /// No description provided for @app_anchor.
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get app_anchor;

  /// No description provided for @app_audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get app_audience;

  /// No description provided for @app_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get app_me;

  /// No description provided for @app_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get app_live;

  /// No description provided for @app_follow_count.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get app_follow_count;

  /// No description provided for @app_fans_count.
  ///
  /// In en, this message translates to:
  /// **'Fans'**
  String get app_fans_count;

  /// No description provided for @app_set_nickname.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get app_set_nickname;

  /// No description provided for @app_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get app_save;

  /// No description provided for @app_video.
  ///
  /// In en, this message translates to:
  /// **'Living'**
  String get app_video;

  /// No description provided for @app_video_description.
  ///
  /// In en, this message translates to:
  /// **'Live preview/Beauty filters/Multi-host'**
  String get app_video_description;

  /// No description provided for @app_voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get app_voice;

  /// No description provided for @app_voice_description.
  ///
  /// In en, this message translates to:
  /// **'High audio quality/Large room/Smooth mic on/off'**
  String get app_voice_description;

  /// No description provided for @app_broadcast.
  ///
  /// In en, this message translates to:
  /// **'{xxx} Broadcast'**
  String app_broadcast(Object xxx);

  /// No description provided for @app_self_center.
  ///
  /// In en, this message translates to:
  /// **'Self Center'**
  String get app_self_center;

  /// No description provided for @app_log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get app_log;

  /// No description provided for @app_live_content.
  ///
  /// In en, this message translates to:
  /// **'Create Interactive Video Live with Live API for a Seamless Streaming Experience.'**
  String get app_live_content;

  /// No description provided for @app_voice_content.
  ///
  /// In en, this message translates to:
  /// **'Enable Interactive Voice Room with Live API for an Enhanced Communication Experience.'**
  String get app_voice_content;

  /// No description provided for @app_conference.
  ///
  /// In en, this message translates to:
  /// **'Conference'**
  String get app_conference;

  /// No description provided for @app_conference_description.
  ///
  /// In en, this message translates to:
  /// **'Quick meeting/Invite/Manage participants/Share screen'**
  String get app_conference_description;

  /// No description provided for @app_call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get app_call;

  /// No description provided for @app_call_description.
  ///
  /// In en, this message translates to:
  /// **'Ringtone/Floating Window/Less stutter'**
  String get app_call_description;

  /// No description provided for @app_call_user_ids.
  ///
  /// In en, this message translates to:
  /// **'Call User List'**
  String get app_call_user_ids;

  /// No description provided for @app_call_media_type.
  ///
  /// In en, this message translates to:
  /// **'Media Type'**
  String get app_call_media_type;

  /// No description provided for @app_call_optional_params.
  ///
  /// In en, this message translates to:
  /// **'Optional Parameters'**
  String get app_call_optional_params;

  /// No description provided for @app_call_group_id.
  ///
  /// In en, this message translates to:
  /// **'Group ID'**
  String get app_call_group_id;

  /// No description provided for @app_call_initiate.
  ///
  /// In en, this message translates to:
  /// **'Initiate Call'**
  String get app_call_initiate;

  /// No description provided for @app_call_media_type_audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get app_call_media_type_audio;

  /// No description provided for @app_call_media_type_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get app_call_media_type_video;

  /// No description provided for @app_call_user_ids_separated.
  ///
  /// In en, this message translates to:
  /// **'IDs are separated by \',\''**
  String get app_call_user_ids_separated;

  /// No description provided for @app_call_enable_floating_window.
  ///
  /// In en, this message translates to:
  /// **'Enable Floating Window'**
  String get app_call_enable_floating_window;

  /// No description provided for @app_call_enable_incoming_banner.
  ///
  /// In en, this message translates to:
  /// **'Enable Incoming Banner'**
  String get app_call_enable_incoming_banner;

  /// No description provided for @app_call_enable_mute_mode.
  ///
  /// In en, this message translates to:
  /// **'Enable Mute Mode'**
  String get app_call_enable_mute_mode;
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
      'that was used.');
}
