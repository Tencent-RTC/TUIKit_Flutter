import 'dart:io';

import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'main/room_widget.dart';
import 'main/room_widget/room_exit_widget.dart';
import 'main/room_top_bar_widget.dart';
import 'main/room_bottom_bar_widget.dart';

sealed class RoomBehavior {
  const RoomBehavior();

  const factory RoomBehavior.create(CreateRoomOptions options) = CreateRoom;
  const factory RoomBehavior.enter() = EnterRoom;
}

class CreateRoom extends RoomBehavior {
  final CreateRoomOptions options;
  const CreateRoom(this.options);
}

class EnterRoom extends RoomBehavior {
  const EnterRoom();
}

class ConnectConfig {
  final bool autoEnableMicrophone;
  final bool autoEnableCamera;
  final bool autoEnableSpeaker;

  const ConnectConfig({
    required this.autoEnableMicrophone,
    required this.autoEnableCamera,
    required this.autoEnableSpeaker,
  });
}

class RoomMainWidget extends StatefulWidget {
  final String roomID;
  final RoomBehavior behavior;
  final ConnectConfig config;

  const RoomMainWidget({super.key, required this.roomID, required this.behavior, required this.config});

  @override
  State<RoomMainWidget> createState() => _RoomMainWidgetState();
}

class _RoomMainWidgetState extends State<RoomMainWidget> {
  final RoomStore _roomStore = RoomStore.shared;
  late final RoomListener _roomListener;
  late final RoomParticipantStore _participantStore;
  late final RoomParticipantListener _participantListener;

  final _deviceStore = DeviceStore.shared;

  String? _inviteCameraAlertId;
  String? _inviteMicAlertId;

  @override
  void initState() {
    super.initState();
    _createOrEnterRoom();
    _initStore();
    _enableWakeLock();
    _startForegroundService();
    _participantStore.addRoomParticipantListener(_participantListener);
    _roomStore.addRoomListener(_roomListener);
  }

  @override
  void dispose() {
    _participantStore.removeRoomParticipantListener(_participantListener);
    _roomStore.removeRoomListener(_roomListener);
    _deviceStore.reset();
    _disableWakeLock();
    _stopForegroundService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        popupWidget(
          RoomExitWidget(
            onExit: () {
              Navigator.of(context).pop();
            },
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1014),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return _buildContent(orientation);
          },
        ),
      ),
    );
  }
}

extension _RoomMainWidgetStatePrivate on _RoomMainWidgetState {
  Widget _buildContent(Orientation orientation) {
    return Stack(
      children: [
        Column(
          children: [
            Visibility(
              visible: orientation == Orientation.portrait,
              child: SizedBox(height: 105.height),
            ),
            Center(
              child: SizedBox(
                width: orientation == Orientation.portrait ? MediaQuery.of(context).size.width : 648.width,
                height: orientation == Orientation.portrait ? 621.height : MediaQuery.of(context).size.height,
                child: RoomWidget(roomId: widget.roomID),
              ),
            ),
          ],
        ),
        RoomTopBarWidget(roomId: widget.roomID, orientation: orientation),
        Column(
          children: [
            const Expanded(child: SizedBox()),
            RoomBottomBarWidget(roomId: widget.roomID, orientation: orientation),
          ],
        ),
      ],
    );
  }

