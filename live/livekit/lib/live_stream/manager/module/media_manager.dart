import 'dart:async';
import 'dart:io';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../api/live_stream_service.dart';
import '../../state/co_guest_state.dart';
import '../../state/media_state.dart';
import '../live_stream_manager.dart';
import '../../../common/platform/index.dart';

const kIOSAppGroup = ''; //'group.com.tencent.fx.livekit'

class MediaManager {
  LSMediaState mediaState = LSMediaState();

  late final Context context;
  late final LiveStreamService service;

  StreamSubscription<bool>? _screenCaptureSubscription;

  void init(Context context) {
    this.context = context;
    service = context.service;
    _enableMultiPlaybackQuality(true);
    _subscribeScreenCaptureState();
  }

  void dispose() {
    _enableMultiPlaybackQuality(false);
    _screenCaptureSubscription?.cancel();
    _screenCaptureSubscription = null;
  }

  void prepareLiveInfoBeforeEnterRoom(LiveInfo liveInfo) {
    _enableMultiPlaybackQuality(true);
  }

  Future<void> requestAllPermission() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    return Future.value();
  }

  Future<TUIActionCallback> openLocalCamera(bool useFrontCamera) async {
    var cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      return TUIActionCallback(code: TUIError.errPermissionDenied, message: 'camera permission denied');
    }

    final result = await DeviceStore.shared.openLocalCamera(useFrontCamera);
    if (result.errorCode == DeviceError.noError.value) {
      return TUIActionCallback(code: TUIError.success, message: "");
    }
    return TUIActionCallback(code: TUIError.errPermissionDenied, message: 'camera permission denied');
  }

  void closeLocalCamera() {
    DeviceStore.shared.closeLocalCamera();
  }

  Future<TUIActionCallback> openLocalMicrophone() async {
    var microphonePermission = await Permission.microphone.request();
    if (!microphonePermission.isGranted) {
      return TUIActionCallback(
          code: TUIError.errPermissionDenied,
          message: 'microphone permission denied');
    }

    final result = await DeviceStore.shared.openLocalMicrophone();
    if (result.errorCode == DeviceError.noError.value) {
      return TUIActionCallback(code: TUIError.success, message: "");
    }
    return TUIActionCallback(code: TUIError.errPermissionDenied, message: 'microphone permission denied');
  }

  void closeLocalMicrophone() {
    DeviceStore.shared.closeLocalMicrophone();
  }

  void launchReplayKitBroadcast() {
    if (Platform.isIOS) {
      ReplayKitLauncher.launchReplayKitBroadcast(kIOSAppGroup);
    }
  }

  void startScreenShare() {
    DeviceStore.shared.startScreenShare();
  }

  void stopScreenShare() {
    DeviceStore.shared.stopScreenShare();
  }

  void onJoinLive(LiveInfo liveInfo) async {
    final result = await getMultiPlaybackQuality(liveInfo.liveID);
    if (result.code != TUIError.success || result.data == null) {
      return;
    }
    final List<TUIVideoQuality> playbackQualityList = result.data as List<TUIVideoQuality>;
    mediaState.playbackQualityList.value = playbackQualityList;
  }

  void onLeaveLive() {
    mediaState = LSMediaState();
  }

  void onStopLive() {
    mediaState = LSMediaState();
    _enableMultiPlaybackQuality(false);
  }

  void setLocalVideoView(int viewId) {
    service.setLocalVideoView(viewId);
  }

  void onCameraOpened() {
    service.enableGravitySensor(true);
  }

  void updateVideoQuality(VideoQuality quality) {
    DeviceStore.shared.updateVideoQuality(quality);
  }

  Future<TUIValueCallBack<List<TUIVideoQuality>>> getMultiPlaybackQuality(String roomId) {
    return service.queryPlaybackQualityList(roomId);
  }

  void switchPlaybackQuality(TUIVideoQuality videoQuality) {
    service.switchPlaybackQuality(videoQuality);
    mediaState.playbackQuality.value = videoQuality;
  }

  void setAudioPlayoutVolume(int volume) {
    service.setAudioPlayoutVolume(volume);
    mediaState.currentPlayoutVolume.value = volume;
  }

  void pauseByAudience() {
    service.pauseByAudience();
    mediaState.isRemoteVideoStreamPaused.value = true;
  }

  void resumeByAudience() {
    service.resumeByAudience();
    mediaState.isRemoteVideoStreamPaused.value = false;
  }

  void onSelfMediaDeviceStateChanged(SeatInfo seatInfo) {
    mediaState.isAudioLocked.value = !seatInfo.userInfo.allowOpenMicrophone;
    mediaState.isVideoLocked.value = !seatInfo.userInfo.allowOpenCamera;
  }

  void onSelfLeaveSeat() {
    mediaState.isAudioLocked.value = false;
    mediaState.isVideoLocked.value = false;
  }

  void onUserVideoSizeChanged(String roomId, String userId, TUIVideoStreamType streamType, int width, int height) {
    final playbackQuality = _getVideoQualityByVideoSize(width, height);
    if (playbackQuality == mediaState.playbackQuality.value) {
      return;
    }
    if (mediaState.playbackQualityList.value.length <= 1 ||
        !mediaState.playbackQualityList.value.contains(playbackQuality)) {
      return;
    }
    if (context.coGuestManager.target?.coGuestState.coGuestStatus.value != CoGuestStatus.none) {
      return;
    }
    mediaState.playbackQuality.value = playbackQuality;
  }
}

extension on MediaManager {
  void _subscribeScreenCaptureState() {
    if (!Platform.isIOS) return;
    _screenCaptureSubscription = TUILiveKitPlatform.screenCaptureStateChanged.listen((isCaptured) {
      LiveKitLogger.info("screenCaptureStateChanged: isCaptured=$isCaptured");
      mediaState.isScreenCaptured.value = isCaptured;
    });
  }

  void _enableMultiPlaybackQuality(bool enable) {
    service.enableMultiPlaybackQuality(enable);
  }

  TUIVideoQuality _getVideoQualityByVideoSize(int width, int height) {
    if (width * height <= 360 * 640) {
      return TUIVideoQuality.videoQuality_360P;
    }
    if (width * height <= 540 * 960) {
      return TUIVideoQuality.videoQuality_540P;
    }
    if (width * height <= 720 * 1280) {
      return TUIVideoQuality.videoQuality_720P;
    }
    return TUIVideoQuality.videoQuality_1080P;
  }
}
