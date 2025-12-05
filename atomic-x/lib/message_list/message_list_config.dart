import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

abstract class MessageListConfigProtocol {
  double get textBubbleCornerRadius;
  String get alignment;
  bool get isShowTimeMessage;
  bool get isShowLeftAvatar;
  bool get isShowLeftNickname;
  bool get isShowRightAvatar;
  bool get isShowRightNickname;
  bool get isShowTimeInBubble;
  double get cellSpacing;
  bool get isShowSystemMessage;
  bool get isShowUnsupportMessage;
  double get horizontalPadding;
  double get avatarSpacing;
  bool get isSupportCopy;
  bool get isSupportDelete;
  bool get isSupportRecall;
}

class ChatMessageListConfig implements MessageListConfigProtocol {
  final double? _userTextBubbleCornerRadius;
  final String? _userAlignment;
  final bool? _userIsShowTimeMessage;
  final bool? _userIsShowLeftAvatar;
  final bool? _userIsShowLeftNickname;
  final bool? _userIsShowRightAvatar;
  final bool? _userIsShowRightNickname;
  final bool? _userIsShowTimeInBubble;
  final double? _userCellSpacing;
  final bool? _userIsShowSystemMessage;
  final bool? _userIsShowUnsupportMessage;
  final bool? _userIsSupportCopy;
  final bool? _userIsSupportDelete;
  final bool? _userIsSupportRecall;
  final double? _userHorizontalPadding;
  final double? _userAvatarSpacing;

  @override
  double get textBubbleCornerRadius => _userTextBubbleCornerRadius ?? 18.0;

  @override
  String get alignment {
    if (_userAlignment != null) {
      return _userAlignment;
    } else {
      final config = AppBuilder.getInstance();
      return config.messageListConfig.alignment;
    }
  }

  @override
  bool get isShowTimeMessage => _userIsShowTimeMessage ?? true;

  @override
  bool get isShowLeftAvatar => _userIsShowLeftAvatar ?? true;

  @override
  bool get isShowLeftNickname => _userIsShowLeftNickname ?? false;

  @override
  bool get isShowRightAvatar => _userIsShowRightAvatar ?? false;

  @override
  bool get isShowRightNickname => _userIsShowRightNickname ?? false;

  @override
  bool get isShowTimeInBubble => _userIsShowTimeInBubble ?? true;

  @override
  double get cellSpacing => _userCellSpacing ?? 0;

  @override
  bool get isShowSystemMessage => _userIsShowSystemMessage ?? true;

  @override
  bool get isShowUnsupportMessage => _userIsShowUnsupportMessage ?? true;

  @override
  bool get isSupportCopy {
    if (_userIsSupportCopy != null) {
      return _userIsSupportCopy;
    } else {
      final config = AppBuilder.getInstance();
      return config.messageListConfig.messageActionList.contains(AppBuilder.MESSAGE_ACTION_COPY);
    }
  }

  @override
  bool get isSupportDelete {
    if (_userIsSupportDelete != null) {
      return _userIsSupportDelete;
    } else {
      final config = AppBuilder.getInstance();
      return config.messageListConfig.messageActionList.contains(AppBuilder.MESSAGE_ACTION_DELETE);
    }
  }

  @override
  bool get isSupportRecall {
    if (_userIsSupportRecall != null) {
      return _userIsSupportRecall;
    } else {
      final config = AppBuilder.getInstance();
      return config.messageListConfig.messageActionList.contains(AppBuilder.MESSAGE_ACTION_RECALL);
    }
  }

  @override
  double get horizontalPadding => _userHorizontalPadding ?? 16.0;

  @override
  double get avatarSpacing => _userAvatarSpacing ?? 8.0;

  const ChatMessageListConfig({
    double? textBubbleCornerRadius,
    String? alignment,
    bool? isShowTimeMessage,
    bool? isShowLeftAvatar,
    bool? isShowLeftNickname,
    bool? isShowRightAvatar,
    bool? isShowRightNickname,
    bool? isShowTimeInBubble,
    double? cellSpacing,
    bool? isShowSystemMessage,
    bool? isShowUnsupportMessage,
    bool? isSupportCopy,
    bool? isSupportDelete,
    bool? isSupportRecall,
    double? horizontalPadding,
    double? avatarSpacing,
  })  : _userTextBubbleCornerRadius = textBubbleCornerRadius,
        _userAlignment = alignment,
        _userIsShowTimeMessage = isShowTimeMessage,
        _userIsShowLeftAvatar = isShowLeftAvatar,
        _userIsShowLeftNickname = isShowLeftNickname,
        _userIsShowRightAvatar = isShowRightAvatar,
        _userIsShowRightNickname = isShowRightNickname,
        _userIsShowTimeInBubble = isShowTimeInBubble,
        _userCellSpacing = cellSpacing,
        _userIsShowSystemMessage = isShowSystemMessage,
        _userIsShowUnsupportMessage = isShowUnsupportMessage,
        _userIsSupportCopy = isSupportCopy,
        _userIsSupportDelete = isSupportDelete,
        _userIsSupportRecall = isSupportRecall,
        _userHorizontalPadding = horizontalPadding,
        _userAvatarSpacing = avatarSpacing;
}
