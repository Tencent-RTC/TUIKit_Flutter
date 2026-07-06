import 'dart:async';
import 'dart:io';

import 'package:tencent_calls_uikit/src/common/metrics/key_metrics.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tencent_calls_uikit/src/common/widget/global.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';
import 'package:tencent_calls_uikit/src/common/utils/foreground_service.dart';
import 'package:tencent_calls_uikit/src/feature/calling_bell_feature.dart';
import 'package:tencent_calls_uikit/src/manager/call_manager.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:tencent_calls_uikit/src/tui_call_kit.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_calls_uikit/src/manager/call_page_router.dart';
import 'bridge/bootloader/bootloader.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide CallEndReason;
import 'bridge/voip/fcm_data_sync_handler.dart';
import 'bridge/voip/voip_data_sync_handler.dart';
import 'common/utils/error_parser.dart';
import 'feature/ios_pip_feature.dart';

class TUICallKitImpl implements TUICallKit {
  static final TUICallKitImpl _instance = TUICallKitImpl();
  static TUICallKitImpl get instance => _instance;
  late final CallPageRouter pageRouter;
  IosPipFeature? pictureInPictureFeature;
  late final voIPDataSyncHandler;
  late final fcmDataSyncHandler;
  final contactStore = ContactStore.shared;
  bool isNotificationPreparing = false;
  late CallEventListener callEventListener = CallEventListener(
    onCallStarted: (callId, mediaType) async {
      await CallManager.instance.prepareCallDevices(
        callId: callId,
        mediaType: mediaType,
        isCalled: false,
      );
      if (GlobalState.instance.enableAITranscriber) {
        aiTranscriberConfigManager.start();
      }
    },
    onCallReceived: (String callId, CallMediaType mediaType, String userData) async {
      KeyMetrics.instance.countUV(EventId.received);
      if (mediaType == CallMediaType.video) {
        await CallManager.instance.openLocalCameraIfPermitted();
      }
    },
    onCallEnded: (callId, mediaType, reason, userId) {
      CallManager.instance.closeLocalMicrophone();
      aiTranscriberConfigManager.reset(preserveSettings: false);
      _closePage();
      ForegroundService.stop();
      if (CallStore.shared.state.activeCall.value.inviteeIds.length > 1
          || CallStore.shared.state.activeCall.value.chatGroupId.isNotEmpty
          || CallStore.shared.state.selfInfo.value.id == userId) {
        return;
      }
      final l10n = AtomicLocalizations.of(Global.appContext());
      switch (reason) {
        case CallEndReason.hangup:
          TUIToast.show(content: l10n.callOtherPartyHungUp);
          break;
        case CallEndReason.unknown:
          break;
        case CallEndReason.reject:
          TUIToast.show(content: l10n.callOtherPartyDeclinedCallRequest);
          break;
        case CallEndReason.noResponse:
          TUIToast.show(content: l10n.callOtherPartyNoResponse);
          break;
        case CallEndReason.offline:
          break;
        case CallEndReason.lineBusy:
          TUIToast.show(content: l10n.callOtherPartyBusy);
          break;
        case CallEndReason.canceled:
          break;
        case CallEndReason.otherDeviceAccepted:
          break;
        case CallEndReason.otherDeviceReject:
          break;
        case CallEndReason.endByServer:
          break;
        }
    }
  );

  TUICallKitImpl() {
    CallStore.shared;
    voIPDataSyncHandler = VoIPDataSyncHandler();
    fcmDataSyncHandler = FcmDataSyncHandler();
    pageRouter = CallPageRouter(navigatorGetter: () => Bootloader.instance.navigator);
    CallManager.instance.bindPageManager(pageRouter);
    _subscribeState();
  }

  @override
  Future<CompletionHandler> login(int sdkAppId, String userId, String userSig) async {
    final completer = Completer<CompletionHandler>();
    TUILogin.instance.login(sdkAppId, userId, userSig, TUICallback(
      onSuccess: () {
        CompletionHandler handler = CompletionHandler();
        handler.errorCode = 0;
        handler.errorMessage = "success";
        completer.complete(handler);
      },
      onError: (code, message) {
        handleErrorCode(code);
        CompletionHandler handler = CompletionHandler();
        handler.errorCode = code;
        handler.errorMessage = message;
        completer.complete(handler);
      }
    ));
    return completer.future;
  }

  @override
  Future<void> logout() async {
    TUILogin.instance.logout(TUICallback(
      onSuccess: () {},
      onError: (code, message) {},
    ));
  }

