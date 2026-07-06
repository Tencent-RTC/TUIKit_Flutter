import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';

import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_live_uikit/common/error/error_handler.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';

import '../../../../../common/constants/constants.dart';
import '../../../../../common/language/index.dart';
import '../../../../../common/resources/colors.dart';
import '../../../../../common/resources/images.dart';
import '../../../../../common/widget/index.dart';
import '../../../../../common/screen/index.dart';
import '../../../../common/logger/logger.dart';
import '../../../../component/live_info/state/follow_define.dart';
import '../../../../live_navigator_observer.dart';

class AudienceUserInfoPanelWidget extends StatefulWidget {
  final LiveUserInfo user;
  final String? liveID;
  final LiveStreamManager liveStreamManager;
  final VoidCallback? onExitRoom;
  final VoidCallback? onClose;
  final bool enableFollow;
  final bool enableEnterRoom;

  const AudienceUserInfoPanelWidget({
    super.key,
    required this.user,
    required this.liveStreamManager,
    this.liveID,
    this.onExitRoom,
    this.onClose,
    this.enableFollow = true,
    this.enableEnterRoom = false,
  });

  @override
  State<AudienceUserInfoPanelWidget> createState() => _AudienceUserInfoPanelWidgetState();
}

class _AudienceUserInfoPanelWidgetState extends State<AudienceUserInfoPanelWidget> {
  late final String liveID;
  final ValueNotifier<bool> _isFollow = ValueNotifier(false);
  final ValueNotifier<int> _fansNumber = ValueNotifier(0);

  late final VoidCallback _coHostConnectedListener = _onCoHostConnectedChanged;

  CoHostStore? _coHostStore;

  @override
  void initState() {
    super.initState();
    liveID = widget.liveID ?? widget.liveStreamManager.roomState.roomId;
    _getFansCount();
    _checkFollowType();
    if (widget.enableEnterRoom) {
      final liveInfo = LiveListStore.shared.liveState.currentLive.value;
      if (liveInfo.liveID.isEmpty) return;
      _coHostStore = CoHostStore.create(liveInfo.liveID);
      _coHostStore!.coHostState.connected.addListener(_coHostConnectedListener);
    }
  }

