import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';

class ForegroundService {
  static bool _isStarted = false;

  static void start() async {
    if (_isStarted) return;

    final cameraStatus = await Permission.check(PermissionType.camera);
    if (cameraStatus == PermissionStatus.granted) {
      TUICallKitPlatform.instance.startForegroundService(true);
      _isStarted = true;
      return;
    }

    final microphoneStatus = await Permission.check(PermissionType.microphone);
    if (microphoneStatus == PermissionStatus.granted) {
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