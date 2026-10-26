import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/common/tui_video_view.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/toast.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';

import '../../../../common/widget/base_bottom_sheet.dart';
import '../../../../component/beauty/index.dart';
import '../../common/permission_request_dialog.dart';

class CoGuestVideoSettingsPanelWidget extends StatefulWidget {
  final int seatIndex;
  final VoidCallback onClose;
  final LiveStreamManager liveStreamManager;

  const CoGuestVideoSettingsPanelWidget({
    super.key,
    required this.liveStreamManager,
    required this.onClose,
    this.seatIndex = -1,
  });

  @override
  State<CoGuestVideoSettingsPanelWidget> createState() => _CoGuestVideoSettingsPanelWidgetState();
}

class _CoGuestVideoSettingsPanelWidgetState extends State<CoGuestVideoSettingsPanelWidget> with WidgetsBindingObserver {
  BottomSheetHandler? _beautyPanelHandler;
  AlertHandler? _cameraRequestAlertHandler;
  AlertHandler? _microphoneRequestAlertHandler;
  int _cameraViewID = 0;
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _beautyPanelHandler?.close();
    _cameraRequestAlertHandler?.close();
    _microphoneRequestAlertHandler?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final previous = _lastLifecycleState;
    _lastLifecycleState = state;
    LiveKitLogger.info('lifecycle change: $previous -> $state');
    final backFromBackground = state == AppLifecycleState.resumed &&
        (previous == AppLifecycleState.paused ||
            previous == AppLifecycleState.inactive ||
            previous == AppLifecycleState.hidden);
    if (backFromBackground) {
      _onPanelResumed();
    }
  }

  void _onPanelResumed() {
    if (!mounted) return;
    LiveKitLogger.info(' resumed to foreground, cameraViewID=$_cameraViewID');
    if (_cameraViewID == 0) return;
    Permission.check(PermissionType.camera).then((result) {
      if (!mounted) return;
      if (!result.isUsable) return;
      _cameraRequestAlertHandler?.close();
      if (_cameraViewID != 0 && DeviceStore.shared.state.cameraStatus.value == DeviceStatus.off) {
        _startCameraTest(_cameraViewID);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.screenWidth,
      height: 718.height,
      child: Column(
        children: [
          SizedBox(height: 20.height),
          _buildTitleWidget(),
          SizedBox(height: 22.height),
          _buildCameraPreviewWidget(),
          SizedBox(height: 24.height),
          _buildVideoSettingWidgets(),
          SizedBox(height: 110.height),
          _buildApplyLinkMicWidget(),
          SizedBox(height: 20.height),
          _buildApplyLinkMicTipsWidget(),
        ],
      ),
    );
  }

  Widget _buildTitleWidget() => SizedBox(
        height: 44.height,
        child: Center(
          child: Text(
            LiveKitLocalizations.of(Global.appContext())!.common_title_link_video_settings,
            style: const TextStyle(
              color: LiveColors.designStandardG7,
              fontSize: 16,
            ),
          ),
        ),
      );

  Widget _buildCameraPreviewWidget() => ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(16.radius)),
        child: SizedBox(
          width: 328.width,
          height: 328.height,
          child: VideoView(
            onViewCreated: (id) {
              _cameraViewID = id;
              _startCameraTest(id);
            },
            onViewDisposed: (id) {
              _cameraViewID = 0;
              widget.liveStreamManager.mediaManager.stopCameraTest();
            },
          ),
        ),
      );

  Widget _buildVideoSettingWidgets() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVideoSettingWidget(
            LiveImages.videoSettingsBeauty,
            LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_beauty,
            _showBeautyPanel,
          ),
          SizedBox(width: 12.width),
          _buildVideoSettingWidget(
            LiveImages.videoSettingsFlip,
            LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_flip,
            _switchCamera,
          ),
          SizedBox(width: 12.width),
        ],
      );

  Widget _buildVideoSettingWidget(String image, String title, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10.radius)),
          child: Container(
            color: LiveColors.designStandardG3,
            width: 56.width,
            height: 56.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24.width,
                  height: 24.height,
                  child: Image.asset(
                    image,
                    package: Constants.pluginName,
                  ),
                ),
                SizedBox(height: 2.height),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: LiveColors.designStandardG7,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildApplyLinkMicWidget() => GestureDetector(
        onTap: _requestIntraRoomVideoConnection,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10.radius)),
          child: Container(
            color: LiveColors.designStandardB1,
            width: 200.width,
            height: 52.height,
            child: Center(
              child: Text(
                LiveKitLocalizations.of(Global.appContext())!.common_apply_link_mic,
                style: const TextStyle(
                  fontSize: 16,
                  color: LiveColors.designStandardFlowkitWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

  Widget _buildApplyLinkMicTipsWidget() => Center(
        child: Text(
          LiveKitLocalizations.of(Global.appContext())!.common_tips_apply_link_mic,
          style: const TextStyle(
            fontSize: 12,
            color: LiveColors.designStandardG4,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );

  void _showBeautyPanel() {
    _beautyPanelHandler = popupWidget(const BeautyPanelWidget(), context: context);
  }
}

extension on _CoGuestVideoSettingsPanelWidgetState {
  void _switchCamera() {
    DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
  }

  void _startCameraTest(int viewID) {
    widget.liveStreamManager.mediaManager
        .startCameraTest(viewID, useFrontCamera: true, mirrorType: MirrorType.auto)
        .then((result) async {
      if (result.isSuccess) return;

      final statusMap = await Permission.request([PermissionType.camera]);
      PermissionStatus cameraPermissionStatus = statusMap[PermissionType.camera] ?? PermissionStatus.denied;
      if (!cameraPermissionStatus.isUsable) {
        if (!mounted) return;
        _cameraRequestAlertHandler = PermissionRequestDialog.showCameraRequestDialog(context, onClose: () {
          _cameraRequestAlertHandler?.close();
          _cameraRequestAlertHandler = null;
        });
        return;
      }
    });
  }

  Future<void> _requestIntraRoomVideoConnection() async {
    final statusMap = await Permission.request([PermissionType.camera]);
    PermissionStatus cameraPermissionStatus = statusMap[PermissionType.camera] ?? PermissionStatus.denied;
    if (!cameraPermissionStatus.isUsable) {
      if (!mounted) return;
      _cameraRequestAlertHandler = PermissionRequestDialog.showCameraRequestDialog(context, onClose: () {
        _cameraRequestAlertHandler?.close();
        _cameraRequestAlertHandler = null;
      });
      return;
    }

    final microphoneStatusMap = await Permission.request([PermissionType.microphone]);
    PermissionStatus microphonePermissionStatus =
        microphoneStatusMap[PermissionType.microphone] ?? PermissionStatus.denied;
    if (!microphonePermissionStatus.isUsable) {
      if (!mounted) return;
      _microphoneRequestAlertHandler = PermissionRequestDialog.showMicrophoneRequestDialog(context, onClose: () {
        _microphoneRequestAlertHandler?.close();
        _microphoneRequestAlertHandler = null;
      });
      return;
    }

    widget.onClose.call();
    widget.liveStreamManager.coGuestManager.onStartRequestIntraRoomConnection();
    widget.liveStreamManager.coGuestManager.updateOpenCameraAfterTakeSeat(true);
    CoGuestStore coGuestStore = CoGuestStore.create(widget.liveStreamManager.roomState.roomId);
    final result =
        await coGuestStore.applyForSeat(seatIndex: widget.seatIndex, timeout: Constants.defaultRequestTimeout);
    if (!mounted) return;
    if (result.errorCode != 0) {
      widget.liveStreamManager.coGuestManager.onRequestIntraRoomConnectionFailed();
      makeToast(context, ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '',
          type: ToastType.error);
    }
  }
}
