import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/common/tui_video_view.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_prepare/anchor_preview_widget_define.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_prepare/widgets/video_stream_source_widget.dart';
import 'package:tencent_live_uikit/live_stream/live_define.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/toast.dart';

import 'package:tuikit_atomic_x/permission/permission.dart';

import '../../../common/widget/base_bottom_sheet.dart';
import '../../manager/live_stream_manager.dart';
import '../common/permission_request_dialog.dart';
import 'widgets/anchor_preview_function_widget.dart';
import 'widgets/anchor_preview_info_edit_widget.dart';

class AnchorPreviewWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final DidClickBack? didClickBack;
  final DidClickStart? didClickStart;

  const AnchorPreviewWidget({super.key, required this.liveStreamManager, this.didClickBack, this.didClickStart});

  @override
  State<AnchorPreviewWidget> createState() => _AnchorPreviewWidgetState();
}

class _AnchorPreviewWidgetState extends State<AnchorPreviewWidget> with WidgetsBindingObserver {
  late final LiveStreamManager liveStreamManager;
  late final EditInfo _editInfo;
  AppLifecycleState? _lastLifecycleState;
  AlertHandler? _cameraRequestAlertHandler;
  AlertHandler? _microphoneRequestAlertHandler;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    _initEditInfo();
    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;
    Permission.request([PermissionType.camera, PermissionType.microphone]).then((permissionMap) {
      _startCamera();
      _startMicrophone();
    });
    DeviceStore.shared.switchMirror(MirrorType.auto);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      _onPreviewResumed();
    }
  }

  void _onPreviewResumed() async {
    if (!mounted) return;
    LiveKitLogger.info('resumed to foreground, videoStreamSource=${_editInfo.videoStreamSource.value}');
    if (_editInfo.videoStreamSource.value == VideoStreamSource.camera) {
      Permission.check(PermissionType.camera).then((result) {
        if (!mounted) return;
        if (!result.isUsable) return;
        _cameraRequestAlertHandler?.close();
        if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.off) {
          _startCamera();
        }
      });
    }
    Permission.check(PermissionType.microphone).then((result) {
      if (!mounted) return;
      if (!result.isUsable) return;
      _microphoneRequestAlertHandler?.close();
      if (DeviceStore.shared.state.microphoneStatus.value == DeviceStatus.off) {
        _startMicrophone();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: LiveColors.notStandardPureBlack,
        child: Stack(children: [
          _initBackgroundWidget(),
          _buildVideoWidget(),
          _buildBackWidget(),
          _buildLiveTabWidget(),
          _buildLiveInfoEditWidget(liveStreamManager),
          _buildFunctionWidget(),
          _buildStartLiveWidget()
        ]),
      ),
    );
  }

  Widget _initBackgroundWidget() {
    return SizedBox(
      width: 1.screenWidth,
      height: 1.screenHeight,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource == VideoStreamSource.camera) {
              return const SizedBox.shrink();
            } else {
              return Image.asset(LiveImages.defaultBackground, fit: BoxFit.cover, package: Constants.pluginName);
            }
          }),
    );
  }

  Widget _buildLiveTabWidget() {
    return Positioned(
      top: 80.height,
      height: 44.height,
      child: SizedBox(
        width: 1.screenWidth,
        child: VideoStreamSourceWidget(videoStreamSourceChanged: (videoStreamSource) {
          _editInfo.videoStreamSource.value = videoStreamSource;
          if (DeviceStore.shared.state.microphoneStatus.value == DeviceStatus.off) {
            _startMicrophone();
          }
          if (videoStreamSource == VideoStreamSource.camera) {
            _editInfo.coGuestTemplateMode.value = LiveTemplateMode.verticalDynamicGrid;
            _startCamera();
          } else {
            _editInfo.coGuestTemplateMode.value = LiveTemplateMode.horizontalDynamic;
            _stopCamera();
          }
        }),
      ),
    );
  }

  Widget _buildVideoWidget() {
    return Positioned(
      width: 1.screenWidth,
      height: 1.screenHeight,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource != VideoStreamSource.camera) return const SizedBox.shrink();
            LiveCoreController liveCoreController = LiveCoreController.create(CoreViewType.pushView);
            liveCoreController.setLiveID(liveStreamManager.roomState.roomId);
            return Padding(
              padding: EdgeInsets.only(top: 36.height, bottom: 96.height),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.radius),
                child: VideoView(
                  onViewCreated: (id) {
                    widget.liveStreamManager.mediaManager.setLocalVideoView(id);
                  },
                  onViewDisposed: (id) {
                    widget.liveStreamManager.mediaManager.setLocalVideoView(0);
                  },
                ),
              ),
            );
          }),
    );
  }

  Widget _buildBackWidget() {
    return Positioned(
        left: 16.width,
        top: 56.height,
        width: 24.radius,
        height: 24.radius,
        child: GestureDetector(
            onTap: () {
              _closeWidget();
            },
            child: Image.asset(LiveImages.returnArrow, package: Constants.pluginName)));
  }

  Widget _buildLiveInfoEditWidget(LiveStreamManager manager) {
    return Positioned(
        top: 120.height,
        left: 16.width,
        right: 16.width,
        height: 112.height,
        child: AnchorPreviewInfoEditWidget(editInfo: _editInfo, liveStreamManager: liveStreamManager));
  }

  Widget _buildFunctionWidget() {
    return Positioned(
      left: 0,
      bottom: 134.height,
      width: 375.width,
      height: 62.height,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource == VideoStreamSource.camera) {
              _editInfo.coGuestTemplateMode.value = LiveTemplateMode.verticalDynamicGrid;
            }
            return Visibility(
                visible: videoStreamSource == VideoStreamSource.camera,
                child: AnchorPreviewFunctionWidget(editInfo: _editInfo, liveStreamManager: liveStreamManager));
          }),
    );
  }

  Widget _buildStartLiveWidget() {
    return Positioned(
      left: 50.width,
      right: 50.width,
      bottom: 64.height,
      height: 48.height,
      child: GestureDetector(
        onTap: () {
          _createRoom();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.height),
            color: LiveColors.designStandardB1,
          ),
          child: Text(
            LiveKitLocalizations.of(Global.appContext())!.common_start_live,
            style: const TextStyle(
                color: LiveColors.designStandardFlowkitWhite, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

extension on _AnchorPreviewWidgetState {
  void _initEditInfo() {
    _editInfo = EditInfo(
      roomName: _getDefaultRoomName(),
      privacyMode: LiveStreamPrivacyStatus.public,
      videoStreamSource: VideoStreamSource.camera,
    );
  }

  String _getDefaultRoomName() {
    final selfInfo = LoginStore.shared.loginState.loginUserInfo;
    if (selfInfo == null) return '';
    if (selfInfo.nickname == null || selfInfo.nickname!.isEmpty) {
      return selfInfo.userID;
    }
    return selfInfo.nickname!;
  }

  void _startCamera() async {
    final isFront = DeviceStore.shared.state.isFrontCamera.value;
    final startCameraResult = await liveStreamManager.mediaManager.openLocalCamera(isFront);
    if (startCameraResult.isSuccess) return;
    if (!mounted) return;
    _cameraRequestAlertHandler = PermissionRequestDialog.showCameraRequestDialog(context, onClose: () {
      _cameraRequestAlertHandler?.close();
      _cameraRequestAlertHandler = null;
    });
  }

  void _startMicrophone() async {
    final startMicrophoneResult = await liveStreamManager.mediaManager.openLocalMicrophone();
    if (startMicrophoneResult.isSuccess) return;
    if (!mounted) return;
    _microphoneRequestAlertHandler = PermissionRequestDialog.showMicrophoneRequestDialog(context, onClose: () {
      _microphoneRequestAlertHandler?.close();
      _microphoneRequestAlertHandler = null;
    });
  }

  void _stopCamera() {
    liveStreamManager.mediaManager.closeLocalCamera();
  }

  void _stopMicrophone() {
    liveStreamManager.mediaManager.closeLocalMicrophone();
  }

  void _createRoom() async {
    if (BottomSheetGuard.instance.isCovered) {
      return;
    }
    if (_editInfo.videoStreamSource.value == VideoStreamSource.camera) {
      final checkCamera = await Permission.check(PermissionType.camera);
      if (!checkCamera.isUsable) {
        final tip = ErrorHandler.convertToErrorMessage(LiveError.cameraNotAuthorized.code, '');
        if (!mounted) return;
        makeToast(context, tip, type: ToastType.error);
        return;
      }
    }
    final checkMicrophone = await Permission.check(PermissionType.microphone);
    if (!checkMicrophone.isUsable) {
      if (!mounted) return;
      final tip = ErrorHandler.convertToErrorMessage(LiveError.microphoneNotAuthorized.code, '');
      makeToast(context, tip, type: ToastType.error);
      return;
    }
    widget.didClickStart?.call(_editInfo);
  }

  void _closeWidget() {
    liveStreamManager.mediaManager.stopForegroundService();
    _stopMicrophone();
    if (_editInfo.videoStreamSource.value == VideoStreamSource.camera) {
      _stopCamera();
    }
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      Navigator.pop(context);
    }
  }
}
