import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

import 'message_input_more_action.dart';

abstract class MessageInputConfigProtocol {
  bool get isShowAudioRecorder;
  bool get isShowMore;
  bool get enableReadReceipt;
  bool get enableMention;
  bool get enableVoiceToTextOnRecord;

  /// 长按录音滑到「转文字」时是否边说边出字。
  ///
  /// 设备不支持实时采集（非 Android 10+ / iOS）时自动退回「松手后上传整段音频再识别」，
  /// 见 `lib/src/message_input/asr/realtime_asr.dart`。
  bool get enableRealtimeVoiceToText;

  /// 长按录音松手是否发送原语音，以及转文字草稿里是否保留「发送原语音」。
  ///
  /// 关掉后只剩取消和转文字：松手不在「转文字」上一律按取消处理，提示改为「滑到转文字」。
  /// 机器人还不识别语音消息时关掉，普通会话默认开着。
  bool get enableSendRecordedVoice;

  /// More panel items (order matches the more panel UI)
  bool get isShowAlbum;
  bool get isShowPhotoTaker;
  bool get isShowVideoRecorder;
  bool get isShowFile;
  bool get isShowVideoCall;
  bool get isShowAudioCall;

  /// Host-supplied entries appended after the built-in more panel items.
  List<MessageInputMoreAction> get customMoreActions;

  /// Asked on every build whether a more panel entry still deserves a red dot,
  /// identified by [MessageInputActionIDs] for the built-in ones or by a custom
  /// action's own id. The plus button mirrors the dot while any entry is still
  /// unread, and both dots clear as soon as the entry is tapped.
  ///
  /// This is a callback rather than a fixed set so that a dot consumed during
  /// one visit stays gone on the next, without the host having to rebuild its
  /// config.
  bool Function(String actionID)? get shouldShowMoreActionRedDot;

  /// Called with the entry's id the first time a dotted entry is tapped, so the
  /// host can persist that the dot has been consumed.
  void Function(String actionID)? get onMoreActionRedDotTap;
}

class ChatMessageInputConfig implements MessageInputConfigProtocol {
  final bool? _userIsShowAudioRecorder;
  final bool? _userIsShowMore;
  final bool? _userEnableReadReceipt;
  final bool? _userEnableMention;
  final bool? _userEnableVoiceToTextOnRecord;
  final bool? _userEnableRealtimeVoiceToText;
  final bool? _userEnableSendRecordedVoice;
  final bool? _userIsShowAlbum;
  final bool? _userIsShowPhotoTaker;
  final bool? _userIsShowVideoRecorder;
  final bool? _userIsShowFile;
  final bool? _userIsShowVideoCall;
  final bool? _userIsShowAudioCall;
  final List<MessageInputMoreAction> _customMoreActions;
  final bool Function(String actionID)? _shouldShowMoreActionRedDot;
  final void Function(String actionID)? _onMoreActionRedDotTap;

  @override
  bool get isShowAudioRecorder => _userIsShowAudioRecorder ?? true;

  @override
  bool get isShowMore => _userIsShowMore ?? true;

  @override
  bool get enableReadReceipt {
    if (_userEnableReadReceipt != null) {
      return _userEnableReadReceipt;
    } else {
      return AppBuilder.getInstance().messageListConfig.enableReadReceipt;
    }
  }

  @override
  bool get enableMention => _userEnableMention ?? true;

  @override
  bool get enableVoiceToTextOnRecord => _userEnableVoiceToTextOnRecord ?? true;

  @override
  bool get enableRealtimeVoiceToText => _userEnableRealtimeVoiceToText ?? true;

  @override
  bool get enableSendRecordedVoice => _userEnableSendRecordedVoice ?? true;

  @override
  bool get isShowAlbum => _userIsShowAlbum ?? true;

  @override
  bool get isShowPhotoTaker => _userIsShowPhotoTaker ?? true;

  @override
  bool get isShowVideoRecorder => _userIsShowVideoRecorder ?? true;

  @override
  bool get isShowFile => _userIsShowFile ?? true;

  @override
  bool get isShowVideoCall => _userIsShowVideoCall ?? true;

  @override
  bool get isShowAudioCall => _userIsShowAudioCall ?? true;

  @override
  List<MessageInputMoreAction> get customMoreActions => _customMoreActions;

