import 'package:atomic_x_core/api/device/audio_effect_store.dart';
import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_mode.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';
import 'package:tencent_live_uikit/seat_grid_widget/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';
import 'package:tencent_live_uikit/voice_room/widget/index.dart';

import '../common/widget/float_window/float_window_controller.dart';

const maxConnectedViewersCount = 10;

enum RoomBehavior { autoCreate, prepareCreate, join }

class RoomParams {
  int maxSeatCount;
  TUISeatMode seatMode;

  RoomParams({this.maxSeatCount = maxConnectedViewersCount, this.seatMode = TUISeatMode.applyToTake});
}

class TUIVoiceRoomWidget extends StatefulWidget {
  final String roomId;
  final RoomBehavior behavior;
  final RoomParams? params;
  final FloatWindowController? floatWindowController;

  const TUIVoiceRoomWidget({
    super.key,
    required this.roomId,
    required this.behavior,
    this.params,
    this.floatWindowController,
  });

  @override
  State<TUIVoiceRoomWidget> createState() => _TUIVoiceRoomWidgetState();
}

class _TUIVoiceRoomWidgetState extends State<TUIVoiceRoomWidget> {
  late final String liveID;
  late final RoomBehavior behavior;
  late final RoomParams? params;
  late final SeatGridController seatGridController;

  late final ValueNotifier<bool> _needToPrepare = ValueNotifier(false);
  final VoiceRoomPrepareStore _prepareStore = VoiceRoomPrepareStore();
  final ToastService _toastService = ToastServiceImpl();
  late final VoidCallback _onFullScreenChangedListener = _onFullScreenChanged;

  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveDataReporter.reportComponent(LiveComponentType.voiceRoom);
    _startForegroundService();
    liveID = widget.roomId;
    behavior = widget.behavior;
    params = widget.params;
    seatGridController = SeatGridController(liveID: liveID);
    _prepareStore.prepareLiveIdBeforeEnterRoom(liveID: liveID);
    _subscribeToast();
    _needToPrepare.value = behavior == RoomBehavior.prepareCreate;
    DeviceStore.shared.setFocus(DeviceFocusOwner.live);
    widget.floatWindowController?.isFullScreen.addListener(_onFullScreenChangedListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() &&
          Global.secondaryNavigatorKey.currentState != null
          && widget.floatWindowController == null) {
        String error = "You have enabled the floating window feature,"
            "but you are using TUIVoiceRoomWidget, Please switch to TUIVoiceRoomOverlay."
            "Or disable the floating window feature in the app's main.dart: "
            "GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);";
        LiveKitLogger.error(error);
        makeToast(msg: "Tip: Please use TUIVoiceRoomOverlay");
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    widget.floatWindowController?.isFullScreen.removeListener(_onFullScreenChangedListener);
    _unsubscribeToast();
    seatGridController.dispose();
    DeviceStore.shared.reset();
    AudioEffectStore.shared.reset();
    BarrageDisplayController.resetState();
    _stopForegroundService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [_initVoiceRoomRootWidget(), _initVoiceRoomPrepareWidget()],
      ),
    );
  }

  void _onFullScreenChanged() {
    if (widget.floatWindowController == null) return;
    bool isFullScreen = widget.floatWindowController!.isFullScreen.value;
    GlobalFloatWindowManager.instance.setFloatWindowMode(isFullScreen ? FloatWindowMode.none : FloatWindowMode.inApp);
  }

  Widget _initVoiceRoomPrepareWidget() {
    return ValueListenableBuilder(
        valueListenable: _needToPrepare,
        builder: (context, value, child) {
          return Visibility(
              visible: value,
              child: VoiceRoomPrepareWidget(
                  prepareStore: _prepareStore,
                  toastService: _toastService,
                  didClickStart: () {
                    _needToPrepare.value = false;
                  }));
        });
  }

  Widget _initVoiceRoomRootWidget() {
    return ValueListenableBuilder(
        valueListenable: _needToPrepare,
        builder: (context, value, child) {
          return Visibility(
              visible: !value,
              child: VoiceRoomRootWidget(
                liveID: liveID,
                prepareStore: _prepareStore,
                toastService: _toastService,
                seatGridController: seatGridController,
                isCreate: behavior != RoomBehavior.join,
                floatWindowController: widget.floatWindowController,
              ));
        });
  }
}

extension on _TUIVoiceRoomWidgetState {
  void _subscribeToast() {
    _toastService.subscribeToast((toast) => makeToast(msg: toast));
  }

  void _unsubscribeToast() {
    _toastService.unsubscribeToast();
  }

  void _startForegroundService() async {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;

    final hasMicrophonePermission = await Permission.microphone.status == PermissionStatus.granted;
    if (!hasMicrophonePermission) {
      LiveKitLogger.error(
          '[ForegroundService] failed to start audio foreground service. reason: without microphone permission');
      return;
    }
    TUILiveKitPlatform.instance.startForegroundService(ForegroundServiceType.audio, "", description);
  }

  void _stopForegroundService() {
    TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.audio);
    Permission.microphone.onGrantedCallback(null);
  }
}
