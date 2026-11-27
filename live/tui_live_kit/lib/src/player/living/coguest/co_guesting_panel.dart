import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';

class CoGuestingPanel extends StatefulWidget {
  const CoGuestingPanel({
    super.key,
    required this.liveID,
    required this.openCameraAfterAccept,
    required this.onCollapse,
    required this.onShowSettings,
    this.onWillDisconnect,
    this.onToast,
  });

  final String liveID;
  final ValueListenable<bool> openCameraAfterAccept;
  final VoidCallback onCollapse;
  final VoidCallback onShowSettings;
  final VoidCallback Function()? onWillDisconnect;
  final ValueChanged<String>? onToast;

  @override
  State<CoGuestingPanel> createState() => _CoGuestingPanelState();
}

class _CoGuestingPanelState extends State<CoGuestingPanel> {
  static const double _sheetHeight = 160;

  final BottomSheetController _controller = BottomSheetController();

  bool _isBusy = false;
  bool _requestingCameraPermission = false;

  @override
  void initState() {
    super.initState();
    CoGuestStore.create(widget.liveID)
        .coGuestState
        .connected
        .addListener(_onSeatChanged);
    widget.openCameraAfterAccept.addListener(_onSeatChanged);
  }

  @override
  void dispose() {
    CoGuestStore.create(widget.liveID)
        .coGuestState
        .connected
        .removeListener(_onSeatChanged);
    widget.openCameraAfterAccept.removeListener(_onSeatChanged);
    super.dispose();
  }

  void _onSeatChanged() {
    if (mounted) setState(() {});
  }

  SeatUserInfo? get _selfSeatUser {
    final String selfID =
        LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (selfID.isEmpty) return null;
    for (final SeatUserInfo seatUserInfo
        in CoGuestStore.create(widget.liveID).coGuestState.connected.value) {
      if (seatUserInfo.userID == selfID) return seatUserInfo;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SeatUserInfo? self = _selfSeatUser;
    final bool microphoneEnabled = self?.microphoneStatus == DeviceStatus.on;
    final bool cameraEnabled = self?.cameraStatus == DeviceStatus.on;
    return BottomSheetView(
      sheetHeight: _sheetHeight,
      controller: _controller,
      onDismiss: widget.onCollapse,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _ControlButton(
              size: 48,
              backgroundColor: _CoGuestingStyle.neutralBackground,
              onTap: _toggleMicrophone,
              child: Image(
                image: LiveKitResources.image(
                  microphoneEnabled
                      ? 'livekit_coguest_action_mic'
                      : 'livekit_coguest_action_mic_off',
                ),
                width: 48,
                height: 48,
              ),
            ),
            if (widget.openCameraAfterAccept.value) ...<Widget>[
              _ControlButton(
                size: 48,
                backgroundColor: _CoGuestingStyle.neutralBackground,
                onTap: _toggleCamera,
                child: Image(
                  image: LiveKitResources.image(
                    cameraEnabled
                        ? 'livekit_coguest_action_camera'
                        : 'livekit_coguest_action_camera_off',
                  ),
                  width: 48,
                  height: 48,
                ),
              ),
              _ControlButton(
                size: 48,
                backgroundColor: _CoGuestingStyle.neutralBackground,
                onTap: widget.onShowSettings,
                child: Image(
                  image: LiveKitResources.image(
                    'livekit_coguest_action_adjust',
                  ),
                  width: 48,
                  height: 48,
                ),
              ),
            ],
            _ControlButton(
              enabled: !_isBusy,
              size: 48,
              backgroundColor: _CoGuestingStyle.disconnectBackground,
              onTap: _disconnect,
              child: Image(
                image: LiveKitResources.image(
                  'livekit_coguest_disconnect',
                ),
                width: 48,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMicrophone() async {
    final SeatUserInfo? self = _selfSeatUser;
    if (self == null) return;
    if (self.microphoneStatus == DeviceStatus.on) {
      LiveSeatStore.create(widget.liveID).muteMicrophone();
      return;
    } else if (self.allowOpenMicrophone == true) {
      final PermissionStatus permission = await Permission.microphone.request();
      if (!permission.isGranted) return;
      await LiveSeatStore.create(widget.liveID).unmuteMicrophone();
    } else if (self.allowOpenMicrophone == false) {
      widget.onToast?.call(LiveKitResources.localizedString(
        'tuilivekit.player.coguest.microphone_locked',
      ));
    }
  }

  Future<void> _toggleCamera() async {
    final SeatUserInfo? self = _selfSeatUser;
    if (self == null) return;
    if (self.cameraStatus == DeviceStatus.on) {
      DeviceStore.shared.closeLocalCamera();
      return;
    }
    if (_requestingCameraPermission) return;
    _requestingCameraPermission = true;
    final PermissionStatus permission = await Permission.camera.request();
    _requestingCameraPermission = false;
    if (!permission.isGranted) return;
    await DeviceStore.shared
        .openLocalCamera(DeviceStore.shared.state.isFrontCamera.value);
  }

  Future<void> _disconnect() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final cancelSeatExit = widget.onWillDisconnect?.call();
    try {
      final result = await CoGuestStore.create(widget.liveID).disconnect();
      if (!mounted) return;
      if (!result.isSuccess) cancelSeatExit?.call();
    } catch (_) {
      if (!mounted) return;
      cancelSeatExit?.call();
    }
    if (!mounted) return;
    setState(() => _isBusy = false);
    await _controller.dismiss();
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.size,
    required this.backgroundColor,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

  final double size;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: widget.child,
    );
  }
}
abstract final class _CoGuestingStyle {
  static const neutralBackground = Color(0x17FFFFFF);
  static const disconnectBackground = Color(0xFFFF5158);
}
