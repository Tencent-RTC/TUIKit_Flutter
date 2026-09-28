// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   DeviceStoreImpl @ AtomicXCore
// Function: DeviceStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

part of 'package:atomic_x_core/api/device/device_store.dart';

class _DeviceStateImpl implements DeviceState {
  @override
  final ValueNotifier<DeviceStatus> microphoneStatus = ValueNotifier<DeviceStatus>(DeviceStatus.off);

  @override
  final ValueNotifier<List<DeviceInfo>> microphoneList = ValueNotifier<List<DeviceInfo>>(const <DeviceInfo>[]);

  @override
  final ValueNotifier<DeviceInfo> currentMicrophone = ValueNotifier<DeviceInfo>(const DeviceInfo());

  @override
  final ValueNotifier<DeviceError> microphoneLastError = ValueNotifier<DeviceError>(DeviceError.noError);

  @override
  final ValueNotifier<int> captureVolume = ValueNotifier<int>(100);

  @override
  final ValueNotifier<int> currentMicVolume = ValueNotifier<int>(0);

  @override
  final ValueNotifier<int> outputVolume = ValueNotifier<int>(100);

  @override
  final ValueNotifier<DeviceStatus> cameraStatus = ValueNotifier<DeviceStatus>(DeviceStatus.off);

  @override
  final ValueNotifier<List<DeviceInfo>> cameraList = ValueNotifier<List<DeviceInfo>>(const <DeviceInfo>[]);

  @override
  final ValueNotifier<DeviceInfo> currentCamera = ValueNotifier<DeviceInfo>(const DeviceInfo());

  @override
  final ValueNotifier<DeviceError> cameraLastError = ValueNotifier<DeviceError>(DeviceError.noError);

  @override
  final ValueNotifier<bool> isFrontCamera = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<MirrorType> localMirrorType = ValueNotifier<MirrorType>(MirrorType.auto);

  @override
  final ValueNotifier<VideoQuality> localVideoQuality = ValueNotifier<VideoQuality>(VideoQuality.quality720P);

  @override
  final ValueNotifier<AudioRoute> currentAudioRoute = ValueNotifier<AudioRoute>(AudioRoute.speakerphone);

  @override
  final ValueNotifier<List<DeviceInfo>> speakerList = ValueNotifier<List<DeviceInfo>>(const <DeviceInfo>[]);

  @override
  final ValueNotifier<DeviceInfo> currentSpeaker = ValueNotifier<DeviceInfo>(const DeviceInfo());

  @override
  final ValueNotifier<DeviceStatus> screenStatus = ValueNotifier<DeviceStatus>(DeviceStatus.off);

  @override
  final ValueNotifier<NetworkInfo> networkInfo = ValueNotifier<NetworkInfo>(NetworkInfo());
}

// API keys
const String _kOpenLocalMicrophone = 'DeviceModule.openLocalMicrophone';
const String _kCloseLocalMicrophone = 'DeviceModule.closeLocalMicrophone';
const String _kSetCurrentMicrophone = 'DeviceModule.setCurrentMicrophone';
const String _kSetCaptureVolume = 'DeviceModule.setCaptureVolume';
const String _kSetOutputVolume = 'DeviceModule.setOutputVolume';
const String _kSetCurrentSpeaker = 'DeviceModule.setCurrentSpeaker';
const String _kSetAudioRoute = 'DeviceModule.setAudioRoute';
const String _kStartCameraTest = 'DeviceModule.startCameraTest';
const String _kStopCameraTest = 'DeviceModule.stopCameraTest';
const String _kOpenLocalCamera = 'DeviceModule.openLocalCamera';
const String _kCloseLocalCamera = 'DeviceModule.closeLocalCamera';
const String _kSwitchCamera = 'DeviceModule.switchCamera';
const String _kSetCurrentCamera = 'DeviceModule.setCurrentCamera';
const String _kSwitchMirror = 'DeviceModule.switchMirror';
const String _kUpdateVideoQuality = 'DeviceModule.updateVideoQuality';
const String _kStartScreenShare = 'DeviceModule.startScreenShare';
const String _kStopScreenShare = 'DeviceModule.stopScreenShare';
const String _kRefreshDeviceList = 'DeviceModule.refreshDeviceList';
const String _kReset = 'DeviceModule.reset';

