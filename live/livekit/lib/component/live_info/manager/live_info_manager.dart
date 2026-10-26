import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../../common/logger/logger.dart';
import '../state/follow_define.dart';
import '../state/live_info_state.dart';

class LiveInfoManager {
  final state = LiveInfoState();
  late final friendshipManager = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();

  void initRoomInfo(LiveInfo liveInfo) async {
    state.roomId = liveInfo.liveID;
    state.selfUserId = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    state.ownerId.value = liveInfo.liveOwner.userID;
    state.ownerName.value = liveInfo.liveOwner.userName;
    state.ownerAvatarUrl.value = liveInfo.liveOwner.avatarURL;
    LiveKitLogger.info("initRoomInfo, roomId=${state.roomId}, selfUserId=${state.selfUserId}, ownerId=${state
        .ownerId.value}, ownerName=${state.ownerName.value}");
    _syncUserFollowingStatus(liveInfo.liveOwner.userID);
  }

  void getFansNumber() async {
    final result = await friendshipManager.getUserFollowInfo(userIDList: [state.ownerId.value]);
    const success = 0;
    if (result.code == success && result.data != null && result.data!.firstOrNull != null) {
      final V2TimFollowInfo followInfo = result.data!.first;
      state.fansNumber.value = followInfo.followersCount ?? 0;
    }
  }

  void followUser(String userId) async {
    final result = await friendshipManager.followUser(userIDList: [userId]);
    const success = 0;
    if (result.code == success) {
      final Set<String> followingList = Set.from(state.followingList.value);
      followingList.add(userId);
      state.followingList.value = followingList;
      getFansNumber();
    }
  }

  void unfollowUser(String userId) async {
    final result = await friendshipManager.unfollowUser(userIDList: [userId]);
    const success = 0;
    if (result.code == success) {
      final Set<String> followingList = Set.from(state.followingList.value);
      followingList.removeWhere((userID) => userID == userId);
      state.followingList.value = followingList;
      getFansNumber();
    }
  }

  bool isFollow() {
    return state.followingList.value.any((userID) => userID == state.ownerId.value);
  }

  void dispose() {
    state.dispose();
  }
}

extension LiveInfoManagerCallback on LiveInfoManager {
  void onMyFollowingListChanged(List<V2TimUserFullInfo> userInfoList, bool isAdd) {
    final Set<String> followingList = Set.from(state.followingList.value);
    final userIDs = userInfoList.map((item) => item.userID ?? '').where((item) => item.isNotEmpty);
    if (isAdd) {
      followingList.addAll(userIDs);
    } else {
      followingList.removeAll(userIDs);
    }
    state.followingList.value = followingList;
  }

  void onMyFollowersListChanged(List<V2TimUserFullInfo> userInfoList, bool isAdd) {
    getFansNumber();
  }
}

extension on LiveInfoManager {
  void _syncUserFollowingStatus(String userId) async {
    final result = await friendshipManager.checkFollowType(userIDList: [userId]);
    const success = 0;
    if (result.code == success && result.data != null && result.data!.isNotEmpty) {
      final followType = IMFollowType.fromInt(result.data![0].followType ?? 0);
      final isFollow = followType == IMFollowType.inMyFollowingList || followType == IMFollowType.inBothFollowersList;

      final Set<String> followingList = Set.from(state.followingList.value);
      if (!isFollow) {
        followingList.removeWhere((userID) => userID == userId);
        state.followingList.value = followingList;
        return;
      }
      followingList.add(userId);
      state.followingList.value = followingList;
    }
  }
}
