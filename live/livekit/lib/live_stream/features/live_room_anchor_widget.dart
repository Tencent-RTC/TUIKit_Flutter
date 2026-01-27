import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:live_uikit_barrage/widget/display/barrage_display_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../common/index.dart';
import '../../common/widget/float_window/index.dart';
import '../../component/float_window/global_float_window_manager.dart';
import '../../live_navigator_observer.dart';
import '../live_define.dart';
import '../manager/live_stream_manager.dart';
import 'anchor_broadcast/index.dart';
import 'anchor_prepare/anchor_preview_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide DeviceStatus;

class TUILiveRoomAnchorWidget extends StatefulWidget {
  final String roomId;
  final bool needPrepare;
  final LiveInfo? liveInfo;
  final VoidCallback? onStartLive;
  final FloatWindowController? floatWindowController;

  const TUILiveRoomAnchorWidget(
      {super.key,
      required this.roomId,
      this.needPrepare = true,
      this.liveInfo,
      this.onStartLive,
      this.floatWindowController});

  @override
  State<TUILiveRoomAnchorWidget> createState() => _TUILiveRoomAnchorWidgetState();
}

class _TUILiveRoomAnchorWidgetState extends State<TUILiveRoomAnchorWidget> {
  final LiveCoreController _liveCoreController = LiveCoreController.create(CoreViewType.pushView);
  final LiveStreamManager _liveStreamManager = LiveStreamManager();
  final ValueNotifier<bool> _isShowingPreviewWidget = ValueNotifier(false);
  late final VoidCallback _onFloatWindowModeChangedListener = _onFloatWindowModeChanged;
  late final VoidCallback _onFullScreenChangedListener = _onFullScreenChanged;

  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveDataReporter.reportComponent(LiveComponentType.liveRoom);
    _changeStatusBar2LightMode();
    _initLiveStream();
    _addObserver();
    _startForegroundService();
    _startWakeLock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() && widget.floatWindowController == null) {
        String error = "You have enabled the floating window feature,"
            "but you are using TUILiveRoomAnchorWidget, Please switch to TUILiveRoomAnchorOverlay."
            "Or disable the floating window feature in the app's main.dart: "
            "GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);";
        LiveKitLogger.error(error);
        makeToast(msg: "Tip: Please use TUILiveRoomAnchorOverlay");
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _stopWakeLock();
    _stopForegroundService();
    _removeObserver();
    _unInitLiveStream();
    AudioEffectStore.shared.reset();
    DeviceStore.shared.reset();
    BaseBeautyStore.shared.reset();
    BarrageDisplayController.resetState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [_buildAnchorBroadcastWidget(), _buildAnchorPreviewWidget()]),
    );
  }

  Widget _buildAnchorBroadcastWidget() {
    return ValueListenableBuilder(
        valueListenable: _isShowingPreviewWidget,
        builder: (context, showPreview, _) {
          return Visibility(
            visible: !showPreview,
            child: AnchorBroadcastWidget(
              liveStreamManager: _liveStreamManager,
              liveCoreController: _liveCoreController,
              onTapEnterFloatWindowInApp: () {
                widget.floatWindowController?.onTapSwitchFloatWindowInApp(true);
              },
            ),
          );
        });
  }

  Widget _buildAnchorPreviewWidget() {
    return ValueListenableBuilder(
        valueListenable: _isShowingPreviewWidget,
        builder: (context, showPreview, _) {
          return Visibility(
            visible: showPreview,
            child: AnchorPreviewWidget(
              liveStreamManager: _liveStreamManager,
              didClickBack: () {
                Navigator.of(context).pop();
              },
              didClickStart: (editInfo) {
                _liveStreamManager.coHostManager.setLayoutTemplateId(editInfo.coHostTemplateMode.value.id);
                _startLiveStream(editInfo.roomName.value, editInfo.coverUrl.value, editInfo.privacyMode.value,
                    editInfo.coGuestTemplateMode.value);
              },
            ),
          );
        });
  }
}

extension on _TUILiveRoomAnchorWidgetState {
  void _changeStatusBar2LightMode() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _initLiveStream() async {
    _liveCoreController.setLiveID(widget.roomId);
    _liveStreamManager.setLiveID(widget.roomId);
    widget.liveInfo != null
        ? _liveStreamManager.prepareLiveInfoBeforeEnterRoom(widget.liveInfo!)
        : _liveStreamManager.prepareRoomIdBeforeEnterRoom(widget.roomId);
    final isObsBroadcast = await _checkWhetherObsBroadcast(widget.roomId);

    widget.needPrepare && !isObsBroadcast ? _liveStreamManager.onStartPreview() : _joinSelfCreatedRoom(isObsBroadcast);

    _isShowingPreviewWidget.value = !isObsBroadcast && widget.needPrepare;
  }

  void _unInitLiveStream() {
    _liveStreamManager.dispose();
  }

