import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/follow_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class PlayerFollowService extends ChangeNotifier {
  PlayerFollowService._();

  static final PlayerFollowService shared = PlayerFollowService._();

  final Map<String, bool> _following = <String, bool>{};
  final Set<String> _loading = <String>{};
  V2TimFriendshipListener? _friendshipListener;

  /// 对应 iOS `HostInfoView.registerFriendshipListener`：订阅我的关注列表变化，
  /// 其他端改关注后重新拉取关注类型。
  Future<void> startListening() async {
    if (_friendshipListener != null) return;
    final V2TimFriendshipListener listener = V2TimFriendshipListener(
      onMyFollowingListChanged:
          (List<V2TimUserFullInfo> userInfoList, bool isAdd) {
        final List<String> userIDs = userInfoList
            .map((V2TimUserFullInfo info) => info.userID ?? '')
            .where((String userID) => userID.isNotEmpty)
            .toList(growable: false);
        if (userIDs.isEmpty) return;
        unawaited(_refreshFollowTypes(userIDs));
      },
    );
    _friendshipListener = listener;
    try {
      await TencentImSDKPlugin.v2TIMManager
          .getFriendshipManager()
          .addFriendListener(listener: listener);
    } on Object {
      _friendshipListener = null;
    }
  }

  Future<void> stopListening() async {
    final V2TimFriendshipListener? listener = _friendshipListener;
    if (listener == null) return;
    _friendshipListener = null;
    try {
      await TencentImSDKPlugin.v2TIMManager
          .getFriendshipManager()
          .removeFriendListener(listener: listener);
    } on Object {
      // 监听器移除失败不改变本端已缓存的关注展示。
    }
  }

  Future<void> _refreshFollowTypes(List<String> userIDs) async {
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getFriendshipManager()
          .checkFollowType(userIDList: userIDs);
      if (result.code != 0 || result.data == null) return;
      for (final item in result.data!) {
        final String? userID = item.userID;
        if (userID == null || userID.isEmpty) continue;
        final int type =
            item.followType ?? FollowType.V2TIM_FOLLOW_TYPE_NONE;
        _following[userID] = _isFollowed(type);
      }
      notifyListeners();
    } on Object {
      // 拉取失败保留上次展示，不把失败当成未关注。
    }
  }

  static bool _isFollowed(int type) {
    return type == FollowType.V2TIM_FOLLOW_TYPE_IN_MY_FOLLOWING_LIST ||
        type == FollowType.V2TIM_FOLLOW_TYPE_IN_BOTH_FOLLOWERS_LIST;
  }

  bool isFollowing(String userID) => _following[userID] ?? false;

  bool isLoading(String userID) => _loading.contains(userID);

  Future<String?> refresh(String userID) async {
    if (userID.isEmpty || _loading.contains(userID)) return null;
    _loading.add(userID);
    notifyListeners();
    try {
      final result = await TencentImSDKPlugin.v2TIMManager
          .getFriendshipManager()
          .checkFollowType(userIDList: <String>[userID]);
      if (result.code != 0 || result.data == null || result.data!.isEmpty) {
        return result.desc;
      }
      _following[userID] =
          _isFollowed(result.data!.first.followType ?? FollowType.V2TIM_FOLLOW_TYPE_NONE);
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _loading.remove(userID);
      notifyListeners();
    }
  }

  Future<String?> toggle(String userID) async {
    if (userID.isEmpty || _loading.contains(userID)) return null;
    final bool nextValue = !isFollowing(userID);
    _loading.add(userID);
    notifyListeners();
    try {
      final manager = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();
      final result = nextValue
          ? await manager.followUser(userIDList: <String>[userID])
          : await manager.unfollowUser(userIDList: <String>[userID]);
      final bool itemSucceeded = result.data == null ||
          result.data!.isEmpty ||
          (result.data!.first.resultCode ?? 0) == 0;
      if (result.code != 0 || !itemSucceeded) {
        final String itemMessage = result.data?.first.resultInfo ?? '';
        return itemMessage.isEmpty ? result.desc : itemMessage;
      }
      _following[userID] = nextValue;
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _loading.remove(userID);
      notifyListeners();
    }
  }

  void update(String userID, bool following) {
    if (userID.isEmpty || _following[userID] == following) return;
    _following[userID] = following;
    notifyListeners();
  }
}
