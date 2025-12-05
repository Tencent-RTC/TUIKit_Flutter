import 'dart:async';
import 'dart:io';

import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:flutter/material.dart' as material;
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';
import 'package:tencent_calls_uikit/src/common/utils/foreground_service.dart';
import 'package:tencent_calls_uikit/src/feature/calling_bell_feature.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:tencent_calls_uikit/src/tui_call_kit.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_calls_uikit/src/view/call_page_manager.dart';
import 'bridge/bootloader/bootloader.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide CallEndReason;
import 'bridge/voip/fcm_data_sync_handler.dart';
import 'bridge/voip/voip_data_sync_handler.dart';
import 'common/utils/error_parser.dart';
import 'feature/ios_pip_feature.dart';

class TUICallKitImpl implements TUICallKit {
  static final TUICallKitImpl _instance = TUICallKitImpl();
  static TUICallKitImpl get instance => _instance;
  late final CallPageManager pageManager;
  IosPipFeature? pictureInPictureFeature;
  late final voIPDataSyncHandler;
  late final fcmDataSyncHandler;
  final contactListStore = ContactListStore.create();
  bool isNotificationPreparing = false;
  late CallEventListener callEventListener = CallEventListener(
    onCallEnded: (callId, mediaType, reason, userId) {
      _closePage();
      _stopRing();
      ForegroundService.stop();
      if (CallStore.shared.state.activeCall.value.inviteeIds.length > 1
          || CallStore.shared.state.activeCall.value.chatGroupId.isNotEmpty
          || CallParticipantStore.shared.state.selfInfo.value.id == userId) {
        return;
      }
      switch (reason) {
        case CallEndReason.hangup:
          TUIToast.show(content: CallKit_t("otherPartyHungUp"));
          break;
        case CallEndReason.unknown:
          break;
        case CallEndReason.reject:
          TUIToast.show(content: CallKit_t("otherPartyDeclinedCallRequest"));
          break;
        case CallEndReason.noResponse:
          TUIToast.show(content: CallKit_t("otherPartyNoResponse"));
          break;
        case CallEndReason.offline:
          break;
        case CallEndReason.lineBusy:
          TUIToast.show(content: CallKit_t("otherPartyBusy"));
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
    CallParticipantStore.shared;
    voIPDataSyncHandler = VoIPDataSyncHandler();
    fcmDataSyncHandler = FcmDataSyncHandler();
    pageManager = CallPageManager(navigatorGetter: () => Bootloader.instance.navigator);
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
    CompletionHandler handler = await LoginStore.shared.setSelfInfo(userInfo: userInfo);
    return handler;
  }

  @override
  Future<CompletionHandler> calls(List<String> userIdList, callMediaType, [CallParams? params]) async {
    bool isGroupCall = (userIdList.length > 1) || (params?.chatGroupId.isNotEmpty ?? false);
    final hasPermission = await _getAndroidAudioAndVideoPermission(callMediaType, isGroupCall);
    if (!hasPermission) {
      pageManager.handleNoPermissionAndEndCall(false);
      handleErrorCode(-1101);
      CompletionHandler handler = CompletionHandler();
      handler.errorCode = -1101;
      handler.errorMessage = "Failed to obtain audio and video permissions";
      return handler;
    }
    CompletionHandler handler = await CallStore.shared.calls(
        userIdList, callMediaType, params);

    handleErrorCode(handler.errorCode);
    
    return handler;
  }

  @override
  Future<void> join(String callId) async {
    CompletionHandler handler = await CallStore.shared.join(callId);
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
    if (Platform.isIOS) {
      pictureInPictureFeature = IosPipFeature();
    }
  }

  void handleLogoutSuccess() async {
    TUICallEngine.instance.unInit();
    CallStore.shared.removeListener(callEventListener);
    LoginStore.shared.logout();
    if (Platform.isIOS && pictureInPictureFeature != null) {
      pictureInPictureFeature!.dispose();
      pictureInPictureFeature = null;
    }
  }

  void _subscribeState() {
    contactListStore.addListener(() async {
      final activeCall = CallStore.shared.state.activeCall.value;
      final selfInfo = CallParticipantStore.shared.state.selfInfo.value;
      if (isNotificationPreparing && activeCall.inviterId.isNotEmpty) {
        if (contactListStore.contactListState.addFriendInfo?.contactID == activeCall.inviterId
            && activeCall.inviterId != selfInfo.id && activeCall.mediaType != null) {
          fcmDataSyncHandler.openNotificationView(
            contactListStore.contactListState.addFriendInfo?.title ?? "",
            contactListStore.contactListState.addFriendInfo?.avatarURL ?? "",
            activeCall.mediaType!,
          );
        }
      }
    });

    CallParticipantStore.shared.state.selfInfo.addListener(() async {
      final activeCall = CallStore.shared.state.activeCall.value;
      final isCalled = CallParticipantStore.shared.state.selfInfo.value.id != activeCall.inviterId;
      final isGroupCall = activeCall.inviteeIds.length > 1 || activeCall.chatGroupId.isNotEmpty;

      if (activeCall.mediaType == null) {
        return;
      }
      final hasPermission = await _getAndroidAudioAndVideoPermission(activeCall.mediaType!, isGroupCall);
      if (!hasPermission) { 
        pageManager.handleNoPermissionAndEndCall(isCalled);
        return;
      }

      final callStatus = CallParticipantStore.shared.state.selfInfo.value.status;

      if (callStatus == CallParticipantStatus.waiting) {
        _showPage();
        _startRing();
      } else if (callStatus == CallParticipantStatus.accept) {
        _showPage();
        _stopRing();
      } else if (callStatus == CallParticipantStatus.none) {
        _closePage();
        _stopRing();
      }
    });
  }

  Future<bool> _getAndroidAudioAndVideoPermission(CallMediaType mediaType, bool isGroupCall) async {
    if (mediaType == CallMediaType.video || isGroupCall) {
      final cameraStatus = await Permission.check(PermissionType.camera);
      final microphoneStatus = await Permission.check(PermissionType.microphone);
      
      if (cameraStatus == PermissionStatus.granted && microphoneStatus == PermissionStatus.granted) {
        return true;
      }
      
      final status = await Permission.request([PermissionType.camera, PermissionType.microphone]);
      if (status.containsValue(PermissionStatus.denied) ||
          status.containsValue(PermissionStatus.permanentlyDenied)) {
        return false;
      }
      return true;
    }

    if (mediaType == CallMediaType.audio) {
      final microphoneStatus = await Permission.check(PermissionType.microphone);
      
      if (microphoneStatus == PermissionStatus.granted) {
        return true;
      }
      
      final status = await Permission.request([PermissionType.microphone]);
      final micStatus = status[PermissionType.microphone];
      if (micStatus == PermissionStatus.denied ||
          micStatus == PermissionStatus.permanentlyDenied) {
        return false;
      }
      return true;
    }
    return true;
  }

  void _showPage() async {
    if (pageManager.getCurrentPageRoute() != CallPageType.none) return;

    final activeCall = CallStore.shared.state.activeCall.value;
    if (AppLifecycle.instance.isBackground && activeCall.inviterId.isNotEmpty) {
      contactListStore.fetchUserInfo(userID: activeCall.inviterId);
      isNotificationPreparing = true;
    }

    if (GlobalState.instance.enableIncomingBanner &&
        CallParticipantStore.shared.state.selfInfo.value.id !=
            CallStore.shared.state.activeCall.value.inviterId) {
      pageManager.showIncomingBanner();
    } else {
      pageManager.showCallingPage();
    }
  }

  void _closePage() async {
    if (pageManager.getCurrentPageRoute() == CallPageType.none) return;

    isNotificationPreparing = false;
    fcmDataSyncHandler.closeNotificationView();
    pageManager.closeAllPage();
  }

  void _startRing() async {
    await CallingBellFeature.instance.startRing();
  }

  void _stopRing() async {
    await CallingBellFeature.instance.stopRing();
  }

  void handleErrorCode(int errorCode) {
    final errorMessage = ErrorParser.getErrorMessage(errorCode);
    if (errorMessage != null) {
      TUIToast.show(content: errorMessage);
    }
  }
}