  @override
  void dispose() {
    _isFollow.dispose();
    _fansNumber.dispose();
    _coHostStore?.coHostState.connected.removeListener(_coHostConnectedListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 281.height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _buildBackground(),
          _buildUserAvatarWidget(),
          _buildUserNameWidget(),
          _buildLiveIDWidget(),
          _buildFansWidget(),
          _buildFollowWidget(),
          _buildEnterRoomWidget(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
        margin: EdgeInsets.only(top: 30.height),
        width: MediaQuery.sizeOf(context).width,
        height: 251.height,
        decoration: BoxDecoration(
          color: LiveColors.designStandardG2,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20.radius), topRight: Radius.circular(20.radius)),
        ));
  }

  Widget _buildUserAvatarWidget() {
    return Container(
        margin: EdgeInsets.only(left: 4.width, right: 8.width),
        width: 56.radius,
        height: 56.radius,
        child: ClipOval(
          child: Image.network(
            widget.user.avatarURL,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                LiveImages.defaultAvatar,
                package: Constants.pluginName,
              );
            },
          ),
        ));
  }

  Widget _buildUserNameWidget() {
    return Positioned(
      top: 64.height,
      width: 1.screenWidth,
      child: Text(
        widget.user.userName.isNotEmpty ? widget.user.userName : widget.user.userID,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
      ),
    );
  }

  Widget _buildLiveIDWidget() {
    return Positioned(
      top: 94.height,
      width: 1.screenWidth,
      child: Text(
        LiveKitLocalizations.of(Global.appContext())!.common_room_info_liveroom_id + liveID,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
      ),
    );
  }

  Widget _buildFansWidget() {
    return Positioned(
      top: 119.height,
      width: 275.width,
      child: ValueListenableBuilder(
        valueListenable: _fansNumber,
        builder: (context, fansNumber, child) {
          return Text(
            fansNumber.toString() + LiveKitLocalizations.of(Global.appContext())!.common_fan_count,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
          );
        },
      ),
    );
  }

  Widget _buildFollowWidget() {
    return Positioned(
      top: 144.height,
      width: 275.width,
      height: 40.height,
      child: Visibility(
        visible: widget.enableFollow,
        child: ValueListenableBuilder(
          valueListenable: _isFollow,
          builder: (context, isFollow, child) {
            return GestureDetector(
              onTap: () {
                _followButtonClicked();
              },
              child: Container(
                margin: EdgeInsets.only(left: 14.width, right: 4.width),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.radius),
                  color: isFollow ? LiveColors.designStandardG3 : LiveColors.designStandardB1,
                ),
                alignment: Alignment.center,
                child: Text(
                  isFollow
                      ? LiveKitLocalizations.of(Global.appContext())!.common_unfollow_anchor
                      : LiveKitLocalizations.of(Global.appContext())!.common_follow_anchor,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnterRoomWidget() {
    return Positioned(
      top: 200.height,
      width: 275.width,
      height: 40.height,
      child: Visibility(
        visible: widget.enableEnterRoom,
        child: GestureDetector(
          onTap: () => _gotoNewLiveRoom(),
          child: Container(
            margin: EdgeInsets.only(left: 14.width, right: 4.width),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.radius),
              color: LiveColors.designStandardB1,
            ),
            alignment: Alignment.center,
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_enter_anchor_live_room,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.normal, color: LiveColors.designStandardG7),
            ),
          ),
        ),
      ),
    );
  }
}

extension on _AudienceUserInfoPanelWidgetState {
  void _getFansCount() async {
    final result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .getUserFollowInfo(userIDList: [widget.user.userID]);
    if (result.code != 0 || result.data == null || result.data is! List<V2TimFollowInfo>) {
      return;
    }
    final V2TimFollowInfo? followInfo = result.data!.firstOrNull;
    if (followInfo == null) {
      return;
    }
    _fansNumber.value = followInfo.followersCount ?? 0;
  }

  void _checkFollowType() async {
    final result =
        await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().checkFollowType(userIDList: [widget.user.userID]);
    if (result.code != 0 || result.data == null || result.data is! List<V2TimFollowTypeCheckResult>) {
      return;
    }
    final V2TimFollowTypeCheckResult? checkResult = result.data!.firstOrNull;
    if (checkResult == null) {
      return;
    }
    final followType = IMFollowType.fromInt(result.data![0].followType ?? 0);
    _isFollow.value = followType == IMFollowType.inMyFollowingList || followType == IMFollowType.inBothFollowersList;
  }

  void _followButtonClicked() async {
    final friendshipManager = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();
    final userId = widget.user.userID;
    if (userId.isEmpty) {
      return;
    }

    if (!_isFollow.value) {
      final result = await friendshipManager.followUser(userIDList: [userId]);
      if (result.code != 0) {
        widget.liveStreamManager.toastSubject.add('code:${result.code}, message:${result.desc}');
        return;
      }
      final V2TimFollowOperationResult? followResult = result.data!.firstOrNull;
      if (followResult == null) {
        return;
      }
      _fansNumber.value += 1;
      _isFollow.value = true;
    } else {
      final result = await friendshipManager.unfollowUser(userIDList: [userId]);
      if (result.code != 0) {
        widget.liveStreamManager.toastSubject.add('code:${result.code}, message:${result.desc}');
        return;
      }
      final V2TimFollowOperationResult? followResult = result.data!.firstOrNull;
      if (followResult == null) {
        return;
      }
      _fansNumber.value -= 1;
      _isFollow.value = false;
    }
  }

  void _gotoNewLiveRoom() async {
    LiveKitLogger.info("_gotoNewLiveRoom enter");
    widget.onClose?.call();
    if (widget.onExitRoom == null || widget.liveID == null) {
      LiveKitLogger.warning("onExitRoom or liveID is null");
      return;
    }
    try {
      final result = await LiveListStore.shared.fetchLiveInfo(widget.liveID!);
      if (!result.isSuccess) {
        makeToast(Global.appContext(), ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        return;
      }
      TUILiveKitNavigatorObserver.instance.enteringRoomID.value = result.liveInfo.liveID;
      await LiveListStore.shared.leaveLive();
      if (mounted) widget.onExitRoom!.call();
      if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
        GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
      }
      TUILiveKitNavigatorObserver.instance.enterLiveRoomPage(Global.appContext(), result.liveInfo);
    } on Exception catch (e) {
      LiveKitLogger.error(e.toString());
      TUILiveKitNavigatorObserver.instance.enteringRoomID.value = '';
    }
  }

  void _onCoHostConnectedChanged() {
    if (_coHostStore == null) return;
    bool isHost = _coHostStore!.coHostState.connected.value.any((user) => user.liveID == widget.liveID);
    if (!isHost) widget.onClose?.call();
  }
}
