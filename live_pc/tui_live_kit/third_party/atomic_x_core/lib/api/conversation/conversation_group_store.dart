import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/impl/conversation/conversation_group_store_impl.dart';
import 'package:flutter/foundation.dart';

abstract class ConversationGroupState {
  ValueListenable<List<String>> get groupList;
}

abstract class ConversationGroupStore {
  static ConversationGroupStore get shared => ConversationGroupStoreImpl.shared;

  ConversationGroupState get state;

  Future<CompletionHandler> loadGroups();

  Future<CompletionHandler> createGroup({
    required String groupName,
    required List<String> conversationIDList,
  });

  Future<CompletionHandler> deleteGroup({required String groupName});

  Future<CompletionHandler> renameGroup({
    required String oldName,
    required String newName,
  });

  Future<CompletionHandler> addConversationsToGroup({
    required String groupName,
    required List<String> conversationIDList,
  });

  Future<CompletionHandler> deleteConversationsFromGroup({
    required String groupName,
    required List<String> conversationIDList,
  });
}
