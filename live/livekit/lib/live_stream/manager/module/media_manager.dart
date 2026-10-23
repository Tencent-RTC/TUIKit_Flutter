import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rtc_room_engine/api/common/tui_common_define.dart';
import 'package:rtc_room_engine/api/room/tui_room_engine.dart';
import 'package:rtc_room_engine/api/room/tui_room_observer.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../../component/beauty/live_beauty_store.dart';
import '../../../live_navigator_observer.dart';
import '../../state/co_guest_state.dart';
import '../../state/media_state.dart';
import '../live_stream_manager.dart';

const kIOSAppGroup = ''; //'group.com.tencent.fx.livekit'

typedef OpenCameraDelegate = Future<CompletionHandler> Function();

class MediaManager {
  LSMediaState mediaState = LSMediaState();

  late final Context context;

  StreamSubscription<bool>? _screenCaptureSubscription;

  TUIRoomObserver? _roomObserver;

  void init(Context context) {
    this.context = context;
    _enableMultiPlaybackQuality(true);
    _subscribeScreenCaptureState();
    _roomObserver ??= TUIRoomObserver(onUserVideoSizeChanged: (roomId, userId, streamType, width, height) {
      final currentRoomId = context.roomManager.target?.roomState.roomId;
      if (currentRoomId != roomId) return;
      _onUserVideoSizeChanged(userId, width, height);
    });
    TUIRoomEngine.sharedInstance().addObserver(_roomObserver!);
  }

  void dispose() {
    _enableMultiPlaybackQuality(false);
    _screenCaptureSubscription?.cancel();
    _screenCaptureSubscription = null;
    if (_roomObserver != null) {
      TUIRoomEngine.sharedInstance().removeObserver(_roomObserver!);
    }
  }

  void prepareLiveInfoBeforeEnterRoom(LiveInfo liveInfo) {
    _enableMultiPlaybackQuality(true);
  }

  void startForegroundService(ForegroundServiceType type) {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;
    TUILiveKitPlatform.instance.startForegroundService(type, "", description);
  }

