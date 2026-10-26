import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../component/live_info/state/follow_define.dart';

class VoiceRoomIMState {
  ValueNotifier<Set<LiveUserInfo>> myFollowingUserList = ValueNotifier({});
}

class VoiceRoomIMStore {
  final VoiceRoomIMState state = VoiceRoomIMState();
  final _friendshipManager = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();
  late final V2TimFriendshipListener _friendshipListener;

  VoiceRoomIMStore() {
    _addObserver();
  }

  void unInit() {
    _removeObserver();
  }

  void followUser(LiveUserInfo userInfo) async {
    final result = await _friendshipManager.followUser(userIDList: [userInfo.userID]);
    const success = 0;
    if (result.code == success) {
      final Set<LiveUserInfo> followingList = state.myFollowingUserList.value.toSet();
      followingList.add(userInfo);
      state.myFollowingUserList.value = followingList;
    }
  }

  void unfollowUser(LiveUserInfo userInfo) async {
    final result = await _friendshipManager.unfollowUser(userIDList: [userInfo.userID]);
    const success = 0;
    if (result.code == success) {
      final Set<LiveUserInfo> followingList = Set.from(state.myFollowingUserList.value);
      followingList.removeWhere((following) => following.userID == userInfo.userID);
      state.myFollowingUserList.value = followingList;
    }
  }

  void checkFollowType(String userID) async {
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().checkFollowType(userIDList: [userID]);
    if (result.code != 0 || result.data == null || result.data is! List<V2TimFollowTypeCheckResult>) {
      return;
    }
    final V2TimFollowTypeCheckResult? checkResult = result.data!.firstOrNull;
    if (checkResult == null) {
      return;
    }
    final followType = IMFollowType.fromInt(result.data![0].followType ?? 0);
    final followed = followType == IMFollowType.inMyFollowingList || followType == IMFollowType.inBothFollowersList;
    _updateFollowingUserList([LiveUserInfo(userID: userID, userName: '', avatarURL: '')], followed);
  }
}

extension on VoiceRoomIMStore {
  void _addObserver() {
    _friendshipListener = V2TimFriendshipListener(onMyFollowingListChanged: (userInfoList, isAdd) {
      _onMyFollowingListChanged(userInfoList, isAdd);
    });
    _friendshipManager.addFriendListener(listener: _friendshipListener);
  }

  void _removeObserver() {
    _friendshipManager.removeFriendListener(listener: _friendshipListener);
  }

  void _onMyFollowingListChanged(List<V2TimUserFullInfo> userInfoList, bool isAdd) {
    final users = userInfoList
        .map((imUserInfo) => LiveUserInfo(
            userID: imUserInfo.userID ?? '',
            userName: imUserInfo.nickName ?? '',
            avatarURL: imUserInfo.faceUrl ?? ''))
        .toList();
    _updateFollowingUserList(users, isAdd);
  }

  void _updateFollowingUserList(List<LiveUserInfo> users, bool isFollow) {
    if (isFollow) {
      for (LiveUserInfo user in users) {
        if (state.myFollowingUserList.value.any((following) => following.userID == user.userID)) continue;
        state.myFollowingUserList.value = {...state.myFollowingUserList.value, user};
      }
      return;
    }

    final unfollowUserIds = users.map((user) => user.userID).toSet();
    state.myFollowingUserList.value =
        state.myFollowingUserList.value.where((user) => !unfollowUserIds.contains(user.userID)).toSet();
  }
}
