import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimGroupListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_change_info_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_filter_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

// ======== State implementation ========

class _GroupMemberStateImpl implements GroupMemberState {
  final ValueNotifier<List<GroupMember>> memberListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasMoreMembersValue = ValueNotifier(false);

  @override
  ValueListenable<List<GroupMember>> get memberList => memberListValue;

  @override
  ValueListenable<bool> get hasMoreMembers => hasMoreMembersValue;
}

// ======== Listener Handle for Finalizer ========

class _ListenerHandle {
  V2TimGroupListener? groupListener;
  V2TimFriendshipListener? friendshipListener;

  void removeGroupListener() {
    if (groupListener != null) {
      TencentImSDKPlugin.v2TIMManager.removeGroupListener(listener: groupListener!);
      groupListener = null;
    }
  }

  void removeFriendshipListener() {
    if (friendshipListener != null) {
      TencentImSDKPlugin.v2TIMManager.getFriendshipManager().removeFriendListener(listener: friendshipListener);
      friendshipListener = null;
    }
  }
}

// ======== Store implementation ========

class GroupMemberStoreImpl extends GroupMemberStore {
  static final Finalizer<_ListenerHandle> _finalizer = Finalizer((handle) {
    handle.removeGroupListener();
    handle.removeFriendshipListener();
  });

  final String _groupID;
  final _state = _GroupMemberStateImpl();
  final _listenerHandle = _ListenerHandle();

  String _memberNextSeq = '0';
  String _currentUserID = '';

  GroupMemberStoreImpl(this._groupID) {
    _initCurrentUser();
    _addGroupListener();
    _addFriendshipListener();
    _finalizer.attach(this, _listenerHandle, detach: this);
  }

  String get groupID => _groupID;

  @override
  GroupMemberState get state => _state;

