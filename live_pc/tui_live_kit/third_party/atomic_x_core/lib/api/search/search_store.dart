import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/search/search_store_impl.dart';
import 'package:flutter/foundation.dart';

abstract class SearchState {
  ValueListenable<List<UserProfile>> get userList;

  ValueListenable<int> get userTotalCount;

  ValueListenable<bool> get hasMoreUsers;

  ValueListenable<List<FriendSearchInfo>> get friendList;

  ValueListenable<int> get friendTotalCount;

  ValueListenable<bool> get hasMoreFriends;

  ValueListenable<List<GroupSearchInfo>> get groupList;

  ValueListenable<int> get groupTotalCount;

  ValueListenable<bool> get hasMoreGroups;

  ValueListenable<Map<String, List<GroupMember>>> get groupMemberList;

  ValueListenable<int> get groupMemberTotalCount;

  ValueListenable<bool> get hasMoreGroupMembers;

  ValueListenable<List<MessageSearchResultItem>> get messageResults;

  ValueListenable<int> get messageResultTotalCount;

  ValueListenable<bool> get hasMoreMessageResults;
}

abstract class SearchStore {
  SearchState get state;

  static SearchStore create() {
    return SearchStoreImpl();
  }

  Future<CompletionHandler> search({
    required List<String> keywordList,
    SearchOption? option,
  });

  Future<CompletionHandler> searchMore({required SearchType searchType});
}

class SearchOption {
  KeywordListMatchMode keywordListMatchMode;
  List<SearchType> searchScope;
  int pageSize;
  UserSearchFilter? userFilter;
  GroupMemberSearchFilter? groupMemberFilter;
  MessageSearchFilter? messageFilter;

  SearchOption({
    this.keywordListMatchMode = KeywordListMatchMode.or,
    this.searchScope = const [SearchType.friend, SearchType.message, SearchType.group, SearchType.groupMember],
    this.pageSize = 20,
    this.userFilter,
    this.groupMemberFilter,
    this.messageFilter,
  });
}

enum KeywordListMatchMode {
  or,
  and,
}

enum SearchType {
  friend,
  group,
  groupMember,
  message,
}

class UserSearchFilter {
  Gender gender;
  int minBirthday;
  int? maxBirthday;

  UserSearchFilter({
    this.gender = Gender.unknown,
    this.minBirthday = 0,
    this.maxBirthday,
  });
}

class GroupMemberSearchFilter {
  List<String> groupIDList;

  GroupMemberSearchFilter({
    this.groupIDList = const [],
  });
}

class MessageSearchFilter {
  String? conversationID;
  int searchTimePosition;
  int searchTimePeriod;
  List<String>? senderUserIDList;
  List<MessageType>? messageTypeList;

  MessageSearchFilter({
    this.conversationID,
    this.searchTimePosition = 0,
    this.searchTimePeriod = 0,
    this.senderUserIDList,
    this.messageTypeList,
  });
}

class FriendSearchInfo {
  String userID;
  String? friendRemark;
  int friendAddTime;
  Map<String, dynamic>? friendCustomInfo;
  UserProfile? userInfo;

  FriendSearchInfo({
    required this.userID,
    this.friendRemark,
    this.friendAddTime = 0,
    this.friendCustomInfo,
    this.userInfo,
  });
}

class GroupSearchInfo {
  String groupID;
  GroupType groupType;
  String? groupName;
  int memberCount;
  String? groupAvatarURL;
  String? introduction;
  GroupJoinOption joinGroupApprovalType;
  GroupInviteOption inviteToGroupApprovalType;

  GroupSearchInfo({
    this.groupID = '',
    this.groupType = GroupType.work,
    this.groupName,
    this.memberCount = 0,
    this.groupAvatarURL,
    this.introduction,
    this.joinGroupApprovalType = GroupJoinOption.forbid,
    this.inviteToGroupApprovalType = GroupInviteOption.forbid,
  });
}

class MessageSearchResultItem {
  String conversationID;
  String conversationShowName;
  String? conversationAvatarURL;
  int messageCount;
  List<MessageInfo> messageList;

  MessageSearchResultItem({
    this.conversationID = '',
    this.conversationShowName = '',
    this.conversationAvatarURL,
    this.messageCount = 0,
    this.messageList = const [],
  });
}
