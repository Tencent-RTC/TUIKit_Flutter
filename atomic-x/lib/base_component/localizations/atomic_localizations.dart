import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'atomic_localizations_ar.dart';
import 'atomic_localizations_en.dart';
import 'atomic_localizations_ja.dart';
import 'atomic_localizations_ko.dart';
import 'atomic_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AtomicLocalizations
/// returned by `AtomicLocalizations.of(context)`.
///
/// Applications need to include `AtomicLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localizations/atomic_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AtomicLocalizations.localizationsDelegates,
///   supportedLocales: AtomicLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AtomicLocalizations.supportedLocales
/// property.
abstract class AtomicLocalizations {
  AtomicLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AtomicLocalizations of(BuildContext context) {
    return Localizations.of<AtomicLocalizations>(context, AtomicLocalizations)!;
  }

  static const LocalizationsDelegate<AtomicLocalizations> delegate =
      _AtomicLocalizationsDelegate();

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

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Required permissions'**
  String get permissionNeeded;

  /// No description provided for @permissionDeniedContent.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the required permission.'**
  String get permissionDeniedContent;

  /// No description provided for @permissionDeniedCamera.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Camera permission.'**
  String get permissionDeniedCamera;

  /// No description provided for @permissionDeniedMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Microphone permission.'**
  String get permissionDeniedMicrophone;

  /// No description provided for @permissionDeniedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Photos permission.'**
  String get permissionDeniedPhotos;

  /// No description provided for @permissionDeniedStorage.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Storage permission.'**
  String get permissionDeniedStorage;

  /// No description provided for @permissionDeniedNotification.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Notification permission.'**
  String get permissionDeniedNotification;

  /// No description provided for @callRejectCaller.
  ///
  /// In en, this message translates to:
  /// **'Call declined by user'**
  String get callRejectCaller;

  /// No description provided for @callRejectCallee.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callRejectCallee;

  /// No description provided for @callCancelCaller.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get callCancelCaller;

  /// No description provided for @callCancelCallee.
  ///
  /// In en, this message translates to:
  /// **'Call canceled by caller'**
  String get callCancelCallee;

  /// No description provided for @callCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get callCancel;

  /// No description provided for @callTimeoutCaller.
  ///
  /// In en, this message translates to:
  /// **'Call was not answered'**
  String get callTimeoutCaller;

  /// No description provided for @callTimeoutCallee.
  ///
  /// In en, this message translates to:
  /// **'Call timeout'**
  String get callTimeoutCallee;

  /// No description provided for @callLineBusyCaller.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get callLineBusyCaller;

  /// No description provided for @callLineBusyCallee.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get callLineBusyCallee;

  /// No description provided for @callingSwitchToAudio.
  ///
  /// In en, this message translates to:
  /// **'Switch to voice call'**
  String get callingSwitchToAudio;

  /// No description provided for @callingSwitchToAudioAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm video to voice'**
  String get callingSwitchToAudioAccept;

  /// No description provided for @aiSubtitleSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Subtitle Settings'**
  String get aiSubtitleSettings;

  /// No description provided for @aiSubtitleRecognitionAndTranslation.
  ///
  /// In en, this message translates to:
  /// **'Recognition & Translation Settings'**
  String get aiSubtitleRecognitionAndTranslation;

  /// No description provided for @aiSubtitleRecognitionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Original audio'**
  String get aiSubtitleRecognitionLanguage;

  /// No description provided for @aiSubtitleTranslationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translate display'**
  String get aiSubtitleTranslationLanguage;

  /// No description provided for @aiSubtitleShowBilingual.
  ///
  /// In en, this message translates to:
  /// **'Bilingual captions'**
  String get aiSubtitleShowBilingual;

  /// No description provided for @aiSubtitleSelectRecognitionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Recognition Language'**
  String get aiSubtitleSelectRecognitionLanguage;

  /// No description provided for @aiSubtitleSelectTranslationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Translation Language'**
  String get aiSubtitleSelectTranslationLanguage;

  /// No description provided for @aiSubtitleNoTranslation.
  ///
  /// In en, this message translates to:
  /// **'No Translation'**
  String get aiSubtitleNoTranslation;

  /// No description provided for @aiSubtitleAutoDetectChineseEnglish.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect (Chinese/English)'**
  String get aiSubtitleAutoDetectChineseEnglish;

