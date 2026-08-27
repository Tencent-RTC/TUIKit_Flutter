import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

import 'message_input_more_action.dart';

abstract class MessageInputConfigProtocol {
  bool get isShowAudioRecorder;
  bool get isShowMore;
  bool get enableReadReceipt;
  bool get enableMention;
  bool get enableVoiceToTextOnRecord;

  /// More panel items (order matches the more panel UI)
  bool get isShowAlbum;
  bool get isShowPhotoTaker;
  bool get isShowVideoRecorder;
  bool get isShowFile;
  bool get isShowVideoCall;
  bool get isShowAudioCall;

  /// Host-supplied entries appended after the built-in more panel items.
  List<MessageInputMoreAction> get customMoreActions;
}

class ChatMessageInputConfig implements MessageInputConfigProtocol {
  final bool? _userIsShowAudioRecorder;
  final bool? _userIsShowMore;
  final bool? _userEnableReadReceipt;
  final bool? _userEnableMention;
  final bool? _userEnableVoiceToTextOnRecord;
  final bool? _userIsShowAlbum;
  final bool? _userIsShowPhotoTaker;
  final bool? _userIsShowVideoRecorder;
  final bool? _userIsShowFile;
  final bool? _userIsShowVideoCall;
  final bool? _userIsShowAudioCall;
  final List<MessageInputMoreAction> _customMoreActions;

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

  const ChatMessageInputConfig({
    bool? isShowAudioRecorder,
    bool? isShowMore,
    bool? enableReadReceipt,
    bool? enableMention,
    bool? enableVoiceToTextOnRecord,
    bool? isShowAlbum,
    bool? isShowPhotoTaker,
    bool? isShowVideoRecorder,
    bool? isShowFile,
    bool? isShowVideoCall,
    bool? isShowAudioCall,
    List<MessageInputMoreAction> customMoreActions = const [],
  })  : _customMoreActions = customMoreActions,
        _userIsShowAudioRecorder = isShowAudioRecorder,
        _userIsShowMore = isShowMore,
        _userEnableReadReceipt = enableReadReceipt,
        _userEnableMention = enableMention,
        _userEnableVoiceToTextOnRecord = enableVoiceToTextOnRecord,
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
    bool? isShowAlbum,
    bool? isShowPhotoTaker,
    bool? isShowVideoRecorder,
    bool? isShowFile,
    bool? isShowVideoCall,
    bool? isShowAudioCall,
    List<MessageInputMoreAction>? customMoreActions,
  }) {
    return ChatMessageInputConfig(
      isShowAudioRecorder: isShowAudioRecorder ?? _userIsShowAudioRecorder,
      isShowMore: isShowMore ?? _userIsShowMore,
      enableReadReceipt: enableReadReceipt ?? _userEnableReadReceipt,
      enableMention: enableMention ?? _userEnableMention,
      enableVoiceToTextOnRecord: enableVoiceToTextOnRecord ?? _userEnableVoiceToTextOnRecord,
      isShowAlbum: isShowAlbum ?? _userIsShowAlbum,
      isShowPhotoTaker: isShowPhotoTaker ?? _userIsShowPhotoTaker,
      isShowVideoRecorder: isShowVideoRecorder ?? _userIsShowVideoRecorder,
      isShowFile: isShowFile ?? _userIsShowFile,
      isShowVideoCall: isShowVideoCall ?? _userIsShowVideoCall,
      isShowAudioCall: isShowAudioCall ?? _userIsShowAudioCall,
      customMoreActions: customMoreActions ?? _customMoreActions,
    );
  }
}
