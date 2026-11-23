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
  String barrageNewMessages(Object count) {
    return '$count new messages';
  }

  @override
  String get barrageInputHint => 'Send a barrage...';

  @override
  String get barrageErrorMuted => 'You are muted and cannot send comments.';

  @override
  String get barrageErrorAllMuted =>
      'Comments are disabled for everyone in this live room.';

  @override
  String get barrageErrorTooFrequent =>
      'You are sending too quickly. Please try again later.';

  @override
  String get barrageErrorContentRejected =>
      'This comment does not meet the content guidelines. Please edit it and try again.';

  @override
  String get barrageErrorTooLong =>
      'Your comment is too long. Please shorten it and try again.';

  @override
  String get barrageErrorLoginExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get barrageErrorLoginElsewhere =>
      'Your account is logged in on another device. Please log in again.';

  @override
  String get barrageErrorNotJoined =>
      'Please join the live room before sending comments.';

  @override
  String get barrageErrorRoomUnavailable =>
      'This live room is unavailable. Comments cannot be sent.';

  @override
  String get barrageErrorNoPermission =>
      'You do not have permission to send comments in this live room.';

  @override
  String get barrageErrorNetwork =>
      'Network connection error. Please check your connection and try again.';

  @override
  String get barrageErrorTimeout =>
      'Sending your comment timed out. Please try again later.';

  @override
  String get barrageErrorSendRejected =>
      'Your comment could not be sent. Please try again later.';

  @override
  String get barrageErrorSendFailed =>
      'Failed to send comment. Please try again later.';

  @override
  String get interactionTitle => 'Interaction';

  @override
  String get barrageHostTag => 'Host';

  @override
  String get giftEmpty => 'No gifts yet';

  @override
  String giftNewItems(Object count) {
    return '$count new gifts';
  }

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
  String audienceMutedToast(Object name) {
    return 'Muted \"$name\"';
  }

  @override
  String audienceUnmutedToast(Object name) {
    return 'Unmuted \"$name\"';
  }

  @override
  String audienceKickedToast(Object name) {
    return 'Removed \"$name\" from the live';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get sceneDefault => 'Scene';

  @override
  String sceneCustomSuggestion(Object index) {
    return 'Scene $index';
  }

  @override
  String sceneCopySuffix(Object name, Object index) {
    return '$name $index';
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
  String get sceneNameLimit => 'Name cannot exceed 20 characters';

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
  String get errorStartMixing => 'Failed to start mixing';

  @override
  String get errorSourceNotFound => 'Source not found';

  @override
  String get errorSourceDuplicated =>
      'The same content has already been added to this scene';

  @override
  String get liveShareCopied => 'Live room ID copied';

  @override
  String get liveShareTooltip => 'Share live room (copy room ID)';

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
  String get imageFormatsHintNoGif => 'Supports BMP / JPG / PNG';

  @override
  String get imageSizeTooLarge => 'Image size cannot exceed 8192×8192';

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
  String get videoFileFormatsHint => 'Supports MOV / MP4 / MKV';

  @override
  String get onlineVideoEditTitle => 'Edit Online Video';

  @override
  String get onlineVideoAddTitle => 'Add Online Video';

  @override
  String get onlineVideoUrlLabel => 'Video URL';

  @override
  String get onlineVideoUrlHint =>
      'RTMP live stream URL, or an HTTP(S) media URL in .m3u8 / .flv / .mov / .mp4 / .mkv format';

  @override
  String get onlineVideoUrlInvalid =>
      'Please enter a valid RTMP live stream URL or an HTTP(S) media URL\nSupported HTTP(S) media formats: .m3u8 / .flv / .mov / .mp4 / .mkv';

  @override
  String get onlineVideoCacheLabel => 'Network Cache';

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
  String get featureComingSoon => 'Coming soon';

  @override
  String get beautyNoCamera => 'No camera added in this scene';

  @override
  String get beautyAllCamerasHidden =>
      'All cameras are hidden. Unhide a camera to adjust beauty effects';

  @override
  String get beautyFilterTitle => 'Beauty Filter';

  @override
  String get beautySkinSmooth => 'Smooth';

  @override
  String get beautyWhiteness => 'Whiteness';

  @override
  String get beautyRuddy => 'Ruddy';

  @override
  String runtimeSourceError(Object sourceName, Object reason) {
    return 'Source \"$sourceName\": $reason';
  }

  @override
  String get errorImageLoadFailed => 'Image failed to load';

  @override
  String get errorCameraNotAuthorized => 'Camera not authorized';

  @override
  String get errorCameraIsOccupied => 'Camera is occupied';

  @override
  String get errorCameraDisconnected => 'Camera disconnected';

  @override
  String get errorVideoFileNotExist => 'Video file does not exist';

  @override
  String get errorOnlineVideoProtocol => 'Unsupported online video protocol';

  @override
  String get errorLocalVideoFormat => 'Unsupported local video format';

  @override
  String get errorHevcDecoder => 'No available decoder';

  @override
  String get errorInvalidParams => 'Invalid parameters';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get errorOperationFailed => 'Operation failed, please try again';

  @override
  String get errorOnlineVideoConnectFailed => 'Online video connection failed';

  @override
  String get errorOnlineVideoConnectionLost => 'Online video connection lost';

  @override
  String get errorScreenSourceClosed => 'Shared window or screen was closed';

  @override
  String get errorScreenDisplayChanged => 'Display disconnected or changed';

  @override
  String get errorCameraRunFailed => 'Camera source failed';

  @override
  String get errorScreenRunFailed => 'Screen capture failed';

  @override
  String get errorImageRunFailed => 'Image display failed';

  @override
  String get errorVideoFilePlayFailed => 'Video file playback failed';

  @override
  String get errorOnlineVideoPlayFailed => 'Online video playback failed';

  @override
  String get mixingStoppedSourceLost => 'Source lost, mixing stopped';

  @override
  String get orientationLandscape => 'Landscape';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get liveStart => 'Start Live';

  @override
  String get liveStarting => 'Starting…';

  @override
  String liveStartFailed(Object code, Object message) {
    return 'Failed to start live, error code: $code; error: $message';
  }

  @override
  String get liveStartFailedSensitiveInfo =>
      'Failed to start live: the live info contains sensitive content, please edit and retry';

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
  String get liveSummaryTitle => 'Live stream ended';

  @override
  String get liveSummaryDuration => 'Live duration';

  @override
  String get liveSummaryGiftsSent => 'Gifts received';

  @override
  String get liveSummaryViewers => 'Viewers';

  @override
  String get liveSummaryMessages => 'Comments';

  @override
  String get liveSummaryLikes => 'Likes';

  @override
  String get liveSummaryGiftSenders => 'Gift senders';

  @override
  String get liveSummaryGiftIncome => 'Gift value';

  @override
  String get liveSummaryUnitPiece => 'items';

  @override
  String get liveSummaryUnitCoin => 'coins';

  @override
  String get liveSummaryUnitPerson => 'people';

  @override
  String get liveSummaryUnitMessage => 'msgs';

  @override
  String get liveSummaryUnitTime => 'times';

  @override
  String get liveSummaryDone => 'Done';
}
