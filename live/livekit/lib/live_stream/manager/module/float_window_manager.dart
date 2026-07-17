import 'dart:convert';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';

import '../../../common/widget/float_window/float_window_mode.dart';
import '../../state/float_window_state.dart';
import '../live_stream_manager.dart';

class FloatWindowManager {
  final LSFloatWindowState floatWindowState = LSFloatWindowState();

  late final Context context;

  late final VoidCallback _onPipModeChangedListener = _onPipModeChanged;
  late final VoidCallback _onFloatWindowModeChangedListener = _onFloatWindowModeChanged;

  void init(Context context) {
    this.context = context;
    TUILiveKitPlatform.instance.onPipModeChanged.listen((isPipMode) {
      floatWindowState.pipMode.value = isPipMode;
    });
    floatWindowState.pipMode.addListener(_onPipModeChangedListener);
    floatWindowState.floatWindowMode.addListener(_onFloatWindowModeChangedListener);
  }

  void dispose() {
    floatWindowState.pipMode.removeListener(_onPipModeChangedListener);
    floatWindowState.floatWindowMode.removeListener(_onFloatWindowModeChangedListener);
  }

  void enablePipMode(bool enable) {
    if (floatWindowState.enablePipMode is ValueNotifier<bool>) {
      ValueNotifier<bool> enablePipMode = floatWindowState.enablePipMode as ValueNotifier<bool>;
      enablePipMode.value = enable;
    }
  }

  void setScreenOrientation(bool isLandscape) {
    if (floatWindowState.isLandscape is ValueNotifier<bool>) {
      (floatWindowState.isLandscape as ValueNotifier<bool>).value = isLandscape;
    }
  }

  Future<bool> enablePictureInPicture(String roomId, bool enable, {bool isLandscape = false}) async {
    final jsonString = _buildEnablePipJsonParams(enable, roomId, isLandscape: isLandscape);
    return TUILiveKitPlatform.instance.enablePictureInPicture(jsonString);
  }

  String _buildEnablePipJsonParams(
    bool enable,
    String roomId, {
    bool isLandscape = false,
    Size canvasSize = const Size(720, 1280),
  }) {
    Map<String, dynamic> jsonObject = {
      'api': 'enablePictureInPicture',
      'params': {
        "room_id": roomId,
        "enable": enable,
        "camBackgroundCapture": true,
        "canvas": {
          "width": isLandscape ? canvasSize.height : canvasSize.width,
          "height": isLandscape ? canvasSize.width : canvasSize.height,
          "backgroundColor": "#000000"
        },
        "regions": [
          {
            "userId": "",
            "userName": "",
            "width": 1,
            "height": 1,
            "x": 0,
            "y": 0,
            "streamType": "high",
            "backgroundColor": "#000000",
            "backgroundImage": "" // /path/to/user1_placeholder.png
          }
        ]
      }
    };
    final jsonString = jsonEncode(jsonObject);
    return jsonString;
  }

  void _onPipModeChanged() {
    if (floatWindowState.floatWindowMode is ValueNotifier<FloatWindowMode>) {
      (floatWindowState.floatWindowMode as ValueNotifier<FloatWindowMode>).value =
          floatWindowState.pipMode.value ? FloatWindowMode.outOfApp : FloatWindowMode.none;
    }
  }

  void _onFloatWindowModeChanged() {
    final liveInfo = LiveListStore.shared.liveState.currentLive.value;
    LiveKitLogger.info("Live(liveID=${liveInfo.liveID}) float window mode: ${floatWindowState.floatWindowMode.value}");
    if (floatWindowState.isFloatWindowMode is ValueNotifier<bool>) {
      (floatWindowState.isFloatWindowMode as ValueNotifier<bool>).value =
          floatWindowState.floatWindowMode.value != FloatWindowMode.none;
    }
    if (floatWindowState.isFloatWindowMode.value) {
      GlobalFloatWindowManager.instance.setRoomId(liveInfo.liveID);
    }
  }
}
