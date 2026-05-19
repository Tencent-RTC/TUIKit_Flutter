import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../../../../component/live_info/state/follow_define.dart';

class AudienceUserManagementPanelWidget extends StatefulWidget {
  final LiveUserInfo user;
  final LiveStreamManager liveStreamManager;
  final VoidCallback closeCallback;

  const AudienceUserManagementPanelWidget({
    super.key,
    required this.user,
    required this.liveStreamManager,
    required this.closeCallback,
  });

  @override
  State<AudienceUserManagementPanelWidget> createState() => _AudienceUserManagementPanelWidgetState();
}

class _AudienceUserManagementPanelWidgetState extends State<AudienceUserManagementPanelWidget> {
  final ValueNotifier<bool> _isFollow = ValueNotifier(false);
  final ValueNotifier<bool> _isMicrophoneMuted = ValueNotifier(true);
  final ValueNotifier<bool> _isCameraOpened = ValueNotifier(false);

  bool _enableFollowButton = true;
  AlertHandler? _leaveSeatAlertHandler;

  late final LiveSeatStore liveSeatStore;
  late final VoidCallback _onSeatListListener = _onSeatListChanged;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    _checkFollowType();
    liveSeatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
    liveSeatStore.liveSeatState.seatList.addListener(_onSeatListListener);
    _onSeatListChanged();
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_floatWindowModeListener);
  }

  @override
  void dispose() {
    _leaveSeatAlertHandler?.close();
    liveSeatStore.liveSeatState.seatList.removeListener(_onSeatListListener);
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_floatWindowModeListener);
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
        _buildMenuWidget()
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
                right: 94.width,
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
                child: ValueListenableBuilder(
                  valueListenable: _isFollow,
                  builder: (context, isFollow, child) {
                    return Visibility(
                      visible: widget.user.userID != TUIRoomEngine.getSelfInfo().userId,
                      child: GestureDetector(
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
                      ),
                    );
                  },
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildMenuWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.width),
      child: Container(
        constraints: BoxConstraints(maxWidth: 327.width),
        height: 77.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20.width,
          children: _buildMenuItemList(),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItemList() {
    List<Widget> children = [];
    children.add(ListenableBuilder(
      listenable: Listenable.merge([_isMicrophoneMuted, widget.liveStreamManager.mediaState.isAudioLocked]),
      builder: (context, child) {
        final isMicrophoneMuted = _isMicrophoneMuted.value;
        final isAudioLocked = widget.liveStreamManager.mediaState.isAudioLocked.value;
        return CommonMenuWidget(
          imageName: isMicrophoneMuted ? LiveImages.muteMicrophone : LiveImages.unmuteMicrophone,
          title: isMicrophoneMuted
              ? LiveKitLocalizations.of(context)!.common_voiceroom_unmuted_seat
              : LiveKitLocalizations.of(context)!.common_voiceroom_mute_seat,
          opacity: isAudioLocked ? 0.5 : 1.0,
          onTap: () => _microphoneButtonClicked(),
        );
      },
    ));

    if (widget.liveStreamManager.roomState.liveInfo.seatTemplate is! VideoLandscape4Seats) {
      children.add(ListenableBuilder(
        listenable: Listenable.merge([_isCameraOpened, widget.liveStreamManager.mediaState.isVideoLocked]),
        builder: (context, child) {
          final isCameraOpened = _isCameraOpened.value;
          final isVideoLocked = widget.liveStreamManager.mediaState.isVideoLocked.value;
          return CommonMenuWidget(
            imageName: isCameraOpened ? LiveImages.openCamera : LiveImages.closeCamera,
            title: isCameraOpened
                ? LiveKitLocalizations.of(context)!.common_stop_video
                : LiveKitLocalizations.of(context)!.common_start_video,
            opacity: isVideoLocked ? 0.5 : 1.0,
            onTap: () => _cameraButtonClicked(),
          );
        },
      ));

      if (_isCameraOpened.value) {
        children.add(CommonMenuWidget(
            imageName: LiveImages.videoSettingsFlip,
            title: LiveKitLocalizations.of(context)!.common_video_settings_item_flip,
            onTap: () => _flipButtonClicked()));
      }
    }

    children.add(CommonMenuWidget(
      imageName: LiveImages.leaveSeat,
      title: LiveKitLocalizations.of(context)!.common_end_user,
      onTap: () => _leaveSeatButtonClicked(),
    ));
    return children;
  }
}

