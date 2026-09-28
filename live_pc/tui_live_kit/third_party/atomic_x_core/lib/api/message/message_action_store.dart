import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/message/message_action_store_impl.dart';
import 'package:flutter/foundation.dart';

abstract class MessageActionState {
  ValueListenable<List<GroupMember>> get readMemberList;

  ValueListenable<bool> get hasMoreReadMembers;

  ValueListenable<List<GroupMember>> get unreadMemberList;

  ValueListenable<bool> get hasMoreUnreadMembers;

  ValueListenable<List<UserProfile>> get reactionUserList;

  ValueListenable<bool> get hasMoreReactionUsers;
}

abstract class MessageActionStore {
  static MessageActionStore create(MessageInfo message) {
    return MessageActionStoreImpl(message);
  }

  MessageActionState get state;

  Future<CompletionHandler> revoke();

  Future<CompletionHandler> delete();

  Future<CompletionHandler> pin({required bool isPinned});

  Future<CompletionHandler> loadReadMembers({required int count});

  Future<CompletionHandler> loadUnreadMembers({required int count});

  Future<CompletionHandler> loadMoreMembers({required bool isRead});

  Future<CompletionHandler> addReaction({required String reactionID});

  Future<CompletionHandler> removeReaction({required String reactionID});

  Future<CompletionHandler> loadReactionUsers({required String reactionID, required int count});

  Future<CompletionHandler> loadMoreReactionUsers();

  Future<CompletionHandler> setExtensions({required List<MessageExtension> extensions});

  Future<CompletionHandler> deleteExtensions({List<String>? keys});

  Future<CompletionHandler> translateText(
      {required List<String> sourceTextList, String? sourceLanguage, required String targetLanguage});

  Future<CompletionHandler> convertVoiceToText({required String language});

  Future<CompletionHandler> downloadMedia({MediaQuality? quality});

  Future<MergedMessageListCompletionHandler> downloadMergedMessageList();
}

class MergedMessageListCompletionHandler extends CompletionHandler {
  List<MessageInfo> messageList;

  MergedMessageListCompletionHandler({
    this.messageList = const [],
  });
}

enum MediaQuality {
  thumbnail,
  standard,
  original,
}
