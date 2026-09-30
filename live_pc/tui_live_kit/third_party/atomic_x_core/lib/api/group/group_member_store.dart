import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/impl/group/group_member_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_role.dart';
import 'package:tencent_cloud_chat_sdk/native_im/adapter/tim_manager.dart';

class GetMemberInfoCompletionHandler extends CompletionHandler {
  List<GroupMember> memberInfoList;

  GetMemberInfoCompletionHandler({
    this.memberInfoList = const [],
  });
}

abstract class GroupMemberState {
  ValueListenable<List<GroupMember>> get memberList;

  ValueListenable<bool> get hasMoreMembers;
}

abstract class GroupMemberStore {
  static GroupMemberStore create({required String groupID}) {
    return GroupMemberStoreImpl(groupID);
  }

  GroupMemberState get state;

  Future<CompletionHandler> loadMembers({List<GroupMemberFilterRole> roleList});

  Future<CompletionHandler> loadMoreMembers();

  Future<GetMemberInfoCompletionHandler> getMemberInfo({required List<String> userIDList});

  Future<CompletionHandler> addMember({required List<String> userIDList});

  Future<CompletionHandler> deleteMember({required List<String> userIDList});

  Future<CompletionHandler> muteMember({required String userID, required int time});

  Future<CompletionHandler> setSelfNameCard({required String nameCard});

  Future<CompletionHandler> setMemberRole({required String userID, required GroupMemberRole role});
}

class GroupMember {
  final String userID;
  String? nickname;
  String? friendRemark;
  String? nameCard;
  String? avatarURL;
  GroupMemberRole role;
  int muteUntil;

  GroupMember({
    required this.userID,
    this.nickname,
    this.friendRemark,
    this.nameCard,
    this.avatarURL,
    this.role = GroupMemberRole.member,
    this.muteUntil = 0,
  });

  bool get isMuted => muteUntil != 0 && muteUntil > TIMManager.instance.getServerTime();
}

enum GroupMemberFilterRole {
  all(0),
  member(200),
  admin(300),
  owner(400);

  const GroupMemberFilterRole(this.value);

  final int value;
}

enum GroupMemberRole {
  undefined(GroupMemberRoleType.V2TIM_GROUP_MEMBER_UNDEFINED),
  member(GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER),
  admin(GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN),
  owner(GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER);

  const GroupMemberRole(this.value);

  final int value;

  static GroupMemberRole fromValue(int value) {
    for (final role in GroupMemberRole.values) {
      if (role.value == value) return role;
    }
    return GroupMemberRole.undefined;
  }
}