extension on _AudienceUserManagementPanelWidgetState {
  void _onSeatListChanged() {
    final seatList = liveSeatStore.liveSeatState.seatList.value;
    final isScreenShareLive = widget.liveStreamManager.roomManager.isScreenShareLive();
    for (var seat in seatList) {
      if (seat.userInfo.userID == widget.user.userID) {
        _isCameraOpened.value = seat.userInfo.cameraStatus == DeviceStatus.on && !isScreenShareLive;
        _isMicrophoneMuted.value = seat.userInfo.microphoneStatus != DeviceStatus.on;
        break;
      }
    }
  }

  void _onFloatWindowModeChanged() {
    bool isFloatWindowMode = widget.liveStreamManager.floatWindowState.isFloatWindowMode.value;
    if (isFloatWindowMode) {
      widget.closeCallback.call();
    }
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
    if (_enableFollowButton == false) {
      return;
    }
    _enableFollowButton = false;
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
      _isFollow.value = true;
      _enableFollowButton = true;
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
      _isFollow.value = false;
      _enableFollowButton = true;
    }
  }

  void _microphoneButtonClicked() {
    widget.closeCallback.call();
    final isAudioLocked = widget.liveStreamManager.mediaState.isAudioLocked.value;
    if (isAudioLocked) {
      return;
    }

    LiveSeatStore liveSeatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
    final isMicrophoneMuted = _isMicrophoneMuted.value;
    if (isMicrophoneMuted) {
      liveSeatStore.unmuteMicrophone().then((result) {
        if (result.errorCode != TUIError.success.rawValue) {
          widget.liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        }
      });
    } else {
      liveSeatStore.muteMicrophone();
    }
  }

  void _cameraButtonClicked() {
    widget.closeCallback.call();
    final isVideoLocked = widget.liveStreamManager.mediaState.isVideoLocked.value;
    if (isVideoLocked) {
      return;
    }

    final isCameraOpened = _isCameraOpened.value;
    if (isCameraOpened) {
      widget.liveStreamManager.mediaManager.closeLocalCamera();
    } else {
      final isFrontCamera = DeviceStore.shared.state.isFrontCamera.value;
      widget.liveStreamManager.mediaManager.openLocalCamera(isFrontCamera).then((result) {
        if (result.code != TUIError.success) {
          widget.liveStreamManager.toastSubject
              .add(ErrorHandler.convertToErrorMessage(result.code.rawValue, result.message) ?? '');
        }
      });
    }
  }

  void _flipButtonClicked() {
    widget.closeCallback.call();
    final isFrontCamera = DeviceStore.shared.state.isFrontCamera.value;
    DeviceStore.shared.switchCamera(!isFrontCamera);
  }

  void _leaveSeatButtonClicked() {
    final alertInfo = AlertInfo(
        description: LiveKitLocalizations.of(Global.appContext())!.common_terminate_room_connection_message,
        cancelText: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        cancelCallback: () => _closeLeaveSeatAlert(),
        defaultText: LiveKitLocalizations.of(Global.appContext())!.common_end_link,
        defaultCallback: () {
          CoGuestStore coGuestStore = CoGuestStore.create(widget.liveStreamManager.roomState.roomId);
          coGuestStore.disconnect();
          _closeLeaveSeatAlert();
        });

    _leaveSeatAlertHandler = Alert.showAlert(alertInfo, context);
  }

  void _closeLeaveSeatAlert() {
    _leaveSeatAlertHandler?.close();
    widget.closeCallback.call();
  }
}

class CommonMenuWidget extends StatelessWidget {
  final String? imageName;
  final String? title;
  final double opacity;
  final GestureTapCallback? onTap;

  const CommonMenuWidget({
    super.key,
    this.imageName,
    this.title,
    this.opacity = 1,
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
                    : Opacity(
                        opacity: opacity,
                        child: Image.asset(imageName!,
                            package: Constants.pluginName, width: 25.radius, height: 25.radius)),
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
