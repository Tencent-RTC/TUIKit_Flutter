import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/group/group_store_impl.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_search_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_search_result_item.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

// ======== State implementation ========

class _SearchStateImpl implements SearchState {
  final ValueNotifier<List<UserProfile>> userListValue = ValueNotifier([]);
  final ValueNotifier<int> userTotalCountValue = ValueNotifier(0);
  final ValueNotifier<bool> hasMoreUsersValue = ValueNotifier(true);

  final ValueNotifier<List<FriendSearchInfo>> friendListValue = ValueNotifier([]);
  final ValueNotifier<int> friendTotalCountValue = ValueNotifier(0);
  final ValueNotifier<bool> hasMoreFriendsValue = ValueNotifier(true);

  final ValueNotifier<List<GroupSearchInfo>> groupListValue = ValueNotifier([]);
  final ValueNotifier<int> groupTotalCountValue = ValueNotifier(0);
  final ValueNotifier<bool> hasMoreGroupsValue = ValueNotifier(true);

  final ValueNotifier<Map<String, List<GroupMember>>> groupMemberListValue = ValueNotifier({});
  final ValueNotifier<int> groupMemberTotalCountValue = ValueNotifier(0);
  final ValueNotifier<bool> hasMoreGroupMembersValue = ValueNotifier(true);

  final ValueNotifier<List<MessageSearchResultItem>> messageResultsValue = ValueNotifier([]);
  final ValueNotifier<int> messageResultTotalCountValue = ValueNotifier(0);
  final ValueNotifier<bool> hasMoreMessageResultsValue = ValueNotifier(true);

  @override
  ValueListenable<List<UserProfile>> get userList => userListValue;
  @override
  ValueListenable<int> get userTotalCount => userTotalCountValue;
  @override
  ValueListenable<bool> get hasMoreUsers => hasMoreUsersValue;

  @override
  ValueListenable<List<FriendSearchInfo>> get friendList => friendListValue;
  @override
  ValueListenable<int> get friendTotalCount => friendTotalCountValue;
  @override
  ValueListenable<bool> get hasMoreFriends => hasMoreFriendsValue;

  @override
  ValueListenable<List<GroupSearchInfo>> get groupList => groupListValue;
  @override
  ValueListenable<int> get groupTotalCount => groupTotalCountValue;
  @override
  ValueListenable<bool> get hasMoreGroups => hasMoreGroupsValue;

  @override
  ValueListenable<Map<String, List<GroupMember>>> get groupMemberList => groupMemberListValue;
  @override
  ValueListenable<int> get groupMemberTotalCount => groupMemberTotalCountValue;
  @override
  ValueListenable<bool> get hasMoreGroupMembers => hasMoreGroupMembersValue;

  @override
  ValueListenable<List<MessageSearchResultItem>> get messageResults => messageResultsValue;
  @override
  ValueListenable<int> get messageResultTotalCount => messageResultTotalCountValue;
  @override
  ValueListenable<bool> get hasMoreMessageResults => hasMoreMessageResultsValue;
}

// ======== Store implementation ========

class SearchStoreImpl extends SearchStore {
  final _state = _SearchStateImpl();

  List<String> _currentKeywordList = [];
  SearchOption _currentOption = SearchOption();
  String _messageSearchCursor = '';

  SearchStoreImpl();

  @override
  SearchState get state => _state;

  @override
  Future<CompletionHandler> search({
    required List<String> keywordList,
    SearchOption? option,
  }) async {
    DataReport.reportAtomicMetrics(AtomicMetrics.search);

    final searchOption = option ?? SearchOption();

    if (keywordList.isEmpty) {
      return CompletionHandler()
        ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
        ..errorMessage = 'Keyword list cannot be empty';
    }

    if (searchOption.searchScope.isEmpty) {
      return CompletionHandler()
        ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
        ..errorMessage = 'Search scope cannot be empty';
    }

    if (searchOption.pageSize <= 0) {
      return CompletionHandler()
        ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
        ..errorMessage = 'Page size must be greater than 0';
    }

    _currentKeywordList = keywordList;
    _currentOption = searchOption;
    _resetSearchData(searchOption.searchScope);

    bool searchSuccess = false;
    final List<Future<CompletionHandler>> futures = [];

    for (final type in searchOption.searchScope) {
      switch (type) {
        case SearchType.friend:
          futures.add(_searchFriendsInternal(keywordList, searchOption));
          break;
        case SearchType.group:
          futures.add(_searchGroupsInternal(keywordList, searchOption));
          break;
        case SearchType.groupMember:
          futures.add(_searchGroupMembersInternal(keywordList, searchOption));
          break;
        case SearchType.message:
          futures.add(_searchMessagesInternal(keywordList, searchOption));
          break;
      }
    }

    final results = await Future.wait(futures);
    CompletionHandler? firstFailure;
    for (final result in results) {
      if (result.errorCode == TIMErrCode.ERR_SUCC.value) {
        searchSuccess = true;
      } else if (firstFailure == null) {
        firstFailure = result;
      }
    }

    if (searchSuccess) {
      return CompletionHandler();
    }
    return CompletionHandler()
      ..errorCode = firstFailure?.errorCode ?? -1
      ..errorMessage = firstFailure?.errorMessage ?? 'Search failed';
  }