  void _joinSelfCreatedRoom(bool isObsBroadcast) async {
    if (!isObsBroadcast && DeviceStore.shared.state.cameraStatus.value == DeviceStatus.off) {
      _startCameraAndMicrophone();
    }
    final result = await LiveListStore.shared.joinLive(widget.roomId);
    if (result.errorCode != TUIError.success.rawValue) {
      _toastAndPop(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      return;
    }

    widget.onStartLive?.call();
    _liveStreamManager.onStartLive(true, result.liveInfo);
  }

  void _startLiveStream(
      String? roomName, String? coverUrl, LiveStreamPrivacyStatus? privacyMode, LiveTemplateMode templateMode) async {
    _isShowingPreviewWidget.value = false;
    widget.onStartLive?.call();

    if (roomName != null) {
      _liveStreamManager.onSetRoomName(roomName);
    }
    if (coverUrl != null) {
      _liveStreamManager.onSetRoomCoverUrl(coverUrl);
    }
    if (privacyMode != null) {
      _liveStreamManager.onSetRoomPrivacy(privacyMode);
    }

    final liveInfo = LiveInfo();
    liveInfo.liveID = widget.roomId;
    liveInfo.liveName = _liveStreamManager.roomState.roomName;
    liveInfo.isSeatEnabled = true;
    liveInfo.seatMode = TakeSeatMode.apply;
    liveInfo.coverURL = coverUrl ?? "";
    liveInfo.backgroundURL = coverUrl ?? "";
    liveInfo.isPublicVisible = privacyMode == LiveStreamPrivacyStatus.public;
    liveInfo.activityStatus = widget.liveInfo?.activityStatus ?? 0;
    liveInfo.keepOwnerOnSeat = true;
    liveInfo.seatLayoutTemplateID = templateMode.id;

    final result = await LiveListStore.shared.createLive(liveInfo);
    if (result.errorCode != TUIError.success.rawValue) {
      _toastAndPop(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      return;
    }

    _liveStreamManager.onStartLive(false, result.liveInfo);
  }

  Future<bool> _checkWhetherObsBroadcast(String roomId) async {
    final result = await _liveStreamManager.fetchLiveInfo(roomId);
    if (result.code != TUIError.success || result.data == null) {
      return false;
    }
    final TUILiveInfo liveInfo = result.data!;
    return !liveInfo.keepOwnerOnSeat;
  }

  void _toastAndPop(String toast) {
    makeToast(msg: toast);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startCameraAndMicrophone() async {
    final startCameraResult = await _liveStreamManager.mediaManager.openLocalCamera(true);
    if (startCameraResult.code != TUIError.success) {
      _liveStreamManager.toastSubject
          .add(ErrorHandler.convertToErrorMessage(startCameraResult.code.rawValue, startCameraResult.message) ?? '');
    }
    final startMicrophoneResult = await _liveStreamManager.mediaManager.openLocalMicrophone();
    if (startMicrophoneResult.code != TUIError.success) {
      _liveStreamManager.toastSubject.add(
          ErrorHandler.convertToErrorMessage(startMicrophoneResult.code.rawValue, startMicrophoneResult.message) ?? '');
    }
  }

  void _startForegroundService() async {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;
    final hasCameraPermission = await Permission.camera.status == PermissionStatus.granted;
    if (!hasCameraPermission) {
      LiveKitLogger.error(
          '[ForegroundService] failed to start video foreground service. reason: without camera permission');
      return;
    }
    TUILiveKitPlatform.instance.startForegroundService(ForegroundServiceType.video, "", description);
  }

  void _stopForegroundService() {
    TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.video);
    Permission.camera.onGrantedCallback(null);
  }

  void _addObserver() {
    _liveStreamManager.floatWindowState.floatWindowMode.addListener(_onFloatWindowModeChangedListener);
    widget.floatWindowController?.isFullScreen.addListener(_onFullScreenChangedListener);
  }

  void _removeObserver() {
    _liveStreamManager.floatWindowState.floatWindowMode.removeListener(_onFloatWindowModeChangedListener);
    widget.floatWindowController?.isFullScreen.removeListener(_onFullScreenChangedListener);
  }

  void _startWakeLock() async {
    TUILiveKitPlatform.instance.enableWakeLock(true);
  }

  void _stopWakeLock() async {
    TUILiveKitPlatform.instance.enableWakeLock(false);
  }

  void _onFloatWindowModeChanged() {
    FloatWindowMode floatWindowMode = _liveStreamManager.floatWindowState.floatWindowMode.value;
    if (floatWindowMode == FloatWindowMode.outOfApp) {
      widget.floatWindowController?.onSwitchFloatWindowOutOfApp.call(true);
    } else if (floatWindowMode == FloatWindowMode.none) {
      widget.floatWindowController?.onSwitchFloatWindowOutOfApp.call(false);
    }
    GlobalFloatWindowManager.instance.setFloatWindowMode(floatWindowMode);
  }

  void _onFullScreenChanged() {
    if (widget.floatWindowController == null) {
      return;
    }
    bool isFullScreen = widget.floatWindowController!.isFullScreen.value;
    FloatWindowMode floatWindowMode = _liveStreamManager.floatWindowState.floatWindowMode.value;
    if (isFullScreen) {
      if (floatWindowMode != FloatWindowMode.outOfApp) {
        _liveStreamManager.setFloatWindowMode(FloatWindowMode.none);
      }
    } else {
      _liveStreamManager.setFloatWindowMode(FloatWindowMode.inApp);
    }
  }
}
