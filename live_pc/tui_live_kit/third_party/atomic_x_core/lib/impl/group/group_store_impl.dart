import 'dart:async';

import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimGroupListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_add_opt_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_application_handle_result.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_application_handle_status.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_application_type.dart' as sdk;
import 'package:tencent_cloud_chat_sdk/enum/group_application_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_change_info_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_type.dart' as sdk_group_type;
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_application.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_info.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class _GroupStateImpl implements GroupState {
  final ValueNotifier<List<GroupInfo>> joinedGroupListValue = ValueNotifier([]);
  final ValueNotifier<List<GroupApplicationInfo>> applicationListValue = ValueNotifier([]);
  final ValueNotifier<int> unreadApplicationCountValue = ValueNotifier(0);

  @override
  ValueListenable<List<GroupInfo>> get joinedGroupList => joinedGroupListValue;

  @override
  ValueListenable<List<GroupApplicationInfo>> get applicationList => applicationListValue;

  @override
  ValueListenable<int> get unreadApplicationCount => unreadApplicationCountValue;
}

class GroupStoreImpl extends GroupStore {
  static final GroupStoreImpl shared = GroupStoreImpl._();

  final _groupState = _GroupStateImpl();
  final _groupEventController = StreamController<GroupEvent>.broadcast();

  V2TimGroupListener? _groupListener;

  LoginStatus _lastObservedLoginStatus = LoginStatus.unlogin;

  String? get _currentLoginUserID => LoginStoreImpl.instance.loginState.loginUserInfo?.userID;

  GroupStoreImpl._() {
    _lastObservedLoginStatus = LoginStoreImpl.instance.loginState.loginStatus;
    _addListeners();
    LoginStoreImpl.instance.addListener(_onLoginStateChanged);
  }

  void _onLoginStateChanged() {
    final next = LoginStoreImpl.instance.loginState.loginStatus;
    if (next == _lastObservedLoginStatus) return;
    final prev = _lastObservedLoginStatus;
    _lastObservedLoginStatus = next;

    if (next == LoginStatus.logined) {
      _reattachAfterLogin();
    } else if (prev == LoginStatus.logined) {
      _resetAfterLogout();
    }
  }

  void _reattachAfterLogin() {
    _addListeners();
  }

  void _resetAfterLogout() {
    _groupState.joinedGroupListValue.value = const [];
    _groupState.applicationListValue.value = const [];
    _groupState.unreadApplicationCountValue.value = 0;
  }

  @override
  GroupState get state => _groupState;

  @override
  Stream<GroupEvent> get groupEventStream => _groupEventController.stream;

  void _addListeners() {
    _groupListener ??= V2TimGroupListener(
      onReceiveJoinApplication: _onReceiveJoinApplication,
      onGroupDismissed: _onGroupDismissed,
      onMemberKicked: _onMemberKicked,
      onQuitFromGroup: _onQuitFromGroup,
      onApplicationProcessed: _onApplicationProcessed,
      onGroupInfoChanged: _onGroupInfoChanged,
      onGroupAttributeChanged: _onGroupAttributeChanged,
      onMemberEnter: _onMemberEnter,
      onMemberLeave: _onMemberLeave,
      onMemberInvited: _onMemberInvited,
      onGrantAdministrator: _onGrantAdministrator,
      onRevokeAdministrator: _onRevokeAdministrator,
    );
    TencentImSDKPlugin.v2TIMManager.addGroupListener(listener: _groupListener!);
  }

  @override
  Future<CompletionHandler> loadJoinedGroups() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getJoinedGroupList();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final groupInfoList = _convertToGroupInfoList(result.data ?? []);
    _groupState.joinedGroupListValue.value = List.unmodifiable(groupInfoList);

