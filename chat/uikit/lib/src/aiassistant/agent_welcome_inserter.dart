import 'package:flutter/foundation.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import 'ai_assistant_agent.dart';
import 'ai_assistant_control_messages.dart';

/// While the conversation is still empty, inserts the directory's welcome text
/// as a local message that looks like it came from the robot but is never sent.
///
/// `welcome` is not an IM message the server has sent. It is only added on
/// first use or after the user cleared the history: any history message means
/// the conversation has been used. Robot control signals (login activation
/// ping, voice call enter/leave) are never shown, so they do not count.
class AgentWelcomeInserter {
  AgentWelcomeInserter._();

  static final Map<String, Future<void>> _inFlight = {};

  static Future<void> insertIfConversationEmpty(AIAssistantAgent agent) async {
    final conversationID = agent.conversationID;
    final existing = _inFlight[conversationID];
    if (existing != null) {
      return existing;
    }
    late final Future<void> operation;
    operation = _insertIfConversationEmpty(agent).whenComplete(() {
      if (identical(_inFlight[conversationID], operation)) {
        _inFlight.remove(conversationID);
      }
    });
    _inFlight[conversationID] = operation;
    return operation;
  }

  static Future<void> _insertIfConversationEmpty(AIAssistantAgent agent) async {
    final welcome = agent.welcome;
    if (welcome.isEmpty) return;
    try {
      final store =
          MessageListStore.create(conversationID: agent.conversationID);
      final result = await store.loadMessages();
      // Without history there is no telling whether the conversation was used,
      // and a duplicate welcome would stay forever; skipping it only hides it
      // this once.
      if (!result.isSuccess) {
        debugPrint(
            'AgentWelcome: load history failed, skip welcome: ${result.errorCode} ${result.errorMessage}');
        return;
      }
      final hasHistory = store.state.messageList.value
          .any((m) => !AIAssistantControlMessages.isControlMessage(m));
      if (hasHistory) return;

      // TODO: Restore the local welcome message after the current
      // AtomicXCore exposes MessageInputStore.insertLocalMessage.
      // await MessageInputStore.create(conversationID: agent.conversationID)
      //     .insertLocalMessage(
      //   payload: TextSendMessagePayload(text: welcome),
      //   sender: agent.imUserId,
      // );
    } catch (e) {
      debugPrint('AgentWelcome: insert welcome failed: $e');
    }
  }
}
