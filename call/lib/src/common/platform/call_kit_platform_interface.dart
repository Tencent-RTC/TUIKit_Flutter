import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'call_kit_method_channel.dart';

abstract class TUICallKitPlatform extends PlatformInterface {
  TUICallKitPlatform() : super(token: _token);
  static final Object _token = Object();
  static TUICallKitPlatform _instance = MethodChannelTUICallKit();
  static TUICallKitPlatform get instance => _instance;
  static set instance(TUICallKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void startVibration() {
    instance.startVibration();
  }

  void stopVibration() {
    instance.stopVibration();
  }

  void openAndroidNotificationView(String name, String avatar, CallMediaType mediaType) {
    instance.openAndroidNotificationView(name, avatar, mediaType);
  }

  void closeAndroidNotificationView() {
    instance.closeAndroidNotificationView();
  }

  void startForegroundService(bool isVideo) {
    instance.startForegroundService(isVideo);
  }

  void stopForegroundService() {
    instance.stopForegroundService();
  }
}
