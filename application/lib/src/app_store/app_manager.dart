import 'package:flutter/cupertino.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import 'app_store.dart';


class AppManager {
  static const String tag = 'IMManager';

  static Future<void> getUserInfo(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    var result = await TencentImSDKPlugin.v2TIMManager.getUsersInfo(userIDList: [userId]);
    AppStore.userName.value = result.data?[0].nickName ?? "";
    AppStore.userAvatar = result.data?[0].faceUrl ?? "";
    return;
  }

  static Future<CompletionHandler> setSelfInfo(String avatar, String nickname) async {
    final result = await LoginStore.shared.setSelfInfo(
      userInfo: UserProfile(
        userID: LoginStore.shared.loginState.loginUserInfo?.userID ?? '',
        avatarURL: avatar,
        nickname: nickname,
      ),
    );

    if (result.isSuccess) {
      AppStore.userName.value = nickname;
      AppStore.userAvatar = avatar;
    }
    return result;
  }

  static void getUserFollowInfo(String userId) async {
    List<String> userIDList = [userId];

    var result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getUserFollowInfo(userIDList: userIDList);
    if (result.data == null) {
      debugPrint("getUserFollowInfo result(code: $result.code), msg:${result.desc}");
      return;
    }
    List<V2TimFollowInfo>? followInfo = result.data;
    if (followInfo != null && followInfo.isNotEmpty) {
      V2TimFollowInfo result = followInfo[0];
      AppStore.followCount.value = (result.followingCount == null ? 0 : result.followingCount!);
      AppStore.fansCount.value = (result.followersCount == null ? 0 : result.followersCount!);
    }
  }
}

class TUIResult {
  int code;
  String? message;

  TUIResult({
    required this.code,
    required this.message,
  });
}
