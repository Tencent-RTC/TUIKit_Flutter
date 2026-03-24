// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'LiveKit API Example';

  @override
  String get loginSubtitle => 'Login to start';

  @override
  String get loginUserIDPlaceholder => 'Enter User ID';

  @override
  String get loginUserSigPlaceholder => 'User Sig (Auto-generated)';

  @override
  String get loginButton => 'Login';

  @override
  String get loginStatusNotLoggedIn => 'Not logged in';

  @override
  String get loginStatusLoggingIn => 'Logging in...';

  @override
  String get loginStatusLoggedIn => 'Logged in';

  @override
  String get loginErrorEmptyUserID => 'Please enter User ID';

  @override
  String loginErrorLoginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get loginDebugTip => 'UserSig will be generated locally (debug mode only)';

  @override
  String get loginErrorKickedOffline => 'You have been kicked offline, please login again';

  @override
  String get loginErrorLoginExpired => 'Login expired, please login again';

  @override
  String get profileTitle => 'Profile Setup';

  @override
  String get profileHeader => 'Set Up Your Profile';

  @override
  String get profileSubtitle => 'Set your nickname and avatar so others can recognize you';

  @override
  String get profileNicknamePlaceholder => 'Enter nickname';

  @override
  String get profileConfirm => 'Done';

  @override
  String get profileSkip => 'Skip';

  @override
  String get profileStatusSaved => 'Profile saved successfully';

  @override
  String get profileErrorEmptyNickname => 'Please enter a nickname';

  @override
  String profileErrorSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get featureListTitle => 'Features';

  @override
  String get featureListSectionHeader => 'Select Feature';

  @override
  String get featureListLanguage => 'Switch Language';

  @override
  String get roleSelectTitle => 'Select Role';

  @override
  String get roleSelectSubtitle => 'Choose your experience role';

  @override
  String get roleSelectAnchor => 'Anchor';

  @override
  String get roleSelectAnchorDesc => 'Can create live, initiate co-host, start PK';

  @override
  String get roleSelectAudience => 'Audience';

  @override
  String get roleSelectAudienceDesc => 'Can watch live, send barrage, send gifts, apply for co-host';

  @override
  String get liveIDInputTitleAnchor => 'Enter Room ID';

  @override
  String get liveIDInputTitleAudience => 'Enter Room ID';

  @override
  String get liveIDInputMessageAnchor => 'A random Room ID has been generated, you can modify or randomize it';

  @override
  String get liveIDInputMessageAudience => 'Please enter the Room ID to join';

  @override
  String get liveIDInputPlaceholder => '9-digit Room ID';

  @override
  String get liveIDInputRandom => '🎲 Randomize';

  @override
  String get liveIDInputErrorEmpty => 'Room ID cannot be empty';

  @override
  String get stageBasicStreaming => 'Basic Streaming';

  @override
  String get stageBasicStreamingDesc => 'start/join live';

  @override
  String get stageInteractive => 'Interactive';

  @override
  String get stageInteractiveDesc => 'Barrage, gifts, likes, beauty, sound effects';

  @override
  String get stageCoGuest => 'Co-Guest';

  @override
  String get stageCoGuestDesc => 'Audience list, guest connection request, host invitation, seat management';

  @override
  String get stageLivePK => 'Live PK';

  @override
  String get stageLivePKDesc => 'Cross-room host connection, PK battle, score display';

  @override
  String get basicStreamingTitle => 'Basic Streaming';

  @override
  String get basicStreamingStartLive => 'Start Live';

  @override
  String get basicStreamingStatusCreating => 'Creating live...';

  @override
  String get basicStreamingStatusEnding => 'Ending live...';

  @override
  String get basicStreamingStatusJoining => 'Joining live...';

  @override
  String basicStreamingStatusCreated(String liveId) {
    return 'Live created: $liveId';
  }

  @override
  String basicStreamingStatusJoined(String liveId) {
    return 'Joined live: $liveId';
  }

  @override
  String get basicStreamingStatusEnded => 'Live ended';

  @override
  String basicStreamingStatusFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get basicStreamingEndLiveConfirmTitle => 'End Live';

  @override
  String get basicStreamingEndLiveConfirmMessage => 'Are you sure you want to end the live?';

  @override
  String get interactiveTitle => 'Interactive';

  @override
  String get interactiveSettingsTitle => 'Settings';

  @override
  String get interactiveBarrageTitle => 'Barrage';

  @override
  String get interactiveBarrageDescription => 'Send and receive barrage messages';

  @override
  String get interactiveBarragePlaceholder => 'Say something...';

  @override
  String get interactiveBarrageSend => 'Send Barrage';

  @override
  String get interactiveGiftTitle => 'Gifts';

  @override
  String get interactiveGiftDescription => 'Send and receive gifts';

  @override
  String get interactiveGiftSend => 'Send';

  @override
  String get interactiveGiftSent => 'sent';

  @override
  String get interactiveLikeTitle => 'Likes';

  @override
  String get interactiveLikeDescription => 'Send and receive likes';

  @override
  String get interactiveLikeSend => 'Send Like';

  @override
  String get interactiveBeautyTitle => 'Beauty';

  @override
  String get interactiveBeautyDescription => 'Enable beauty effects';

  @override
  String get interactiveBeautySmooth => 'Smooth';

  @override
  String get interactiveBeautyWhiteness => 'Whiteness';

  @override
  String get interactiveBeautyRuddy => 'Ruddy';

  @override
  String get interactiveBeautyReset => 'Reset All';

  @override
  String get interactiveAudioEffectTitle => 'Audio Effects';

  @override
  String get interactiveAudioEffectChangerTitle => 'Voice Changer';

  @override
  String get interactiveAudioEffectChangerNone => 'None';

  @override
  String get interactiveAudioEffectChangerChild => 'Child';

  @override
  String get interactiveAudioEffectChangerLittleGirl => 'Girl';

  @override
  String get interactiveAudioEffectChangerMan => 'Uncle';

  @override
  String get interactiveAudioEffectChangerEthereal => 'Ethereal';

  @override
  String get interactiveAudioEffectReverbTitle => 'Reverb';

  @override
  String get interactiveAudioEffectReverbNone => 'None';

  @override
  String get interactiveAudioEffectReverbKtv => 'KTV';

  @override
  String get interactiveAudioEffectReverbSmallRoom => 'Room';

  @override
  String get interactiveAudioEffectReverbAuditorium => 'Hall';

  @override
  String get interactiveAudioEffectReverbMetallic => 'Metallic';

  @override
  String get interactiveAudioEffectEarMonitor => 'Ear Monitor';

  @override
  String get interactiveAudioEffectEarMonitorVolume => 'Monitor Volume';

  @override
  String get interactiveAudioEffectReset => 'Reset All';

  @override
  String get interactiveErrorEmptyContent => 'Please enter barrage content';

  @override
  String get interactiveSuccessGift => 'Gift sent successfully';

  @override
  String get interactiveSuccessLike => 'Like sent successfully';

  @override
  String get multiConnectTitle => 'Co-Guest';

  @override
  String get coGuestAudienceListTitle => 'Online Audience';

  @override
  String get coGuestAudienceListEmpty => 'No audience online';

  @override
  String get coGuestAudienceListInvite => 'Connect';

  @override
  String get coGuestAudienceListInviting => 'Inviting';

  @override
  String get coGuestAudienceListConnected => 'Connected';

  @override
  String coGuestAudienceCount(int count) {
    return '$count Online';
  }

  @override
  String get coGuestStatusApplying => 'Applying for connection...';

  @override
  String get coGuestStatusCancelled => 'Connection request cancelled';

  @override
  String get coGuestStatusConnected => 'Connected successfully';

  @override
  String get coGuestStatusDisconnected => 'Disconnected';

  @override
  String get coGuestStatusInvited => 'Connection invitation sent';

  @override
  String get coGuestApplicationTitle => 'Connection Request';

  @override
  String coGuestApplicationMessage(String user) {
    return '$user is requesting to connect';
  }

  @override
  String get coGuestApplicationAccept => 'Accept';

  @override
  String get coGuestApplicationReject => 'Reject';

  @override
  String get coGuestInvitationTitle => 'Connection Invitation';

  @override
  String coGuestInvitationMessage(String user) {
    return 'Host $user is inviting you to connect';
  }

  @override
  String get coGuestInvitationAccept => 'Accept';

  @override
  String get coGuestInvitationReject => 'Reject';

  @override
  String coGuestEventInviteAccepted(String user) {
    return '$user accepted the connection invitation';
  }

  @override
  String coGuestEventInviteRejected(String user) {
    return '$user rejected the connection invitation';
  }

  @override
  String coGuestEventApplicationCancelled(String user) {
    return '$user cancelled the connection request';
  }

  @override
  String coGuestEventApplicationRejected(String user) {
    return '$user rejected your connection request';
  }

  @override
  String get coGuestEventApplicationTimeout => 'Connection request timed out, please try again';

  @override
  String get coGuestEventKickedOff => 'You have been removed from the connection';

  @override
  String get coGuestEventInvitationCancelled => 'Host cancelled the connection invitation';

  @override
  String coGuestManageTitle(String user) {
    return 'Manage $user';
  }

  @override
  String get coGuestManageOpenCamera => 'Request to open camera';

  @override
  String get coGuestManageCloseCamera => 'Close camera';

  @override
  String get coGuestManageOpenMic => 'Request to open microphone';

  @override
  String get coGuestManageCloseMic => 'Close microphone';

  @override
  String get coGuestManageKickOff => 'Remove from connection';

  @override
  String get coGuestSelfManageTitle => 'Device Settings';

  @override
  String get coGuestSelfManageDisconnect => 'Disconnect';

  @override
  String get coGuestSelfManageOpenCamera => 'Turn On Camera';

  @override
  String get coGuestSelfManageCloseCamera => 'Turn Off Camera';

  @override
  String get coGuestSelfManageOpenMic => 'Turn On Microphone';

  @override
  String get coGuestSelfManageCloseMic => 'Turn Off Microphone';

  @override
  String get coGuestDeviceCameraRequestTitle => 'Turn On Camera';

  @override
  String get coGuestDeviceCameraRequestMessage => 'The host requests you to turn on your camera';

  @override
  String get coGuestDeviceMicRequestTitle => 'Turn On Microphone';

  @override
  String get coGuestDeviceMicRequestMessage => 'The host requests you to turn on your microphone';

  @override
  String get coGuestDeviceCameraClosed => 'Host has turned off your camera';

  @override
  String get coGuestDeviceMicClosed => 'Host has turned off your microphone';

  @override
  String get livePKTitle => 'Live PK';

  @override
  String get livePKCoHostConnect => 'Connect';

  @override
  String get livePKCoHostDisconnect => 'Disconnect';

  @override
  String get livePKCoHostConnecting => 'Connecting...';

  @override
  String get livePKCoHostConnected => 'Connected';

  @override
  String get livePKCoHostDisconnected => 'Disconnected';

  @override
  String get livePKCoHostSelectHost => 'Select Host';

  @override
  String get livePKCoHostEmptyList => 'No other live rooms available';

  @override
  String livePKCoHostRequestReceived(String user) {
    return '$user requests to connect';
  }

  @override
  String livePKCoHostRequestAccepted(String user) {
    return '$user accepted the connection';
  }

  @override
  String livePKCoHostRequestRejected(String user) {
    return '$user rejected the connection';
  }

  @override
  String get livePKCoHostRequestTimeout => 'Connection request timed out';

  @override
  String get livePKCoHostRequestCancelled => 'Connection request cancelled';

  @override
  String livePKCoHostUserLeft(String user) {
    return '$user left the connection';
  }

  @override
  String get livePKCoHostConfirmDisconnect => 'Are you sure you want to disconnect?';

  @override
  String get livePKBattleTitle => 'PK Battle';

  @override
  String get livePKBattleStart => 'Start PK';

  @override
  String get livePKBattleEnd => 'End PK';

  @override
  String get livePKBattleRequesting => 'PK requesting...';

  @override
  String get livePKBattleStarted => 'PK Started!';

  @override
  String get livePKBattleEnded => 'PK Ended';

  @override
  String livePKBattleRequestReceived(String user) {
    return '$user challenges you to PK';
  }

  @override
  String get livePKBattleRequestAccepted => 'PK accepted';

  @override
  String get livePKBattleRequestRejected => 'PK rejected';

  @override
  String get livePKBattleRequestTimeout => 'PK request timed out';

  @override
  String livePKBattleDuration(int seconds) {
    return 'PK Duration: $seconds seconds';
  }

  @override
  String livePKBattleScore(int score1, int score2) {
    return '$score1 : $score2';
  }

  @override
  String get livePKBattleWin => '🏆 Win';

  @override
  String get livePKBattleLose => 'Lose';

  @override
  String get livePKBattleDraw => 'Draw';

  @override
  String get livePKBattleMe => 'Me';

  @override
  String get livePKBattleConfirmEnd => 'Are you sure you want to end PK?';

  @override
  String get livePKStatusIdle => 'Waiting to connect';

  @override
  String get livePKStatusCoHostConnected => 'Connected · Ready for PK';

  @override
  String get livePKStatusBattling => 'PK in progress';

  @override
  String get deviceSettingTitle => 'Device Settings';

  @override
  String get deviceSettingCamera => 'Camera';

  @override
  String get deviceSettingMicrophone => 'Microphone';

  @override
  String get deviceSettingFrontCamera => 'Front Camera';

  @override
  String get deviceSettingMirror => 'Mirror Mode';

  @override
  String get deviceSettingVideoQuality => 'Video Quality';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonWarning => 'Warning';
}
