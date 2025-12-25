import 'package:flutter/cupertino.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../component/live_info/state/follow_define.dart';

class VoiceRoomIMState {
  ValueNotifier<Set<TUIUserInfo>> myFollowingUserList = ValueNotifier({});
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

  void followUser(TUIUserInfo userInfo) async {
    final result = await _friendshipManager.followUser(userIDList: [userInfo.userId]);
    const success = 0;
    if (result.code == success) {
      final Set<TUIUserInfo> followingList = state.myFollowingUserList.value.toSet();
      followingList.add(userInfo);
      state.myFollowingUserList.value = followingList;
    }
  }

  void unfollowUser(TUIUserInfo userInfo) async {
    final result = await _friendshipManager.unfollowUser(userIDList: [userInfo.userId]);
    const success = 0;
    if (result.code == success) {
      final Set<TUIUserInfo> followingList = Set.from(state.myFollowingUserList.value);
      followingList.removeWhere((following) => following.userId == userInfo.userId);
      state.myFollowingUserList.value = followingList;
    }
  }

  void checkFollowType(String userId) async {
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().checkFollowType(userIDList: [userId]);
    if (result.code != 0 || result.data == null || result.data is! List<V2TimFollowTypeCheckResult>) {
      return;
    }
    final V2TimFollowTypeCheckResult? checkResult = result.data!.firstOrNull;
    if (checkResult == null) {
      return;
    }
    final followType = IMFollowType.fromInt(result.data![0].followType ?? 0);
    final followed = followType == IMFollowType.inMyFollowingList || followType == IMFollowType.inBothFollowersList;
    _updateFollowingUserList(
        [TUIUserInfo(userId: userId, userName: '', avatarUrl: '', userRole: TUIRole.generalUser)], followed);
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
        .map((imUserInfo) => TUIUserInfo(
            userId: imUserInfo.userID ?? '',
            userName: imUserInfo.nickName ?? '',
            avatarUrl: imUserInfo.faceUrl ?? '',
            userRole: TUIRole.generalUser))
        .toList();
    _updateFollowingUserList(users, isAdd);
  }

  void _updateFollowingUserList(List<TUIUserInfo> users, bool isFollow) {
    if (isFollow) {
      for (TUIUserInfo user in users) {
        if (state.myFollowingUserList.value.any((following) => following.userId == user.userId)) continue;
        state.myFollowingUserList.value = {...state.myFollowingUserList.value, user};
      }
      return;
    }

    final unfollowUserIds = users.map((user) => user.userId).toSet();
    state.myFollowingUserList.value =
        state.myFollowingUserList.value.where((user) => !unfollowUserIds.contains(user.userId)).toSet();
  }
}