  @override
  bool Function(String actionID)? get shouldShowMoreActionRedDot => _shouldShowMoreActionRedDot;

  @override
  void Function(String actionID)? get onMoreActionRedDotTap => _onMoreActionRedDotTap;

  const ChatMessageInputConfig({
    bool? isShowAudioRecorder,
    bool? isShowMore,
    bool? enableReadReceipt,
    bool? enableMention,
    bool? enableVoiceToTextOnRecord,
    bool? enableRealtimeVoiceToText,
    bool? enableSendRecordedVoice,
    bool? isShowAlbum,
    bool? isShowPhotoTaker,
    bool? isShowVideoRecorder,
    bool? isShowFile,
    bool? isShowVideoCall,
    bool? isShowAudioCall,
    List<MessageInputMoreAction> customMoreActions = const [],
    bool Function(String actionID)? shouldShowMoreActionRedDot,
    void Function(String actionID)? onMoreActionRedDotTap,
  })  : _customMoreActions = customMoreActions,
        _shouldShowMoreActionRedDot = shouldShowMoreActionRedDot,
        _onMoreActionRedDotTap = onMoreActionRedDotTap,
        _userIsShowAudioRecorder = isShowAudioRecorder,
        _userIsShowMore = isShowMore,
        _userEnableReadReceipt = enableReadReceipt,
        _userEnableMention = enableMention,
        _userEnableVoiceToTextOnRecord = enableVoiceToTextOnRecord,
        _userEnableRealtimeVoiceToText = enableRealtimeVoiceToText,
        _userEnableSendRecordedVoice = enableSendRecordedVoice,
        _userIsShowAlbum = isShowAlbum,
        _userIsShowPhotoTaker = isShowPhotoTaker,
        _userIsShowVideoRecorder = isShowVideoRecorder,
        _userIsShowFile = isShowFile,
        _userIsShowVideoCall = isShowVideoCall,
        _userIsShowAudioCall = isShowAudioCall;

  /// Returns a copy with the given values replaced. Arguments left null keep the
  /// current setting — including "never set", so those fields still fall back to
  /// their defaults when read.
  ChatMessageInputConfig copyWith({
    bool? isShowAudioRecorder,
    bool? isShowMore,
    bool? enableReadReceipt,
    bool? enableMention,
    bool? enableVoiceToTextOnRecord,
    bool? enableRealtimeVoiceToText,
    bool? enableSendRecordedVoice,
    bool? isShowAlbum,
    bool? isShowPhotoTaker,
    bool? isShowVideoRecorder,
    bool? isShowFile,
    bool? isShowVideoCall,
    bool? isShowAudioCall,
    List<MessageInputMoreAction>? customMoreActions,
    bool Function(String actionID)? shouldShowMoreActionRedDot,
    void Function(String actionID)? onMoreActionRedDotTap,
  }) {
    return ChatMessageInputConfig(
      isShowAudioRecorder: isShowAudioRecorder ?? _userIsShowAudioRecorder,
      isShowMore: isShowMore ?? _userIsShowMore,
      enableReadReceipt: enableReadReceipt ?? _userEnableReadReceipt,
      enableMention: enableMention ?? _userEnableMention,
      enableVoiceToTextOnRecord: enableVoiceToTextOnRecord ?? _userEnableVoiceToTextOnRecord,
      enableRealtimeVoiceToText: enableRealtimeVoiceToText ?? _userEnableRealtimeVoiceToText,
      enableSendRecordedVoice: enableSendRecordedVoice ?? _userEnableSendRecordedVoice,
      isShowAlbum: isShowAlbum ?? _userIsShowAlbum,
      isShowPhotoTaker: isShowPhotoTaker ?? _userIsShowPhotoTaker,
      isShowVideoRecorder: isShowVideoRecorder ?? _userIsShowVideoRecorder,
      isShowFile: isShowFile ?? _userIsShowFile,
      isShowVideoCall: isShowVideoCall ?? _userIsShowVideoCall,
      isShowAudioCall: isShowAudioCall ?? _userIsShowAudioCall,
      customMoreActions: customMoreActions ?? _customMoreActions,
      shouldShowMoreActionRedDot: shouldShowMoreActionRedDot ?? _shouldShowMoreActionRedDot,
      onMoreActionRedDotTap: onMoreActionRedDotTap ?? _onMoreActionRedDotTap,
    );
  }
}
