import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';

class ForegroundService {
  static bool _isStarted = false;

  static void start() async {
    if (_isStarted) return;

    if (await Permission.camera.status.isGranted) {
      TUICallKitPlatform.instance.startForegroundService(true);
      _isStarted = true;
    }
    else if (await Permission.microphone.status.isGranted) {
      TUICallKitPlatform.instance.startForegroundService(false);
      _isStarted = true;
    }
  }

  static void stop() {
    if (!_isStarted) {
      return;
    }
    _isStarted = false;
    TUICallKitPlatform.instance.stopForegroundService();
  }
}