  /// No description provided for @aiSubtitleSpeakChinese.
  ///
  /// In en, this message translates to:
  /// **'Speaking Chinese'**
  String get aiSubtitleSpeakChinese;

  /// No description provided for @aiSubtitleSpeakEnglish.
  ///
  /// In en, this message translates to:
  /// **'Speaking English'**
  String get aiSubtitleSpeakEnglish;

  /// No description provided for @aiSubtitleMe.
  ///
  /// In en, this message translates to:
  /// **'(Me)'**
  String get aiSubtitleMe;

  /// No description provided for @aiSubtitleLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文 (Chinese)'**
  String get aiSubtitleLanguageChinese;

  /// No description provided for @aiSubtitleLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aiSubtitleLanguageEnglish;

  /// No description provided for @aiSubtitleLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語 (Japanese)'**
  String get aiSubtitleLanguageJapanese;

  /// No description provided for @aiSubtitleLanguageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어 (Korean)'**
  String get aiSubtitleLanguageKorean;

  /// No description provided for @aiSubtitleLanguageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt (Vietnamese)'**
  String get aiSubtitleLanguageVietnamese;

  /// No description provided for @aiSubtitleLanguageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia (Indonesian)'**
  String get aiSubtitleLanguageIndonesian;

  /// No description provided for @aiSubtitleLanguageThai.
  ///
  /// In en, this message translates to:
  /// **'ภาษาไทย (Thai)'**
  String get aiSubtitleLanguageThai;

  /// No description provided for @aiSubtitleLanguagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português (Portuguese)'**
  String get aiSubtitleLanguagePortuguese;

  /// No description provided for @aiSubtitleLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get aiSubtitleLanguageArabic;

  /// No description provided for @aiSubtitleLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español (Spanish)'**
  String get aiSubtitleLanguageSpanish;

  /// No description provided for @aiSubtitleLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français (French)'**
  String get aiSubtitleLanguageFrench;

  /// No description provided for @aiSubtitleLanguageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu (Malay)'**
  String get aiSubtitleLanguageMalay;

  /// No description provided for @aiSubtitleLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch (German)'**
  String get aiSubtitleLanguageGerman;

  /// No description provided for @aiSubtitleLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano (Italian)'**
  String get aiSubtitleLanguageItalian;

  /// No description provided for @aiSubtitleLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский (Russian)'**
  String get aiSubtitleLanguageRussian;

  /// No description provided for @callWaitingForInvitationAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other party to accept the invitation'**
  String get callWaitingForInvitationAcceptance;

  /// No description provided for @callInvitedToAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Invited you to audio call'**
  String get callInvitedToAudioCall;

  /// No description provided for @callInvitedToVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Invited you to video call'**
  String get callInvitedToVideoCall;

  /// No description provided for @callInvitedToGroupCall.
  ///
  /// In en, this message translates to:
  /// **'Invited you to a group call'**
  String get callInvitedToGroupCall;

  /// No description provided for @callInsufficientPermissions.
  ///
  /// In en, this message translates to:
  /// **'A new call is incoming, but cannot be answered due to insufficient permissions. Please make sure the camera/microphone permission is turned on.'**
  String get callInsufficientPermissions;

  /// No description provided for @callInviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get callInviteMembers;

  /// No description provided for @callYourself.
  ///
  /// In en, this message translates to:
  /// **'yourself'**
  String get callYourself;

  /// No description provided for @callMicrophone.
  ///
  /// In en, this message translates to:
  /// **'microphone'**
  String get callMicrophone;

  /// No description provided for @callHangUp.
  ///
  /// In en, this message translates to:
  /// **'hang up'**
  String get callHangUp;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'speaker'**
  String get callSpeaker;

  /// No description provided for @callEarpiece.
  ///
  /// In en, this message translates to:
  /// **'earpiece'**
  String get callEarpiece;

  /// No description provided for @callCamera.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get callCamera;

  /// No description provided for @callSwitchToVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'switch to voice call'**
  String get callSwitchToVoiceCall;

  /// No description provided for @callAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'accept'**
  String get callAcceptAction;

  /// No description provided for @callExceededMaximumNumber.
  ///
  /// In en, this message translates to:
  /// **'Exceeded the maximum number of people'**
  String get callExceededMaximumNumber;

