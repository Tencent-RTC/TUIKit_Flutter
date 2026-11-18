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
/// import 'gen_l10n/demo_localizations.dart';
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

  /// No description provided for @aiTab.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiTab;

  /// No description provided for @aiHomeInputPrompt.
  ///
  /// In en, this message translates to:
  /// **'First tell me who you are, then what you can help me with.'**
  String get aiHomeInputPrompt;

  /// No description provided for @customBotDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom AI assistant'**
  String get customBotDialogTitle;

  /// No description provided for @customBotDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'After creating an AI assistant in the experience workbench, enter the part of its assistant IM ID after @RBT# below.'**
  String get customBotDialogDesc;

  /// No description provided for @customBotDialogDocLink.
  ///
  /// In en, this message translates to:
  /// **'View integration guide ›'**
  String get customBotDialogDocLink;

  /// No description provided for @customBotInputHint.
  ///
  /// In en, this message translates to:
  /// **'AIAssistant'**
  String get customBotInputHint;

  /// No description provided for @customBotNotFound.
  ///
  /// In en, this message translates to:
  /// **'Bot not found. Make sure the AI assistant is enabled and the IM bot is connected in the workbench.'**
  String get customBotNotFound;

  /// No description provided for @customBotNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error, please try again later'**
  String get customBotNetworkError;

  /// No description provided for @customBotCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get customBotCancel;

  /// No description provided for @customBotConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get customBotConfirm;

  /// No description provided for @aiQuickStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your AI assistant'**
  String get aiQuickStartTitle;

  /// No description provided for @aiQuickStartIntro.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant answers your users\' questions by text or voice in one-to-one chats, based on the knowledge you import, and hands over to a human agent when needed.'**
  String get aiQuickStartIntro;

  /// No description provided for @aiQuickStartStep1.
  ///
  /// In en, this message translates to:
  /// **'Create an AI assistant in the experience workbench and connect it to your IM app'**
  String get aiQuickStartStep1;

  /// No description provided for @aiQuickStartStep2.
  ///
  /// In en, this message translates to:
  /// **'Enter the callback URL and token from the workbench in the IM console'**
  String get aiQuickStartStep2;

  /// No description provided for @aiQuickStartStep3.
  ///
  /// In en, this message translates to:
  /// **'Tap the assistant name in the upper-left corner, choose \"Custom AI assistant\", and enter the assistant ID'**
  String get aiQuickStartStep3;

  /// No description provided for @aiQuickStartDocHint.
  ///
  /// In en, this message translates to:
  /// **'For details, see \"Quick start with UIKit (no server required)\" in the official documentation'**
  String get aiQuickStartDocHint;

  /// No description provided for @aiQuickStartDoc.
  ///
  /// In en, this message translates to:
  /// **'View integration guide'**
  String get aiQuickStartDoc;

  /// No description provided for @aiQuickStartCancel.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get aiQuickStartCancel;

  /// No description provided for @aiAgentPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI assistant'**
  String get aiAgentPickerTitle;

  /// No description provided for @aiAgentCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom AI assistant'**
  String get aiAgentCustomTitle;

  /// No description provided for @aiAgentCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your assistant ID'**
  String get aiAgentCustomDesc;

  /// No description provided for @aiAgentCustomEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get aiAgentCustomEdit;

  /// No description provided for @aiAgentCustomGo.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get aiAgentCustomGo;

  /// No description provided for @aiAgentNewBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get aiAgentNewBadge;

  /// No description provided for @aiVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiVoiceTitle;

  /// No description provided for @aiVoiceHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get aiVoiceHistory;

  /// No description provided for @aiVoiceHeadline.
  ///
  /// In en, this message translates to:
  /// **'Talk to AI in real time'**
  String get aiVoiceHeadline;

  /// No description provided for @aiVoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Knows all Tencent Cloud Chat docs · Interrupt anytime'**
  String get aiVoiceSubtitle;

  /// No description provided for @aiVoiceSubtitleAircon.
  ///
  /// In en, this message translates to:
  /// **'Knows air conditioner usage and after-sales guides · Interrupt anytime'**
  String get aiVoiceSubtitleAircon;

  /// No description provided for @aiVoiceSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Just ask out loud · Interrupt anytime'**
  String get aiVoiceSubtitleDefault;

  /// No description provided for @aiVoiceTryLabel.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get aiVoiceTryLabel;

  /// No description provided for @aiVoiceSamples.
  ///
  /// In en, this message translates to:
  /// **'Why are group messages not received?\nHow do I configure message roaming?\nWhy are offline push notifications not arriving?\nHow do I recall a sent message?\nHow can I add an AI agent to my app?'**
  String get aiVoiceSamples;

  /// No description provided for @aiVoiceSamplesAircon.
  ///
  /// In en, this message translates to:
  /// **'My air conditioner is not cooling. How do I check it?\nIs white mist from the air outlet normal?\nWhat size unit fits a 20 square meter west-facing bedroom?\nWhat temperature does sleep mode reach at midnight?\nCan I still return the air conditioner after installation?'**
  String get aiVoiceSamplesAircon;

  /// No description provided for @aiVoiceSamplesDefault.
  ///
  /// In en, this message translates to:
  /// **'What can you help me with?\nWhat questions can you answer?\nHow do I reach a human agent?'**
  String get aiVoiceSamplesDefault;

  /// No description provided for @aiQuickQuestions.
  ///
  /// In en, this message translates to:
  /// **'Why does UserSig expire?\nHow long should ExpireTime be?\nGroup messages not received?\nHow to set up message roaming?'**
  String get aiQuickQuestions;

  /// No description provided for @aiQuickQuestionsAircon.
  ///
  /// In en, this message translates to:
  /// **'What does error code E4 mean?\nDo I need repair when H1 shows in winter?\nIs white mist from the air outlet normal?\nWhat size unit for a 20 m² west-facing bedroom?\nCan a 3 HP unit use a power strip?'**
  String get aiQuickQuestionsAircon;

  /// No description provided for @aiVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start a call'**
  String get aiVoiceStart;

  /// No description provided for @aiVoiceUseText.
  ///
  /// In en, this message translates to:
  /// **'Ask by text instead ›'**
  String get aiVoiceUseText;

  /// No description provided for @aiVoiceBack.
  ///
  /// In en, this message translates to:
  /// **'‹ Voice'**
  String get aiVoiceBack;

  /// No description provided for @aiVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI assistant is not ready yet. Please try again later.'**
  String get aiVoiceUnavailable;

  /// No description provided for @aiMicTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone access needed'**
  String get aiMicTitle;

  /// No description provided for @aiMicDesc.
  ///
  /// In en, this message translates to:
  /// **'AI needs to hear you to answer.\nOnly used during the call and stops when you hang up.'**
  String get aiMicDesc;

  /// No description provided for @aiMicTip.
  ///
  /// In en, this message translates to:
  /// **'● Works best in a quiet place or with earphones'**
  String get aiMicTip;

  /// No description provided for @aiMicAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow and start call'**
  String get aiMicAllow;

  /// No description provided for @aiMicText.
  ///
  /// In en, this message translates to:
  /// **'Ask by text first'**
  String get aiMicText;

  /// No description provided for @aiMicDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is turned off.\nTurn it on in Settings to talk to AI.'**
  String get aiMicDeniedDesc;

  /// No description provided for @aiMicOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get aiMicOpenSettings;

  /// No description provided for @aiCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring the same AI agent to your app'**
  String get aiCtaTitle;

  /// No description provided for @aiCtaDesc.
  ///
  /// In en, this message translates to:
  /// **'Built on Tencent Cloud Chat + Conversational AI'**
  String get aiCtaDesc;

  /// No description provided for @aiCtaAction.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get aiCtaAction;

  /// No description provided for @aiCtaClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aiCtaClose;
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
