import 'dart:async';
import 'dart:ui';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';

import 'package:tencent_live_uikit/common/index.dart';

import '../state/network_info_state.dart';

class NetworkInfoManager {
  final String liveID;
  final NetWorkInfoState state = NetWorkInfoState();
  Timer? _poorNetworkTimer;
  bool _hasAudioPermission = false;
  bool _hasVideoPermission = false;
  // bool _isNetworkAvailable = false;
  bool _isDisposed = false;
  int _countdown = 0;
  // StreamSubscription<bool>? _networkStatusSubscription;
  StreamSubscription<ThermalState>? _thermalSubscription;

  LiveSeatStore? liveSeatStore;
  late final VoidCallback _avStatisticsListener = _onAVStatisticsChanged;
  late final VoidCallback _seatListListener = _onSeatListChanged;
  late final VoidCallback _currentLiveListener = _onCurrentLiveChanged;
  late final VoidCallback _networkInfoListener = _onNetworkInfoChanged;

  NetworkInfoManager(this.liveID) {
    DeviceStore.shared.state.networkInfo.addListener(_networkInfoListener);
    LiveListStore.shared.liveState.currentLive.addListener(_currentLiveListener);
    _addThermalObserver();
    _initManager();
  }

  void dispose() {
    _thermalSubscription?.cancel();
    DeviceStore.shared.state.networkInfo.removeListener(_networkInfoListener);
    LiveListStore.shared.liveState.currentLive.removeListener(_currentLiveListener);
    liveSeatStore?.liveSeatState.avStatistics.removeListener(_avStatisticsListener);
    liveSeatStore?.liveSeatState.seatList.removeListener(_seatListListener);
    _poorNetworkTimer?.cancel();
    _poorNetworkTimer = null;
    // _stopNetworkMonitoring();
    _isDisposed = true;
  }
}

extension NetowrkInfoManagerWithCallback on NetworkInfoManager {
  void handleAudioSliderChanged(int volume) {
    DeviceStore.shared.setCaptureVolume(volume);
  }

  void onNetworkInfoStatusToastWidgetClosed() {
    _poorNetworkTimer?.cancel();
    _poorNetworkTimer = null;
    state.showToast.value = false;
  }
}

extension on NetworkInfoManager {
  void _onCurrentLiveChanged() {
    final currentLiveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (currentLiveID.isEmpty) {
      liveSeatStore?.liveSeatState.avStatistics.removeListener(_avStatisticsListener);
      liveSeatStore?.liveSeatState.seatList.removeListener(_seatListListener);
      liveSeatStore = null;
      return;
    }
    if (liveID != currentLiveID) return;
    liveSeatStore = LiveSeatStore.create(liveID);
    liveSeatStore!.liveSeatState.avStatistics.addListener(_avStatisticsListener);
    liveSeatStore!.liveSeatState.seatList.addListener(_seatListListener);
  }

  void _onAVStatisticsChanged() {
    if (liveSeatStore == null) return;
    final avStatistics = liveSeatStore!.liveSeatState.avStatistics.value;
    if (avStatistics.isEmpty || avStatistics[0].userID.isNotEmpty) {
      return;
    }
    final bigStreamStatus = avStatistics[0];

    final videoWidth = bigStreamStatus.videoWidth;
    state.videoResolution.value = videoWidth;
    if (!_hasVideoPermission) {
      return;
    }

    if (state.videoState.value != VideoState.close) {
      final isLowFrameRate = bigStreamStatus.frameRate < 15;
      bool isLowBitrate = false;
      switch (videoWidth) {
        case 240:
          isLowBitrate = bigStreamStatus.videoBitrate < 100;
          break;
        case 360:
          isLowBitrate = bigStreamStatus.videoBitrate < 200;
          break;
        case 480:
          isLowBitrate = bigStreamStatus.videoBitrate < 350;
        case 540:
          isLowBitrate = bigStreamStatus.videoBitrate < (bigStreamStatus.videoHeight == 960 ? 800 : 500);
          break;
        case 1080:
          isLowBitrate = bigStreamStatus.videoBitrate < 1500;
          break;
        default:
          isLowBitrate = false;
          break;
      }
      state.videoState.value = (isLowFrameRate || _isPoorNetworkQuality(state.networkQuality.value) || isLowBitrate)
          ? VideoState.exception
          : VideoState.normal;
    }

    if (!_hasAudioPermission) {
      return;
    }
    if (state.audioState.value == AudioState.close) return;
    if (DeviceStore.shared.state.captureVolume.value == 0) {
      state.audioState.value = AudioState.mute;
    } else {
      state.audioState.value = bigStreamStatus.audioBitrate > 0 ? AudioState.normal : AudioState.exception;
    }
  }