  /// No description provided for @callRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callRejectAction;

  /// No description provided for @callNoResponse.
  ///
  /// In en, this message translates to:
  /// **'no response'**
  String get callNoResponse;

  /// No description provided for @callBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get callBusy;

  /// No description provided for @callLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get callLeave;

  /// No description provided for @callSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get callSwitchCamera;

  /// No description provided for @callBlurBackground.
  ///
  /// In en, this message translates to:
  /// **'Blur Background'**
  String get callBlurBackground;

  /// No description provided for @callShowBlurBackground.
  ///
  /// In en, this message translates to:
  /// **'Show blur background'**
  String get callShowBlurBackground;

  /// No description provided for @callConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callConnected;

  /// No description provided for @callTheyAreAlsoThere.
  ///
  /// In en, this message translates to:
  /// **'They are also there'**
  String get callTheyAreAlsoThere;

  /// No description provided for @callJoinIn.
  ///
  /// In en, this message translates to:
  /// **'Join In'**
  String get callJoinIn;

  /// No description provided for @callPersonIsOnTheCall.
  ///
  /// In en, this message translates to:
  /// **' person is on the call'**
  String get callPersonIsOnTheCall;

  /// No description provided for @callMicrophoneIsOn.
  ///
  /// In en, this message translates to:
  /// **'Unmuted'**
  String get callMicrophoneIsOn;

  /// No description provided for @callMicrophoneIsOff.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get callMicrophoneIsOff;

  /// No description provided for @callSpeakerIsOn.
  ///
  /// In en, this message translates to:
  /// **'Speaker On'**
  String get callSpeakerIsOn;

  /// No description provided for @callSpeakerIsOff.
  ///
  /// In en, this message translates to:
  /// **'Speaker Off'**
  String get callSpeakerIsOff;

  /// No description provided for @callCameraIsOn.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get callCameraIsOn;

  /// No description provided for @callCameraIsOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get callCameraIsOff;

  /// No description provided for @callOtherPartyNetworkLowQuality.
  ///
  /// In en, this message translates to:
  /// **'The other party\'s network connection is poor'**
  String get callOtherPartyNetworkLowQuality;

  /// No description provided for @callSelfNetworkLowQuality.
  ///
  /// In en, this message translates to:
  /// **'Your network connection is poor'**
  String get callSelfNetworkLowQuality;

  /// No description provided for @callErrorInPeerBlacklist.
  ///
  /// In en, this message translates to:
  /// **'The identifier is in blacklist. Failed to send this message!'**
  String get callErrorInPeerBlacklist;

  /// No description provided for @callWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get callWaiting;

  /// No description provided for @callYouHaveANewCall.
  ///
  /// In en, this message translates to:
  /// **'You have a new call'**
  String get callYouHaveANewCall;

  /// No description provided for @callApplyForMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Apply for microphone permission'**
  String get callApplyForMicrophonePermission;

  /// No description provided for @callApplyForMicrophoneAndCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'Apply for microphone and camera permissions'**
  String get callApplyForMicrophoneAndCameraPermissions;

  /// No description provided for @callNeedToAccessMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'You need to access your microphone permission, which can be used for voice calls, multi-person voice calls, video calls, multi-person video calls and other functions after being turned on.'**
  String get callNeedToAccessMicrophonePermission;

  /// No description provided for @callNeedToAccessMicrophoneAndCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'You need to access your microphone and camera permissions, which can be used for voice calls, multi-person voice calls, video calls, multi-person video calls, etc.'**
  String get callNeedToAccessMicrophoneAndCameraPermissions;

  /// No description provided for @callDisplayPopUpWindowPermissions.
  ///
  /// In en, this message translates to:
  /// **'Display pop-up window while running in the background and Display pop-up Window permissions'**
  String get callDisplayPopUpWindowPermissions;

  /// No description provided for @callAnonymity.
  ///
  /// In en, this message translates to:
  /// **'Anonymity'**
  String get callAnonymity;

  /// No description provided for @callOtherPartyHungUp.
  ///
  /// In en, this message translates to:
  /// **'Other party hung up, call ended'**
  String get callOtherPartyHungUp;

  /// No description provided for @callOtherPartyDeclinedCallRequest.
  ///
  /// In en, this message translates to:
  /// **'Your call was declined by the other party'**
  String get callOtherPartyDeclinedCallRequest;

