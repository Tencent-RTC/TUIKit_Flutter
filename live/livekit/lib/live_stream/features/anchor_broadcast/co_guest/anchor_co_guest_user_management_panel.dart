import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../common/anchor_user_management_panel_base.dart';

class AnchorCoGuestUserManagementPanel extends StatefulWidget {
  final SeatInfo seatInfo;
  final LiveStreamManager liveStreamManager;
  final VoidCallback closeCallback;

  const AnchorCoGuestUserManagementPanel({
    super.key,
    required this.seatInfo,
    required this.liveStreamManager,
    required this.closeCallback,
  });

  @override
  State<AnchorCoGuestUserManagementPanel> createState() => _AnchorCoGuestUserManagementPanelState();
}

class _AnchorCoGuestUserManagementPanelState extends State<AnchorCoGuestUserManagementPanel> {
  final ValueNotifier<bool> _isMicrophoneMuted = ValueNotifier(true);
  final ValueNotifier<bool> _isCameraOpened = ValueNotifier(false);
  AlertHandler? _kickOutOfSeatAlertHandler;
  late final LiveUserInfo user;
  late final LiveSeatStore liveSeatStore;
  late final VoidCallback _onSeatListListener = _onSeatListChanged;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    final userInfo = widget.seatInfo.userInfo;
    user = LiveUserInfo(userID: userInfo.userID, userName: userInfo.userName, avatarURL: userInfo.avatarURL);
    liveSeatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
    liveSeatStore.liveSeatState.seatList.addListener(_onSeatListListener);
    _onSeatListChanged();
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_floatWindowModeListener);
  }

  @override
  void dispose() {
    _kickOutOfSeatAlertHandler?.close();
    _isMicrophoneMuted.dispose();
    _isCameraOpened.dispose();
    liveSeatStore.liveSeatState.seatList.removeListener(_onSeatListListener);
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_floatWindowModeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnchorUserManagementPanelBase(
      user: user,
      liveStreamManager: widget.liveStreamManager,
      child: _buildMenuWidget(),
    );
  }

  Widget _buildMenuWidget() {
    final selfID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (selfID.isEmpty) return const SizedBox.shrink();
    List<Widget> children = selfID == user.userID ? _buildForSelfChildren() : _buildForRemoteChildren();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.width),
      child: Container(
        constraints: BoxConstraints(maxWidth: 327.width),
        height: 77.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20.width,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _buildForSelfChildren() {
    final children = <Widget>[];
    // Mute microphone
    children.add(ValueListenableBuilder(
      valueListenable: _isMicrophoneMuted,
      builder: (context, isMicrophoneMuted, child) {
        return CommonMenuWidget(
          imageName: isMicrophoneMuted ? LiveImages.anchorMute : LiveImages.anchorUnmute,
          title: isMicrophoneMuted
              ? LiveKitLocalizations.of(context)!.common_voiceroom_unmuted_seat
              : LiveKitLocalizations.of(context)!.common_voiceroom_mute_seat,
          onTap: () => _localMicrophoneButtonClicked(),
        );
      },
    ));

    // Switch camera
    children.add(ValueListenableBuilder(
        valueListenable: _isCameraOpened,
        builder: (context, isCameraOpened, _) {
          return Visibility(
            visible: isCameraOpened,
            child: CommonMenuWidget(
              imageName: LiveImages.settingsItemFlip,
              title: LiveKitLocalizations.of(context)!.common_video_settings_item_flip,
              onTap: () => _flipButtonClicked(),
            ),
          );
        }));
    return children;
  }

  List<Widget> _buildForRemoteChildren() {
    final children = <Widget>[];
    // lockAudio
    children.add(
      ValueListenableBuilder(
        valueListenable: widget.liveStreamManager.coGuestState.lockAudioUserList,
        builder: (context, lockAudioUserList, child) {
          final isAudioLocked = _isAudioLocked();
          return CommonMenuWidget(
            imageName: isAudioLocked ? LiveImages.disableAudio : LiveImages.anchorUnmute,
            title: isAudioLocked
                ? LiveKitLocalizations.of(context)!.common_enable_audio
                : LiveKitLocalizations.of(context)!.common_disable_audio,
            onTap: () => _remoteMicrophoneButtonClicked(),
          );
        },
      ),
    );

    // lockVideo (seatTemplate is not 200)
    if (widget.liveStreamManager.roomState.liveInfo.seatTemplate is! VideoLandscape4Seats) {
      children.add(
        ValueListenableBuilder(
          valueListenable: widget.liveStreamManager.coGuestState.lockVideoUserList,
          builder: (context, lockVideoUserList, child) {
            final isVideoLocked = _isVideoLocked();
            return CommonMenuWidget(
              imageName: isVideoLocked ? LiveImages.disableCamera : LiveImages.openCamera,
              title: isVideoLocked
                  ? LiveKitLocalizations.of(context)!.common_enable_video
                  : LiveKitLocalizations.of(context)!.common_disable_video,
              onTap: () => _remoteCameraButtonClicked(),
            );
          },
        ),
      );
    }

    // kickout
    children.add(CommonMenuWidget(
      imageName: LiveImages.leaveSeat,
      title: LiveKitLocalizations.of(context)!.common_end_user,
      onTap: () => _kickOutOfSeatButtonClicked(),
    ));

    return children;
  }
}

