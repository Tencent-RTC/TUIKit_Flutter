import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tencent_calls_uikit/src/common/utils/logger.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_calls_uikit/src/common/utils/preference.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';
import 'package:tencent_calls_uikit/src/common/platform/call_kit_platform_interface.dart';

class CallingBellFeature {
  static CallingBellFeature instance = CallingBellFeature._();

  static const String _keyRingPath = "key_ring_path";
  static const String _packagePrefix = "packages/";
  static const String _pluginName = "tencent_calls_uikit/";
  static const String _assetsPrefix = "assets/audios/";
  static const String _callerRingName = "phone_dialing.mp3";
  static const String _calledRingName = "phone_ringing.mp3";
  static const int _musicId = 1;
  static const int _loopCount = 6;
  static const int _volume = 100;

  FileSystem fileSystem = const LocalFileSystem();
  bool isPlaying = false;
  bool isVibrating = false;

  CallingBellFeature._();

  Future<void> startRing() async {
    if (isPlaying) {
      return;
    }
    
    Logger.info('CallingBellFeature startRing');
    isPlaying = true;
    
    final filePath = await _getRingFilePath();
    if (filePath.isEmpty) {
      isPlaying = false;
      return;
    }

    _playByTRTC(filePath);

    if (_isCalled()) {
      TUICallKitPlatform.instance.startVibration();
      isVibrating = true;
    }
  }

  Future<void> stopRing() async {
    if (!isPlaying) {
      return;
    }
    
    Logger.info('CallingBellFeature stopRing');
    isPlaying = false;

    _stopByTRTC();

    if (isVibrating) {
      TUICallKitPlatform.instance.stopVibration();
    }
  }

  Future<String> _getRingFilePath() async {
    final customFilePath = await PreferenceUtils.getInstance().getString(_keyRingPath);
    if (customFilePath.isNotEmpty && _shouldUseCustomRing()) {
      return customFilePath;
    }
    
    final String ringName;
    
    if (_isCalled()) {
      if (GlobalState.instance.enableMuteMode) {
        return "";
      }
      ringName = _calledRingName;
    } else {
      ringName = _callerRingName;
    }
    
    return await _getAssetsFilePath(ringName);
  }

  bool _isCalled() {
    final userId = CallParticipantStore.shared.state.selfInfo.value.id;
    final inviterId = CallStore.shared.state.activeCall.value.inviterId;
    return userId != inviterId;
  }

  bool _shouldUseCustomRing() {
    return _isCalled() &&
           !GlobalState.instance.enableMuteMode;
  }

  Future<String> getAssetsFilePath(String assetName) async {
    if (assetName.isEmpty) {
      return "";
    }
    
    final tempDirectory = await getTempDirectory();
    final filePath = "$tempDirectory/$assetName";
    final file = fileSystem.file(filePath);
    
    if (!await file.exists()) {
      final byteData = await loadAsset(assetName);
      await file.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    
    return file.path;
  }

  Future<String> _getAssetsFilePath(String ringName) async {
    final assetPath = '$_packagePrefix$_pluginName$_assetsPrefix$ringName';
    return await getAssetsFilePath(assetPath);
  }

  Future<void> _playByTRTC(String filePath) async {
    final trtcCloud = await TRTCCloud.sharedInstance();
    final audioEffectManager = trtcCloud.getAudioEffectManager();

    final param = AudioMusicParam(id: _musicId, path: filePath, loopCount: _loopCount);
    param.publish = false;
    audioEffectManager.startPlayMusic(param);
    audioEffectManager.setMusicPlayoutVolume(_musicId, _volume);
  }

  Future<void> _stopByTRTC() async {
    final trtcCloud = await TRTCCloud.sharedInstance();
    final audioEffectManager = trtcCloud.getAudioEffectManager();
    audioEffectManager.stopPlayMusic(_musicId);
  }

  @visibleForTesting
  Future<ByteData> loadAsset(String path) => rootBundle.load(path);

  @visibleForTesting
  Future<String> getTempDirectory() async => (await getTemporaryDirectory()).path;
}