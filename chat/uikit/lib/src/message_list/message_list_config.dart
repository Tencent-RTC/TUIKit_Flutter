import 'package:atomic_x_core/atomicxcore.dart' show MessageInfo;
import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

import 'widgets/message_types/custom_message_renderer.dart';

typedef MessageListHidePredicate = bool Function(MessageInfo message);

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
  bool get enableReadReceipt;
  bool get isSupportForward;
  bool get isSupportMultiSelect;
  bool get isSupportReaction;
  bool get isSupportTranslate;
  bool get isSupportTongue;
  bool get isSupportQuote;

  /// Host-supplied renderers for custom messages, keyed by `businessID` and
  /// consulted before the built-in custom message handling.
  Map<String, CustomMessageBuilder> get customMessageBuilders;

  /// When this returns true the message is omitted from the list (no row, no
  /// avatar). Use it for demo control pings that must not appear as empty
  /// custom bubbles.
  MessageListHidePredicate? get shouldHideMessage;

  /// In chatbot conversations, whether a text message the user just sent shows
  /// the "typing" placeholder until the bot replies. Turn it off when a human
  /// agent may answer instead, otherwise the placeholder waits until timeout.
  bool get enableChatbotReplyPlaceholder;
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
  final bool? _userEnableReadReceipt;
  final bool _isSupportForward;
  final bool _isSupportMultiSelect;
  final bool _isSupportReaction;
  final bool _isSupportTranslate;
  final bool _isSupportTongue;
  final bool _isSupportQuote;
  final Map<String, CustomMessageBuilder> _customMessageBuilders;
  final MessageListHidePredicate? _shouldHideMessage;
  final bool _enableChatbotReplyPlaceholder;

  @override
  double get textBubbleCornerRadius => _userTextBubbleCornerRadius ?? 10.0;

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
  bool get isShowRightAvatar => _userIsShowRightAvatar ?? true;

  @override
  bool get isShowRightNickname => _userIsShowRightNickname ?? false;

  @override
  bool get isShowTimeInBubble => _userIsShowTimeInBubble ?? false;

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

  @override
  bool get enableReadReceipt {
    if (_userEnableReadReceipt != null) {
      return _userEnableReadReceipt;
    } else {
      return AppBuilder.getInstance().messageListConfig.enableReadReceipt;
    }
  }

  @override
  bool get isSupportForward => _isSupportForward;

  @override
  bool get isSupportMultiSelect => _isSupportMultiSelect;

  @override
  bool get isSupportReaction => _isSupportReaction;

  @override
  bool get isSupportTranslate => _isSupportTranslate;

  @override
  bool get isSupportTongue => _isSupportTongue;

  @override
  bool get isSupportQuote => _isSupportQuote;

  @override
  Map<String, CustomMessageBuilder> get customMessageBuilders => _customMessageBuilders;

  @override
  MessageListHidePredicate? get shouldHideMessage => _shouldHideMessage;

  @override
  bool get enableChatbotReplyPlaceholder => _enableChatbotReplyPlaceholder;

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
    bool? enableReadReceipt,
    bool isSupportForward = true,
    bool isSupportMultiSelect = true,
    bool isSupportReaction = true,
    bool isSupportTranslate = true,
    bool isSupportTongue = true,
    bool isSupportQuote = true,
    Map<String, CustomMessageBuilder> customMessageBuilders = const {},
    MessageListHidePredicate? shouldHideMessage,
    bool enableChatbotReplyPlaceholder = true,
  })  : _customMessageBuilders = customMessageBuilders,
        _shouldHideMessage = shouldHideMessage,
        _enableChatbotReplyPlaceholder = enableChatbotReplyPlaceholder,
        _userTextBubbleCornerRadius = textBubbleCornerRadius,
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
        _userAvatarSpacing = avatarSpacing,
        _userEnableReadReceipt = enableReadReceipt,
        _isSupportForward = isSupportForward,
        _isSupportMultiSelect = isSupportMultiSelect,
        _isSupportReaction = isSupportReaction,
        _isSupportTranslate = isSupportTranslate,
        _isSupportTongue = isSupportTongue,
        _isSupportQuote = isSupportQuote;

  /// Fields left unset here keep this config's value, including "unset", so
  /// AppBuilder defaults still apply to them.
  ChatMessageListConfig copyWith({
    bool? isShowLeftAvatar,
    bool? isShowRightAvatar,
    bool? isSupportMultiSelect,
    Map<String, CustomMessageBuilder>? customMessageBuilders,
    MessageListHidePredicate? shouldHideMessage,
    bool? enableChatbotReplyPlaceholder,
  }) {
    return ChatMessageListConfig(
      textBubbleCornerRadius: _userTextBubbleCornerRadius,
      alignment: _userAlignment,
      isShowTimeMessage: _userIsShowTimeMessage,
      isShowLeftAvatar: isShowLeftAvatar ?? _userIsShowLeftAvatar,
      isShowLeftNickname: _userIsShowLeftNickname,
      isShowRightAvatar: isShowRightAvatar ?? _userIsShowRightAvatar,
      isShowRightNickname: _userIsShowRightNickname,
      isShowTimeInBubble: _userIsShowTimeInBubble,
      cellSpacing: _userCellSpacing,
      isShowSystemMessage: _userIsShowSystemMessage,
      isShowUnsupportMessage: _userIsShowUnsupportMessage,
      isSupportCopy: _userIsSupportCopy,
      isSupportDelete: _userIsSupportDelete,
      isSupportRecall: _userIsSupportRecall,
      horizontalPadding: _userHorizontalPadding,
      avatarSpacing: _userAvatarSpacing,
      enableReadReceipt: _userEnableReadReceipt,
      isSupportForward: _isSupportForward,
      isSupportMultiSelect: isSupportMultiSelect ?? _isSupportMultiSelect,
      isSupportReaction: _isSupportReaction,
      isSupportTranslate: _isSupportTranslate,
      isSupportTongue: _isSupportTongue,
      isSupportQuote: _isSupportQuote,
      customMessageBuilders: customMessageBuilders ?? _customMessageBuilders,
      shouldHideMessage: shouldHideMessage ?? _shouldHideMessage,
      enableChatbotReplyPlaceholder: enableChatbotReplyPlaceholder ?? _enableChatbotReplyPlaceholder,
    );
  }
}
