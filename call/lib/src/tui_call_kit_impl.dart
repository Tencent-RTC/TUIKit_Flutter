import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' as material;
import 'package:atomic_x/atomicx.dart';
import 'package:atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';
import 'package:tencent_calls_uikit/src/common/utils/foreground_service.dart';
import 'package:tencent_calls_uikit/src/feature/calling_bell_feature.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:tencent_calls_uikit/src/tui_call_kit.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_calls_uikit/src/view/call_page_manager.dart';
import 'bridge/bootloader/bootloader.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'bridge/voip/fcm_data_sync_handler.dart';
import 'bridge/voip/voip_data_sync_handler.dart';

class TUICallKitImpl implements TUICallKit {
  static final TUICallKitImpl _instance = TUICallKitImpl();
  static TUICallKitImpl get instance => _instance;
  late final CallPageManager pageManager;
  final voIPDataSyncHandler = VoIPDataSyncHandler();
  final fcmDataSyncHandler = FcmDataSyncHandler();
  final contactListStore = ContactListStore.create();
  bool isNotificationPreparing = false;
  late CallEventListener callEventListener = CallEventListener(
    onCallEnded: (reason, userId) {
      ForegroundService.stop();
      if (CallListStore.shared.state.activeCall.value.inviteeIds.length > 1
          || CallListStore.shared.state.activeCall.value.chatGroupId.isNotEmpty
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
    CallListStore.shared;
    CallParticipantStore.shared;
    pageManager = CallPageManager(navigatorGetter: () => Bootloader.instance.navigator);
    _subscribeState();
  }

  @override
  Future<TUIResult> login(int sdkAppId, String userId, String userSig) async {
    final completer = Completer<TUIResult>();
    TUILogin.instance.login(sdkAppId, userId, userSig, TUICallback(
      onSuccess: () {
        completer.complete(TUIResult(
          code: "0",
          message: "success",
        ));
      },
      onError: (code, message) {
        completer.complete(TUIResult(
          code: code.toString(),
          message: message,
        ));
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
  Future<TUIResult> setSelfInfo(String nickname, String avatar) async {
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
    return TUIResult(
      code: handler.errorCode.toString(),
      message: handler.errorMessage,
    );
  }

  @override
  Future<TUIResult> calls(List<String> userIdList, callMediaType, [TUICallParams? params]) async {
    bool isGroupCall = (userIdList.length > 1) || (params?.chatGroupId.isNotEmpty ?? false);
    final hasPermission = await _getAndroidAudioAndVideoPermission(callMediaType, isGroupCall);
    if (!hasPermission) {
      pageManager.handleNoPermissionAndEndCall(TUICallRole.caller);
      return TUIResult(
        code: "-1101",
        message: "Failed to obtain audio and video permissions",
      );
    }
    CompletionHandler handler = await CallListStore.shared.calls(
        userIdList, callMediaType, params);
    return TUIResult(
      code: handler.errorCode.toString(),
      message: handler.errorMessage,
    );
  }

  @override
  Future<void> join(String callId) async {
    await CallListStore.shared.join(callId);
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
    CallListStore.shared.addListener(callEventListener);
  }

  void handleLogoutSuccess() {
    TUICallEngine.instance.unInit();
    CallListStore.shared.removeListener(callEventListener);
    LoginStore.shared.logout();
  }

  void _subscribeState() {
    contactListStore.addListener(() async {
      final activeCall = CallListStore.shared.state.activeCall.value;
      if (isNotificationPreparing && activeCall.inviterId.isNotEmpty) {
        if (contactListStore.contactListState.addFriendInfo?.contactID == activeCall.inviterId) {
          fcmDataSyncHandler.openNotificationView(
            contactListStore.contactListState.addFriendInfo?.title ?? "",
            contactListStore.contactListState.addFriendInfo?.avatarURL ?? "",
            activeCall.mediaType,
          );
        }
      }
    });

    CallParticipantStore.shared.state.selfInfo.addListener(() async {
      final activeCall = CallListStore.shared.state.activeCall.value;
      final role = CallParticipantStore.shared.state.selfInfo.value.role;
      final isGroupCall = activeCall.inviteeIds.length > 1 || activeCall.chatGroupId.isNotEmpty;
      final hasPermission = await _getAndroidAudioAndVideoPermission(activeCall.mediaType, isGroupCall);

      if (!hasPermission) { 
        pageManager.handleNoPermissionAndEndCall(role);
        return;
      }

      final callStatus = CallParticipantStore.shared.state.selfInfo.value.status;

      if (callStatus == TUICallStatus.waiting) {
        _handleCallWaiting();
      } else if (callStatus == TUICallStatus.none) {
        _handleCallNone();
      } else {
        _handleOtherCallStatus();
      }
    });
  }

  Future<bool> _getAndroidAudioAndVideoPermission(TUICallMediaType mediaType, bool isGroupCall) async {

    if (mediaType == TUICallMediaType.video || isGroupCall) {
      final status = await [Permission.camera, Permission.microphone].request();
      if (status.containsValue(PermissionStatus.denied) || status.containsValue(PermissionStatus.permanentlyDenied)) {
        return false;
      }
      return true;
    }

    if (mediaType == TUICallMediaType.audio) {
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        return false;
      }
      return true;
    }

    return true;
  }

  void _handleCallWaiting() async {
    final activeCall = CallListStore.shared.state.activeCall.value;
    if (AppLifecycle.instance.isBackground && activeCall.inviterId.isNotEmpty) {
      contactListStore.fetchUserInfo(userID: activeCall.inviterId);
      isNotificationPreparing = true;
    }

    if (GlobalState.instance.enableIncomingBanner) {
      pageManager.showIncomingBanner();
    } else {
      pageManager.showCallingPage();
    }
    await CallingBellFeature.instance.startRing();
  }

  void _handleCallNone() async {
    isNotificationPreparing = false;
    await CallingBellFeature.instance.stopRing();
    fcmDataSyncHandler.closeNotificationView();
    pageManager.closeAllPage();
  }

  void _handleOtherCallStatus() async {
    await CallingBellFeature.instance.stopRing();
  }
}