  void _createOrEnterRoom() async {
    switch (widget.behavior) {
      case CreateRoom(:final options):
        final result = await _roomStore.createAndJoinRoom(roomID: widget.roomID, options: options);
        _initMediaState();
        if (!result.isSuccess && mounted) {
          Toast.error(context, ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return;
        }
      case EnterRoom():
        final result = await _roomStore.joinRoom(roomID: widget.roomID);
        _initMediaState();
        if (!result.isSuccess && mounted) {
          Toast.error(context, ErrorLocalized.convertToErrorMessage(result.errorCode, result.errorMessage));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return;
        }
    }
    _participantStore.getParticipantList(null);
  }

  void _setAudioRoute(AudioRoute route) async {
    _deviceStore.setAudioRoute(route);
  }

  void _initStore() {
    _participantStore = RoomParticipantStore.create(widget.roomID);
    _participantListener = RoomParticipantListener(
      onOwnerChanged: _onOwnerChanged,
      onAdminSet: _onAdminSet,
      onAdminRevoked: _onAdminRevoked,
      onKickedFromRoom: _onKickedFromRoom,
      onParticipantDeviceClosed: _onParticipantDeviceClosed,
      onUserMessageDisabled: _onUserMessageDisabled,
      onAllDevicesDisabled: _onAllDevicesDisabled,
      onDeviceInvitationReceived: _onDeviceInvitationReceived,
      onDeviceInvitationCancelled: _onDeviceInvitationCancelled,
    );
    _roomListener = RoomListener(onRoomEnded: _onRoomEnded);
  }

  Future<void> _initMediaState() async {
    if (widget.config.autoEnableCamera) await DeviceOperator.openCamera(context);
    if (widget.config.autoEnableMicrophone) {
      // ignore: use_build_context_synchronously
      await DeviceOperator.unmuteMicrophone(context: context, participantStore: _participantStore);
    }
    _setAudioRoute(widget.config.autoEnableSpeaker ? AudioRoute.speakerphone : AudioRoute.earpiece);
  }

  void _onOwnerChanged(RoomUser newOwner, RoomUser oldOwner) {
    if (mounted && newOwner.userID == _participantStore.state.localParticipant.value?.userID) {
      Toast.info(context, RoomLocalizations.of(context)!.roomkit_toast_you_are_owner, useRootOverlay: true);
    }
  }

  void _onAdminSet(RoomUser userInfo) {
    if (mounted && userInfo.userID == _participantStore.state.localParticipant.value?.userID) {
      Toast.info(context, RoomLocalizations.of(context)!.roomkit_toast_you_are_admin, useRootOverlay: true);
    }
  }

  void _onAdminRevoked(RoomUser userInfo) {
    if (mounted && userInfo.userID == _participantStore.state.localParticipant.value?.userID) {
      Toast.info(context, RoomLocalizations.of(context)!.roomkit_toast_you_are_no_longer_admin, useRootOverlay: true);
    }
  }

  void _onKickedFromRoom(KickedOutOfRoomReason reason, String message) {
    if (mounted) {
      AtomicAlertDialog.show(
        context,
        title: RoomLocalizations.of(context)!.roomkit_toast_you_were_removed,
        confirmText: RoomLocalizations.of(context)!.roomkit_ok,
        onConfirm: () {
          _routeToRoomMainWidget();
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _onParticipantDeviceClosed(DeviceType device, RoomUser operator) {
    String message = '';
    switch (device) {
      case DeviceType.microphone:
        message = RoomLocalizations.of(context)!.roomkit_toast_muted_by_host;
        break;
      case DeviceType.camera:
        message = RoomLocalizations.of(context)!.roomkit_toast_camera_closed_by_host;
        break;
      default:
        break;
    }
    Toast.info(context, message, useRootOverlay: true);
  }

  void _onUserMessageDisabled(bool disable, RoomUser operator) {
    String message = disable
        ? RoomLocalizations.of(context)!.roomkit_toast_text_chat_disabled
        : RoomLocalizations.of(context)!.roomkit_toast_text_chat_enabled;
    Toast.info(context, message, useRootOverlay: true);
  }

  void _onAllDevicesDisabled(DeviceType device, bool disable, RoomUser operator) {
    String message = '';
    switch (device) {
      case DeviceType.microphone:
        message = disable
            ? RoomLocalizations.of(context)!.roomkit_toast_all_audio_disabled
            : RoomLocalizations.of(context)!.roomkit_toast_all_audio_enabled;
      case DeviceType.camera:
        message = disable
            ? RoomLocalizations.of(context)!.roomkit_toast_all_video_disabled
            : RoomLocalizations.of(context)!.roomkit_toast_all_video_enabled;
      default:
        break;
    }
    Toast.info(context, message, useRootOverlay: true);
  }

  void _onDeviceInvitationReceived(DeviceRequestInfo invitation) {
    String userName = invitation.senderNameCard.isNotEmpty ? invitation.senderNameCard : invitation.senderUserName;
    String title = RoomLocalizations.of(context)!.roomkit_msg_invite_start_video;
    switch (invitation.device) {
      case DeviceType.microphone:
        title = RoomLocalizations.of(context)!.roomkit_msg_invite_unmute_audio.replaceAll('xxx', userName);
        break;
      case DeviceType.camera:
        title = RoomLocalizations.of(context)!.roomkit_msg_invite_start_video.replaceAll('xxx', userName);
        break;
      default:
        break;
    }
    final alertId = AtomicAlertDialog.show(
      context,
      title: title,
      confirmText: RoomLocalizations.of(context)!.roomkit_agree,
      cancelText: RoomLocalizations.of(context)!.roomkit_reject,
      onConfirm: () async {
        final permissionStatus = await Permission.check(invitation.device.toPermissionType);
        final noPermissionMessage = invitation.device == DeviceType.microphone
            ? RoomLocalizations.of(context)!.roomkit_err_n1105_mic_no_permission
            : RoomLocalizations.of(context)!.roomkit_err_n1101_camera_no_permission;
        if (permissionStatus != PermissionStatus.granted) {
          final result = await Permission.request([invitation.device.toPermissionType]);
          if (result[invitation.device.toPermissionType] != PermissionStatus.granted && mounted) {
            Toast.error(context, noPermissionMessage, useRootOverlay: true);
          }
        }
        await _participantStore.acceptOpenDeviceInvitation(
          userID: invitation.senderUserID,
          device: invitation.device,
        );
        _clearDeviceInviteAlertId(invitation.device);
      },
      onCancel: () {
        _participantStore.declineOpenDeviceInvitation(userID: invitation.senderUserID, device: invitation.device);
        _clearDeviceInviteAlertId(invitation.device);
      },
    );
    _setDeviceInviteAlertId(invitation.device, alertId);
  }

  void _onDeviceInvitationCancelled(DeviceRequestInfo invitation) {
    switch (invitation.device) {
      case DeviceType.microphone:
        if (_inviteMicAlertId != null) AtomicAlertDialog.dismiss(_inviteMicAlertId!);
        break;
      case DeviceType.camera:
        if (_inviteCameraAlertId != null) AtomicAlertDialog.dismiss(_inviteCameraAlertId!);
        break;
      default:
        break;
    }
  }

  void _onRoomEnded(RoomInfo info) {
    if (mounted) {
      AtomicAlertDialog.show(
        context,
        title: RoomLocalizations.of(context)!.roomkit_toast_room_closed,
        confirmText: RoomLocalizations.of(context)!.roomkit_ok,
        onConfirm: () {
          _routeToRoomMainWidget();
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _routeToRoomMainWidget() {
    final navigator = Navigator.of(context, rootNavigator: true);
    while (navigator.canPop()) {
      navigator.pop();
    }
    AtomicAlertDialog.dismissAll();
  }

  void _enableWakeLock() async {
    try {
      await TencentConferenceUikitPlatform.instance.enableWakeLock(true);
    } catch (e) {
      debugPrint('Failed to enable WakeLock: $e');
    }
  }

  void _disableWakeLock() async {
    try {
      await TencentConferenceUikitPlatform.instance.enableWakeLock(false);
    } catch (e) {
      debugPrint('Failed to disable WakeLock: $e');
    }
  }

  void _startForegroundService() async {
    if (!Platform.isAndroid) return;

    final micStatus = await Permission.check(PermissionType.microphone);
    if (micStatus != PermissionStatus.granted) {
      debugPrint('[ForegroundService] Failed to start audio foreground service. reason: without microphone permission');
      return;
    }

    try {
      await TencentConferenceUikitPlatform.instance.startForegroundService(
        ForegroundServiceType.audio,
        '',
        RoomLocalizations.of(context)!.roomkit_room_running,
      );
    } catch (e) {
      debugPrint('[ForegroundService] Failed to start audio service: $e');
    }
  }

  void _stopForegroundService() async {
    if (!Platform.isAndroid) return;

    try {
      await TencentConferenceUikitPlatform.instance.stopForegroundService(
        ForegroundServiceType.audio,
      );
    } catch (e) {
      debugPrint('[ForegroundService] Failed to stop audio service: $e');
    }
  }

  void _setDeviceInviteAlertId(DeviceType deviceType, String id) {
    switch (deviceType) {
      case DeviceType.microphone:
        _inviteMicAlertId = id;
        break;
      case DeviceType.camera:
        _inviteCameraAlertId = id;
        break;
      default:
        break;
    }
  }

  void _clearDeviceInviteAlertId(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.microphone:
        _inviteMicAlertId = null;
        break;
      case DeviceType.camera:
        _inviteCameraAlertId = null;
        break;
      default:
        break;
    }
  }
}
