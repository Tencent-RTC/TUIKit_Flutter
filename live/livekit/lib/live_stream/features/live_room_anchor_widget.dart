import 'dart:io';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:live_uikit_barrage/widget/display/barrage_display_controller.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../common/index.dart';
import '../../common/widget/float_window/index.dart';
import '../../component/float_window/global_float_window_manager.dart';
import '../../live_info_utils.dart';
import '../../live_navigator_observer.dart';
import '../live_define.dart';
import '../manager/live_stream_manager.dart';
import 'anchor_broadcast/index.dart';
import 'anchor_prepare/anchor_preview_widget.dart';
import 'anchor_broadcast/living_widget/screen_share_guide_dialog.dart';
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
  late final ValueNotifier<bool> _isShowingPreviewWidget = ValueNotifier(widget.needPrepare);
  late final VoidCallback _onFloatWindowModeChangedListener = _onFloatWindowModeChanged;
  late final VoidCallback _onFullScreenChangedListener = _onFullScreenChanged;
  late LiveInfo? _liveInfo = widget.liveInfo;
  final ScreenShareGuideDialog _iOSScreenShareGuideDialog = ScreenShareGuideDialog();
  late final VoidCallback _onScreenCaptureListener = _onScreenCaptureChanged;

  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveDataReporter.reportComponent(LiveComponentType.liveRoom);
    _changeStatusBar2LightMode();
    _initLiveStream();
    _addObserver();
    _startWakeLock();
  }

  @override
  void dispose() {
    _iOSScreenShareGuideDialog.dismiss();
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
    DeviceLanguage.checkLocale(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [_buildAnchorBroadcastWidget(), _buildAnchorPreviewWidget()]),
    );
  }

  Widget _buildAnchorBroadcastWidget() {
    return ValueListenableBuilder(
        valueListenable: _isShowingPreviewWidget,
        builder: (context, showPreview, _) {
          if (showPreview) return const SizedBox.shrink();
          return AnchorBroadcastWidget(
            liveStreamManager: _liveStreamManager,
            liveCoreController: _liveCoreController,
            onTapEnterFloatWindowInApp: () {
              widget.floatWindowController?.onTapSwitchFloatWindowInApp(true);
            },
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
                _startLiveStream(editInfo.videoStreamSource.value, editInfo.roomName.value, editInfo.coverUrl.value,
                    editInfo.privacyMode.value, editInfo.coGuestTemplateMode.value);
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
    if (_liveInfo == null) {
      final result = await LiveListStore.shared.fetchLiveInfo(widget.roomId);
      if (result.errorCode == TUIError.success.value()) {
        _liveInfo = result.liveInfo;
      }
    }
    if (_liveInfo != null) {
      _liveStreamManager.roomState.liveInfo.seatTemplate = _liveInfo!.seatTemplate;
      _liveStreamManager.roomState.liveInfo.keepOwnerOnSeat = _liveInfo!.keepOwnerOnSeat;
    }
    if (widget.needPrepare) {
      if (_liveInfo == null) {
        _liveStreamManager.prepareRoomIdBeforeEnterRoom(widget.roomId);
      } else {
        _liveStreamManager.prepareLiveInfoBeforeEnterRoom(_liveInfo!);
      }
    }
    bool isObsBroadcast = widget.liveInfo == null ? false : !_liveInfo!.keepOwnerOnSeat;
    widget.needPrepare ? _liveStreamManager.onStartPreview() : _joinSelfCreatedRoom(isObsBroadcast);
    _isShowingPreviewWidget.value = !isObsBroadcast && widget.needPrepare;
  }

  void _unInitLiveStream() {
    if (_liveStreamManager.roomState.videoStreamSource == VideoStreamSource.screenShare) {
      _liveStreamManager.mediaManager.stopScreenShare();
    }
    _liveStreamManager.dispose();
  }

  void _joinSelfCreatedRoom(bool isObsBroadcast) async {
    if (!isObsBroadcast) {
      _startMicrophone();
      if (_liveInfo?.seatTemplate is VideoLandscape4Seats) {
        // call after joinLive
        // DeviceStore.shared.startScreenShare();
      } else {
        _startCamera();
      }
    }
    final result = await LiveListStore.shared.joinLive(widget.roomId);
    if (result.errorCode != TUIError.success.rawValue) {
      _toastAndPop(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      return;
    }
    if (result.liveInfo.seatTemplate is VideoLandscape4Seats && result.liveInfo.keepOwnerOnSeat) {
      LiveKitLogger.info("templateMode is 200, startScreenShare after joinLive!");
      _liveStreamManager.mediaManager.startScreenShare();
    }
    widget.onStartLive?.call();
    _liveStreamManager.onStartLive(true, result.liveInfo);
    _startForegroundService();
  }

  void _startLiveStream(VideoStreamSource videoStreamSource, String? roomName, String? coverUrl,
      LiveStreamPrivacyStatus? privacyMode, LiveTemplateMode templateMode) async {
    _liveStreamManager.roomState.videoStreamSource = videoStreamSource;
    _liveStreamManager.roomState.liveInfo.seatTemplate = LiveInfoUtils.convertToSeatLayoutTemplateByID(templateMode.id);
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
    liveInfo.seatMode = TakeSeatMode.apply;
    liveInfo.coverURL = coverUrl ?? Constants.defaultCoverUrl;
    liveInfo.backgroundURL = Constants.defaultBackgroundUrl;
    liveInfo.isPublicVisible = privacyMode == LiveStreamPrivacyStatus.public;
    liveInfo.activityStatus = widget.liveInfo?.activityStatus ?? 0;
    liveInfo.keepOwnerOnSeat = true;
    liveInfo.seatTemplate = LiveInfoUtils.convertToSeatLayoutTemplateByID(templateMode.id);

    final result = await LiveListStore.shared.createLive(liveInfo);
    if (result.errorCode != TUIError.success.rawValue) {
      _toastAndPop(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      return;
    }
    if (templateMode == LiveTemplateMode.horizontalDynamic) {
      if (Platform.isIOS) {
        _showScreenShareGuideDialog();
      }
      LiveKitLogger.info("templateMode is 200, startScreenShare after startLive!");
      _liveStreamManager.mediaManager.startScreenShare();
    }
    _liveStreamManager.onStartLive(false, result.liveInfo);
    _startForegroundService();
  }

  void _showScreenShareGuideDialog() {
    _liveStreamManager.mediaManager.launchReplayKitBroadcast();
    _iOSScreenShareGuideDialog.show(
      context: context,
      onCancel: () {
        _liveStreamManager.mediaManager.stopScreenShare();
      },
      onConfirm: () {
        _liveStreamManager.mediaManager.launchReplayKitBroadcast();
      },
    );
  }

  void _toastAndPop(String toast) {
    makeToast(msg: toast);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startCamera() async {
    final startCameraResult = await _liveStreamManager.mediaManager.openLocalCamera(true);
    if (startCameraResult.code != TUIError.success) {
      _liveStreamManager.toastSubject
          .add(ErrorHandler.convertToErrorMessage(startCameraResult.code.rawValue, startCameraResult.message) ?? '');
    }
  }

  void _startMicrophone() async {
    final startMicrophoneResult = await _liveStreamManager.mediaManager.openLocalMicrophone();
    if (startMicrophoneResult.code != TUIError.success) {
      _liveStreamManager.toastSubject.add(
          ErrorHandler.convertToErrorMessage(startMicrophoneResult.code.rawValue, startMicrophoneResult.message) ?? '');
    }
  }

  void _startForegroundService() async {
    final seatTemplate = _liveStreamManager.roomState.liveInfo.seatTemplate;
    LiveKitLogger.info("_startForegroundService, seatTemplate=$seatTemplate");
    if (seatTemplate is VideoLandscape4Seats) {
      _startAudioForegroundService();
    } else {
      _startVideoForegroundService();
    }
  }

  void _stopForegroundService() {
    final seatTemplate = _liveStreamManager.roomState.liveInfo.seatTemplate;
    LiveKitLogger.info("_stopForegroundService, seatTemplate=$seatTemplate");
    if (seatTemplate is VideoLandscape4Seats) {
      _stopAudioForegroundService();
    } else {
      _stopVideoForegroundService();
    }
  }

  void _startVideoForegroundService() async {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;
    final hasCameraPermission = await Permission.camera.status == PermissionStatus.granted;
    if (!hasCameraPermission) {
      LiveKitLogger.error(
          '[ForegroundService] failed to start video foreground service. reason: without camera permission');
      return;
    }
    TUILiveKitPlatform.instance.startForegroundService(ForegroundServiceType.video, "", description);
  }

  void _stopVideoForegroundService() {
    TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.video);
    Permission.camera.onGrantedCallback(null);
  }

  void _startAudioForegroundService() async {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;
    final hasMicrophonePermission = await Permission.microphone.status == PermissionStatus.granted;
    if (!hasMicrophonePermission) {
      LiveKitLogger.error(
          '[ForegroundService] failed to start audio foreground service. reason: without microphone permission');
      return;
    }
    TUILiveKitPlatform.instance.startForegroundService(ForegroundServiceType.audio, "", description);
  }

  void _stopAudioForegroundService() {
    TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.audio);
    Permission.microphone.onGrantedCallback(null);
  }

  void _addObserver() {
    _liveStreamManager.floatWindowState.floatWindowMode.addListener(_onFloatWindowModeChangedListener);
    widget.floatWindowController?.isFullScreen.addListener(_onFullScreenChangedListener);
    _liveStreamManager.mediaState.isScreenCaptured.addListener(_onScreenCaptureListener);
  }

  void _removeObserver() {
    _liveStreamManager.floatWindowState.floatWindowMode.removeListener(_onFloatWindowModeChangedListener);
    widget.floatWindowController?.isFullScreen.removeListener(_onFullScreenChangedListener);
    _liveStreamManager.mediaState.isScreenCaptured.removeListener(_onScreenCaptureListener);
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

  void _onScreenCaptureChanged() {
    if (_liveStreamManager.mediaState.isScreenCaptured.value) _iOSScreenShareGuideDialog.dismiss();
  }
}
