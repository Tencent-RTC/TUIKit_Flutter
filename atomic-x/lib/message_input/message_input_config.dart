abstract class MessageInputConfigProtocol {
  bool get isShowAudioRecorder;
  bool get isShowPhotoTaker;
  bool get isShowMore;
}

class ChatMessageInputConfig implements MessageInputConfigProtocol {
  final bool? _userIsShowAudioRecorder;
  final bool? _userIsShowPhotoTaker;
  final bool? _userIsShowMore;

  @override
  bool get isShowAudioRecorder => _userIsShowAudioRecorder ?? true;

  @override
  bool get isShowPhotoTaker => _userIsShowPhotoTaker ?? true;

  @override
  bool get isShowMore => _userIsShowMore ?? true;

  const ChatMessageInputConfig({
    bool? isShowAudioRecorder,
    bool? isShowPhotoTaker,
    bool? isShowMore,
  })  : _userIsShowAudioRecorder = isShowAudioRecorder,
        _userIsShowPhotoTaker = isShowPhotoTaker,
        _userIsShowMore = isShowMore;
}
