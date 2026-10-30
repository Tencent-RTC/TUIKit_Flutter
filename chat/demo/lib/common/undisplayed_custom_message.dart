import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

/// Prints custom payloads that the Demo cannot render as a dedicated bubble.
class UndisplayedCustomMessageLogger {
  UndisplayedCustomMessageLogger._();

  static const String typingBusinessID = 'user_typing_status';

  static final Set<String> _logged = <String>{};

  static void register() {
    CustomMessageFallbackRegistry.handler = log;
    MessageSummaryRegistry.register(typingBusinessID, (context, message) => '');
  }

  /// Web Chat UIKit sends these as online-only custom pings. Flutter Demo has
  /// no typing indicator yet, so they must not appear as empty custom bubbles.
  static bool isTypingStatusMessage(MessageInfo message) {
    if (message.messageType != MessageType.custom) return false;
    final payload = message.messagePayload as CustomMessagePayload?;
    if (payload == null) return false;
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(payload.customData);
      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    if (data?['businessID']?.toString() == typingBusinessID) return true;
    final action = data?['actionParam']?.toString() ?? '';
    return action == 'EIMAMSG_InputStatus_Ing' ||
        action == 'EIMAMSG_InputStatus_End';
  }

  /// Layers the AI control-signal and typing-status filters onto [base].
  static ChatMessageListConfig decorate(ChatMessageListConfig base) {
    return base.copyWith(
      shouldHideMessage: (message) {
        final hidden = base.shouldHideMessage?.call(message) == true ||
            isTypingStatusMessage(message) ||
            AIAssistantControlMessages.isControlMessage(message);
        if (hidden) {
          logIfCustom(message);
        }
        return hidden;
      },
    );
  }

  /// Hidden messages never reach the fallback bubble, so [shouldHideMessage]
  /// must call this or they would not be printed.
  static void logIfCustom(MessageInfo message) {
    if (message.messageType != MessageType.custom) return;
    log(message);
  }

  static void log(MessageInfo message) {
    final payload = message.messagePayload as CustomMessagePayload?;
    final id = message.msgID.isNotEmpty
        ? message.msgID
        : '${message.from.userID}-${message.timestamp}-${payload?.customData}';
    if (!_logged.add(id)) {
      return;
    }
    debugPrint(
      '[Demo] undisplayed custom message '
      'msgID=${message.msgID} '
      'from=${message.from.userID} '
      'description=${payload?.description} '
      'extensionInfo=${payload?.extensionInfo} '
      'customData=${payload?.customData}',
    );
  }
}
