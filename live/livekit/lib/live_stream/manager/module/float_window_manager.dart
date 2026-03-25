import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../../common/platform/rtc_live_tuikit_platform_interface.dart';
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
    double w = 1.0;
    double h = isLandscape ? 9.0 / 16 * canvasSize.width / canvasSize.height : 1.0;
    double x = 0.0;
    double y = isLandscape ? (1 - h) / 2.0 : 0.0;
    Map<String, dynamic> jsonObject = {
      'api': 'enablePictureInPicture',
      'params': {
        "room_id": roomId,
        "enable": enable,
        "camBackgroundCapture": true,
        "canvas": {"width": canvasSize.width, "height": canvasSize.height, "backgroundColor": "#000000"},
        "regions": [
          {
            "userId": "",
            "userName": "",
            "width": w,
            "height": h,
            "x": x,
            "y": y,
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
    if (floatWindowState.isFloatWindowMode is ValueNotifier<bool>) {
      (floatWindowState.isFloatWindowMode as ValueNotifier<bool>).value =
          floatWindowState.floatWindowMode.value != FloatWindowMode.none;
    }
  }
}
