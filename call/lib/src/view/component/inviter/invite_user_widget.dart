import 'dart:ffi';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_filter_enum.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_calls_uikit/src/common/constants.dart';
import 'package:tencent_calls_uikit/src/common/i18n/i18n_utils.dart';
import 'package:tencent_calls_uikit/src/common/utils/string_stream.dart';
import 'package:tencent_calls_uikit/src/view/call_page_manager.dart';

class InviteUserWidget extends StatefulWidget {
  final InviteUserCallbacks? callbacks;

  const InviteUserWidget({Key? key, this.callbacks}) : super(key: key);

  @override
  State<InviteUserWidget> createState() => _InviteUserWidgetState();
}

class _InviteUserWidgetState extends State<InviteUserWidget> {
  final List<GroupMemberInfo> _groupMemberList = [];
  final List<String> _defaultSelectList = [];

  @override
  void initState() {
    super.initState();
    _getGroupMember();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            getI18nString('inviteMembers'),
            textScaleFactor: 1.0,
          ),
          leading: IconButton(
              onPressed: _goBack,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.control_point_sharp),
              tooltip: 'Search',
              onPressed: () => _inviteUser(),
            ),
          ],
        ),
        body: ListView.builder(
            itemCount: _groupMemberList.length,
            itemExtent: 60,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  _selectUser(index);
                },
                child: Row(
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                    Image.asset(
                      _groupMemberList[index].isSelected
                          ? 'assets/images/check_box_group_selected.png'
                          : 'assets/images/check_box_group_unselected.png',
                      package: 'tencent_calls_uikit',
                      width: 18,
                      height: 18,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                    Container(
                      width: 40,
                      height: 40,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Image(
                        image: NetworkImage(_groupMemberList[index].avatar),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stackTrace) => Image.asset(
                          'assets/images/user_icon.png',
                          package: 'tencent_calls_uikit',
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Text(
                      _getMemberDisPlayName(_groupMemberList[index]),
                      textScaleFactor: 1.0,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    )
                  ],
                ),
              );
            }));
  }

  _getGroupMember() async {
    final memberInfoResult = await TencentImSDKPlugin.v2TIMManager
        .getGroupManager()
        .getGroupMemberList(
        groupID: CallListStore.shared.state.activeCall.value.chatGroupId,
        filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
        nextSeq: '0');
    _groupMemberList.clear();
    if (memberInfoResult.data == null || memberInfoResult.data!.memberInfoList == null) {
      return;
    }

    for (var user in CallParticipantStore.shared.state.allParticipants.value) {
      _defaultSelectList.add(user.id);
    }

    var memberInfo = GroupMemberInfo();
    memberInfo.userId = CallParticipantStore.shared.state.selfInfo.value.id;
    memberInfo.userName =
    '${StringStream.makeNull(CallParticipantStore.shared.state.selfInfo.value.name,
        CallParticipantStore.shared.state.selfInfo.value.id)} (${getI18nString("yourself")})';
    memberInfo.avatar =
        StringStream.makeNull(CallParticipantStore.shared.state.selfInfo.value.avatarURL, Constants.defaultAvatar);
    memberInfo.isSelected = true;
    _groupMemberList.add(memberInfo);

    for (var info in memberInfoResult.data!.memberInfoList!) {
      if (info == null || info.userID == CallParticipantStore.shared.state.selfInfo.value.id) {
        continue;
      }
      var memberInfo = GroupMemberInfo();
      memberInfo.userId = info.userID;
      memberInfo.userName = StringStream.makeNull(info.nickName, '');
      memberInfo.remark = StringStream.makeNull(info.friendRemark, '');
      memberInfo.avatar = StringStream.makeNull(info.faceUrl, Constants.defaultAvatar);
      memberInfo.isSelected = _defaultSelectList.contains(info.userID);
      _groupMemberList.add(memberInfo);
    }
    if (mounted) {
      setState(() {});
    }
  }

  _selectUser(int index) {
    if (index == 0) return;
    _groupMemberList[index].isSelected = !_groupMemberList[index].isSelected;
    if (mounted) {
      setState(() {});
    }
  }

  _inviteUser() {
    List<String> userIdList = [];
    for (GroupMemberInfo info in _groupMemberList) {
      if (!_isUserAlreadyInRoom(info.userId) && info.isSelected) {
        userIdList.add(info.userId);
      }
    }

    CallListStore.shared.invite(userIdList, TUICallParams());
    _goBack();
  }

  _goBack() {
    widget.callbacks?.onShowCalling?.call();
  }

  bool _isUserAlreadyInRoom(String userId) {
    for (var user in CallParticipantStore.shared.state.allParticipants.value) {
      if (user.id == userId) {
        return true;
      }
    }
    return false;
  }

  _getMemberDisPlayName(GroupMemberInfo member) {
    if (member.remark.isNotEmpty) {
      return member.remark;
    }
    if (member.userName.isNotEmpty) {
      return member.userName;
    }
    return member.userId;
  }
}

class GroupMemberInfo {
  String userId = "";
  String userName = "";
  String avatar = "";
  String remark = "";
  bool isSelected = false;
}

