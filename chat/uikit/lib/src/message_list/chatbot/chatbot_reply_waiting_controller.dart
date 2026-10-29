import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

/// 机器人会话里，用户发出消息后到机器人第一段可见回复之间，在列表底部显示一个
/// 「对方正在输入」的占位。对齐 Android 的 ChatbotConversationController。
class ChatbotReplyWaitingController extends ChangeNotifier {
  ChatbotReplyWaitingController({
    required String conversationID,
    bool Function(MessageInfo)? shouldHideMessage,
  })  : _enabled = isChatbotConversation(conversationID),
        _shouldHideMessage = shouldHideMessage;

  /// 机器人没回复也不能一直转圈，超时后收起占位。
  static const Duration replyTimeout = Duration(milliseconds: 15000);

  /// 新出现、且已经是发送成功状态的消息，只有在这个时间窗内才算「刚发出」，
  /// 否则是拉历史 / 多端同步带回来的旧消息。
  static const int _recentSendWindowSeconds = 10;

  static const String _chatbotUserIDPrefix = '@RBT#';
  static const String _c2cPrefix = 'c2c_';
  static const String _groupPrefix = 'group_';

  /// 会话 ID 去掉 `c2c_` / `group_` 前缀后以 `@RBT#` 开头即为机器人会话。
  static bool isChatbotConversation(String conversationID) {
    var id = conversationID;
    if (id.startsWith(_c2cPrefix)) {
      id = id.substring(_c2cPrefix.length);
    } else if (id.startsWith(_groupPrefix)) {
      id = id.substring(_groupPrefix.length);
    }
    return id.startsWith(_chatbotUserIDPrefix);
  }

  final bool _enabled;
  bool Function(MessageInfo)? _shouldHideMessage;

  bool _initialized = false;
  final Map<String, MessageStatus> _knownStatuses = {};
  Set<String> _baselineIDs = const {};
  Timer? _timeout;
  bool _waiting = false;

  /// 是否正在等机器人回复。
  bool get isWaiting => _waiting;

  set shouldHideMessage(bool Function(MessageInfo)? value) => _shouldHideMessage = value;

  /// 每次消息列表变化时调用，传入按时间正序的完整列表。
  void onMessagesChanged(List<MessageInfo> chronological) {
    if (!_enabled) return;
    if (!_initialized) {
      // 首屏拉到的是历史，不能把最后一条自己发的消息当成刚发出
      _initialized = true;
      _rememberStatuses(chronological);
      return;
    }

    if (_waiting && _hasNewVisibleReply(chronological)) {
      _stopWaiting();
    }
    if (_hasJustSentMessage(chronological)) {
      _startWaiting(chronological);
    }
    _rememberStatuses(chronological);
  }

  bool _hasJustSentMessage(List<MessageInfo> messages) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final message in messages) {
      if (!message.isSentBySelf || message.messageType != MessageType.text) continue;
      if (message.status != MessageStatus.sendSuccess) continue;
      final previous = _knownStatuses[message.msgID];
      if (previous == null) {
        final timestamp = message.timestamp ?? 0;
        if ((nowSeconds - timestamp).abs() <= _recentSendWindowSeconds) return true;
      } else if (previous == MessageStatus.sending || previous == MessageStatus.init) {
        return true;
      }
    }
    return false;
  }

  bool _hasNewVisibleReply(List<MessageInfo> messages) {
    for (final message in messages) {
      if (message.isSentBySelf || _baselineIDs.contains(message.msgID)) continue;
      if (_isVisibleReply(message)) return true;
    }
    return false;
  }

  bool _isVisibleReply(MessageInfo message) {
    if (message.messageType == MessageType.tips) return false;
    final hide = _shouldHideMessage;
    if (hide != null && hide(message)) return false;
    if (message.messageType == MessageType.stream) {
      final payload = message.messagePayload;
      // 流式消息先落一条空壳，第一段文字到了才算真正回复
      return payload is StreamMessagePayload && payload.markdown.isNotEmpty;
    }
    return true;
  }

  void _startWaiting(List<MessageInfo> messages) {
    _baselineIDs = messages.map((message) => message.msgID).toSet();
    _timeout?.cancel();
    _timeout = Timer(replyTimeout, _stopWaiting);
    if (!_waiting) {
      _waiting = true;
      notifyListeners();
    }
  }

  void _stopWaiting() {
    _timeout?.cancel();
    _timeout = null;
    if (_waiting) {
      _waiting = false;
      notifyListeners();
    }
  }

  void _rememberStatuses(List<MessageInfo> messages) {
    _knownStatuses
      ..clear()
      ..addEntries(messages.map((message) => MapEntry(message.msgID, message.status)));
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _timeout = null;
    super.dispose();
  }
}