  @override
  Future<CompletionHandler> searchMore({required SearchType searchType}) async {
    switch (searchType) {
      case SearchType.friend:
        return CompletionHandler()
          ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
          ..errorMessage = 'Friend search does not support pagination';
      case SearchType.group:
        return CompletionHandler()
          ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
          ..errorMessage = 'Group search does not support pagination';
      case SearchType.groupMember:
        return CompletionHandler()
          ..errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value
          ..errorMessage = 'Group member search does not support pagination';
      case SearchType.message:
        if (!_state.hasMoreMessageResultsValue.value) return CompletionHandler();
        return _searchMessagesInternal(_currentKeywordList, _currentOption);
    }
  }

  // ======== Reset ========

  void _resetSearchData(List<SearchType> searchScope) {
    for (final type in searchScope) {
      switch (type) {
        case SearchType.friend:
          _state.friendListValue.value = [];
          _state.friendTotalCountValue.value = 0;
          _state.hasMoreFriendsValue.value = false;
          break;
        case SearchType.group:
          _state.groupListValue.value = [];
          _state.groupTotalCountValue.value = 0;
          _state.hasMoreGroupsValue.value = false;
          break;
        case SearchType.groupMember:
          _state.groupMemberListValue.value = {};
          _state.groupMemberTotalCountValue.value = 0;
          _state.hasMoreGroupMembersValue.value = false;
          break;
        case SearchType.message:
          _messageSearchCursor = '';
          _state.messageResultsValue.value = [];
          _state.messageResultTotalCountValue.value = 0;
          _state.hasMoreMessageResultsValue.value = true;
          break;
      }
    }
  }

  // ======== Friend Search (local) ========

