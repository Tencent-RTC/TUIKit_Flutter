import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';

class FcmDataSyncHandler {
  FcmDataSyncHandler() {
    AppLifecycle.instance.currentState.addListener(_onAppLifecycleChanged);
  }

  void _onAppLifecycleChanged() {
    if (AppLifecycle.instance.isForeground) {
      closeNotificationView();
    }
  }

  void openNotificationView(String name, String avatar, CallMediaType mediaType) {
    if (AppLifecycle.instance.isBackground) {
      TUICallKitPlatform.instance.openAndroidNotificationView(name, avatar, mediaType);
    }
  }

  void closeNotificationView() {
    TUICallKitPlatform.instance.closeAndroidNotificationView();
  }

  void handleFcmReject() {
    CallStore.shared.reject();
  }

  void handleFcmAccept() {
    CallStore.shared.accept();
  }
}