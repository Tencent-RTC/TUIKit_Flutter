import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_mode.dart';

import 'global_float_window_state.dart';

/// Lifecycle events dispatched by [OverlayManager] whenever the overlay
/// entry is inserted into / removed from the root overlay.
enum OverlayEvent { inserted, removed }

/// Two scenarios:
/// 1.In-app : Overlay
/// 2.out-of-app : PIP
class GlobalFloatWindowManager {
  static final GlobalFloatWindowManager instance = GlobalFloatWindowManager._internal();

  final OverlayManager overlayManager = OverlayManager();
  final GlobalFloatWindowState state = GlobalFloatWindowState();
  VoidCallback? onOverlayClosed;

  factory GlobalFloatWindowManager() {
    return instance;
  }

  GlobalFloatWindowManager._internal();

  void setFloatWindowMode(FloatWindowMode mode) {
    if (state.floatWindowMode is ValueNotifier<FloatWindowMode>) {
      (state.floatWindowMode as ValueNotifier<FloatWindowMode>).value = mode;
    }
  }

  void setOverlayClosedCallback(VoidCallback? callback) {
    onOverlayClosed = callback;
  }

  void enableFloatWindowFeature(bool enable) {
    state.enableFloatWindowFeature = enable;
  }

  bool isEnableFloatWindowFeature() {
    return state.enableFloatWindowFeature;
  }

  bool isFloating() {
    return state.floatWindowMode.value != FloatWindowMode.none;
  }

  void setRoomId(String roomId) {
    if (state.roomId is ValueNotifier<String>) {
      (state.roomId as ValueNotifier<String>).value = roomId;
    }
  }

  void setOwnerId(String userId) {
    if (state.ownerId is ValueNotifier<String>) {
      (state.ownerId as ValueNotifier<String>).value = userId;
    }
  }

  void switchToFullScreenMode() {
    overlayManager.switchToFullScreenMode();
  }
}

class OverlayManager {
  OverlayState? _rootOverlay;
  OverlayEntry? _overlayEntry;
  VoidCallback? _switchToFullScreenMode;

  final StreamController<OverlayEvent> _eventController = StreamController<OverlayEvent>.broadcast();

  Stream<OverlayEvent> get eventStream => _eventController.stream;

  bool get isShowing => _overlayEntry != null;

  void showOverlayEntry(OverlayEntry overlayEntry) {
    _rootOverlay = Navigator.of(Global.appContext(), rootNavigator: true).overlay;
    if (_rootOverlay == null) {
      LiveKitLogger.error("OverlayManager, _rootOverlay is null");
      return;
    }
    LiveKitLogger.info("OverlayManager, showOverlayEntry, _rootOverlay.mounted = ${_rootOverlay!.mounted}");
    _rootOverlay?.insert(overlayEntry);
    _overlayEntry = overlayEntry;
    _dispatch(OverlayEvent.inserted);
  }

  void closeOverlay() {
    LiveKitLogger.error("OverlayManager, closeOverlay, _overlayEntry = $_overlayEntry");
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _switchToFullScreenMode = null;
      GlobalFloatWindowManager.instance.onOverlayClosed?.call();
      GlobalFloatWindowManager.instance.setRoomId("");
      GlobalFloatWindowManager.instance.setOwnerId("");
      GlobalFloatWindowManager.instance.setFloatWindowMode(FloatWindowMode.none);
      TUILiveKitPlatform.instance.exitPictureInPicture();
      _dispatch(OverlayEvent.removed);
    }
  }

  void switchToFullScreenMode() {
    _switchToFullScreenMode?.call();
  }

  void setSwitchToFullScreenCallback(VoidCallback callback) {
    _switchToFullScreenMode = callback;
  }

  void _dispatch(OverlayEvent event) {
    if (_eventController.isClosed) return;
    LiveKitLogger.info("OverlayManager dispatch: $event");
    _eventController.add(event);
  }
}