extension on _AnchorCoGuestUserManagementPanelState {
  void _onSeatListChanged() {
    final seatList = liveSeatStore.liveSeatState.seatList.value;
    final isScreenShareLive = widget.liveStreamManager.roomManager.isScreenShareLive();
    for (var seat in seatList) {
      if (seat.userInfo.userID == user.userID) {
        _isCameraOpened.value = seat.userInfo.cameraStatus == DeviceStatus.on && !isScreenShareLive;
        _isMicrophoneMuted.value = seat.userInfo.microphoneStatus != DeviceStatus.on;
        break;
      }
    }
  }

  void _onFloatWindowModeChanged() {
    bool isFloatWindowMode = widget.liveStreamManager.floatWindowState.isFloatWindowMode.value;
    if (isFloatWindowMode) {
      _closeKickOutOfSeatAlert();
    }
  }

  void _localMicrophoneButtonClicked() {
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
    widget.closeCallback.call();
  }

  void _localCameraButtonClicked() {
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
    widget.closeCallback.call();
  }

  void _flipButtonClicked() {
    DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
    widget.closeCallback.call();
  }

  void _remoteMicrophoneButtonClicked() async {
    final lockParams = TUISeatLockParams();
    lockParams.lockAudio = !_isAudioLocked();
    lockParams.lockVideo = _isVideoLocked();
    widget.liveStreamManager.onLockMediaStatusBtnClicked(user.userID, lockParams).then((result) {
      if (result.code != TUIError.success) {
        widget.liveStreamManager.toastSubject
            .add(ErrorHandler.convertToErrorMessage(result.code.rawValue, result.message) ?? '');
      }
    });
    widget.closeCallback.call();
  }

  void _remoteCameraButtonClicked() {
    final lockParams = TUISeatLockParams();
    lockParams.lockAudio = _isAudioLocked();
    lockParams.lockVideo = !_isVideoLocked();
    widget.liveStreamManager.onLockMediaStatusBtnClicked(user.userID, lockParams).then((result) {
      if (result.code != TUIError.success) {
        widget.liveStreamManager.toastSubject
            .add(ErrorHandler.convertToErrorMessage(result.code.rawValue, result.message) ?? '');
      }
    });
    widget.closeCallback.call();
  }

  void _kickOutOfSeatButtonClicked() {
    String userName = user.userName;
    if (userName.isEmpty) userName = user.userID;
    final alertInfo = AlertInfo(
        isDestructive: true,
        description:
            LiveKitLocalizations.of(Global.appContext())!.common_disconnect_guest_tips.replaceAll("xxx", userName),
        cancelText: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        cancelCallback: () => _closeKickOutOfSeatAlert(),
        defaultText: LiveKitLocalizations.of(Global.appContext())!.common_down,
        defaultCallback: () {
          liveSeatStore.kickUserOutOfSeat(user.userID).then((result) {
            widget.liveStreamManager.toastSubject
                .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
          });
          _closeKickOutOfSeatAlert();
        });

    _kickOutOfSeatAlertHandler = Alert.showAlert(alertInfo, context);
  }

  void _closeKickOutOfSeatAlert() {
    _kickOutOfSeatAlertHandler?.close();
    widget.closeCallback.call();
  }

  bool _isAudioLocked() {
    return widget.liveStreamManager.coGuestState.lockAudioUserList.value.contains(user.userID);
  }

  bool _isVideoLocked() {
    return widget.liveStreamManager.coGuestState.lockVideoUserList.value.contains(user.userID);
  }
}
