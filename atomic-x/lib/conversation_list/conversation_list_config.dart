import 'package:tuikit_atomic_x/base_component/utils/app_builder.dart';

abstract class ConversationActionConfigProtocol {
  bool get isSupportDelete;
  bool get isSupportMute;
  bool get isSupportPin;
  bool get isSupportMarkUnread;
  bool get isSupportClearHistory;
}

class ChatConversationActionConfig implements ConversationActionConfigProtocol {
  final bool? _userIsSupportDelete;
  final bool? _userIsSupportMute;
  final bool? _userIsSupportPin;
  final bool? _userIsSupportMarkUnread;
  final bool? _userIsSupportClearHistory;

  @override
  bool get isSupportDelete {
    if (_userIsSupportDelete != null) {
      return _userIsSupportDelete;
    } else {
      final config = AppBuilder.getInstance();
      return config.conversationListConfig.conversationActionList
          .contains(AppBuilder.CONVERSATION_ACTION_DELETE);
    }
  }

  @override
  bool get isSupportMute {
    if (_userIsSupportMute != null) {
      return _userIsSupportMute;
    } else {
      final config = AppBuilder.getInstance();
      return config.conversationListConfig.conversationActionList
          .contains(AppBuilder.CONVERSATION_ACTION_MUTE);
    }
  }

  @override
  bool get isSupportPin {
    if (_userIsSupportPin != null) {
      return _userIsSupportPin;
    } else {
      final config = AppBuilder.getInstance();
      return config.conversationListConfig.conversationActionList
          .contains(AppBuilder.CONVERSATION_ACTION_PIN);
    }
  }

  @override
  bool get isSupportMarkUnread {
    if (_userIsSupportMarkUnread != null) {
      return _userIsSupportMarkUnread;
    } else {
      final config = AppBuilder.getInstance();
      return config.conversationListConfig.conversationActionList
          .contains(AppBuilder.CONVERSATION_ACTION_MARK_UNREAD);
    }
  }

  @override
  bool get isSupportClearHistory {
    if (_userIsSupportClearHistory != null) {
      return _userIsSupportClearHistory;
    } else {
      final config = AppBuilder.getInstance();
      return config.conversationListConfig.conversationActionList
          .contains(AppBuilder.CONVERSATION_ACTION_CLEAR_HISTORY);
    }
  }

  const ChatConversationActionConfig({
    bool? isSupportDelete,
    bool? isSupportMute,
    bool? isSupportPin,
    bool? isSupportMarkUnread,
    bool? isSupportClearHistory,
  })  : _userIsSupportDelete = isSupportDelete,
        _userIsSupportMute = isSupportMute,
        _userIsSupportPin = isSupportPin,
        _userIsSupportMarkUnread = isSupportMarkUnread,
        _userIsSupportClearHistory = isSupportClearHistory;
}