  void stopForegroundService({ForegroundServiceType? type}) {
    if (type == null) {
      TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.audio);
      TUILiveKitPlatform.instance.stopForegroundService(ForegroundServiceType.video);
    } else {
      TUILiveKitPlatform.instance.stopForegroundService(type);
    }
  }

  void setLocalVideoView(int viewId) {
    TUIRoomEngine.sharedInstance().setLocalVideoView(viewId);
  }

  Future<CompletionHandler> openLocalCamera(bool useFrontCamera) {
    LiveBeautyStore.shared.enableBeauty(true);
    return _openLocalCamera(() {
      DeviceStore.shared.switchMirror(DeviceStore.shared.state.localMirrorType.value);
      final localVideoQuality = DeviceStore.shared.state.localVideoQuality.value;
      DeviceStore.shared.updateVideoQuality(localVideoQuality, orientation: VideoOrientation.portrait);
      return DeviceStore.shared.openLocalCamera(useFrontCamera);
    });
  }

  void closeLocalCamera() {
    LiveBeautyStore.shared.enableBeauty(false);
    DeviceStore.shared.closeLocalCamera();
  }

  Future<CompletionHandler> startCameraTest(int viewID, {bool? useFrontCamera, MirrorType? mirrorType}) {
    LiveBeautyStore.shared.enableBeauty(true);
    if (useFrontCamera != null) DeviceStore.shared.switchCamera(useFrontCamera);
    if (mirrorType != null) DeviceStore.shared.switchMirror(mirrorType);
    return _openLocalCamera(() {
      DeviceStore.shared.updateVideoQuality(DeviceStore.shared.state.localVideoQuality.value);
      TUIRoomEngine.sharedInstance().setLocalVideoView(viewID);
      return DeviceStore.shared.openLocalCamera(useFrontCamera ?? true);
      // return DeviceStore.shared.startCameraTest(viewID);
    });
  }

  void stopCameraTest() {
    LiveBeautyStore.shared.enableBeauty(false);
    DeviceStore.shared.closeLocalCamera();
    // DeviceStore.shared.stopCameraTest();
  }

  Future<CompletionHandler> _openLocalCamera(OpenCameraDelegate delegate) async {
    final cameraStatus = await Permission.check(PermissionType.camera);
    if (cameraStatus.isUsable) {
      startForegroundService(ForegroundServiceType.video);
      return delegate.call();
    }

    final statusMap = await Permission.request([PermissionType.camera]);
    PermissionStatus cameraPermissionStatus = statusMap[PermissionType.camera] ?? PermissionStatus.denied;
    if (!cameraPermissionStatus.isUsable) {
      final completionHandler = CompletionHandler();
      completionHandler.errorCode = -1003;
      completionHandler.errorMessage = 'camera permission denied';
      return completionHandler;
    }
    startForegroundService(ForegroundServiceType.video);
    return delegate.call();
  }

  Future<CompletionHandler> openLocalMicrophone() async {
    final microphoneStatus = await Permission.check(PermissionType.microphone);
    if (microphoneStatus.isUsable) {
      startForegroundService(ForegroundServiceType.audio);
      return DeviceStore.shared.openLocalMicrophone();
    }

    final statusMap = await Permission.request([PermissionType.microphone]);
    PermissionStatus microphonePermissionStatus = statusMap[PermissionType.microphone] ?? PermissionStatus.denied;

    if (!microphonePermissionStatus.isUsable) {
      final completionHandler = CompletionHandler();
      completionHandler.errorCode = -1003;
      completionHandler.errorMessage = 'microphone permission denied';
      return completionHandler;
    }

    startForegroundService(ForegroundServiceType.audio);
    return DeviceStore.shared.openLocalMicrophone();
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
    if (Platform.isAndroid) {
      TUIRoomEngine.sharedInstance().enableSystemAudioSharing(true);
    }
    final localVideoQuality = DeviceStore.shared.state.localVideoQuality.value;
    DeviceStore.shared.updateVideoQuality(localVideoQuality, orientation: VideoOrientation.landscape);
    DeviceStore.shared.startScreenShare();
  }

  void stopScreenShare() {
    if (Platform.isAndroid) {
      TUIRoomEngine.sharedInstance().enableSystemAudioSharing(false);
    }
    DeviceStore.shared.stopScreenShare();
  }

  void onJoinLive(LiveInfo liveInfo) async {
    final result = await getMultiPlaybackQuality(liveInfo.liveID);
    if (!result.isSuccess) {
      return;
    }
    mediaState.playbackQualityList.value = result.videoQualityList;
  }

  void onLeaveLive() {
    stopForegroundService();
    resetState();
  }

  void onStopLive() {
    stopForegroundService();
    resetState();
    _enableMultiPlaybackQuality(false);
  }

  void resetState() {
    mediaState.isAudioLocked.value = false;
    mediaState.isVideoLocked.value = false;
    mediaState.playbackQuality.value = null;
    mediaState.playbackQualityList.value = [];
    mediaState.isRemoteVideoStreamPaused.value = false;
    mediaState.currentPlayoutVolume.value = 100;
    mediaState.isScreenCaptured.value = false;
  }

  void updateVideoQuality(VideoQuality quality) {
    DeviceStore.shared.updateVideoQuality(quality);
  }

  Future<VideoQualityCompletionHandler> getMultiPlaybackQuality(String roomId) {
    return _queryPlaybackQualityList(roomId);
  }

  void switchPlaybackQuality(VideoQuality videoQuality) {
    _switchPlaybackQuality(videoQuality);
    mediaState.playbackQuality.value = videoQuality;
  }

  void setAudioPlayoutVolume(int volume) {
    _setAudioPlayoutVolume(volume);
    mediaState.currentPlayoutVolume.value = volume;
  }

  void pauseByAudience() {
    _pauseByAudience();
    mediaState.isRemoteVideoStreamPaused.value = true;
  }

  void resumeByAudience() {
    _setAudioPlayoutVolume(mediaState.currentPlayoutVolume.value);
    _resumeByAudience();
    mediaState.isRemoteVideoStreamPaused.value = false;
  }

  void onSelfMediaDeviceStateChanged(SeatInfo seatInfo) {
    mediaState.isAudioLocked.value = !seatInfo.userInfo.allowOpenMicrophone;
    mediaState.isVideoLocked.value = !seatInfo.userInfo.allowOpenCamera;
  }

  void onSelfLeaveSeat() {
    mediaState.isAudioLocked.value = false;
    mediaState.isVideoLocked.value = false;
    LiveBeautyStore.shared.enableBeauty(false);
  }

  void _onUserVideoSizeChanged(String userId, int width, int height) {
    context.roomManager.target?.onUserVideoSizeChanged(width, height);
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

  VideoQuality _getVideoQualityByVideoSize(int width, int height) {
    if (width * height <= 360 * 640) {
      return VideoQuality.quality360P;
    }
    if (width * height <= 540 * 960) {
      return VideoQuality.quality540P;
    }
    if (width * height <= 720 * 1280) {
      return VideoQuality.quality720P;
    }
    return VideoQuality.quality1080P;
  }

  void _enableMultiPlaybackQuality(bool enable) {
    try {
      Map<String, dynamic> params = {'enable': false};

      Map<String, dynamic> jsonObject = {
        'api': 'enableMultiPlaybackQuality',
        'params': params,
      };
      String jsonString = jsonEncode(jsonObject);
      invokeExperimentalAPI(jsonString);
    } catch (e) {
      LiveKitLogger.error('Error enableMultiPlaybackQuality');
    }
  }

  Future<VideoQualityCompletionHandler> _queryPlaybackQualityList(String roomId) async {
    try {
      Map<String, dynamic> params = {'roomId': roomId};

      Map<String, dynamic> jsonObject = {
        'api': 'queryPlaybackQualityList',
        'params': params,
      };
      String jsonString = jsonEncode(jsonObject);
      final result = await invokeExperimentalAPI(jsonString);
      VideoQualityCompletionHandler completionHandler = VideoQualityCompletionHandler();
      if (result.isSuccess) {
        completionHandler.videoQualityList = _decodeJsonString2TUIVideoQuality(result.value);
      } else {
        completionHandler.errorCode = completionHandler.errorCode;
        completionHandler.errorMessage = completionHandler.errorMessage;
      }
      return completionHandler;
    } catch (e) {
      LiveKitLogger.error('Error queryPlaybackQualityList');
      VideoQualityCompletionHandler completionHandler = VideoQualityCompletionHandler();
      completionHandler.errorCode = -1;
      completionHandler.errorMessage = 'queryPlaybackQualityList failed';
      return completionHandler;
    }
  }

  void _switchPlaybackQuality(VideoQuality videoQuality) async {
    try {
      Map<String, dynamic> params = {'quality': videoQuality.value};
      Map<String, dynamic> jsonObject = {
        'api': 'switchPlaybackQuality',
        'params': params,
      };

      String jsonString = jsonEncode(jsonObject);
      invokeExperimentalAPI(jsonString);
    } catch (e) {
      LiveKitLogger.error('Error switchPlaybackQuality');
    }
  }

  List<VideoQuality> _decodeJsonString2TUIVideoQuality(String jsonString) {
    try {
      final videoQualityNumbers = jsonDecode(jsonString);
      final List<VideoQuality> videoQualities = [];
      for (int videoQualityNumber in videoQualityNumbers) {
        final videoQuality = VideoQuality.values
            .firstWhere((item) => item.value == videoQualityNumber, orElse: () => VideoQuality.quality720P);
        videoQualities.add(videoQuality);
      }
      return videoQualities;
    } catch (e) {
      return List.empty();
    }
  }

  void _pauseByAudience() async {
    try {
      Map<String, dynamic> params = {};
      Map<String, dynamic> jsonObject = {'api': 'pause', 'params': params};
      final jsonString = json.encode(jsonObject);
      await invokeExperimentalAPI(jsonString);
    } catch (e) {
      LiveKitLogger.error('Error pauseByAudience');
    }
  }

  void _resumeByAudience() async {
    try {
      Map<String, dynamic> params = {};
      Map<String, dynamic> jsonObject = {'api': 'resume', 'params': params};
      final jsonString = json.encode(jsonObject);
      await invokeExperimentalAPI(jsonString);
    } catch (e) {
      LiveKitLogger.error('Error resumeByAudience');
    }
  }

  void _setAudioPlayoutVolume(int volume) async {
    TUIRoomEngine.sharedInstance().setAudioPlayoutVolume(volume);
  }

  Future<StringValueCompletionHandler> invokeExperimentalAPI(String apiJsonString) {
    final completer = Completer<StringValueCompletionHandler>();
    TUIRoomEngine.sharedInstance().invokeExperimentalAPI(apiJsonString).then((result) {
      LiveKitLogger.info(
          "MediaManager, callExperimentalAPI, api=$apiJsonString, code=$result.code, jsonStr=${result.data}");
      if (completer.isCompleted) return;
      final handler = StringValueCompletionHandler()
        ..value = result.data ?? ''
        ..errorCode = result.code.value()
        ..errorMessage = result.message;
      completer.complete(handler);
    });
    return completer.future;
  }
}

class StringValueCompletionHandler extends CompletionHandler {
  String value = '';
}

class VideoQualityCompletionHandler extends CompletionHandler {
  List<VideoQuality> videoQualityList = [];
}