  Future<CompletionHandler> _searchFriendsInternal(List<String> keywordList, SearchOption option) async {
    final searchParam = V2TimFriendSearchParam(
      keywordList: keywordList,
      isSearchUserID: true,
      isSearchNickName: true,
      isSearchRemark: true,
    );

    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().searchFriends(searchParam: searchParam);

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      final friendList = result.data!
          .where((item) => item.friendInfo != null)
          .map((item) => _convertToFriendSearchInfo(item.friendInfo!))
          .where((item) => item != null)
          .cast<FriendSearchInfo>()
          .toList();

      _state.friendListValue.value = List.unmodifiable(friendList);
      _state.friendTotalCountValue.value = friendList.length;
      _state.hasMoreFriendsValue.value = false;

      return CompletionHandler();
    } else {
      return CompletionHandler()
        ..errorCode = result.code
        ..errorMessage = result.desc;
    }
  }

  // ======== Group Search (local) ========

  Future<CompletionHandler> _searchGroupsInternal(List<String> keywordList, SearchOption option) async {
    final searchParam = V2TimGroupSearchParam(
      keywordList: keywordList,
      isSearchGroupID: true,
      isSearchGroupName: true,
    );

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().searchGroups(searchParam: searchParam);

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      final groups = result.data!
          .map((groupInfo) => _convertToGroupSearchInfo(groupInfo))
          .where((item) => item != null)
          .cast<GroupSearchInfo>()
          .toList();

      _state.groupListValue.value = List.unmodifiable(groups);
      _state.groupTotalCountValue.value = groups.length;
      _state.hasMoreGroupsValue.value = false;

      return CompletionHandler();
    } else {
      return CompletionHandler()
        ..errorCode = result.code
        ..errorMessage = result.desc;
    }
  }

  // ======== Group Member Search (local) ========

  Future<CompletionHandler> _searchGroupMembersInternal(List<String> keywordList, SearchOption option) async {
    final searchParam = V2TimGroupMemberSearchParam(
      keywordList: keywordList,
      isSearchMemberUserID: true,
      isSearchMemberNickName: true,
      isSearchMemberRemark: true,
      isSearchMemberNameCard: true,
    );

    if (option.groupMemberFilter?.groupIDList != null && option.groupMemberFilter!.groupIDList.isNotEmpty) {
      searchParam.groupIDList = option.groupMemberFilter!.groupIDList;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().searchGroupMembers(param: searchParam);

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      final Map<String, List<GroupMember>> groupMemberDict = {};
      final searchResultItems = result.data!.groupMemberSearchResultItems;
      if (searchResultItems != null) {
        searchResultItems.forEach((groupID, memberInfoList) {
          if (memberInfoList is List) {
            final members =
                memberInfoList.map((member) => _convertToGroupMember(member as V2TimGroupMemberFullInfo)).toList();
            if (groupID.isNotEmpty) {
              groupMemberDict[groupID] = members;
            }
          }
        });
      }

      int totalCount = 0;
      for (final members in groupMemberDict.values) {
        totalCount += members.length;
      }

      _state.groupMemberListValue.value = Map.unmodifiable(groupMemberDict);
      _state.groupMemberTotalCountValue.value = totalCount;
      _state.hasMoreGroupMembersValue.value = false;

      return CompletionHandler();
    } else {
      return CompletionHandler()
        ..errorCode = result.code
        ..errorMessage = result.desc;
    }
  }

  // ======== Message Search (local) ========

  Future<CompletionHandler> _searchMessagesInternal(List<String> keywordList, SearchOption option) async {
    final currentPageIndex = int.tryParse(_messageSearchCursor) ?? 0;

    final searchParam = V2TimMessageSearchParam(
      keywordList: keywordList,
      type: option.keywordListMatchMode == KeywordListMatchMode.or ? 0 : 1,
      pageIndex: currentPageIndex,
      pageSize: option.pageSize,
    );

    if (option.messageFilter != null) {
      final filter = option.messageFilter!;
      if (filter.conversationID != null) {
        searchParam.conversationID = filter.conversationID;
      }
      searchParam.searchTimePosition = filter.searchTimePosition;
      searchParam.searchTimePeriod = filter.searchTimePeriod;
      if (filter.senderUserIDList != null) {
        searchParam.userIDList = filter.senderUserIDList;
      }
      if (filter.messageTypeList != null) {
        searchParam.messageTypeList = filter.messageTypeList!.map((type) => _convertToV2TIMElemType(type)).toList();
      }
    }

    final isSearchInConversation = searchParam.conversationID != null && searchParam.conversationID!.isNotEmpty;

    final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().searchLocalMessages(
          searchParam: searchParam,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      final isFirstPage = currentPageIndex == 0;
      final messageResults =
          result.data!.messageSearchResultItems?.map((item) => _convertToMessageSearchResultItem(item)).toList() ?? [];

      final totalCount = result.data!.totalCount ?? 0;
      final pageSize = option.pageSize;
      final totalPage = (totalCount % pageSize == 0) ? (totalCount ~/ pageSize) : (totalCount ~/ pageSize + 1);
      final hasMore = (currentPageIndex + 1) < totalPage;

      _messageSearchCursor = (currentPageIndex + 1).toString();

      final updatedResults = (!isFirstPage && isSearchInConversation)
          ? messageResults
          : await _fetchConversationInfoForMessageResults(messageResults);

      _updateMessageResults(
        isFirstPage: isFirstPage,
        isSearchInConversation: isSearchInConversation,
        newResults: updatedResults,
        totalCount: totalCount,
        hasMore: hasMore,
      );

      return CompletionHandler();
    } else {
      return CompletionHandler()
        ..errorCode = result.code
        ..errorMessage = result.desc;
    }
  }

  void _updateMessageResults({
    required bool isFirstPage,
    required bool isSearchInConversation,
    required List<MessageSearchResultItem> newResults,
    required int totalCount,
    required bool hasMore,
  }) {
    if (isFirstPage) {
      _state.messageResultsValue.value = List.unmodifiable(newResults);
    } else if (isSearchInConversation) {
      final currentResults = _state.messageResultsValue.value;
      if (currentResults.isNotEmpty && newResults.isNotEmpty) {
        final existingResult = currentResults.first;
        final newMessageList = newResults.first.messageList;
        _state.messageResultsValue.value = List.unmodifiable([
          MessageSearchResultItem(
            conversationID: existingResult.conversationID,
            conversationShowName: existingResult.conversationShowName,
            conversationAvatarURL: existingResult.conversationAvatarURL,
            messageCount: existingResult.messageCount + newResults.first.messageCount,
            messageList: [...existingResult.messageList, ...newMessageList],
          )
        ]);
      }
    } else {
      final currentResults = List<MessageSearchResultItem>.from(_state.messageResultsValue.value);
      currentResults.addAll(newResults);
      _state.messageResultsValue.value = List.unmodifiable(currentResults);
    }

    _state.messageResultTotalCountValue.value = totalCount;
    _state.hasMoreMessageResultsValue.value = hasMore;
  }

  // ======== Conversion Methods ========

  FriendSearchInfo? _convertToFriendSearchInfo(V2TimFriendInfo friendInfo) {
    if (friendInfo.userID.isEmpty) return null;
    return FriendSearchInfo(
      userID: friendInfo.userID,
      userInfo: friendInfo.userProfile != null ? ChatUtil.convertToUserFullProfile(friendInfo.userProfile!) : null,
      friendRemark: friendInfo.friendRemark,
      friendAddTime: 0,
      friendCustomInfo: friendInfo.friendCustomInfo,
    );
  }

  GroupSearchInfo? _convertToGroupSearchInfo(V2TimGroupInfo groupInfo) {
    if (groupInfo.groupID.isEmpty) return null;
    return GroupSearchInfo(
      groupID: groupInfo.groupID,
      groupName: groupInfo.groupName,
      groupAvatarURL: groupInfo.faceUrl,
      introduction: groupInfo.introduction,
      groupType: GroupStoreImpl.groupTypeFromV2TIMString(groupInfo.groupType),
      memberCount: groupInfo.memberCount ?? 0,
      joinGroupApprovalType: ChatUtil.convertGroupAddOptToJoinOption(groupInfo.groupAddOpt),
      inviteToGroupApprovalType: ChatUtil.convertApproveOptToInviteOption(groupInfo.approveOpt),
    );
  }

  MessageSearchResultItem _convertToMessageSearchResultItem(V2TimMessageSearchResultItem resultItem) {
    return MessageSearchResultItem(
      conversationID: resultItem.conversationID ?? '',
      messageCount: resultItem.messageCount ?? 0,
      messageList: resultItem.messageList?.map((msg) => ChatUtil.convertToUIMessage(msg)).toList() ?? [],
    );
  }

  int _convertToV2TIMElemType(MessageType messageType) {
    switch (messageType) {
      case MessageType.text:
        return MessageElemType.V2TIM_ELEM_TYPE_TEXT;
      case MessageType.image:
        return MessageElemType.V2TIM_ELEM_TYPE_IMAGE;
      case MessageType.video:
        return MessageElemType.V2TIM_ELEM_TYPE_VIDEO;
      case MessageType.audio:
        return MessageElemType.V2TIM_ELEM_TYPE_SOUND;
      case MessageType.file:
        return MessageElemType.V2TIM_ELEM_TYPE_FILE;
      case MessageType.face:
        return MessageElemType.V2TIM_ELEM_TYPE_FACE;
      case MessageType.tips:
        return MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS;
      case MessageType.custom:
        return MessageElemType.V2TIM_ELEM_TYPE_CUSTOM;
      default:
        return MessageElemType.V2TIM_ELEM_TYPE_NONE;
    }
  }

  GroupMember _convertToGroupMember(V2TimGroupMemberFullInfo memberInfo) {
    return GroupMember(
      userID: memberInfo.userID,
      nickname: memberInfo.nickName,
      avatarURL: memberInfo.faceUrl,
      nameCard: memberInfo.nameCard,
      friendRemark: memberInfo.friendRemark,
      role: GroupMemberRole.fromValue(memberInfo.role ?? 0),
      muteUntil: memberInfo.muteUntil ?? 0,
    );
  }

  Future<List<MessageSearchResultItem>> _fetchConversationInfoForMessageResults(
      List<MessageSearchResultItem> messageResults) async {
    if (messageResults.isEmpty) return messageResults;

    final conversationIDList = messageResults
        .map((result) => result.conversationID)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (conversationIDList.isEmpty) return messageResults;

    try {
      final conversationResult = await TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .getConversationListByConversationIds(conversationIDList: conversationIDList);

      if (conversationResult.code == TIMErrCode.ERR_SUCC.value && conversationResult.data != null) {
        final conversationMap = <String, dynamic>{};
        for (final conversation in conversationResult.data!) {
          conversationMap[conversation.conversationID] = conversation;
        }

        return messageResults.map((result) {
          if (result.conversationID.isEmpty) return result;
          final conversation = conversationMap[result.conversationID];
          if (conversation != null) {
            return MessageSearchResultItem(
              conversationID: result.conversationID,
              conversationShowName: conversation.showName ?? '',
              conversationAvatarURL: conversation.faceUrl ?? '',
              messageCount: result.messageCount,
              messageList: result.messageList,
            );
          }
          return result;
        }).toList();
      }
    } catch (_) {}

    return messageResults;
  }
}
