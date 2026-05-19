import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import 'package:tencent_live_uikit/component/live_info/state/follow_define.dart';

class AnchorUserManagementPanelBase extends StatefulWidget {
  final LiveUserInfo user;
  final LiveStreamManager liveStreamManager;
  final Widget? child;

  const AnchorUserManagementPanelBase({
    super.key,
    required this.user,
    required this.liveStreamManager,
    this.child,
  });

  @override
  State<AnchorUserManagementPanelBase> createState() => _AnchorUserManagementPanelBaseState();
}

class _AnchorUserManagementPanelBaseState extends State<AnchorUserManagementPanelBase> {
  final ValueNotifier<bool> _isFollow = ValueNotifier(false);
  bool _enableFollowButton = true;

  @override
  void initState() {
    super.initState();
    _checkFollowType();
  }

  @override
  void dispose() {
    _isFollow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.screenWidth,
      constraints: BoxConstraints(minHeight: 88.height, maxHeight: 179.height),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(15.width), topRight: Radius.circular(15.width))),
      height: 179.height,
      child: Column(children: [
        SizedBox(height: 24.height),
        _buildUserInfoWidget(),
        SizedBox(height: 20.height),
        widget.child ?? const SizedBox.shrink(),
      ]),
    );
  }

  Widget _buildUserInfoWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.width),
      child: SizedBox(
        width: 1.screenWidth,
        child: Stack(
          children: [
            SizedBox(
              width: 40.width,
              height: 40.width,
              child: ClipOval(
                child: Image.network(widget.user.avatarURL, errorBuilder: (context, error, stackTrace) {
                  return Image.asset(LiveImages.defaultAvatar, package: Constants.pluginName);
                }),
              ),
            ),
            Positioned(
                top: 0,
                left: 52.width,
                right: widget.user.userID != LoginStore.shared.loginState.loginUserInfo?.userID ? 94.width : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.userName.isNotEmpty ? widget.user.userName : widget.user.userID,
                        style: const TextStyle(color: LiveColors.designStandardG6, fontSize: 16),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis),
                    Text('Id: ${widget.user.userID}',
                        style: const TextStyle(color: LiveColors.notStandardGrey, fontSize: 12),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis)
                  ],
                )),
            Positioned(
                top: 4.height,
                bottom: 4.height,
                right: 0,
                child: Visibility(
                  visible: widget.user.userID != LoginStore.shared.loginState.loginUserInfo?.userID,
                  child: ValueListenableBuilder(
                    valueListenable: _isFollow,
                    builder: (context, isFollow, child) {
                      return GestureDetector(
                        onTap: () => _followButtonClicked(),
                        child: Container(
                          width: 70.width,
                          height: 32.height,
                          decoration: BoxDecoration(
                              color: isFollow ? LiveColors.notStandardGreyC5 : LiveColors.notStandardBlue,
                              borderRadius: BorderRadius.circular(16.height)),
                          child: Center(
                            child: isFollow
                                ? Image.asset(
                                    LiveImages.followed,
                                    package: Constants.pluginName,
                                    width: 16.radius,
                                    height: 16.radius,
                                  )
                                : Text(
                                    LiveKitLocalizations.of(Global.appContext())!.common_follow_anchor,
                                    style: const TextStyle(
                                        fontSize: 12, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

extension on _AnchorUserManagementPanelBaseState {
  void _postToast(String message) {
    widget.liveStreamManager.toastSubject.add(message);
  }

  void _checkFollowType() async {
    final result =
        await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().checkFollowType(userIDList: [widget.user.userID]);
    if (result.code != 0 || result.data == null || result.data is! List<V2TimFollowTypeCheckResult>) {
      return;
    }
    final V2TimFollowTypeCheckResult? checkResult = result.data!.firstOrNull;
    if (checkResult == null) return;
    final followType = IMFollowType.fromInt(result.data![0].followType ?? 0);
    _isFollow.value = followType == IMFollowType.inMyFollowingList || followType == IMFollowType.inBothFollowersList;
  }

  void _followButtonClicked() async {
    if (!_enableFollowButton) return;
    _enableFollowButton = false;
    final friendshipManager = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();
    final userId = widget.user.userID;
    if (userId.isEmpty) return;

    if (_isFollow.value) {
      final result = await friendshipManager.unfollowUser(userIDList: [userId]);
      if (result.code != 0) {
        _postToast('code:${result.code}, message:${result.desc}');
        return;
      }
      final V2TimFollowOperationResult? followResult = result.data!.firstOrNull;
      if (followResult == null) {
        return;
      }
      _isFollow.value = false;
      _enableFollowButton = true;
    } else {
      final result = await friendshipManager.followUser(userIDList: [userId]);
      if (result.code != 0) {
        _postToast('code:${result.code}, message:${result.desc}');
        return;
      }
      final V2TimFollowOperationResult? followResult = result.data!.firstOrNull;
      if (followResult == null) {
        return;
      }
      _isFollow.value = true;
      _enableFollowButton = true;
    }
  }
}

class CommonMenuWidget extends StatelessWidget {
  final String? imageName;
  final String? title;
  final GestureTapCallback? onTap;

  const CommonMenuWidget({
    super.key,
    this.imageName,
    this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
              decoration: BoxDecoration(
                  color: LiveColors.designStandardG3.withAlpha(77), borderRadius: BorderRadius.circular(12.5.radius)),
              width: 50.radius,
              height: 50.radius,
              child: Center(
                child: imageName == null
                    ? const SizedBox.square()
                    : Image.asset(imageName!, package: Constants.pluginName, width: 25.radius, height: 25.radius),
              )),
          Text(
            title ?? '',
            style: const TextStyle(color: LiveColors.designStandardG6, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
