import 'dart:convert';

import 'package:tuikit_atomic_x/atomicx.dart';

/// Online-only control messages used by the AI assistant voice session.
class AIAssistantControlMessages {
  AIAssistantControlMessages._();

  static const String voiceEnterAction = 'enterVoiceCall';
  static const String voiceLeaveAction = 'leaveVoiceCall';
  static const String voiceSessionDescription = 'voice call session';

  static const Set<String> _actions = {
    voiceEnterAction,
    voiceLeaveAction,
  };
  static const String _typingBusinessID = 'user_typing_status';
  static const Set<String> _typingActions = {
    'EIMAMSG_InputStatus_Ing',
    'EIMAMSG_InputStatus_End',
  };

  static Future<CompletionHandler> sendVoiceSessionSignal({
    required String robotUserID,
    required String action,
  }) {
    return MessageInputStore.create(conversationID: 'c2c_$robotUserID')
        .sendMessage(
      payload: CustomSendMessagePayload(
        customData: jsonEncode({'action': action}),
        description: voiceSessionDescription,
      ),
      option: SendMessageOption(onlineUserOnly: true),
    );
  }

  static bool isControlMessage(MessageInfo message) {
    if (message.messageType != MessageType.custom) return false;
    final payload = message.messagePayload as CustomMessagePayload?;
    if (payload == null) return false;
    if ((payload.description?.trim() ?? '') == voiceSessionDescription) {
      return true;
    }
    try {
      final decoded = jsonDecode(payload.customData);
      return decoded is Map && _actions.contains(decoded['action']?.toString());
    } catch (_) {
      return false;
    }
  }

  /// Messages that belong to assistant protocol state rather than chat
  /// content and therefore must not render as custom-message bubbles.
  static bool shouldHideMessage(MessageInfo message) {
    if (isControlMessage(message)) return true;
    if (message.messageType != MessageType.custom) return false;
    final payload = message.messagePayload as CustomMessagePayload?;
    if (payload == null) return false;
    try {
      final decoded = jsonDecode(payload.customData);
      if (decoded is! Map) return false;
      if (decoded['businessID']?.toString() == _typingBusinessID) return true;
      return _typingActions.contains(decoded['actionParam']?.toString());
    } catch (_) {
      return false;
    }
  }
}