  /// No description provided for @callOtherPartyBusy.
  ///
  /// In en, this message translates to:
  /// **'The other party is busy, please try again later'**
  String get callOtherPartyBusy;

  /// No description provided for @callOtherPartyNoResponse.
  ///
  /// In en, this message translates to:
  /// **'The other party did not answer, please try again later'**
  String get callOtherPartyNoResponse;

  /// No description provided for @callOtherPartyCanceled.
  ///
  /// In en, this message translates to:
  /// **'Call canceled by the other party'**
  String get callOtherPartyCanceled;

  /// No description provided for @callRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'rejected call'**
  String get callRequestDeclined;

  /// No description provided for @callEndedTheCall.
  ///
  /// In en, this message translates to:
  /// **'end the call'**
  String get callEndedTheCall;

  /// No description provided for @callGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get callGoToSettings;

  /// No description provided for @callFeatureRequiresAudioVideoCallingPackage.
  ///
  /// In en, this message translates to:
  /// **'This feature requires the audio and video calling capability package. To avoid affecting your usage, we recommend going to the Tencent Cloud Real-Time Audio and Video console to activate the free trial or purchase a formal package'**
  String get callFeatureRequiresAudioVideoCallingPackage;

  /// No description provided for @callCurrentPackageDoesNotSupportFeature.
  ///
  /// In en, this message translates to:
  /// **'Your current package type does not support this feature. To unlock more capabilities, we recommend upgrading your package in the Tencent Cloud Real-Time Audio and Video console'**
  String get callCurrentPackageDoesNotSupportFeature;

  /// No description provided for @callMicrophoneOrCameraPermissionNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is not enabled, unable to start audio call. Go to \'Settings > TUICallKit\' to enable microphone permission; Camera permission is not enabled, unable to start video call. Go to \'Settings > TUICallKit\' to enable camera permission'**
  String get callMicrophoneOrCameraPermissionNotEnabled;

  /// No description provided for @callCameraOccupiedBySystemCall.
  ///
  /// In en, this message translates to:
  /// **'Current camera is occupied by system call'**
  String get callCameraOccupiedBySystemCall;

  /// No description provided for @callMicrophoneOccupiedBySystemCall.
  ///
  /// In en, this message translates to:
  /// **'Current microphone is occupied by system call'**
  String get callMicrophoneOccupiedBySystemCall;

  /// No description provided for @callCurrentlyOnCallCannotInitiateAnother.
  ///
  /// In en, this message translates to:
  /// **'You are currently on a call, please end the current call before making another one'**
  String get callCurrentlyOnCallCannotInitiateAnother;

  /// No description provided for @callFailedToInitiateCallCheckLoginStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate call, please check your login status and try again'**
  String get callFailedToInitiateCallCheckLoginStatus;

  /// No description provided for @callFailedToInitiateOrJoinCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to initiate call / Failed to join call'**
  String get callFailedToInitiateOrJoinCall;

  /// No description provided for @callCurrentCallSupportsMax9Participants.
  ///
  /// In en, this message translates to:
  /// **'Current call supports a maximum of 9 participants online simultaneously'**
  String get callCurrentCallSupportsMax9Participants;

  /// No description provided for @callInviteUserErrorOrInvalidCallParameters.
  ///
  /// In en, this message translates to:
  /// **'Invite user error or invalid call parameters'**
  String get callInviteUserErrorOrInvalidCallParameters;
}

class _AtomicLocalizationsDelegate
    extends LocalizationsDelegate<AtomicLocalizations> {
  const _AtomicLocalizationsDelegate();

  @override
  Future<AtomicLocalizations> load(Locale locale) {
    return SynchronousFuture<AtomicLocalizations>(
        lookupAtomicLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AtomicLocalizationsDelegate old) => false;
}

AtomicLocalizations lookupAtomicLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AtomicLocalizationsZhHans();
          case 'Hant':
            return AtomicLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AtomicLocalizationsAr();
    case 'en':
      return AtomicLocalizationsEn();
    case 'ja':
      return AtomicLocalizationsJa();
    case 'ko':
      return AtomicLocalizationsKo();
    case 'zh':
      return AtomicLocalizationsZh();
  }

  throw FlutterError(
      'AtomicLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