// Event keys (engine → Dart)
const String _kOnMicrophoneStateChanged = 'DeviceModule.onMicrophoneStateChanged';
const String _kOnCameraStateChanged = 'DeviceModule.onCameraStateChanged';
const String _kOnIsFrontCameraChanged = 'DeviceModule.onIsFrontCameraChanged';
const String _kOnCurrentAudioRouteChanged = 'DeviceModule.onCurrentAudioRouteChanged';

// State channel (engine → Dart)
const String _kStateChanged = 'DeviceModule.stateChanged';

class _DeviceStoreImpl extends DeviceStore {
  _DeviceStoreImpl() {
    _registerEventHandlers();
  }

  final _DeviceStateImpl _state = _DeviceStateImpl();

  @override
  DeviceState get state => _state;

  @override
  Future<CompletionHandler> openLocalMicrophone() {
    return EngineBridge.invoke(_kOpenLocalMicrophone, '{}').then((r) => r.toCompletionHandler());
  }

  @override
  void closeLocalMicrophone() {
    unawaited(EngineBridge.invoke(_kCloseLocalMicrophone, '{}'));
  }

  @override
  void setCurrentMicrophone(DeviceInfo microphone) {
    final param = jsonEncode(<String, Object>{'deviceId': microphone.deviceId});
    unawaited(EngineBridge.invoke(_kSetCurrentMicrophone, param));
  }

  @override
  void setCaptureVolume(int volume) {
    final param = jsonEncode(<String, Object>{'volume': volume});
    unawaited(EngineBridge.invoke(_kSetCaptureVolume, param));
  }

  @override
  void setOutputVolume(int volume) {
    final param = jsonEncode(<String, Object>{'volume': volume});
    unawaited(EngineBridge.invoke(_kSetOutputVolume, param));
  }

  @override
  void setCurrentSpeaker(DeviceInfo speaker) {
    final param = jsonEncode(<String, Object>{'deviceId': speaker.deviceId});
    unawaited(EngineBridge.invoke(_kSetCurrentSpeaker, param));
  }

  @override
  void setAudioRoute(AudioRoute route) {
    final param = jsonEncode(<String, Object>{'route': route.value});
    unawaited(EngineBridge.invoke(_kSetAudioRoute, param));
  }

  @override
  Future<CompletionHandler> startCameraTest(int cameraViewPtr) {
    final param = jsonEncode(<String, Object>{'view': ViewIdCodec.encode(cameraViewPtr)});
    return EngineBridge.invoke(_kStartCameraTest, param).then((r) => r.toCompletionHandler());
  }

  @override
  void stopCameraTest() {
    unawaited(EngineBridge.invoke(_kStopCameraTest, '{}'));
  }

  @override
  Future<CompletionHandler> openLocalCamera(bool isFront) {
    final param = jsonEncode(<String, Object>{'isFront': isFront});
    return EngineBridge.invoke(_kOpenLocalCamera, param).then((r) => r.toCompletionHandler());
  }

  @override
  void closeLocalCamera() {
    unawaited(EngineBridge.invoke(_kCloseLocalCamera, '{}'));
  }

  @override
  void setCurrentCamera(DeviceInfo camera) {
    final param = jsonEncode(<String, Object>{'deviceId': camera.deviceId});
    unawaited(EngineBridge.invoke(_kSetCurrentCamera, param));
  }

  @override
  void switchCamera(bool isFront) {
    final param = jsonEncode(<String, Object>{'isFront': isFront});
    unawaited(EngineBridge.invoke(_kSwitchCamera, param));
  }

  @override
  void switchMirror(MirrorType mirrorType) {
    final param = jsonEncode(<String, Object>{'mirrorType': mirrorType.value});
    unawaited(EngineBridge.invoke(_kSwitchMirror, param));
  }

  @override
  void updateVideoQuality(VideoQuality quality,
      {VideoOrientation orientation = VideoOrientation.portrait}) {
    final param = jsonEncode(<String, Object>{
      'quality': quality.value,
      'orientation': orientation.value,
    });
    unawaited(EngineBridge.invoke(_kUpdateVideoQuality, param));
  }

