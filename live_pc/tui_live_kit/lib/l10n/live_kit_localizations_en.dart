// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'live_kit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LiveKitLocalizationsEn extends LiveKitLocalizations {
  LiveKitLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get barrageEmpty => 'No messages yet';

  @override
  String get barrageLatest => 'Latest messages';

  @override
  String get barrageBackToBottom => 'Back to bottom';

  @override
  String get barrageInputHint => 'Send a barrage...';

  @override
  String get interactionTitle => 'Interaction';

  @override
  String get giftEmpty => 'No gifts yet';

  @override
  String get giftSent => 'sent';

  @override
  String get audienceTitle => 'Audience';

  @override
  String get audienceEmpty => 'No audience yet';

  @override
  String get audienceMute => 'Mute';

  @override
  String get audienceUnmute => 'Unmute';

  @override
  String get audienceKick => 'Remove';

  @override
  String get audienceMutedTag => 'Muted';

  @override
  String get loginBrandTitle => 'Live Streaming Assistant';

  @override
  String get loginTabUsername => 'Username Login';

  @override
  String get loginUsernameHint => 'Enter username';

  @override
  String get loginButton => 'Login';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'OK';

  @override
  String get errorDialogTitle => 'Operation Failed';

  @override
  String get sceneGame => 'Game Streaming';

  @override
  String get sceneMovie => 'Watch Together';

  @override
  String get sceneChat => 'Group Chat';

  @override
  String get sceneTalk => 'Casual Talk';

  @override
  String get sceneRest => 'Be Right Back';

  @override
  String get sceneDefault => 'Scene 1';

  @override
  String sceneCustomSuggestion(Object index) {
    return 'Custom $index';
  }

  @override
  String sceneCopySuffix(Object name) {
    return '$name Copy';
  }

  @override
  String get sceneMenuRename => 'Rename';

  @override
  String get sceneMenuDuplicate => 'Duplicate';

  @override
  String get sceneMenuDelete => 'Delete';

  @override
  String get sceneRenameTitle => 'Rename Scene';

  @override
  String get sceneNameHint => 'Scene name';

  @override
  String get sceneAddTitle => 'Add Scene';

  @override
  String get sceneIconPick => 'Choose an icon';

  @override
  String get sceneGroupLandscape => 'Landscape Scenes';

  @override
  String get sceneGroupPortrait => 'Portrait Scenes';

  @override
  String get sourceAddTitle => 'Add Source';

  @override
  String get sourceTypeCamera => 'Camera';

  @override
  String get sourceTypeCameraDesc => 'Capture camera video';

  @override
  String get sourceTypeScreen => 'Screen';

  @override
  String get sourceTypeScreenDesc => 'Screen / window capture';

  @override
  String get sourceTypeImage => 'Image';

  @override
  String get sourceTypeImageDesc => 'Static image';

  @override
  String get sourceTypeOnlineVideo => 'Online Video';

  @override
  String get sourceTypeOnlineVideoDesc => 'Network video stream URL';

  @override
  String get sourceTypeVideoFile => 'Video File';

  @override
  String get sourceTypeVideoFileDesc => 'Local video file';

  @override
  String get sourceNameCamera => 'Camera Feed';

  @override
  String get sourceNameScreen => 'Screen Share';

  @override
  String get sourceListEmpty =>
      'No sources in this scene\nTap + at the top right to add';

  @override
  String get errorStartMixing => 'Failed to start mixing';

  @override
  String get errorSourceNotFound => 'Source not found';

  @override
  String errorAddSource(Object code) {
    return 'Failed to add source (error code $code)';
  }

  @override
  String get cameraEditTitle => 'Edit Camera';

  @override
  String get cameraAddTitle => 'Add Camera';

  @override
  String get cameraDeviceLabel => 'Select an available camera';

  @override
  String get cameraDeviceHint => 'Select camera';

  @override
  String get cameraNotFound => 'No camera device detected';

  @override
  String get cameraResolutionLabel => 'Capture Resolution';

  @override
  String get cameraMirrorLabel => 'Mirror';

  @override
  String get imageEditTitle => 'Edit Image';

  @override
  String get imageAddTitle => 'Add Image';

  @override
  String get imageFileLabel => 'Image File';

  @override
  String get imagePickPlaceholder => 'Choose a local image';

  @override
  String get imagePickButton => 'Choose Image';

  @override
  String get imageFormatsHint => 'Supports BMP / JPG / PNG / GIF';

  @override
  String get videoFileEditTitle => 'Edit Video File';

  @override
  String get videoFileAddTitle => 'Add Video File';

  @override
  String get videoFileLabel => 'Video File';

  @override
  String get videoPickPlaceholder => 'Choose a local video';

  @override
  String get videoPickButton => 'Choose Video';

  @override
  String get videoFileFormatsHint =>
      'Supports MP4 / MOV / M4V / MKV / AVI / FLV / WMV';

  @override
  String get onlineVideoEditTitle => 'Edit Online Video';

  @override
  String get onlineVideoAddTitle => 'Add Online Video';

  @override
  String get onlineVideoUrlLabel => 'Video URL';

  @override
  String get onlineVideoUrlHint =>
      'Video URL starting with http:// or https://';

  @override
  String get onlineVideoProtocolHint => 'Only HTTP / HTTPS supported';

  @override
  String get onlineVideoUrlInvalid =>
      'Please enter a valid http / https video URL';

  @override
  String get onlineVideoCacheLabel => 'Network Cache';

  @override
  String get onlineVideoCacheAuto => 'Auto';

  @override
  String get onlineVideoCacheAutoScale => '0 (Auto)';

  @override
  String get screenEditTitle => 'Edit Screen Share';

  @override
  String get screenAddTitle => 'Add Screen Share';

  @override
  String get screenTabWindow => 'Window';

  @override
  String screenEmpty(Object kind) {
    return 'No shareable $kind found\nCheck \"System Settings → Privacy & Security → Screen Recording\" permission';
  }

  @override
  String get screenEnumFailed => 'Failed to enumerate share sources';

  @override
  String filePickRequired(Object label) {
    return 'Please select a $label file';
  }

  @override
  String fileFormatUnsupported(Object label, Object ext) {
    return 'Unsupported $label format: .$ext';
  }

  @override
  String get fileNotReadable => 'File does not exist or is unreadable';

  @override
  String get playbackVolume => 'Playback Volume';

  @override
  String get tabSources => 'Sources';

  @override
  String get tabBeauty => 'Beauty';

  @override
  String get tabMore => 'More';

  @override
  String get featureInDevelopment => 'In development';

  @override
  String get featureComingSoon => 'Coming soon';

  @override
  String get beautyNoCamera => 'No camera added in this scene';

  @override
  String get beautyFilterTitle => 'Beauty Filter';

  @override
  String get beautySkinSmooth => 'Smooth';

  @override
  String get beautyWhiteness => 'Whiteness';

  @override
  String get beautySharpen => 'Sharpen';

  @override
  String get beautyRuddy => 'Ruddy';

  @override
  String get orientationLandscape => 'Landscape';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get liveStart => 'Start Live';

  @override
  String get liveEnd => 'End Live';

  @override
  String get liveInfoEditTitle => 'Edit Live Info';

  @override
  String get liveInfoNameLabel => 'Live Name';

  @override
  String get liveInfoVisibilityLabel => 'Visibility';

  @override
  String get liveInfoVisibilityPublic => 'Public';

  @override
  String get liveInfoVisibilityPrivate => 'Private';

  @override
  String get liveInfoSave => 'Save Settings';

  @override
  String liveDefaultName(Object name) {
    return '$name\'s Room';
  }

  @override
  String liveStatsGiftSenders(Object count) {
    return '$count sent gifts';
  }

  @override
  String get liveSummaryTitle => 'Live Ended';

  @override
  String get liveSummarySubtitle => 'Live Session Summary';

  @override
  String get liveSummaryDuration => 'Duration';

  @override
  String get liveSummaryViewers => 'Total Viewers';

  @override
  String get liveSummaryLikes => 'Total Likes';

  @override
  String get liveSummaryGiftSenders => 'Gift Senders';

  @override
  String get liveSummaryDone => 'Done';

  @override
  String get languageSwitch => 'Language';

  @override
  String get languageFollowSystem => 'Follow System';
}
