import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/panel/co_guest_video_setting_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/common/permission_request_dialog.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import '../../../manager/live_stream_manager.dart';

class CoGuestTypeSelectPanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final int seatIndex;
  final bool enableCamera;
  final BuildContext parentContext;
  final VoidCallback onClose;

  const CoGuestTypeSelectPanelWidget({
    super.key,
    required this.parentContext,
    required this.liveStreamManager,
    required this.onClose,
    this.seatIndex = -1,
    this.enableCamera = true,
  });

  @override
  State<CoGuestTypeSelectPanelWidget> createState() => _CoGuestTypeSelectPanelWidgetState();
}

class _CoGuestTypeSelectPanelWidgetState extends State<CoGuestTypeSelectPanelWidget> {
  BottomSheetHandler? _videoSettingsPanelHandler;
  AlertHandler? _cameraRequestAlertHandler;
  AlertHandler? _microphoneRequestAlertHandler;

  @override
  void dispose() {
    _videoSettingsPanelHandler?.close();
    _cameraRequestAlertHandler?.close();
    _microphoneRequestAlertHandler?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.screenWidth,
      constraints: BoxConstraints(maxHeight: 234.height),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleWidget(),
          Visibility(
            visible: widget.enableCamera,
            child: _buildOptionButton(
              icon: LiveImages.linkVideo,
              text: LiveKitLocalizations.of(context)!.common_text_link_mic_video,
              onTap: _connectVideo,
            ),
          ),
          _buildOptionButton(
            icon: LiveImages.linkAudio,
            text: LiveKitLocalizations.of(context)!.common_text_link_mic_audio,
            onTap: _connectAudio,
          ),
          SizedBox(height: 34.height),
        ],
      ),
    );
  }

  Widget _buildTitleWidget() {
    double screenWidth = 1.screenWidth;
    return SizedBox(
      height: 89.height,
      width: screenWidth,
      child: Stack(
        children: [
          Positioned(
            top: 20.height,
            child: SizedBox(
              width: screenWidth,
              child: Center(
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_title_link_mic_selector,
                  style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
                ),
              ),
            ),
          ),
          Positioned(
            top: 52.height,
            child: SizedBox(
              width: screenWidth,
              child: Center(
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_text_link_mic_selector,
                  style: const TextStyle(color: LiveColors.notStandardGrey, fontSize: 12),
                ),
              ),
            ),
          ),
          Visibility(
            visible: widget.enableCamera,
            child: Positioned(
              right: 16.width,
              top: 35.height,
              child: GestureDetector(
                onTap: () {
                  _showSettingsPanel();
                },
                child: Container(
                  width: 40.width,
                  height: 40.height,
                  padding: EdgeInsets.all(10.width),
                  color: LiveColors.designStandardTransparent,
                  child: Image.asset(LiveImages.linkSettings, package: Constants.pluginName),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({required String icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54.height,
        width: 1.screenWidth,
        color: LiveColors.designStandardTransparent,
        child: Stack(
          children: [
            Container(width: 1.width, height: 1.height, color: LiveColors.notStandardBlue30Transparency),
            Positioned(
              top: 17.height,
              left: 16.width,
              child: Image.asset(icon, package: Constants.pluginName, width: 20.width, height: 20.height),
            ),
            Positioned(
              top: 17.height,
              left: 49.width,
              child: Text(text, style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    _videoSettingsPanelHandler = popupWidget(
      CoGuestVideoSettingsPanelWidget(
        liveStreamManager: widget.liveStreamManager,
        seatIndex: widget.seatIndex,
        onClose: () {
          widget.onClose.call();
        },
      ),
      context: context,
    );
  }
}

extension on _CoGuestTypeSelectPanelWidgetState {
  void _connectVideo() => _requestConnection(isVideo: true);

  void _connectAudio() => _requestConnection(isVideo: false);

  Future<void> _requestConnection({required bool isVideo}) async {
    if (isVideo) {
      final statusMap = await Permission.request([PermissionType.camera]);
      PermissionStatus cameraPermissionStatus = statusMap[PermissionType.camera] ?? PermissionStatus.denied;
      if (!cameraPermissionStatus.isUsable) {
        if (!widget.parentContext.mounted) return;
        _cameraRequestAlertHandler = PermissionRequestDialog.showCameraRequestDialog(widget.parentContext, onClose: () {
          _cameraRequestAlertHandler?.close();
          _cameraRequestAlertHandler = null;
        });
        return;
      }
    }

    final statusMap = await Permission.request([PermissionType.microphone]);
    PermissionStatus microphonePermissionStatus = statusMap[PermissionType.microphone] ?? PermissionStatus.denied;
    if (!microphonePermissionStatus.isUsable) {
      if (!widget.parentContext.mounted) return;
      _microphoneRequestAlertHandler = PermissionRequestDialog.showMicrophoneRequestDialog(widget.parentContext, onClose: () {
        _microphoneRequestAlertHandler?.close();
        _microphoneRequestAlertHandler = null;
      });
      return;
    }
    widget.onClose.call();
    widget.liveStreamManager.coGuestManager.onStartRequestIntraRoomConnection();
    widget.liveStreamManager.coGuestManager.updateOpenCameraAfterTakeSeat(isVideo);
    if (isVideo) DeviceStore.shared.switchMirror(MirrorType.auto);
    CoGuestStore coGuestStore = CoGuestStore.create(widget.liveStreamManager.roomState.roomId);
    final result = await coGuestStore.applyForSeat(
      seatIndex: widget.seatIndex,
      timeout: Constants.defaultRequestTimeout,
    );
    if (result.errorCode != 0) {
      widget.liveStreamManager.coGuestManager.onRequestIntraRoomConnectionFailed();
      if (widget.parentContext.mounted == true) {
        makeToast(widget.parentContext, ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '',
            type: ToastType.error);
      }
    }
  }
}
