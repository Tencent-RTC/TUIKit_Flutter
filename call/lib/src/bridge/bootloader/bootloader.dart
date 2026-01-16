import 'package:flutter/cupertino.dart';
import 'package:tencent_calls_uikit/src/tui_call_kit_impl.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';
import 'package:tencent_calls_uikit/src/bridge/chat/deprecated/call_service.dart';
import 'package:tencent_calls_uikit/src/bridge/chat/deprecated/call_ui_extension.dart';
import 'package:tencent_calls_uikit/src/bridge/chat/event_bus_handler.dart';

class Bootloader extends NavigatorObserver {
  static Bootloader get instance => _instance;
  static final Bootloader _instance = Bootloader();

  Bootloader() {
    _bootstrap();
  }

  ITUINotificationCallback loginSuccessCallBack = (arg) {
    TUICallKitImpl.instance.handleLoginSuccess(arg['sdkAppId'], arg['userId'], arg['userSig']);
  };

  ITUINotificationCallback logoutSuccessCallBack = (arg) {
    TUICallKitImpl.instance.handleLogoutSuccess();
  };

  ITUINotificationCallback imSDKInitSuccessCallBack = (arg) {
    TUICallKitPlatform.instance.imSDKInitSuccess();
  };

  _bootstrap() {
    EventBusHandler.instance;
    TUICallKitPlatform.instance;

    TUICore.instance.registerService(TUICALLKIT_SERVICE_NAME, CallService.instance);
    TUICore.instance.registerExtension(TUIExtensionID.joinInGroup, CallUIExtension.instance);

    TUICore.instance.registerEvent(loginSuccessEvent, loginSuccessCallBack);
    TUICore.instance.registerEvent(logoutSuccessEvent, logoutSuccessCallBack);

    TUICore.instance.registerEvent(imSDKInitSuccessEvent, imSDKInitSuccessCallBack);
  }
}
