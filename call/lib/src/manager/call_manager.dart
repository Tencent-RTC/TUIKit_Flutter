import 'dart:async';

import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tencent_calls_uikit/src/manager/call_page_router.dart';

class CallManager {
  CallManager._();

  static final CallManager _instance = CallManager._();
  static CallManager get instance => _instance;

  CallPageRouter? _pageManager;

  void bindPageManager(CallPageRouter pageManager) {
    _pageManager = pageManager;
  }

  Future<CompletionHandler> setSelfInfo(UserProfile userInfo) {
    return LoginStore.shared.setSelfInfo(userInfo: userInfo);
  }

  Future<CompletionHandler> calls(
    List<String> userIdList,
    CallMediaType callMediaType, [
    CallParams? params,
  ]) async {
    final hasPermission = await _ensureAudioVideoPermission(callMediaType);
    if (!hasPermission) {
      _pageManager?.handleNoPermissionAndEndCall();
      final handler = CompletionHandler();
      handler.errorCode = -1101;
      handler.errorMessage = 'Failed to obtain audio and video permissions';
      return handler;
    }

    return CallStore.shared.calls(userIdList, callMediaType, params);
  }

  Future<CompletionHandler> join(String callId) {
    return CallStore.shared.join(callId);
  }

  Future<void> accept() async {
    final activeCall = CallStore.shared.state.activeCall.value;
    final mediaType = activeCall.mediaType;
    if (mediaType == null) {
      return;
    }

    final canProceed = await _runPermissionGate(
      callId: activeCall.callId,
      mediaType: mediaType,
    );
    if (!canProceed) {
      return;
    }
    unawaited(_openDevices(mediaType));
    await CallStore.shared.accept();
  }

  Future<void> reject() {
    return CallStore.shared.reject();
  }

  Future<void> hangup() {
    return CallStore.shared.hangup();
  }

  Future<void> openLocalMicrophone() async {
    await DeviceStore.shared.openLocalMicrophone();
  }

  Future<void> closeLocalMicrophone() async {
    DeviceStore.shared.closeLocalMicrophone();
  }

  Future<void> openLocalCamera(bool isFront) async {
    final hasPermission = await _ensurePermission(PermissionType.camera);
    if (!hasPermission) {
      _pageManager?.handleNoPermissionAndEndCall();
      return;
    }
    await DeviceStore.shared.openLocalCamera(isFront);
  }

  Future<void> closeLocalCamera() async {
    DeviceStore.shared.closeLocalCamera();
  }

  Future<void> switchCamera(bool isFront) async {
    DeviceStore.shared.switchCamera(isFront);
  }

  Future<void> setAudioRoute(AudioRoute route) async {
    DeviceStore.shared.setAudioRoute(route);
  }

  Future<void> prepareCallDevices({
    required String callId,
    required CallMediaType mediaType,
    required bool isCalled,
  }) async {
    final activeCall = _activeCallMatching(callId);
    if (activeCall == null) {
      return;
    }

    final canProceed = await _runPermissionGate(
      callId: callId,
      mediaType: mediaType,
    );
    if (!canProceed) {
      return;
    }
    unawaited(_openDevices(mediaType));
  }

  Future<void> openLocalCameraIfPermitted() async {
    final cameraStatus = await Permission.check(PermissionType.camera);
    if (cameraStatus != PermissionStatus.granted) {
      return;
    }
    await DeviceStore.shared.openLocalCamera(true);
  }

  CallInfo? _activeCallMatching(String expectedCallId) {
    final activeCall = CallStore.shared.state.activeCall.value;
    if (activeCall.callId != expectedCallId) {
      return null;
    }
    return activeCall;
  }

  Future<bool> _runPermissionGate({
    required String callId,
    required CallMediaType mediaType,
  }) async {
    final hasPermission = await _ensureAudioVideoPermission(mediaType);
    if (_activeCallMatching(callId) == null) {
      return false;
    }
    if (!hasPermission) {
      _pageManager?.handleNoPermissionAndEndCall();
      return false;
    }
    return true;
  }

  Future<void> _openDevices(CallMediaType mediaType) async {
    await openLocalMicrophone();
    await setAudioRoute(
      mediaType == CallMediaType.audio
          ? AudioRoute.earpiece
          : AudioRoute.speakerphone,
    );
    if (mediaType == CallMediaType.video) {
      await DeviceStore.shared.openLocalCamera(true);
    }
  }

  Future<bool> _ensureAudioVideoPermission(CallMediaType mediaType) async {
    final micOk = await _ensurePermission(PermissionType.microphone);
    if (!micOk) {
      return false;
    }
    if (mediaType == CallMediaType.video) {
      final cameraOk = await _ensurePermission(PermissionType.camera);
      if (!cameraOk) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _ensurePermission(PermissionType type) async {
    final status = await Permission.check(type);
    if (_isUsable(status)) {
      return true;
    }
    if (status == PermissionStatus.permanentlyDenied) {
      return false;
    }
    final result = await Permission.request([type]);
    return _isUsable(result[type] ?? PermissionStatus.denied);
  }

  bool _isUsable(PermissionStatus status) =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.limited;
}