  @override
  void startScreenShare({String iOSAppGroup = ''}) {
    final param = jsonEncode(<String, Object>{'appGroup': iOSAppGroup});
    unawaited(EngineBridge.invoke(_kStartScreenShare, param));
  }

  @override
  void stopScreenShare() {
    unawaited(EngineBridge.invoke(_kStopScreenShare, '{}'));
  }

  @override
  void refreshDeviceList() {
    unawaited(EngineBridge.invoke(_kRefreshDeviceList, '{}'));
  }

  @override
  void reset() {
    unawaited(EngineBridge.invoke(_kReset, '{}'));
  }

  // MARK: - Event handlers (engine → Dart)

  void _registerEventHandlers() {
    EngineBridge.subscribe(_kOnMicrophoneStateChanged, _handleMicrophoneChanged);
    EngineBridge.subscribe(_kOnCameraStateChanged, _handleCameraChanged);
    EngineBridge.subscribe(_kOnIsFrontCameraChanged, _handleIsFrontCameraChanged);
    EngineBridge.subscribe(_kOnCurrentAudioRouteChanged, _handleCurrentAudioRouteChanged);
    EngineBridge.subscribe(_kStateChanged, _handleStateChanged);
  }

  void _handleMicrophoneChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final isOpen = dict['isOpen'];
    if (isOpen is! bool) return;
    _state.microphoneStatus.value = isOpen ? DeviceStatus.on : DeviceStatus.off;
  }

  void _handleCameraChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final isOpen = dict['isOpen'];
    if (isOpen is! bool) return;
    _state.cameraStatus.value = isOpen ? DeviceStatus.on : DeviceStatus.off;
  }

  void _handleIsFrontCameraChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final isFront = dict['isFront'];
    if (isFront is! bool) return;
    _state.isFrontCamera.value = isFront;
  }

  void _handleCurrentAudioRouteChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final route = dict['route'];
    if (route is! int) return;
    if (route != AudioRoute.speakerphone.value && route != AudioRoute.earpiece.value) return;
    _state.currentAudioRoute.value = AudioRoute.values.firstWhere(
      (e) => e.value == route,
      orElse: () => AudioRoute.speakerphone,
    );
  }

  // MARK: - Passive State dispatcher (engine → Dart)

  void _handleStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'];
    if (property is! String) return;
    final modify = (dict['listModifyType'] as int?) ?? ListModifyType.full.value;
    switch (property) {
      case 'microphoneStatus':
        _state.microphoneStatus.value = _toDeviceStatus(dict['microphoneStatus']);
        break;
      case 'microphoneList':
        _state.microphoneList.value = _applyListModify(
          _state.microphoneList.value,
          modify,
          _toDeviceInfoList(dict['microphoneList']),
          (e) => e.deviceId,
        );
        break;
      case 'currentMicrophone':
        _state.currentMicrophone.value = _toDeviceInfo(dict['currentMicrophone']);
        break;
      case 'microphoneLastError':
        _state.microphoneLastError.value = _toDeviceError(dict['microphoneLastError']);
        break;
      case 'captureVolume':
        _state.captureVolume.value = _toInt(dict['captureVolume'], _state.captureVolume.value);
        break;
      case 'currentMicVolume':
        _state.currentMicVolume.value = _toInt(dict['currentMicVolume'], _state.currentMicVolume.value);
        break;
      case 'outputVolume':
        _state.outputVolume.value = _toInt(dict['outputVolume'], _state.outputVolume.value);
        break;
      case 'cameraStatus':
        _state.cameraStatus.value = _toDeviceStatus(dict['cameraStatus']);
        break;
      case 'cameraList':
        _state.cameraList.value = _applyListModify(
          _state.cameraList.value,
          modify,
          _toDeviceInfoList(dict['cameraList']),
          (e) => e.deviceId,
        );
        break;
      case 'currentCamera':
        _state.currentCamera.value = _toDeviceInfo(dict['currentCamera']);
        break;
      case 'cameraLastError':
        _state.cameraLastError.value = _toDeviceError(dict['cameraLastError']);
        break;
      case 'isFrontCamera':
        final isFront = dict['isFrontCamera'];
        if (isFront is bool) _state.isFrontCamera.value = isFront;
        break;
      case 'localMirrorType':
        _state.localMirrorType.value = _toMirrorType(dict['localMirrorType']);
        break;
      case 'localVideoQuality':
        _state.localVideoQuality.value = _toVideoQuality(dict['localVideoQuality']);
        break;
      case 'currentAudioRoute':
        _state.currentAudioRoute.value = _toAudioRoute(dict['currentAudioRoute']);
        break;
      case 'speakerList':
        _state.speakerList.value = _applyListModify(
          _state.speakerList.value,
          modify,
          _toDeviceInfoList(dict['speakerList']),
          (e) => e.deviceId,
        );
        break;
      case 'currentSpeaker':
        _state.currentSpeaker.value = _toDeviceInfo(dict['currentSpeaker']);
        break;
      case 'screenStatus':
        _state.screenStatus.value = _toDeviceStatus(dict['screenStatus']);
        break;
      case 'networkInfo':
        _state.networkInfo.value = _toNetworkInfo(dict['networkInfo']);
        break;
      default:
        break;
    }
  }

  static int _toInt(Object? value, int fallback) {
    return value is int ? value : fallback;
  }

  static DeviceStatus _toDeviceStatus(Object? value) {
    return (value is int && value == DeviceStatus.on.value) ? DeviceStatus.on : DeviceStatus.off;
  }

  static DeviceError _toDeviceError(Object? value) {
    if (value is! int) return DeviceError.noError;
    return DeviceError.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceError.noError,
    );
  }

  static MirrorType _toMirrorType(Object? value) {
    if (value is! int) return MirrorType.auto;
    return MirrorType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MirrorType.auto,
    );
  }

  static VideoQuality _toVideoQuality(Object? value) {
    if (value is! int) return VideoQuality.quality720P;
    return VideoQuality.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VideoQuality.quality720P,
    );
  }

  static AudioRoute _toAudioRoute(Object? value) {
    return (value is int && value == AudioRoute.earpiece.value) ? AudioRoute.earpiece : AudioRoute.speakerphone;
  }

  static NetworkQuality _toNetworkQuality(Object? value) {
    if (value is! int) return NetworkQuality.unknown;
    return NetworkQuality.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NetworkQuality.unknown,
    );
  }

  static DeviceInfo _toDeviceInfo(Object? value) {
    if (value is! Map<String, dynamic>) return const DeviceInfo();
    final deviceId = value['deviceId'];
    final deviceName = value['deviceName'];
    return DeviceInfo(
      deviceId: deviceId is String ? deviceId : '',
      deviceName: deviceName is String ? deviceName : '',
    );
  }

  static List<DeviceInfo> _toDeviceInfoList(Object? value) {
    if (value is! List) return const <DeviceInfo>[];
    return value.map(_toDeviceInfo).toList();
  }

  static List<T> _applyListModify<T>(
    List<T> current,
    int modifyType,
    List<T> payload,
    String Function(T) keyOf,
  ) {
    final type = ListModifyType.fromValue(modifyType);
    switch (type) {
      case ListModifyType.full:
        return payload;
      case ListModifyType.add:
        final map = <String, T>{};
        for (final e in current) {
          map[keyOf(e)] = e;
        }
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return map.values.toList();
      case ListModifyType.remove:
        final removing = payload.map(keyOf).toSet();
        return current.where((e) => !removing.contains(keyOf(e))).toList();
      case ListModifyType.replace:
        final map = <String, T>{};
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return current.map((e) => map[keyOf(e)] ?? e).toList();
      case ListModifyType.none:
        return current;
    }
  }

  static NetworkInfo _toNetworkInfo(Object? value) {
    if (value is! Map<String, dynamic>) return NetworkInfo();
    final userID = value['userID'];
    return NetworkInfo(
      userID: userID is String ? userID : '',
      quality: _toNetworkQuality(value['quality']),
      upLoss: _toInt(value['upLoss'], 0),
      downLoss: _toInt(value['downLoss'], 0),
      delay: _toInt(value['delay'], 0),
    );
  }

  static Map<String, dynamic>? _parseJSON(String json) {
    if (json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }
}
