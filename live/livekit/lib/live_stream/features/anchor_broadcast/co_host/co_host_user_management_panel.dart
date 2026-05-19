import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../common/anchor_user_management_panel_base.dart';

class CoHostUserManagementPanel extends StatefulWidget {
  final SeatInfo seatInfo;
  final LiveStreamManager liveStreamManager;
  final VoidCallback closeCallback;

  const CoHostUserManagementPanel({
    super.key,
    required this.seatInfo,
    required this.liveStreamManager,
    required this.closeCallback,
  });

  @override
  State<CoHostUserManagementPanel> createState() => _CoHostUserManagementPanelState();
}

class _CoHostUserManagementPanelState extends State<CoHostUserManagementPanel> {
  final ValueNotifier<bool> _isMicrophoneMuted = ValueNotifier(true);
  final ValueNotifier<bool> _isCameraOpened = ValueNotifier(false);
  late final LiveUserInfo user;
  late final LiveSeatStore liveSeatStore;
  late final VoidCallback _onSeatListListener = _onSeatListChanged;
  late final CoHostStore coHostStore;
  late final VoidCallback _onCoHostConnectedListener = _onCoHostConnectedChanged;

  @override
  void initState() {
    super.initState();
    final userInfo = widget.seatInfo.userInfo;
    user = LiveUserInfo(userID: userInfo.userID, userName: userInfo.userName, avatarURL: userInfo.avatarURL);
    liveSeatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
    liveSeatStore.liveSeatState.seatList.addListener(_onSeatListListener);
    _onSeatListChanged();
    coHostStore = CoHostStore.create(widget.liveStreamManager.roomState.roomId);
    coHostStore.coHostState.connected.addListener(_onCoHostConnectedListener);
  }

  @override
  void dispose() {
    liveSeatStore.liveSeatState.seatList.removeListener(_onSeatListListener);
    coHostStore.coHostState.connected.removeListener(_onCoHostConnectedListener);
    _isMicrophoneMuted.dispose();
    _isCameraOpened.dispose();
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
    // Mute remote audio
    children.add(
      ValueListenableBuilder(
        valueListenable: _isMicrophoneMuted,
        builder: (context, isMicrophoneMuted, child) {
          return CommonMenuWidget(
            imageName: isMicrophoneMuted ? LiveImages.anchorUnmute : LiveImages.disableAudio,
            title: isMicrophoneMuted
                ? LiveKitLocalizations.of(context)!.common_unmute_audio
                : LiveKitLocalizations.of(context)!.common_mute_audio,
            onTap: () {
              widget.closeCallback.call();
              final liveInfo = LiveListStore.shared.liveState.currentLive.value;
              if (liveInfo.liveID.isEmpty) return;
              final liveID = widget.seatInfo.userInfo.liveID;
              final isMute = !isMicrophoneMuted;
              CoHostStore.create(liveInfo.liveID).muteRemoteHostAudio(liveID: liveID, isMuted: isMute).then((result) {
                if (result.errorCode != TUIError.success.rawValue) {
                  widget.liveStreamManager.toastSubject
                      .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
                }
              });
            },
          );
        },
      ),
    );
    return children;
  }
}

extension on _CoHostUserManagementPanelState {
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

  void _onCoHostConnectedChanged() {
    bool isConnected =
        coHostStore.coHostState.connected.value.any((user) => user.liveID == widget.seatInfo.userInfo.liveID);
    if (!isConnected) widget.closeCallback.call();
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

  void _flipButtonClicked() {
    DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
    widget.closeCallback.call();
  }
}