  @override
  Future<CompletionHandler> setSelfInfo(String nickname, String avatar) async {
    UserProfile userInfo = UserProfile(
        userID: LoginStore.shared.loginState.loginUserInfo!.userID,
        nickname: nickname,
        avatarURL: avatar,
        selfSignature: LoginStore.shared.loginState.loginUserInfo!.selfSignature,
        gender: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .gender,
        role: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .role,
        level: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .level,
        birthday: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .birthday,
        allowType: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .allowType,
        customInfo: LoginStore
            .shared
            .loginState
            .loginUserInfo!
            .customInfo);
    return CallManager.instance.setSelfInfo(userInfo);
  }

  @override
  Future<CompletionHandler> calls(List<String> userIdList, callMediaType, [CallParams? params]) async {
    final handler = await CallManager.instance.calls(userIdList, callMediaType, params);
    handleErrorCode(handler.errorCode);
    return handler;
  }

  @override
  Future<void> join(String callId) async {
    final handler = await CallManager.instance.join(callId);
    handleErrorCode(handler.errorCode);
  }

  @override
  Future<void> enableFloatWindow(bool enable) async {
    GlobalState.instance.setEnableFloatWindow(enable);
  }

  @override
  void enableIncomingBanner(bool enable) {
    GlobalState.instance.setEnableIncomingBanner(enable);
  }

  @override
  Future<void> enableMuteMode(bool enable) async {
    GlobalState.instance.setEnableMuteMode(enable);
  }

  @override
  Future<void> enableVirtualBackground(bool enable) async {
    GlobalState.instance.setEnableBlurBackground(enable);
  }

  @override
  Future<void> enableAITranscriber(bool enable) async {
    GlobalState.instance.setEnableAITranscriber(enable);
  }

  @override
  Future<void> setCallingBell(String assetName) {
    GlobalState.instance.setCallingBellAssetName(assetName);
    return Future.value();
  }

  @override
  Future<void> callExperimentalAPI(String json) {
    return Future.value();
  }

  void handleLoginSuccess(int sdkAppID, String userId, String userSig) {
    TUICallEngine.instance.init(sdkAppID, userId, userSig);
    LoginStore.shared.login(
        sdkAppID: sdkAppID, userID: userId, userSig: userSig);
    CallStore.shared.addListener(callEventListener);
    CallingBellFeature.instance.init();
    if (Platform.isIOS) {
      pictureInPictureFeature = IosPipFeature();
    }
  }

  void handleLogoutSuccess() async {
    TUICallEngine.instance.unInit();
    CallStore.shared.removeListener(callEventListener);
    CallingBellFeature.instance.dispose();
    LoginStore.shared.logout();
    if (Platform.isIOS && pictureInPictureFeature != null) {
      pictureInPictureFeature!.dispose();
      pictureInPictureFeature = null;
    }
  }

  void _subscribeState() {
    CallStore.shared.state.selfInfo.addListener(() async {
      final activeCall = CallStore.shared.state.activeCall.value;
      if (activeCall.mediaType == null) {
        return;
      }

      final callStatus = CallStore.shared.state.selfInfo.value.status;

      if (callStatus == CallParticipantStatus.waiting) {
        _showPage();
      } else if (callStatus == CallParticipantStatus.accept) {
        _showPage();
      } else if (callStatus == CallParticipantStatus.none) {
        _closePage();
      }
    });
  }

  void _showPage() async {
    if (pageRouter.getCurrentPageRoute() != CallPageType.none) return;

    final activeCall = CallStore.shared.state.activeCall.value;
    if (AppLifecycle.instance.isBackground && activeCall.inviterId.isNotEmpty) {
      final handler = await contactStore.getContactInfo(userIDList: [activeCall.inviterId]);
      if (handler.isSuccess && handler.contactInfoList.isNotEmpty) {
        final selfInfo = CallStore.shared.state.selfInfo.value;
        final contactInfo = handler.contactInfoList.first;
        if (activeCall.inviterId != selfInfo.id && activeCall.mediaType != null) {
          fcmDataSyncHandler.openNotificationView(
            contactInfo.nickname ?? "",
            contactInfo.avatarURL ?? "",
            activeCall.mediaType!,
          );
        }
      }
      isNotificationPreparing = true;
    }

    if (GlobalState.instance.enableIncomingBanner &&
        CallStore.shared.state.selfInfo.value.id !=
            CallStore.shared.state.activeCall.value.inviterId &&
        CallStore.shared.state.selfInfo.value.status == CallParticipantStatus.waiting) {
      pageRouter.showIncomingBanner();
    } else {
      pageRouter.showCallingPage();
    }
  }

  void _closePage() async {
    if (pageRouter.getCurrentPageRoute() == CallPageType.none) return;

    isNotificationPreparing = false;
    fcmDataSyncHandler.closeNotificationView();
    pageRouter.closeAllPage();
  }

  void handleErrorCode(int errorCode) {
    final errorMessage = ErrorParser.getErrorMessage(errorCode, AtomicLocalizations.of(Global.appContext()));
    if (errorMessage != null) {
      TUIToast.show(content: errorMessage);
    }
  }
}