  Future<void> _initCurrentUser() async {
    final result = await TencentImSDKPlugin.v2TIMManager.getLoginUser();
    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      _currentUserID = result.data!;
    }
  }

  // ======== Public methods ========

  @override
  Future<CompletionHandler> loadMembers(
      {List<GroupMemberFilterRole> roleList = const [GroupMemberFilterRole.all]}) async {
    _memberNextSeq = '0';
    _state.hasMoreMembersValue.value = false;

    final normalizedRoles = _normalizeRoleList(roleList);
    final allMembers = <GroupMember>[];
    final seenUserIDs = <String>{};

    // Fetch owner and admin first (no pagination needed, limited count)
    for (final role in normalizedRoles) {
      if (role == GroupMemberFilterRole.member) continue;

      final result = await _fetchByRole(role);
      if (result != null) {
        for (final member in result) {
          if (seenUserIDs.add(member.userID)) {
            allMembers.add(member);
          }
        }
      }
    }

    // Fetch member with pagination if requested
    if (normalizedRoles.contains(GroupMemberFilterRole.member)) {
      final result = await _fetchByRole(GroupMemberFilterRole.member, nextSeq: '0');
      if (result != null) {
        for (final member in result) {
          if (seenUserIDs.add(member.userID)) {
            allMembers.add(member);
          }
        }
      }
    }

    _state.memberListValue.value = List.unmodifiable(allMembers);
    return CompletionHandler();
  }

  @override
  Future<CompletionHandler> loadMoreMembers() async {
    if (!_state.hasMoreMembersValue.value) {
      return CompletionHandler();
    }

    final result = await _fetchByRole(GroupMemberFilterRole.member, nextSeq: _memberNextSeq);
    if (result != null) {
      final currentList = List<GroupMember>.from(_state.memberListValue.value);
      final seenUserIDs = currentList.map((m) => m.userID).toSet();
      for (final member in result) {
        if (seenUserIDs.add(member.userID)) {
          currentList.add(member);
        }
      }
      _state.memberListValue.value = List.unmodifiable(currentList);
    }

    return CompletionHandler();
  }

  @override
  Future<GetMemberInfoCompletionHandler> getMemberInfo({required List<String> userIDList}) async {
    final handler = GetMemberInfoCompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager
        .getGroupManager()
        .getGroupMembersInfo(groupID: _groupID, memberList: userIDList);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    if (result.data != null) {
      handler.memberInfoList = result.data!.map((m) => _convertFullInfoToMember(m)).toList();
    }
    return handler;
  }

  @override
  Future<CompletionHandler> addMember({required List<String> userIDList}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().inviteUserToGroup(
          groupID: _groupID,
          userList: userIDList,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final list = result.data;
    if (list != null) {
      for (final r in list) {
        if ((r.result ?? V2TimGroupMemberOperationResult.OPERATION_RESULT_SUCC) !=
            V2TimGroupMemberOperationResult.OPERATION_RESULT_SUCC) {
          handler.errorCode = r.result!;
          handler.errorMessage = 'Add group member failed';
          return handler;
        }
      }
    }

    return handler;
  }

  @override
  Future<CompletionHandler> deleteMember({required List<String> userIDList}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().kickGroupMember(
          groupID: _groupID,
          memberList: userIDList,
          reason: '',
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> muteMember({required String userID, required int time}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().muteGroupMember(
          groupID: _groupID,
          userID: userID,
          seconds: time,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setSelfNameCard({required String nameCard}) async {
    final handler = CompletionHandler();

    if (_currentUserID.isEmpty) {
      await _initCurrentUser();
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupMemberInfo(
          groupID: _groupID,
          userID: _currentUserID,
          nameCard: nameCard,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    // Update local member list
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    final index = currentList.indexWhere((m) => m.userID == _currentUserID);
    if (index != -1) {
      currentList[index].nameCard = nameCard;
      _state.memberListValue.value = List.unmodifiable(currentList);
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setMemberRole({required String userID, required GroupMemberRole role}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().setGroupMemberRole(
          groupID: _groupID,
          userID: userID,
          role: role.v2TIMRole,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  // ======== Internal fetch methods ========

  /// Normalize roleList: if contains 'all', return [owner, admin, member].
  /// Otherwise, deduplicate and sort by priority: owner → admin → member.
  List<GroupMemberFilterRole> _normalizeRoleList(List<GroupMemberFilterRole> roleList) {
    if (roleList.isEmpty || roleList.contains(GroupMemberFilterRole.all)) {
      return [GroupMemberFilterRole.owner, GroupMemberFilterRole.admin, GroupMemberFilterRole.member];
    }
    // Deduplicate and sort by priority: owner(400) > admin(300) > member(200)
    final unique = roleList.toSet();
    final sorted = unique.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  /// Fetch members by a single role. Returns the fetched list, or null on error.
  /// For owner/admin, fetches all at once (no pagination).
  /// For member, supports pagination via [nextSeq].
  Future<List<GroupMember>?> _fetchByRole(GroupMemberFilterRole role, {String nextSeq = '0'}) async {
    final filter = _roleToFilter(role);

    final result = await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupMemberList(
          groupID: _groupID,
          filter: filter,
          nextSeq: nextSeq,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value || result.data == null) return null;

    final memberInfoList = result.data!.memberInfoList ?? [];
    final members = memberInfoList.map((m) => _convertFullInfoToMember(m)).toList();

    // Only member role supports pagination
    if (role == GroupMemberFilterRole.member) {
      _memberNextSeq = result.data!.nextSeq ?? '0';
      _state.hasMoreMembersValue.value = _memberNextSeq != '0';
    }

    return members;
  }

  GroupMemberFilterTypeEnum _roleToFilter(GroupMemberFilterRole role) {
    switch (role) {
      case GroupMemberFilterRole.owner:
        return GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_OWNER;
      case GroupMemberFilterRole.admin:
        return GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ADMIN;
      case GroupMemberFilterRole.member:
        return GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_COMMON;
      case GroupMemberFilterRole.all:
        return GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL;
    }
  }

  // ======== Listeners ========

  void _addGroupListener() {
    final groupListener = V2TimGroupListener(
      onMemberEnter: (String groupID, List<V2TimGroupMemberInfo> memberList) {
        if (groupID == _groupID) {
          _addMembersLocally(memberList);
        }
      },
      onMemberLeave: (String groupID, V2TimGroupMemberInfo member) {
        if (groupID == _groupID) {
          _removeMembersLocally([member]);
        }
      },
      onMemberInvited: (String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
        if (groupID == _groupID) {
          _addMembersLocally(memberList);
        }
      },
      onMemberKicked: (String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
        if (groupID == _groupID) {
          _removeMembersLocally(memberList);
        }
      },
      onMemberInfoChanged: (String groupID, List<V2TimGroupMemberChangeInfo> changeInfos) {
        if (groupID == _groupID) {
          _updateMembersInfoLocally(changeInfos);
        }
      },
      onGrantAdministrator: (String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
        if (groupID == _groupID) {
          _updateMemberRoleLocally(memberList, GroupMemberRole.admin);
        }
      },
      onRevokeAdministrator: (String groupID, V2TimGroupMemberInfo opUser, List<V2TimGroupMemberInfo> memberList) {
        if (groupID == _groupID) {
          _updateMemberRoleLocally(memberList, GroupMemberRole.member);
        }
      },
      onGroupInfoChanged: (String groupID, List<V2TimGroupChangeInfo> changeInfos) {
        if (groupID == _groupID) {
          _handleGroupInfoChangedLocally(changeInfos);
        }
      },
    );

    TencentImSDKPlugin.v2TIMManager.addGroupListener(listener: groupListener);
    _listenerHandle.groupListener = groupListener;
  }

  void _addFriendshipListener() {
    final friendshipListener = V2TimFriendshipListener(
      onFriendInfoChanged: _onFriendInfoChanged,
    );
    TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriendListener(listener: friendshipListener);
    _listenerHandle.friendshipListener = friendshipListener;
  }

  // ======== Local state update helpers ========

  void _addMembersLocally(List<V2TimGroupMemberInfo> memberList) {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;

    for (final memberInfo in memberList) {
      final userID = memberInfo.userID;
      if (userID == null) continue;

      final existingIndex = currentList.indexWhere((m) => m.userID == userID);
      if (existingIndex == -1) {
        currentList.add(_convertMemberInfoToMember(memberInfo));
        changed = true;
      }
    }

    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  void _removeMembersLocally(List<V2TimGroupMemberInfo> memberList) {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;

    for (final memberInfo in memberList) {
      final userID = memberInfo.userID;
      if (userID == null) continue;

      final removed = currentList.length;
      currentList.removeWhere((m) => m.userID == userID);
      if (currentList.length != removed) {
        changed = true;
      }
    }

    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  void _updateMembersInfoLocally(List<V2TimGroupMemberChangeInfo> changeInfos) async {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;

    for (final changeInfo in changeInfos) {
      final userID = changeInfo.userID;
      if (userID == null) continue;

      final index = currentList.indexWhere((m) => m.userID == userID);
      if (index != -1) {
        if (changeInfo.muteTime != null && changeInfo.muteTime! >= 0) {
          final result = await TencentImSDKPlugin.v2TIMManager.getServerTime();
          if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null && result.data! > 0) {
            currentList[index].muteUntil = result.data! + changeInfo.muteTime!;
            changed = true;
          }
        }
      }
    }

    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  void _updateMemberRoleLocally(List<V2TimGroupMemberInfo> memberList, GroupMemberRole newRole) {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;

    final memberMap = <String, GroupMember>{};
    for (final member in currentList) {
      memberMap[member.userID] = member;
    }

    for (final memberInfo in memberList) {
      final member = memberMap[memberInfo.userID];
      if (member != null) {
        member.role = newRole;
        changed = true;
      }
    }

    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  /// Handle group-level info changes that affect member roles.
  /// Currently only OWNER transfer needs handling: SDK pushes the change
  /// as V2TIM_GROUP_INFO_CHANGE_TYPE_OWNER (group info), not as a per-member
  /// event, so member roles in our cached list won't auto-update without
  /// this hook.
  void _handleGroupInfoChangedLocally(List<V2TimGroupChangeInfo> changeInfos) {
    for (final change in changeInfos) {
      if (change.type == GroupChangeInfoType.V2TIM_GROUP_INFO_CHANGE_TYPE_OWNER) {
        final newOwnerID = change.value;
        if (newOwnerID == null || newOwnerID.isEmpty) continue;
        _applyOwnerTransferLocally(newOwnerID);
      }
    }
  }

  void _applyOwnerTransferLocally(String newOwnerID) {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;
    for (final member in currentList) {
      if (member.userID == newOwnerID) {
        if (member.role != GroupMemberRole.owner) {
          member.role = GroupMemberRole.owner;
          changed = true;
        }
      } else if (member.role == GroupMemberRole.owner) {
        // Previous owner — no group can have two owners.
        member.role = GroupMemberRole.member;
        changed = true;
      }
    }
    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  void _onFriendInfoChanged(List<V2TimFriendInfo> infoList) {
    final currentList = List<GroupMember>.from(_state.memberListValue.value);
    bool changed = false;

    final memberMap = <String, GroupMember>{};
    for (final member in currentList) {
      memberMap[member.userID] = member;
    }

    for (final friendInfo in infoList) {
      final member = memberMap[friendInfo.userID];
      if (member != null) {
        if (member.nickname != friendInfo.userProfile?.nickName) {
          member.nickname = friendInfo.userProfile?.nickName;
          changed = true;
        }
        if (member.avatarURL != friendInfo.userProfile?.faceUrl) {
          member.avatarURL = friendInfo.userProfile?.faceUrl;
          changed = true;
        }
      }
    }

    if (changed) {
      _state.memberListValue.value = List.unmodifiable(currentList);
    }
  }

  // ======== Data conversion helpers ========

  GroupMember _convertFullInfoToMember(V2TimGroupMemberFullInfo v2Member) {
    return GroupMember(
      userID: v2Member.userID,
      nickname: v2Member.nickName,
      friendRemark: v2Member.friendRemark,
      nameCard: v2Member.nameCard,
      avatarURL: v2Member.faceUrl,
      role: GroupMemberRole.fromValue(v2Member.role ?? 0),
      muteUntil: v2Member.muteUntil ?? 0,
    );
  }

  GroupMember _convertMemberInfoToMember(V2TimGroupMemberInfo memberInfo) {
    return GroupMember(
      userID: memberInfo.userID ?? '',
      nickname: memberInfo.nickName,
      nameCard: memberInfo.nameCard,
      avatarURL: memberInfo.faceUrl,
    );
  }
}

/// Library-private bridge between the SDK-agnostic [GroupMemberRole] (API
/// layer) and the IM SDK's [GroupMemberRoleTypeEnum] (transport layer).
///
/// Lives in this impl file because [setMemberRole] is the only call site
/// that needs to forward an [GroupMemberRole] to the SDK. Callers of
/// `package:atomic_x_core/...` (UI kits, demos) should never have to
/// import `tencent_cloud_chat_sdk` just to set a member's role.
///
/// Mirrors the Kotlin/Swift side, where the equivalent mapping helper is
/// `internal` to the engine module.
extension _GroupMemberRoleSdkX on GroupMemberRole {
  GroupMemberRoleTypeEnum get v2TIMRole {
    switch (this) {
      case GroupMemberRole.undefined:
        return GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_UNDEFINED;
      case GroupMemberRole.member:
        return GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_MEMBER;
      case GroupMemberRole.admin:
        return GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_ADMIN;
      case GroupMemberRole.owner:
        return GroupMemberRoleTypeEnum.V2TIM_GROUP_MEMBER_ROLE_OWNER;
    }
  }
}
