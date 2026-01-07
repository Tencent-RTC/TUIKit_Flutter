import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

abstract class MessageInputConfigProtocol {
  bool get isShowAudioRecorder;
  bool get isShowPhotoTaker;
  bool get isShowMore;
  bool get enableReadReceipt;
  bool get enableMention;
}

class ChatMessageInputConfig implements MessageInputConfigProtocol {
  final bool? _userIsShowAudioRecorder;
  final bool? _userIsShowPhotoTaker;
  final bool? _userIsShowMore;
  final bool? _userEnableReadReceipt;
  final bool? _userEnableMention;

  @override
  bool get isShowAudioRecorder => _userIsShowAudioRecorder ?? true;

  @override
  bool get isShowPhotoTaker => _userIsShowPhotoTaker ?? true;

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

  const ChatMessageInputConfig({
    bool? isShowAudioRecorder,
    bool? isShowPhotoTaker,
    bool? isShowMore,
    bool? enableReadReceipt,
    bool? enableMention,
  })  : _userIsShowAudioRecorder = isShowAudioRecorder,
        _userIsShowPhotoTaker = isShowPhotoTaker,
        _userIsShowMore = isShowMore,
        _userEnableReadReceipt = enableReadReceipt,
        _userEnableMention = enableMention;
}