    return handler;
  }

  @override
  Future<CompletionHandler> loadGroupAttributes({required String groupID, List<String>? keys}) async {
    final handler = CompletionHandler();

    final currentList = _groupState.joinedGroupListValue.value;
    final index = currentList.indexWhere((g) => g.groupID == groupID);
    if (index < 0) {
      handler.errorCode = -1;
      handler.errorMessage = "Group $groupID not found in joinedGroupList";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupAttributes(
          groupID: groupID,
          keys: keys,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    if (result.data != null) {
      final mutableList = List<GroupInfo>.from(currentList);
      mutableList[index].groupAttributes = result.data;
      _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
    }

    return handler;
  }

  @override
  Future<GetGroupInfoCompletionHandler> getGroupInfo({required String groupID}) async {
    final handler = GetGroupInfoCompletionHandler();

    // Step 1: Get group info from SDK
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupsInfo(groupIDList: [groupID]);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final v2Results = result.data ?? [];
    if (v2Results.isEmpty ||
        v2Results.first.resultCode != TIMErrCode.ERR_SUCC.value ||
        v2Results.first.groupInfo == null) {
      handler.errorCode = v2Results.isNotEmpty ? (v2Results.first.resultCode ?? -1) : -1;
      handler.errorMessage =
          v2Results.isNotEmpty ? (v2Results.first.resultMessage ?? 'Unknown error') : 'No group info returned';
      return handler;
    }

    final v2GroupInfo = v2Results.first.groupInfo!;
    final groupInfo = _convertV2TIMGroupInfo(v2GroupInfo);

    // Step 2: Check if the current user is a group member via joinTime.
    // When not a member, joinTime is 0 or null — skip group attributes and merge.
    final isGroupMember = (v2GroupInfo.joinTime ?? 0) > 0;

    if (isGroupMember) {
      // Step 3: Load group attributes to fill in groupInfo
      final attrResult = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupAttributes(
            groupID: groupID,
          );
      if (attrResult.code == TIMErrCode.ERR_SUCC.value && attrResult.data != null) {
        groupInfo.groupAttributes = attrResult.data;
      }

      // Step 4: Merge with joinedGroupList (including groupAttributes)
      _mergeGroupInfoIntoJoinedList(groupInfo, includeAttributes: true);
    }

    handler.groupInfo = groupInfo;
    return handler;
  }

  // ======== Group Operations ========

  @override
  Future<CreateGroupCompletionHandler> createGroup({required GroupCreateParams params}) async {
    final handler = CreateGroupCompletionHandler();

    List<V2TimGroupMember>? v2MemberList;
    if (params.memberList != null) {
      v2MemberList = params.memberList!.map((userID) {
        return V2TimGroupMember(userID: userID, role: GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_MEMBER);
      }).toList();
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().createGroup(
        groupType: groupTypeToV2TIMString(params.groupType),
        groupID: params.groupID,
        groupName: params.groupName,
        faceUrl: params.avatarURL,
        memberList: v2MemberList);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    handler.groupID = result.data ?? '';
    return handler;
  }

  @override
  Future<CompletionHandler> joinGroup({required String groupID, String? message}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.joinGroup(groupID: groupID, message: message ?? "");

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> quitGroup({required String groupID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.quitGroup(groupID: groupID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> dismissGroup({required String groupID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.dismissGroup(groupID: groupID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  // ======== Group Applications ========

  @override
  Future<CompletionHandler> loadApplications() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupApplicationList();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final applicationList = _convertToGroupApplicationList(result.data?.groupApplicationList ?? []);
    _groupState.applicationListValue.value = List.unmodifiable(applicationList);
    _groupState.unreadApplicationCountValue.value = result.data?.unreadCount ?? 0;

    return handler;
  }

  @override
  Future<CompletionHandler> acceptApplication({required GroupApplicationInfo info}) async {
    final handler = CompletionHandler();
    final rawApp = info.rawApplication ?? _findRawApplication(info);
    if (rawApp == null) {
      handler.errorCode = -1;
      handler.errorMessage = "rawApplication is null";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().acceptGroupApplication(
        groupID: info.groupID,
        reason: info.requestMsg,
        fromUser: rawApp.fromUser ?? '',
        toUser: rawApp.toUser ?? '',
        application: rawApp);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final currentList = List<GroupApplicationInfo>.from(_groupState.applicationListValue.value);
    final index = currentList.indexWhere((app) => app.applicationID == info.applicationID);
    if (index != -1) {
      currentList[index].handledStatus = GroupApplicationHandledStatus.byMyself;
      currentList[index].handledResult = GroupApplicationHandledResult.agreed;
      _groupState.applicationListValue.value = List.unmodifiable(currentList);
    }

    return handler;
  }

  @override
  Future<CompletionHandler> refuseApplication({required GroupApplicationInfo info}) async {
    final handler = CompletionHandler();
    final rawApp = info.rawApplication ?? _findRawApplication(info);
    if (rawApp == null) {
      handler.errorCode = -1;
      handler.errorMessage = "rawApplication is null";
      return handler;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().refuseGroupApplication(
        groupID: info.groupID,
        reason: info.requestMsg,
        fromUser: rawApp.fromUser ?? '',
        toUser: rawApp.toUser ?? '',
        addTime: rawApp.addTime ?? 0,
        type: GroupApplicationTypeEnum.values.firstWhere((e) => e.index == rawApp.type),
        application: rawApp);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final currentList = List<GroupApplicationInfo>.from(_groupState.applicationListValue.value);
    final index = currentList.indexWhere((app) => app.applicationID == info.applicationID);
    if (index != -1) {
      currentList[index].handledStatus = GroupApplicationHandledStatus.byMyself;
      currentList[index].handledResult = GroupApplicationHandledResult.refused;
      _groupState.applicationListValue.value = List.unmodifiable(currentList);
    }

    return handler;
  }

  V2TimGroupApplication? _findRawApplication(GroupApplicationInfo info) {
    for (final app in _groupState.applicationListValue.value) {
      if (app.applicationID == info.applicationID ||
          (app.groupID == info.groupID && app.fromUser == info.fromUser && app.toUser == info.toUser)) {
        return app.rawApplication;
      }
    }
    return null;
  }

  @override
  Future<CompletionHandler> clearApplicationUnreadCount() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.v2TIMGroupManager.setGroupApplicationRead();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    _groupState.unreadApplicationCountValue.value = 0;

    return handler;
  }

  // ======== Group Management ========

  @override
  Future<CompletionHandler> changeOwner({required String groupID, required String newOwnerID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager
        .getGroupManager()
        .transferGroupOwner(groupID: groupID, userID: newOwnerID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> updateProfile({required GroupInfo groupInfo}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupInfo(
            info: V2TimGroupInfo(
          groupID: groupInfo.groupID,
          groupType: groupTypeToV2TIMString(groupInfo.groupType ?? GroupType.work),
          groupName: groupInfo.groupName,
          faceUrl: groupInfo.avatarURL,
          notification: groupInfo.notification,
        ));

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setJoinOption({required String groupID, required GroupJoinOption option}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupInfo(
            info: V2TimGroupInfo(
          groupID: groupID,
          groupType: '',
          groupAddOpt: _convertJoinOptionToGroupAddOpt(option),
        ));

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setInviteOption({required String groupID, required GroupInviteOption option}) async {
    final handler = CompletionHandler();
    final v2GroupInfo = V2TimGroupInfo(
      groupID: groupID,
      groupType: '',
      approveOpt: _convertInviteOptionToGroupAddOpt(option),
    );

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupInfo(info: v2GroupInfo);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> muteAllMembers({required String groupID, required bool isMuted}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupInfo(
            info: V2TimGroupInfo(
          groupID: groupID,
          groupType: '',
          isAllMuted: isMuted,
        ));

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  // ======== Data conversion helpers ========

  /// Merge a GroupInfo into joinedGroupList.
  /// - If the group already exists in the list, update non-null fields onto
  ///   the existing entry (preserves any locally cached fields the caller
  ///   didn't supply).
  /// - If the group is not yet in the list, append it as-is. This matters
  ///   because callers like [getGroupInfo] are typically driven by entering
  ///   a chat / group setting page; UI layers (e.g. GroupChatSetting) that
  ///   listen on joinedGroupList must receive a change notification even on
  ///   the very first lookup, otherwise they cannot react to subsequent
  ///   push-driven updates for that group.
  /// When [includeAttributes] is true, groupAttributes is also synced.
  void _mergeGroupInfoIntoJoinedList(GroupInfo groupInfo, {bool includeAttributes = false}) {
    final currentList = _groupState.joinedGroupListValue.value;
    final index = currentList.indexWhere((g) => g.groupID == groupInfo.groupID);
    final mutableList = List<GroupInfo>.from(currentList);
    if (index >= 0) {
      final existing = mutableList[index];
      existing.groupName = groupInfo.groupName ?? existing.groupName;
      existing.avatarURL = groupInfo.avatarURL ?? existing.avatarURL;
      existing.groupType = groupInfo.groupType ?? existing.groupType;
      existing.notification = groupInfo.notification ?? existing.notification;
      existing.joinOption = groupInfo.joinOption ?? existing.joinOption;
      existing.inviteOption = groupInfo.inviteOption ?? existing.inviteOption;
      existing.memberCount = groupInfo.memberCount ?? existing.memberCount;
      existing.isAllMuted = groupInfo.isAllMuted ?? existing.isAllMuted;
      existing.groupOwner = groupInfo.groupOwner ?? existing.groupOwner;
      existing.selfRole = groupInfo.selfRole ?? existing.selfRole;
      if (includeAttributes && groupInfo.groupAttributes != null) {
        existing.groupAttributes = groupInfo.groupAttributes;
      }
    } else {
      mutableList.add(groupInfo);
    }
    _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
  }

  static int _convertJoinOptionToGroupAddOpt(GroupJoinOption option) {
    switch (option) {
      case GroupJoinOption.forbid:
        return GroupAddOptType.V2TIM_GROUP_ADD_FORBID;
      case GroupJoinOption.auth:
        return GroupAddOptType.V2TIM_GROUP_ADD_AUTH;
      case GroupJoinOption.any:
        return GroupAddOptType.V2TIM_GROUP_ADD_ANY;
    }
  }

  static int _convertInviteOptionToGroupAddOpt(GroupInviteOption option) {
    switch (option) {
      case GroupInviteOption.forbid:
        return GroupAddOptType.V2TIM_GROUP_ADD_FORBID;
      case GroupInviteOption.auth:
        return GroupAddOptType.V2TIM_GROUP_ADD_AUTH;
      case GroupInviteOption.any:
        return GroupAddOptType.V2TIM_GROUP_ADD_ANY;
    }
  }

  static const Map<GroupType, String> _groupTypeToString = {
    GroupType.work: sdk_group_type.GroupType.Work,
    GroupType.publicGroup: sdk_group_type.GroupType.Public,
    GroupType.meeting: sdk_group_type.GroupType.Meeting,
    GroupType.avChatRoom: sdk_group_type.GroupType.AVChatRoom,
    GroupType.community: sdk_group_type.GroupType.Community,
  };

  static const Map<String, GroupType> _stringToGroupType = {
    sdk_group_type.GroupType.Work: GroupType.work,
    sdk_group_type.GroupType.Public: GroupType.publicGroup,
    sdk_group_type.GroupType.Meeting: GroupType.meeting,
    sdk_group_type.GroupType.AVChatRoom: GroupType.avChatRoom,
    sdk_group_type.GroupType.Community: GroupType.community,
  };

  static String groupTypeToV2TIMString(GroupType type) {
    return _groupTypeToString[type] ?? sdk_group_type.GroupType.Work;
  }

  static GroupType groupTypeFromV2TIMString(String type) {
    return _stringToGroupType[type] ?? GroupType.work;
  }

  List<GroupInfo> _convertToGroupInfoList(List<V2TimGroupInfo> v2List) {
    return v2List.where((group) => group.groupID.isNotEmpty).map((group) => _convertV2TIMGroupInfo(group)).toList();
  }

  GroupInfo _convertV2TIMGroupInfo(V2TimGroupInfo v2Info) {
    return GroupInfo(
      groupID: v2Info.groupID,
      groupName: v2Info.groupName,
      avatarURL: v2Info.faceUrl,
      groupType: groupTypeFromV2TIMString(v2Info.groupType),
      notification: v2Info.notification,
      memberCount: v2Info.memberCount,
      isAllMuted: v2Info.isAllMuted,
      groupOwner: v2Info.owner,
      joinOption: v2Info.groupAddOpt != null ? GroupJoinOption.values[v2Info.groupAddOpt!] : null,
      inviteOption: v2Info.approveOpt != null ? GroupInviteOption.values[v2Info.approveOpt!] : null,
      selfRole: v2Info.role != null ? GroupMemberRole.fromValue(v2Info.role!) : null,
    );
  }

  List<GroupApplicationInfo> _convertToGroupApplicationList(List<V2TimGroupApplication?> v2ApplicationList) {
    return v2ApplicationList
        .where((app) => app != null && app.handleStatus == 0)
        .map((app) => _convertToGroupApplicationInfo(app!))
        .toList();
  }

  GroupApplicationInfo _convertToGroupApplicationInfo(V2TimGroupApplication application) {
    final applicationID = _generateGroupApplicationID(application);
    return GroupApplicationInfo(
      applicationID: applicationID,
      groupID: application.groupID,
      fromUser: application.fromUser,
      fromUserNickname: application.fromUserNickName,
      fromUserAvatarURL: application.fromUserFaceUrl,
      toUser: application.toUser,
      addTime: application.addTime ?? 0,
      requestMsg: application.requestMsg,
      handledMsg: application.handledMsg,
      type: _toGroupApplicationType(application.type),
      handledStatus: _toGroupApplicationHandledStatus(application.handleStatus),
      handledResult: _toGroupApplicationHandledResult(application.handleResult),
      rawApplication: application,
    );
  }

  String _generateGroupApplicationID(V2TimGroupApplication application) {
    return '${application.groupID}_${application.type}_${application.addTime}_${application.fromUser}_${application.toUser}';
  }

  GroupApplicationType _toGroupApplicationType(int type) {
    switch (type) {
      case sdk.GroupApplicationType.V2TIM_GROUP_APPLICATION_GET_TYPE_JOIN:
        return GroupApplicationType.joinApprovedByAdmin;
      case sdk.GroupApplicationType.V2TIM_GROUP_APPLICATION_GET_TYPE_INVITE:
        return GroupApplicationType.inviteApprovedByInvitee;
      case sdk.GroupApplicationType.V2TIM_GROUP_APPLICATION_NEED_ADMIN_APPROVE:
        return GroupApplicationType.inviteApprovedByAdmin;
      default:
        return GroupApplicationType.inviteApprovedByAdmin;
    }
  }

  GroupApplicationHandledStatus _toGroupApplicationHandledStatus(int status) {
    switch (status) {
      case GroupApplicationHandleStatus.V2TIM_GROUP_APPLICATION_HANDLE_STATUS_UNHANDLED:
        return GroupApplicationHandledStatus.unhandled;
      case GroupApplicationHandleStatus.V2TIM_GROUP_APPLICATION_HANDLE_STATUS_HANDLED_BY_OTHER:
        return GroupApplicationHandledStatus.byOther;
      case GroupApplicationHandleStatus.V2TIM_GROUP_APPLICATION_HANDLE_STATUS_HANDLED_BY_SELF:
        return GroupApplicationHandledStatus.byMyself;
      default:
        return GroupApplicationHandledStatus.unhandled;
    }
  }

  GroupApplicationHandledResult _toGroupApplicationHandledResult(int result) {
    switch (result) {
      case GroupApplicationHandleResult.V2TIM_GROUP_APPLICATION_HANDLE_RESULT_REFUSE:
        return GroupApplicationHandledResult.refused;
      case GroupApplicationHandleResult.V2TIM_GROUP_APPLICATION_HANDLE_RESULT_AGREE:
        return GroupApplicationHandledResult.agreed;
      default:
        return GroupApplicationHandledResult.refused;
    }
  }

  // ======== V2TimGroupListener callbacks ========

  void _onReceiveJoinApplication(
    String groupID,
    V2TimGroupMemberInfo member,
    String opReason,
  ) {
    loadApplications();
    _groupEventController.add(OnReceiveJoinApplication(
      groupID: groupID,
      member: GroupMember(
        userID: member.userID ?? '',
        nickname: member.nickName,
        avatarURL: member.faceUrl,
      ),
      opReason: opReason.isNotEmpty ? opReason : null,
    ));
  }

  void _onGroupDismissed(String groupID, V2TimGroupMemberInfo opUser) {
    _removeGroupFromJoinedList(groupID);
    _groupEventController.add(OnGroupDismissed(
      groupID: groupID,
      opUser: GroupMember(
        userID: opUser.userID ?? '',
        nickname: opUser.nickName,
        avatarURL: opUser.faceUrl,
      ),
    ));
  }

  void _onMemberKicked(String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
    final currentUserID = _currentLoginUserID;
    final isSelfKicked = memberList.any((m) => m.userID == currentUserID);
    if (isSelfKicked) {
      _removeGroupFromJoinedList(groupID);
    } else if (_groupState.joinedGroupListValue.value.any((g) => g.groupID == groupID)) {
      _refreshGroupInfo(groupID);
    }

    _groupEventController.add(OnKickedFromGroup(
      groupID: groupID,
      opUser: GroupMember(
        userID: opUser.userID ?? '',
        nickname: opUser.nickName,
        avatarURL: opUser.faceUrl,
      ),
    ));
  }

  void _onQuitFromGroup(String groupID) {
    _removeGroupFromJoinedList(groupID);
    _groupEventController.add(OnQuitFromGroup(groupID: groupID));
  }

  void _onApplicationProcessed(
    String groupID,
    V2TimGroupMemberInfo opUser,
    bool isAgreeJoin,
    String opReason,
  ) {
    _groupEventController.add(OnApplicationProcessed(
      groupID: groupID,
      opUser: GroupMember(
        userID: opUser.userID ?? '',
        nickname: opUser.nickName,
        avatarURL: opUser.faceUrl,
      ),
      opResult: isAgreeJoin,
      opReason: opReason.isNotEmpty ? opReason : null,
    ));
  }

  void _onGroupInfoChanged(String groupID, List<V2TimGroupChangeInfo> changeInfos) {
    final currentList = _groupState.joinedGroupListValue.value;
    final index = currentList.indexWhere((g) => g.groupID == groupID);
    if (index < 0) return;

    final mutableList = List<GroupInfo>.from(currentList);
    final groupInfo = mutableList[index];
    bool changed = false;

    for (final change in changeInfos) {
      switch (change.type) {
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_NAME:
          groupInfo.groupName = change.value;
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_NOTIFICATION:
          groupInfo.notification = change.value;
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_FACE_URL:
          groupInfo.avatarURL = change.value;
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_OWNER:
          final currentUserID = _currentLoginUserID;
          groupInfo.groupOwner = change.value;
          if (change.value == currentUserID) {
            groupInfo.selfRole = GroupMemberRole.owner;
          } else if (groupInfo.selfRole == GroupMemberRole.owner) {
            groupInfo.selfRole = GroupMemberRole.member;
          }
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_SHUT_UP_ALL:
          groupInfo.isAllMuted = change.boolValue ?? false;
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_ADD_OPT:
          if (change.intValue != null) {
            groupInfo.joinOption = GroupJoinOption.values[change.intValue!];
          }
          changed = true;
          break;
        case GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_APPROVE_OPT:
          if (change.intValue != null) {
            groupInfo.inviteOption = GroupInviteOption.values[change.intValue!];
          }
          changed = true;
          break;
        default:
          break;
      }
    }

    if (changed) {
      _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
    }
  }

  void _onGroupAttributeChanged(String groupID, Map<String, String> groupAttributeMap) {
    final currentList = _groupState.joinedGroupListValue.value;
    final index = currentList.indexWhere((g) => g.groupID == groupID);
    if (index < 0) return;

    final mutableList = List<GroupInfo>.from(currentList);
    mutableList[index].groupAttributes = groupAttributeMap;
    _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
  }

  void _onMemberEnter(String groupID, List<V2TimGroupMemberInfo> memberList) {
    _refreshGroupInfo(groupID);
  }

  void _onMemberLeave(String groupID, V2TimGroupMemberInfo member) {
    _refreshGroupInfo(groupID);
  }

  void _onMemberInvited(String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
    _refreshGroupInfo(groupID);
  }

  void _onGrantAdministrator(String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
    final currentUserID = _currentLoginUserID;
    if (memberList.any((m) => m.userID == currentUserID)) {
      _updateSelfRole(groupID, GroupMemberRole.admin);
    }
  }

  void _onRevokeAdministrator(String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
    final currentUserID = _currentLoginUserID;
    if (memberList.any((m) => m.userID == currentUserID)) {
      _updateSelfRole(groupID, GroupMemberRole.member);
    }
  }

  // ======== JoinedGroupList helpers ========

  void _removeGroupFromJoinedList(String groupID) {
    final currentList = _groupState.joinedGroupListValue.value;
    if (currentList.any((g) => g.groupID == groupID)) {
      final mutableList = List<GroupInfo>.from(currentList);
      mutableList.removeWhere((g) => g.groupID == groupID);
      _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
    }
  }

  /// Refresh group info from server (without group attributes) and merge into joinedGroupList.
  /// Only refreshes if the group exists in joinedGroupList.
  Future<void> _refreshGroupInfo(String groupID) async {
    final currentList = _groupState.joinedGroupListValue.value;
    if (!currentList.any((g) => g.groupID == groupID)) return;

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupsInfo(groupIDList: [groupID]);
    if (result.code != TIMErrCode.ERR_SUCC.value) return;

    final v2Results = result.data ?? [];
    if (v2Results.isEmpty ||
        v2Results.first.resultCode != TIMErrCode.ERR_SUCC.value ||
        v2Results.first.groupInfo == null) return;

    final groupInfo = _convertV2TIMGroupInfo(v2Results.first.groupInfo!);
    _mergeGroupInfoIntoJoinedList(groupInfo);
  }

  void _updateSelfRole(String groupID, GroupMemberRole role) {
    final currentList = _groupState.joinedGroupListValue.value;
    final index = currentList.indexWhere((g) => g.groupID == groupID);
    if (index < 0) return;

    final mutableList = List<GroupInfo>.from(currentList);
    mutableList[index].selfRole = role;
    _groupState.joinedGroupListValue.value = List.unmodifiable(mutableList);
  }
}