  void _onSeatListChanged() {
    if (liveSeatStore == null) return;
    final seatList = liveSeatStore!.liveSeatState.seatList.value;
    for (final item in seatList) {
      final userInfo = item.userInfo;
      if (userInfo.userID == LoginStore.shared.loginState.loginUserInfo?.userID) {
        _onVideoStatusChanged(userInfo.cameraStatus == DeviceStatus.on);
        _onAudioStatusChanged(userInfo.microphoneStatus == DeviceStatus.on);
        break;
      }
    }
  }

  void _onNetworkInfoChanged() {
    final networkInfo = DeviceStore.shared.state.networkInfo.value;
    // if (!_isNetworkAvailable) {
    //   return;
    // }
    state.networkQuality.value = networkInfo.quality;
    state.rtt.value = networkInfo.delay;
    state.downLoss.value = networkInfo.downLoss;
    state.upLoss.value = networkInfo.upLoss;
    // if (_isNetworkAvailable) {
    //   state.networkQuality.value = networkInfo.quality;
    // }
    if (state.showToast.value) {
      return;
    }
    _isPoorNetworkQuality(networkInfo.quality) ? _startPoorNetworkCountdown() : _stopPoorNetworkCountdown();
  }

  void _onAudioStatusChanged(bool hasAudio) {
    state.audioState.value = hasAudio ? AudioState.normal : AudioState.close;
  }

  void _onVideoStatusChanged(bool hasVideo) {
    state.videoState.value = hasVideo ? VideoState.normal : VideoState.close;
  }

  void _addThermalObserver() {
    _thermalSubscription = TUILiveKitPlatform.instance.onThermalStateChanged.listen((status) {
      state.deviceTemperature.value = status.value;
    });
  }

  void _initManager() async {
    // _startNetworkMonitoring();
    _checkMediaPermission();
    handleAudioSliderChanged(DeviceStore.shared.state.captureVolume.value);
    // _isNetworkAvailable = await TUILiveKitPlatform.instance.isNetworkConnected();
  }

  void _startNetworkMonitoring() {
    // _networkStatusSubscription?.cancel();
    // _networkStatusSubscription = null;
    //
    // _networkStatusSubscription = TUILiveKitPlatform.instance.onNetworkConnectionStateChanged.listen((connected) {
    //   _isNetworkAvailable = connected;
    //   if (!_isNetworkAvailable) {
    //     state.networkQuality.value = NetworkQuality.down;
    //     state.videoState.value = VideoState.exception;
    //   }
    // });
  }

  void _stopNetworkMonitoring() {
    // _networkStatusSubscription?.cancel();
    // _networkStatusSubscription = null;
  }

  void _checkMediaPermission() async {
    final microphoneStatus = await Permission.check(PermissionType.microphone);
    final cameraStatus = await Permission.check(PermissionType.camera);

    _hasAudioPermission = microphoneStatus.isUsable;
    _hasVideoPermission = cameraStatus.isUsable;

    if (!_hasAudioPermission) {
      state.audioState.value = AudioState.close;
    }

    if (!_hasVideoPermission) {
      state.videoState.value = VideoState.close;
    }
  }

  bool _isPoorNetworkQuality(NetworkQuality quality) {
    return quality == NetworkQuality.veryBad || quality == NetworkQuality.bad || quality == NetworkQuality.down;
  }

  void _startPoorNetworkCountdown() {
    if (_isDisposed) {
      return;
    }
    if (_poorNetworkTimer != null) {
      return;
    }

    const countdownTimeInSeconds = 30;
    _countdown = countdownTimeInSeconds;
    _poorNetworkTimer?.cancel();
    _poorNetworkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) {
        _poorNetworkTimer?.cancel();
        _poorNetworkTimer = null;
        return;
      }

      _countdown -= 1;
      if (_countdown <= 0) {
        state.showToast.value = true;
        _poorNetworkTimer?.cancel();
        _poorNetworkTimer = null;

        Future.delayed(const Duration(seconds: 5), () {
          if (_isDisposed) {
            return;
          }
          state.showToast.value = false;
        });
      }
    });
  }

  void _stopPoorNetworkCountdown() {
    _poorNetworkTimer?.cancel();
    _poorNetworkTimer = null;
    state.showToast.value = false;
  }
}
