import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';
import 'package:atomic_x/atomicx.dart';

class FcmDataSyncHandler {
  void openNotificationView(String name, String avatar, TUICallMediaType mediaType) {
    TUICallKitPlatform.instance.openAndroidNotificationView(name, avatar, mediaType);
  }

  void closeNotificationView() {
    TUICallKitPlatform.instance.closeAndroidNotificationView();
  }

  void handleFcmReject() {
    CallListStore.shared.reject();
  }

  void handleFcmAccept() {
    CallListStore.shared.accept();
  }
}