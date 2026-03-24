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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'LiveKit API Example'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to start'**
  String get loginSubtitle;

  /// No description provided for @loginUserIDPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter User ID'**
  String get loginUserIDPlaceholder;

  /// No description provided for @loginUserSigPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'User Sig (Auto-generated)'**
  String get loginUserSigPlaceholder;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginStatusNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get loginStatusNotLoggedIn;

  /// No description provided for @loginStatusLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loginStatusLoggingIn;

  /// No description provided for @loginStatusLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get loginStatusLoggedIn;

  /// No description provided for @loginErrorEmptyUserID.
  ///
  /// In en, this message translates to:
  /// **'Please enter User ID'**
  String get loginErrorEmptyUserID;

  /// No description provided for @loginErrorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginErrorLoginFailed(String error);

  /// No description provided for @loginDebugTip.
  ///
  /// In en, this message translates to:
  /// **'UserSig will be generated locally (debug mode only)'**
  String get loginDebugTip;

  /// No description provided for @loginErrorKickedOffline.
  ///
  /// In en, this message translates to:
  /// **'You have been kicked offline, please login again'**
  String get loginErrorKickedOffline;

  /// No description provided for @loginErrorLoginExpired.
  ///
  /// In en, this message translates to:
  /// **'Login expired, please login again'**
  String get loginErrorLoginExpired;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get profileTitle;

  /// No description provided for @profileHeader.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Profile'**
  String get profileHeader;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your nickname and avatar so others can recognize you'**
  String get profileSubtitle;

  /// No description provided for @profileNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get profileNicknamePlaceholder;

  /// No description provided for @profileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileConfirm;

  /// No description provided for @profileSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get profileSkip;

  /// No description provided for @profileStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileStatusSaved;

  /// No description provided for @profileErrorEmptyNickname.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get profileErrorEmptyNickname;

  /// No description provided for @profileErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String profileErrorSaveFailed(String error);

  /// No description provided for @featureListTitle.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featureListTitle;

  /// No description provided for @featureListSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Select Feature'**
  String get featureListSectionHeader;

  /// No description provided for @featureListLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get featureListLanguage;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your experience role'**
  String get roleSelectSubtitle;

  /// No description provided for @roleSelectAnchor.
  ///
  /// In en, this message translates to:
  /// **'Anchor'**
  String get roleSelectAnchor;

  /// No description provided for @roleSelectAnchorDesc.
  ///
  /// In en, this message translates to:
  /// **'Can create live, initiate co-host, start PK'**
  String get roleSelectAnchorDesc;

  /// No description provided for @roleSelectAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get roleSelectAudience;

  /// No description provided for @roleSelectAudienceDesc.
  ///
  /// In en, this message translates to:
  /// **'Can watch live, send barrage, send gifts, apply for co-host'**
  String get roleSelectAudienceDesc;

  /// No description provided for @liveIDInputTitleAnchor.
  ///
  /// In en, this message translates to:
  /// **'Enter Room ID'**
  String get liveIDInputTitleAnchor;

  /// No description provided for @liveIDInputTitleAudience.
  ///
  /// In en, this message translates to:
  /// **'Enter Room ID'**
  String get liveIDInputTitleAudience;

  /// No description provided for @liveIDInputMessageAnchor.
  ///
  /// In en, this message translates to:
  /// **'A random Room ID has been generated, you can modify or randomize it'**
  String get liveIDInputMessageAnchor;

  /// No description provided for @liveIDInputMessageAudience.
  ///
  /// In en, this message translates to:
  /// **'Please enter the Room ID to join'**
  String get liveIDInputMessageAudience;

  /// No description provided for @liveIDInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'9-digit Room ID'**
  String get liveIDInputPlaceholder;

  /// No description provided for @liveIDInputRandom.
  ///
  /// In en, this message translates to:
  /// **'🎲 Randomize'**
  String get liveIDInputRandom;

  /// No description provided for @liveIDInputErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Room ID cannot be empty'**
  String get liveIDInputErrorEmpty;

  /// No description provided for @stageBasicStreaming.
  ///
  /// In en, this message translates to:
  /// **'Basic Streaming'**
  String get stageBasicStreaming;

  /// No description provided for @stageBasicStreamingDesc.
  ///
  /// In en, this message translates to:
  /// **'start/join live'**
  String get stageBasicStreamingDesc;

  /// No description provided for @stageInteractive.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get stageInteractive;

  /// No description provided for @stageInteractiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Barrage, gifts, likes, beauty, sound effects'**
  String get stageInteractiveDesc;

  /// No description provided for @stageCoGuest.
  ///
  /// In en, this message translates to:
  /// **'Co-Guest'**
  String get stageCoGuest;

  /// No description provided for @stageCoGuestDesc.
  ///
  /// In en, this message translates to:
  /// **'Audience list, guest connection request, host invitation, seat management'**
  String get stageCoGuestDesc;

  /// No description provided for @stageLivePK.
  ///
  /// In en, this message translates to:
  /// **'Live PK'**
  String get stageLivePK;

  /// No description provided for @stageLivePKDesc.
  ///
  /// In en, this message translates to:
  /// **'Cross-room host connection, PK battle, score display'**
  String get stageLivePKDesc;

  /// No description provided for @basicStreamingTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Streaming'**
  String get basicStreamingTitle;

  /// No description provided for @basicStreamingStartLive.
  ///
  /// In en, this message translates to:
  /// **'Start Live'**
  String get basicStreamingStartLive;

  /// No description provided for @basicStreamingStatusCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating live...'**
  String get basicStreamingStatusCreating;

  /// No description provided for @basicStreamingStatusEnding.
  ///
  /// In en, this message translates to:
  /// **'Ending live...'**
  String get basicStreamingStatusEnding;

  /// No description provided for @basicStreamingStatusJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining live...'**
  String get basicStreamingStatusJoining;

  /// No description provided for @basicStreamingStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Live created: {liveId}'**
  String basicStreamingStatusCreated(String liveId);

  /// No description provided for @basicStreamingStatusJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined live: {liveId}'**
  String basicStreamingStatusJoined(String liveId);

  /// No description provided for @basicStreamingStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Live ended'**
  String get basicStreamingStatusEnded;

  /// No description provided for @basicStreamingStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String basicStreamingStatusFailed(String error);

  /// No description provided for @basicStreamingEndLiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End Live'**
  String get basicStreamingEndLiveConfirmTitle;

  /// No description provided for @basicStreamingEndLiveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end the live?'**
  String get basicStreamingEndLiveConfirmMessage;

  /// No description provided for @interactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive'**
  String get interactiveTitle;

  /// No description provided for @interactiveSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get interactiveSettingsTitle;

  /// No description provided for @interactiveBarrageTitle.
  ///
  /// In en, this message translates to:
  /// **'Barrage'**
  String get interactiveBarrageTitle;

  /// No description provided for @interactiveBarrageDescription.
  ///
  /// In en, this message translates to:
  /// **'Send and receive barrage messages'**
  String get interactiveBarrageDescription;

  /// No description provided for @interactiveBarragePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get interactiveBarragePlaceholder;

  /// No description provided for @interactiveBarrageSend.
  ///
  /// In en, this message translates to:
  /// **'Send Barrage'**
  String get interactiveBarrageSend;

  /// No description provided for @interactiveGiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get interactiveGiftTitle;

  /// No description provided for @interactiveGiftDescription.
  ///
  /// In en, this message translates to:
  /// **'Send and receive gifts'**
  String get interactiveGiftDescription;

  /// No description provided for @interactiveGiftSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get interactiveGiftSend;

  /// No description provided for @interactiveGiftSent.
  ///
  /// In en, this message translates to:
  /// **'sent'**
  String get interactiveGiftSent;

  /// No description provided for @interactiveLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get interactiveLikeTitle;

  /// No description provided for @interactiveLikeDescription.
  ///
  /// In en, this message translates to:
  /// **'Send and receive likes'**
  String get interactiveLikeDescription;

  /// No description provided for @interactiveLikeSend.
  ///
  /// In en, this message translates to:
  /// **'Send Like'**
  String get interactiveLikeSend;

  /// No description provided for @interactiveBeautyTitle.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get interactiveBeautyTitle;

  /// No description provided for @interactiveBeautyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable beauty effects'**
  String get interactiveBeautyDescription;

  /// No description provided for @interactiveBeautySmooth.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get interactiveBeautySmooth;

  /// No description provided for @interactiveBeautyWhiteness.
  ///
  /// In en, this message translates to:
  /// **'Whiteness'**
  String get interactiveBeautyWhiteness;

  /// No description provided for @interactiveBeautyRuddy.
  ///
  /// In en, this message translates to:
  /// **'Ruddy'**
  String get interactiveBeautyRuddy;

  /// No description provided for @interactiveBeautyReset.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get interactiveBeautyReset;

  /// No description provided for @interactiveAudioEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Effects'**
  String get interactiveAudioEffectTitle;

  /// No description provided for @interactiveAudioEffectChangerTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Changer'**
  String get interactiveAudioEffectChangerTitle;

  /// No description provided for @interactiveAudioEffectChangerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get interactiveAudioEffectChangerNone;

  /// No description provided for @interactiveAudioEffectChangerChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get interactiveAudioEffectChangerChild;

  /// No description provided for @interactiveAudioEffectChangerLittleGirl.
  ///
  /// In en, this message translates to:
  /// **'Girl'**
  String get interactiveAudioEffectChangerLittleGirl;

  /// No description provided for @interactiveAudioEffectChangerMan.
  ///
  /// In en, this message translates to:
  /// **'Uncle'**
  String get interactiveAudioEffectChangerMan;

  /// No description provided for @interactiveAudioEffectChangerEthereal.
  ///
  /// In en, this message translates to:
  /// **'Ethereal'**
  String get interactiveAudioEffectChangerEthereal;

  /// No description provided for @interactiveAudioEffectReverbTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverb'**
  String get interactiveAudioEffectReverbTitle;

  /// No description provided for @interactiveAudioEffectReverbNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get interactiveAudioEffectReverbNone;

  /// No description provided for @interactiveAudioEffectReverbKtv.
  ///
  /// In en, this message translates to:
  /// **'KTV'**
  String get interactiveAudioEffectReverbKtv;

  /// No description provided for @interactiveAudioEffectReverbSmallRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get interactiveAudioEffectReverbSmallRoom;

  /// No description provided for @interactiveAudioEffectReverbAuditorium.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get interactiveAudioEffectReverbAuditorium;

  /// No description provided for @interactiveAudioEffectReverbMetallic.
  ///
  /// In en, this message translates to:
  /// **'Metallic'**
  String get interactiveAudioEffectReverbMetallic;

  /// No description provided for @interactiveAudioEffectEarMonitor.
  ///
  /// In en, this message translates to:
  /// **'Ear Monitor'**
  String get interactiveAudioEffectEarMonitor;

  /// No description provided for @interactiveAudioEffectEarMonitorVolume.
  ///
  /// In en, this message translates to:
  /// **'Monitor Volume'**
  String get interactiveAudioEffectEarMonitorVolume;

  /// No description provided for @interactiveAudioEffectReset.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get interactiveAudioEffectReset;

  /// No description provided for @interactiveErrorEmptyContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter barrage content'**
  String get interactiveErrorEmptyContent;

  /// No description provided for @interactiveSuccessGift.
  ///
  /// In en, this message translates to:
  /// **'Gift sent successfully'**
  String get interactiveSuccessGift;

  /// No description provided for @interactiveSuccessLike.
  ///
  /// In en, this message translates to:
  /// **'Like sent successfully'**
  String get interactiveSuccessLike;

  /// No description provided for @multiConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Co-Guest'**
  String get multiConnectTitle;

  /// No description provided for @coGuestAudienceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Audience'**
  String get coGuestAudienceListTitle;

  /// No description provided for @coGuestAudienceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audience online'**
  String get coGuestAudienceListEmpty;

  /// No description provided for @coGuestAudienceListInvite.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get coGuestAudienceListInvite;

  /// No description provided for @coGuestAudienceListInviting.
  ///
  /// In en, this message translates to:
  /// **'Inviting'**
  String get coGuestAudienceListInviting;

  /// No description provided for @coGuestAudienceListConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get coGuestAudienceListConnected;

  /// No description provided for @coGuestAudienceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Online'**
  String coGuestAudienceCount(int count);

  /// No description provided for @coGuestStatusApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying for connection...'**
  String get coGuestStatusApplying;

  /// No description provided for @coGuestStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Connection request cancelled'**
  String get coGuestStatusCancelled;

  /// No description provided for @coGuestStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get coGuestStatusConnected;

  /// No description provided for @coGuestStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get coGuestStatusDisconnected;

  /// No description provided for @coGuestStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Connection invitation sent'**
  String get coGuestStatusInvited;

  /// No description provided for @coGuestApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Request'**
  String get coGuestApplicationTitle;

  /// No description provided for @coGuestApplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'{user} is requesting to connect'**
  String coGuestApplicationMessage(String user);

  /// No description provided for @coGuestApplicationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get coGuestApplicationAccept;

  /// No description provided for @coGuestApplicationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get coGuestApplicationReject;

  /// No description provided for @coGuestInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Invitation'**
  String get coGuestInvitationTitle;

  /// No description provided for @coGuestInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Host {user} is inviting you to connect'**
  String coGuestInvitationMessage(String user);

  /// No description provided for @coGuestInvitationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get coGuestInvitationAccept;

  /// No description provided for @coGuestInvitationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get coGuestInvitationReject;

  /// No description provided for @coGuestEventInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'{user} accepted the connection invitation'**
  String coGuestEventInviteAccepted(String user);

  /// No description provided for @coGuestEventInviteRejected.
  ///
  /// In en, this message translates to:
  /// **'{user} rejected the connection invitation'**
  String coGuestEventInviteRejected(String user);

  /// No description provided for @coGuestEventApplicationCancelled.
  ///
  /// In en, this message translates to:
  /// **'{user} cancelled the connection request'**
  String coGuestEventApplicationCancelled(String user);

  /// No description provided for @coGuestEventApplicationRejected.
  ///
  /// In en, this message translates to:
  /// **'{user} rejected your connection request'**
  String coGuestEventApplicationRejected(String user);

  /// No description provided for @coGuestEventApplicationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection request timed out, please try again'**
  String get coGuestEventApplicationTimeout;

  /// No description provided for @coGuestEventKickedOff.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the connection'**
  String get coGuestEventKickedOff;

  /// No description provided for @coGuestEventInvitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Host cancelled the connection invitation'**
  String get coGuestEventInvitationCancelled;

  /// No description provided for @coGuestManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage {user}'**
  String coGuestManageTitle(String user);

  /// No description provided for @coGuestManageOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Request to open camera'**
  String get coGuestManageOpenCamera;

  /// No description provided for @coGuestManageCloseCamera.
  ///
  /// In en, this message translates to:
  /// **'Close camera'**
  String get coGuestManageCloseCamera;

  /// No description provided for @coGuestManageOpenMic.
  ///
  /// In en, this message translates to:
  /// **'Request to open microphone'**
  String get coGuestManageOpenMic;

  /// No description provided for @coGuestManageCloseMic.
  ///
  /// In en, this message translates to:
  /// **'Close microphone'**
  String get coGuestManageCloseMic;

  /// No description provided for @coGuestManageKickOff.
  ///
  /// In en, this message translates to:
  /// **'Remove from connection'**
  String get coGuestManageKickOff;

  /// No description provided for @coGuestSelfManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get coGuestSelfManageTitle;

  /// No description provided for @coGuestSelfManageDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get coGuestSelfManageDisconnect;

  /// No description provided for @coGuestSelfManageOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Turn On Camera'**
  String get coGuestSelfManageOpenCamera;

  /// No description provided for @coGuestSelfManageCloseCamera.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Camera'**
  String get coGuestSelfManageCloseCamera;

  /// No description provided for @coGuestSelfManageOpenMic.
  ///
  /// In en, this message translates to:
  /// **'Turn On Microphone'**
  String get coGuestSelfManageOpenMic;

  /// No description provided for @coGuestSelfManageCloseMic.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Microphone'**
  String get coGuestSelfManageCloseMic;

  /// No description provided for @coGuestDeviceCameraRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn On Camera'**
  String get coGuestDeviceCameraRequestTitle;

  /// No description provided for @coGuestDeviceCameraRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'The host requests you to turn on your camera'**
  String get coGuestDeviceCameraRequestMessage;

  /// No description provided for @coGuestDeviceMicRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn On Microphone'**
  String get coGuestDeviceMicRequestTitle;

  /// No description provided for @coGuestDeviceMicRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'The host requests you to turn on your microphone'**
  String get coGuestDeviceMicRequestMessage;

  /// No description provided for @coGuestDeviceCameraClosed.
  ///
  /// In en, this message translates to:
  /// **'Host has turned off your camera'**
  String get coGuestDeviceCameraClosed;

  /// No description provided for @coGuestDeviceMicClosed.
  ///
  /// In en, this message translates to:
  /// **'Host has turned off your microphone'**
  String get coGuestDeviceMicClosed;

  /// No description provided for @livePKTitle.
  ///
  /// In en, this message translates to:
  /// **'Live PK'**
  String get livePKTitle;

  /// No description provided for @livePKCoHostConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get livePKCoHostConnect;

  /// No description provided for @livePKCoHostDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get livePKCoHostDisconnect;

  /// No description provided for @livePKCoHostConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get livePKCoHostConnecting;

  /// No description provided for @livePKCoHostConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get livePKCoHostConnected;

  /// No description provided for @livePKCoHostDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get livePKCoHostDisconnected;

  /// No description provided for @livePKCoHostSelectHost.
  ///
  /// In en, this message translates to:
  /// **'Select Host'**
  String get livePKCoHostSelectHost;

  /// No description provided for @livePKCoHostEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No other live rooms available'**
  String get livePKCoHostEmptyList;

  /// No description provided for @livePKCoHostRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'{user} requests to connect'**
  String livePKCoHostRequestReceived(String user);

  /// No description provided for @livePKCoHostRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'{user} accepted the connection'**
  String livePKCoHostRequestAccepted(String user);

  /// No description provided for @livePKCoHostRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'{user} rejected the connection'**
  String livePKCoHostRequestRejected(String user);

  /// No description provided for @livePKCoHostRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection request timed out'**
  String get livePKCoHostRequestTimeout;

  /// No description provided for @livePKCoHostRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Connection request cancelled'**
  String get livePKCoHostRequestCancelled;

  /// No description provided for @livePKCoHostUserLeft.
  ///
  /// In en, this message translates to:
  /// **'{user} left the connection'**
  String livePKCoHostUserLeft(String user);

  /// No description provided for @livePKCoHostConfirmDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect?'**
  String get livePKCoHostConfirmDisconnect;

  /// No description provided for @livePKBattleTitle.
  ///
  /// In en, this message translates to:
  /// **'PK Battle'**
  String get livePKBattleTitle;

  /// No description provided for @livePKBattleStart.
  ///
  /// In en, this message translates to:
  /// **'Start PK'**
  String get livePKBattleStart;

  /// No description provided for @livePKBattleEnd.
  ///
  /// In en, this message translates to:
  /// **'End PK'**
  String get livePKBattleEnd;

  /// No description provided for @livePKBattleRequesting.
  ///
  /// In en, this message translates to:
  /// **'PK requesting...'**
  String get livePKBattleRequesting;

  /// No description provided for @livePKBattleStarted.
  ///
  /// In en, this message translates to:
  /// **'PK Started!'**
  String get livePKBattleStarted;

  /// No description provided for @livePKBattleEnded.
  ///
  /// In en, this message translates to:
  /// **'PK Ended'**
  String get livePKBattleEnded;

  /// No description provided for @livePKBattleRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'{user} challenges you to PK'**
  String livePKBattleRequestReceived(String user);

  /// No description provided for @livePKBattleRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'PK accepted'**
  String get livePKBattleRequestAccepted;

  /// No description provided for @livePKBattleRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'PK rejected'**
  String get livePKBattleRequestRejected;

  /// No description provided for @livePKBattleRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'PK request timed out'**
  String get livePKBattleRequestTimeout;

  /// No description provided for @livePKBattleDuration.
  ///
  /// In en, this message translates to:
  /// **'PK Duration: {seconds} seconds'**
  String livePKBattleDuration(int seconds);

  /// No description provided for @livePKBattleScore.
  ///
  /// In en, this message translates to:
  /// **'{score1} : {score2}'**
  String livePKBattleScore(int score1, int score2);

  /// No description provided for @livePKBattleWin.
  ///
  /// In en, this message translates to:
  /// **'🏆 Win'**
  String get livePKBattleWin;

  /// No description provided for @livePKBattleLose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get livePKBattleLose;

  /// No description provided for @livePKBattleDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get livePKBattleDraw;

  /// No description provided for @livePKBattleMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get livePKBattleMe;

  /// No description provided for @livePKBattleConfirmEnd.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end PK?'**
  String get livePKBattleConfirmEnd;

  /// No description provided for @livePKStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to connect'**
  String get livePKStatusIdle;

  /// No description provided for @livePKStatusCoHostConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected · Ready for PK'**
  String get livePKStatusCoHostConnected;

  /// No description provided for @livePKStatusBattling.
  ///
  /// In en, this message translates to:
  /// **'PK in progress'**
  String get livePKStatusBattling;

  /// No description provided for @deviceSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get deviceSettingTitle;

  /// No description provided for @deviceSettingCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get deviceSettingCamera;

  /// No description provided for @deviceSettingMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get deviceSettingMicrophone;

  /// No description provided for @deviceSettingFrontCamera.
  ///
  /// In en, this message translates to:
  /// **'Front Camera'**
  String get deviceSettingFrontCamera;

  /// No description provided for @deviceSettingMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror Mode'**
  String get deviceSettingMirror;

  /// No description provided for @deviceSettingVideoQuality.
  ///
  /// In en, this message translates to:
  /// **'Video Quality'**
  String get deviceSettingVideoQuality;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonConfirm;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get commonWarning;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
