import 'dart:async';

import 'package:meta/meta.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/group/group_member_store.dart';
import 'package:atomic_x_core/impl/group/group_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_application.dart';

class GetGroupInfoCompletionHandler extends CompletionHandler {
  GroupInfo? groupInfo;

  GetGroupInfoCompletionHandler({
    this.groupInfo,
  });
}

class CreateGroupCompletionHandler extends CompletionHandler {
  String groupID;

  CreateGroupCompletionHandler({
    this.groupID = '',
  });
}

sealed class GroupEvent {}

class OnGroupDismissed extends GroupEvent {
  final String groupID;
  final GroupMember opUser;

  OnGroupDismissed({required this.groupID, required this.opUser});
}

class OnKickedFromGroup extends GroupEvent {
  final String groupID;
  final GroupMember opUser;

  OnKickedFromGroup({required this.groupID, required this.opUser});
}

class OnQuitFromGroup extends GroupEvent {
  final String groupID;

  OnQuitFromGroup({required this.groupID});
}

class OnReceiveJoinApplication extends GroupEvent {
  final String groupID;
  final GroupMember member;
  final String? opReason;

  OnReceiveJoinApplication({required this.groupID, required this.member, this.opReason});
}

class OnApplicationProcessed extends GroupEvent {
  final String groupID;
  final GroupMember opUser;
  final bool opResult;
  final String? opReason;

  OnApplicationProcessed({required this.groupID, required this.opUser, required this.opResult, this.opReason});
}

abstract class GroupState {
  ValueListenable<List<GroupInfo>> get joinedGroupList;

  ValueListenable<List<GroupApplicationInfo>> get applicationList;

  ValueListenable<int> get unreadApplicationCount;
}

abstract class GroupStore {
  static GroupStore get shared => GroupStoreImpl.shared;

  GroupState get state;

  Stream<GroupEvent> get groupEventStream;

  Future<CompletionHandler> loadJoinedGroups();

  Future<CompletionHandler> loadGroupAttributes({required String groupID, List<String>? keys});

  Future<GetGroupInfoCompletionHandler> getGroupInfo({required String groupID});

  Future<CreateGroupCompletionHandler> createGroup({required GroupCreateParams params});

  Future<CompletionHandler> joinGroup({required String groupID, String? message});

  Future<CompletionHandler> quitGroup({required String groupID});

  Future<CompletionHandler> dismissGroup({required String groupID});

  Future<CompletionHandler> loadApplications();

  Future<CompletionHandler> acceptApplication({required GroupApplicationInfo info});

  Future<CompletionHandler> refuseApplication({required GroupApplicationInfo info});

  Future<CompletionHandler> clearApplicationUnreadCount();

  Future<CompletionHandler> changeOwner({required String groupID, required String newOwnerID});

  Future<CompletionHandler> updateProfile({required GroupInfo groupInfo});

  Future<CompletionHandler> setJoinOption({required String groupID, required GroupJoinOption option});

  Future<CompletionHandler> setInviteOption({required String groupID, required GroupInviteOption option});

  Future<CompletionHandler> muteAllMembers({required String groupID, required bool isMuted});
}

class GroupInfo {
  String groupID;
  String? groupName;
  String? avatarURL;
  GroupType? groupType;
  String? notification;
  GroupJoinOption? joinOption;
  GroupInviteOption? inviteOption;
  int? memberCount;
  bool? isAllMuted;
  String? groupOwner;
  GroupMemberRole? selfRole;
  Map<String, String>? groupAttributes;

  GroupInfo({
    required this.groupID,
    this.groupName,
    this.avatarURL,
    this.groupType,
    this.notification,
    this.joinOption,
    this.inviteOption,
    this.memberCount,
    this.isAllMuted,
    this.groupOwner,
    this.selfRole,
    this.groupAttributes,
  });
}

class GroupApplicationInfo {
  final String applicationID;
  final String groupID;
  final String? fromUser;
  final String? fromUserNickname;
  final String? fromUserAvatarURL;
  final String? toUser;
  final int addTime;
  final String? requestMsg;
  final String? handledMsg;
  final GroupApplicationType type;
  GroupApplicationHandledStatus? handledStatus;
  GroupApplicationHandledResult? handledResult;

  @internal
  final V2TimGroupApplication? rawApplication;

  GroupApplicationInfo({
    required this.applicationID,
    required this.groupID,
    this.fromUser,
    this.fromUserNickname,
    this.fromUserAvatarURL,
    this.toUser,
    this.addTime = 0,
    this.requestMsg,
    this.handledMsg,
    required this.type,
    this.handledStatus,
    this.handledResult,
    this.rawApplication,
  });
}

enum GroupType {
  work,
  publicGroup,
  meeting,
  avChatRoom,
  community,
}

enum GroupJoinOption {
  forbid,
  auth,
  any,
}

enum GroupInviteOption {
  forbid,
  auth,
  any,
}

enum GroupApplicationType {
  joinApprovedByAdmin,
  inviteApprovedByInvitee,
  inviteApprovedByAdmin,
}

enum GroupApplicationHandledStatus {
  unhandled,
  byOther,
  byMyself,
}

enum GroupApplicationHandledResult {
  refused,
  agreed,
}

class GroupCreateParams {
  final GroupType groupType;
  final String groupName;
  final String? groupID;
  final String? avatarURL;
  final List<String>? memberList;

  const GroupCreateParams({
    this.groupType = GroupType.work,
    required this.groupName,
    this.groupID,
    this.avatarURL,
    this.memberList,
  });
}
