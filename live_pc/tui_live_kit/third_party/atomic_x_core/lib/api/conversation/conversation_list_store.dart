import 'package:meta/meta.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/conversation/conversation_list_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

enum ConversationGroup {
  c2c('_c2c_'),
  group('_group_'),
  hasUnreadCount('_hasUnreadCount_'),
  hasGroupAtInfo('_hasGroupAtInfo_');

  const ConversationGroup(this.value);

  final String value;
}

enum ConversationType {
  unknown,
  c2c,
  group,
}

enum GroupAtType {
  atMe,
  atAll,
  atAllAtMe,
}

class GroupAtInfo {
  final int msgSeq;
  final GroupAtType atType;

  GroupAtInfo({required this.msgSeq, required this.atType});
}

enum ReceiveMessageOption {
  receive,
  notReceive,
  notNotify,
  notNotifyExceptMention,
  notReceiveExceptMention,
}

class ConversationMarkType {
  final int rawValue;

  const ConversationMarkType(this.rawValue);

  static const star = ConversationMarkType(0x1);
  static const unread = ConversationMarkType(0x1 << 1);
  static const fold = ConversationMarkType(0x1 << 2);
  static const hide = ConversationMarkType(0x1 << 3);

  bool get isEmpty => rawValue == 0;

  ConversationMarkType operator |(ConversationMarkType other) {
    return ConversationMarkType(rawValue | other.rawValue);
  }

  bool contains(ConversationMarkType other) {
    return (rawValue & other.rawValue) != 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationMarkType && other.rawValue == rawValue;
  }

  @override
  int get hashCode => rawValue.hashCode;
}

class ConversationInfo {
  final String conversationID;
  final ConversationType? type;
  final GroupType? groupType;
  final String? avatarURL;
  String? title;
  final MessageInfo? lastMessage;
  String? draft;
  int unreadCount;
  bool isPinned;
  ReceiveMessageOption receiveOption;
  List<GroupAtInfo>? groupAtInfoList;
  List<ConversationMarkType> conversationMarkList;
  List<String> conversationGroupList;
  @internal
  final V2TimConversation? rawConversation;

  ConversationInfo({
    required this.conversationID,
    this.type,
    this.groupType,
    this.avatarURL,
    this.title,
    this.lastMessage,
    this.draft,
    this.unreadCount = 0,
    this.isPinned = false,
    this.receiveOption = ReceiveMessageOption.receive,
    this.groupAtInfoList,
    this.conversationMarkList = const [],
    this.conversationGroupList = const [],
    this.rawConversation,
  });
}

class ConversationLoadOption {
  int count;
  ConversationMarkType? markType;

  ConversationLoadOption({
    this.count = 100,
    this.markType,
  });
}

abstract class ConversationListState {
  ValueListenable<List<ConversationInfo>> get conversationList;

  ValueListenable<bool> get hasMoreConversations;

  ValueListenable<int> get totalUnreadCount;
}

class GetConversationInfoCompletionHandler extends CompletionHandler {
  ConversationInfo? conversationInfo;

  GetConversationInfoCompletionHandler({
    this.conversationInfo,
  });
}

abstract class ConversationListStore {
  static ConversationListStore create({String? conversationGroup}) {
    return ConversationListStoreImpl(conversationGroup: conversationGroup);
  }

  ConversationListState get state;

  Future<CompletionHandler> loadConversations({ConversationLoadOption? option});

  Future<CompletionHandler> loadMoreConversations();

  Future<CompletionHandler> markConversation({
    required List<String> conversationIDList,
    required ConversationMarkType markType,
    required bool enable,
  });

  Future<CompletionHandler> deleteConversation({required String conversationID});

  Future<CompletionHandler> pinConversation({required String conversationID, required bool pin});

  Future<CompletionHandler> setReceiveMessageOpt({required String conversationID, required ReceiveMessageOption opt});

  Future<CompletionHandler> setConversationDraft({required String conversationID, String? draft});

  Future<CompletionHandler> clearConversationMessages({required String conversationID});

  Future<CompletionHandler> clearConversationUnreadCount({required String conversationID});

  Future<GetConversationInfoCompletionHandler> getConversationInfo({required String conversationID});
}
