// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   MediaMixingStoreImpl @ AtomicXCore
// Function: MediaMixingStore implementation via EngineBridge.

part of 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';

// ============================================================================
// State implementation
// ============================================================================

class _MediaMixingStateImpl implements MediaMixingState {
  @override
  final ValueNotifier<MediaMixingParams> params = ValueNotifier<MediaMixingParams>(
    const MediaMixingParams(videoEncoderParams: VideoEncParam()),
  );

  @override
  final ValueNotifier<MixingStatus> status = ValueNotifier<MixingStatus>(MixingStatus.idle);

  @override
  final ValueNotifier<MixingStopReason> stopReason = ValueNotifier<MixingStopReason>(MixingStopReason.none);

  @override
  final ValueNotifier<MixingErrorInfo> lastError = ValueNotifier<MixingErrorInfo>(MixingErrorInfo.none);

  @override
  final ValueNotifier<List<MixingSourceInfo>> sources = ValueNotifier<List<MixingSourceInfo>>([]);

  @override
  final ValueNotifier<String?> selectedSourceKey = ValueNotifier<String?>(null);

  @override
  final ValueNotifier<VideoFillMode> mixedFillMode = ValueNotifier<VideoFillMode>(VideoFillMode.fill);

  @override
  final ValueNotifier<Map<String, VideoFilePlayProgress>> sourceProgresses =
      ValueNotifier<Map<String, VideoFilePlayProgress>>({});

  @override
  final ValueNotifier<Size> canvasSize = ValueNotifier<Size>(const Size(1920, 1080));
}

// ============================================================================
// API keys (Dart → Engine)
// ============================================================================

const String _kStartMixing = 'MediaMixingModule.startMixing';
const String _kStopMixing = 'MediaMixingModule.stopMixing';
const String _kReset = 'MediaMixingModule.reset';
const String _kAttachToLive = 'MediaMixingModule.attachToLive';
const String _kDetachFromLive = 'MediaMixingModule.detachFromLive';
const String _kUpdateVideoEncoderParams = 'MediaMixingModule.updateVideoEncoderParams';
const String _kSetCanvasColor = 'MediaMixingModule.setCanvasColor';
const String _kSetMixedRenderView = 'MediaMixingModule.setMixedRenderView';
const String _kSetMixedFillMode = 'MediaMixingModule.setMixedFillMode';
const String _kAddCameraSource = 'MediaMixingModule.addCameraSource';
const String _kAddScreenSource = 'MediaMixingModule.addScreenSource';
const String _kAddImageSource = 'MediaMixingModule.addImageSource';
const String _kAddOnlineVideoSource = 'MediaMixingModule.addOnlineVideoSource';
const String _kAddVideoFileSource = 'MediaMixingModule.addVideoFileSource';
const String _kRemoveSource = 'MediaMixingModule.removeSource';
const String _kSelectSource = 'MediaMixingModule.selectSource';
const String _kUpdateSourceLayout = 'MediaMixingModule.updateSourceLayout';
const String _kSetRotation = 'MediaMixingModule.setRotation';
const String _kSetMirror = 'MediaMixingModule.setMirror';
const String _kSetFillMode = 'MediaMixingModule.setFillMode';
const String _kSetCameraBeauty = 'MediaMixingModule.setCameraBeauty';
const String _kSetCameraCaptureParam = 'MediaMixingModule.setCameraCaptureParam';
const String _kSetSourceVolume = 'MediaMixingModule.setSourceVolume';
const String _kSeekVideoFile = 'MediaMixingModule.seekVideoFile';
const String _kPauseVideoFile = 'MediaMixingModule.pauseVideoFile';
const String _kResumeVideoFile = 'MediaMixingModule.resumeVideoFile';
const String _kEnableCameraGreenScreen = 'MediaMixingModule.enableCameraGreenScreen';
const String _kAddPhoneMirrorSource = 'MediaMixingModule.addPhoneMirrorSource';
const String _kSetPhoneMirrorParam = 'MediaMixingModule.setPhoneMirrorParam';
const String _kUpdateScreenCaptureProperty = 'MediaMixingModule.updateScreenCaptureProperty';

// ============================================================================
// Event keys (Engine → Dart)
// ============================================================================

const String _kOnStateChanged = 'MediaMixingModule.stateChanged';

// ============================================================================
// Store implementation
// ============================================================================

class _MediaMixingStoreImpl extends MediaMixingStore {
  _MediaMixingStoreImpl() {
    _registerEventHandlers();
  }

  final _MediaMixingStateImpl _state = _MediaMixingStateImpl();

  @override
  MediaMixingState get state => _state;

  // ========== Lifecycle ==========

  @override
  Future<CompletionHandler> startMixing(MediaMixingParams params) {
    final param = jsonEncode(<String, Object>{
      'videoEncoderParams': <String, Object>{
        'width': params.videoEncoderParams.width,
        'height': params.videoEncoderParams.height,
        'fps': params.videoEncoderParams.fps,
        'bitrateKbps': params.videoEncoderParams.bitrateKbps,
        'resolutionMode': params.videoEncoderParams.resolutionMode.value,
      },
      'canvasColor': params.canvasColor,
      'streamType': params.streamType.value,
      'selectedBorderColor': params.selectedBorderColor,
    });
    return EngineBridge.invoke(_kStartMixing, param).then((r) {
      final result = r.toCompletionHandler();
      if (result.isSuccess) {
        _state.params.value = params;
      }
      return result;
    });
  }

  @override
  void stopMixing() {
    unawaited(EngineBridge.invoke(_kStopMixing, '{}'));
  }

  @override
  void reset() {
    _state.params.value = const MediaMixingParams(videoEncoderParams: VideoEncParam());
    unawaited(EngineBridge.invoke(_kReset, '{}'));
  }

  // ========== TRTC Publishing ==========

  @override
  void attachToLive() {
    unawaited(EngineBridge.invoke(_kAttachToLive, '{}'));
  }

  @override
  void detachFromLive() {
    unawaited(EngineBridge.invoke(_kDetachFromLive, '{}'));
  }

  // ========== Encoding & Rendering ==========

  @override
  void updateVideoEncoderParams(VideoEncParam params) {
    final param = jsonEncode(<String, Object>{
      'width': params.width,
      'height': params.height,
      'fps': params.fps,
      'bitrateKbps': params.bitrateKbps,
      'resolutionMode': params.resolutionMode.value,
    });
    // Optimistically update the reactive params; the engine confirms via the
    // canvasSize event. Safe before startMixing (params are stored engine-side
    // and applied when mixing starts).
    final current = _state.params.value;
    _state.params.value = MediaMixingParams(
      videoEncoderParams: params,
      canvasColor: current.canvasColor,
      streamType: current.streamType,
      selectedBorderColor: current.selectedBorderColor,
    );
    unawaited(EngineBridge.invoke(_kUpdateVideoEncoderParams, param));
  }

  @override
  void setCanvasColor(int color) {
    final param = jsonEncode(<String, Object>{'color': color});
    final current = _state.params.value;
    _state.params.value = MediaMixingParams(
      videoEncoderParams: current.videoEncoderParams,
      canvasColor: color,
      streamType: current.streamType,
      selectedBorderColor: current.selectedBorderColor,
    );
    unawaited(EngineBridge.invoke(_kSetCanvasColor, param));
  }

  @override
  void setMixedRenderView(int viewPtr) {
    final param = jsonEncode(<String, Object>{'view': ViewIdCodec.encode(viewPtr)});
    unawaited(EngineBridge.invoke(_kSetMixedRenderView, param));
  }

  @override
  void setMixedFillMode(VideoFillMode mode) {
    final param = jsonEncode(<String, Object>{'mode': mode.value});
    unawaited(EngineBridge.invoke(_kSetMixedFillMode, param));
  }

  // ========== Source Management ==========

  @override
  Future<CompletionHandler> addCameraSource({
    required String key,
    required String deviceId,
    MixingLayout? layout,
  }) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'deviceId': deviceId,
      if (layout != null) 'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kAddCameraSource, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> addScreenSource({
    required String key,
    required ShareSource source,
    MixingLayout? layout,
    MixingRect? captureRect,
  }) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'sourceId': source.sourceId,
      'sourceType': source.type.value,
      if (layout != null) 'layout': layout.toJson(),
      if (captureRect != null) 'captureRect': captureRect.toJson(),
    });
    return EngineBridge.invoke(_kAddScreenSource, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> addImageSource({
    required String key,
    required String imagePath,
    MixingLayout? layout,
    int fps = 0,
  }) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'imagePath': imagePath,
      'fps': fps,
      if (layout != null) 'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kAddImageSource, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> addOnlineVideoSource({
    required String key,
    required String url,
    MixingLayout? layout,
    int playoutVolume = 100,
    int networkCacheSizeKB = 1024,
  }) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'url': url,
      'playoutVolume': playoutVolume,
      'networkCacheSizeKB': networkCacheSizeKB,
      if (layout != null) 'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kAddOnlineVideoSource, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> addVideoFileSource({
    required String key,
    required String filePath,
    MixingLayout? layout,
    int playoutVolume = 100,
  }) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'filePath': filePath,
      'playoutVolume': playoutVolume,
      if (layout != null) 'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kAddVideoFileSource, param).then((r) => r.toCompletionHandler());
  }

  @override
  void removeSource(String key) {
    final param = jsonEncode(<String, Object>{'key': key});
    unawaited(EngineBridge.invoke(_kRemoveSource, param));
  }

  @override
  void selectSource(String? key) {
    final param = jsonEncode(<String, Object>{'key': key ?? ''});
    unawaited(EngineBridge.invoke(_kSelectSource, param));
  }

  // ========== Source Properties ==========

  @override
  Future<CompletionHandler> updateSourceLayout(String key, MixingLayout layout) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kUpdateSourceLayout, param).then((r) => r.toCompletionHandler());
  }

  @override
  void setRotation(String key, VideoRotation rotation) {
    final param = jsonEncode(<String, Object>{'key': key, 'rotation': rotation.value});
    unawaited(EngineBridge.invoke(_kSetRotation, param));
  }

  @override
  void setMirror(String key, MirrorType mirrorType) {
    final param = jsonEncode(<String, Object>{'key': key, 'mirrorType': mirrorType.value});
    unawaited(EngineBridge.invoke(_kSetMirror, param));
  }

  @override
  void setFillMode(String key, VideoFillMode fillMode) {
    final param = jsonEncode(<String, Object>{'key': key, 'fillMode': fillMode.value});
    unawaited(EngineBridge.invoke(_kSetFillMode, param));
  }

  @override
  void setCameraBeauty(String key, CameraBeautyParam param) {
    final p = jsonEncode(<String, Object>{
      'key': key,
      'beautyStyle': param.beautyStyle,
      'skinSmoothingLevel': param.skinSmoothingLevel,
      'whitenessLevel': param.whitenessLevel,
      'sharpenLevel': param.sharpenLevel,
      'ruddyLevel': param.ruddyLevel,
    });
    unawaited(EngineBridge.invoke(_kSetCameraBeauty, p));
  }

  @override
  void setCameraCaptureParam(String key, CameraCaptureParam param) {
    final p = jsonEncode(<String, Object>{
      'key': key,
      'width': param.width,
      'height': param.height,
      'fps': param.fps,
    });
    unawaited(EngineBridge.invoke(_kSetCameraCaptureParam, p));
  }

  @override
  void setSourceVolume(String key, int volume) {
    final param = jsonEncode(<String, Object>{'key': key, 'volume': volume});
    unawaited(EngineBridge.invoke(_kSetSourceVolume, param));
  }

  @override
  void seekVideoFile(String key, int positionMs) {
    final param = jsonEncode(<String, Object>{'key': key, 'positionMs': positionMs});
    unawaited(EngineBridge.invoke(_kSeekVideoFile, param));
  }

  @override
  void pauseVideoFile(String key) {
    final param = jsonEncode(<String, Object>{'key': key});
    unawaited(EngineBridge.invoke(_kPauseVideoFile, param));
  }

  @override
  void resumeVideoFile(String key) {
    final param = jsonEncode(<String, Object>{'key': key});
    unawaited(EngineBridge.invoke(_kResumeVideoFile, param));
  }

  // ========== Windows-only ==========

  @override
  void enableCameraGreenScreen(String key, bool enable) {
    final param = jsonEncode(<String, Object>{'key': key, 'enable': enable});
    unawaited(EngineBridge.invoke(_kEnableCameraGreenScreen, param));
  }

  @override
  Future<CompletionHandler> addPhoneMirrorSource({
    required String key,
    required PhoneMirrorParam param,
    MixingLayout? layout,
  }) {
    final p = jsonEncode(<String, Object>{
      'key': key,
      'platformType': param.platformType,
      'connectType': param.connectType,
      'deviceId': param.deviceId,
      'deviceName': param.deviceName,
      'placeholderImagePath': param.placeholderImagePath,
      'frameRate': param.frameRate,
      'bitrateKbps': param.bitrateKbps,
      if (layout != null) 'layout': layout.toJson(),
    });
    return EngineBridge.invoke(_kAddPhoneMirrorSource, p).then((r) => r.toCompletionHandler());
  }

  @override
  void setPhoneMirrorParam(String key, PhoneMirrorParam param) {
    final p = jsonEncode(<String, Object>{
      'key': key,
      'platformType': param.platformType,
      'connectType': param.connectType,
      'deviceId': param.deviceId,
      'deviceName': param.deviceName,
      'placeholderImagePath': param.placeholderImagePath,
      'frameRate': param.frameRate,
      'bitrateKbps': param.bitrateKbps,
    });
    unawaited(EngineBridge.invoke(_kSetPhoneMirrorParam, p));
  }

  @override
  void updateScreenCaptureProperty(String key, ShareConfig property) {
    final param = jsonEncode(<String, Object>{
      'key': key,
      'enableCaptureMouse': property.enableCaptureMouse,
    });
    unawaited(EngineBridge.invoke(_kUpdateScreenCaptureProperty, param));
  }

  // ========== Event Handlers (Engine → Dart) ==========

  void _registerEventHandlers() {
    EngineBridge.subscribe(_kOnStateChanged, _handleStateChanged);
  }

  void _updateSelectedSourceKey(List<MixingSourceInfo> sources) {
    for (final s in sources) {
      if (s.isSelected) {
        _state.selectedSourceKey.value = s.key;
        return;
      }
    }
    _state.selectedSourceKey.value = null;
  }

  void _handleStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;
    final property = dict['property'];
    if (property is! String) return;

    switch (property) {
      case 'status':
        final value = dict['status'];
        if (value is int && value >= 0 && value < MixingStatus.values.length) {
          _state.status.value = MixingStatus.values[value];
        }
        break;

      case 'stopReason':
        final value = dict['stopReason'];
        if (value is int) {
          _state.stopReason.value = MixingStopReason.fromValue(value);
        }
        break;

      case 'lastError':
        final err = dict['lastError'];
        if (err is Map<String, dynamic>) {
          _state.lastError.value = MixingErrorInfo(
            seq: (err['seq'] as int?) ?? 0,
            error: MixingError.fromValue((err['error'] as int?) ?? -1),
            message: (err['message'] as String?) ?? '',
            sourceKey: err['sourceKey'] as String?,
          );
        } else {
          _state.lastError.value = MixingErrorInfo.none;
        }
        break;

      case 'sources':
        final arr = dict['sources'];
        if (arr is List) {
          final list = arr.map((item) {
            if (item is! Map<String, dynamic>) {
              return const MixingSourceInfo(key: '', sourceType: MixingSourceType.camera);
            }
            return _parseMixingSourceInfo(item);
          }).toList(growable: false);
          _state.sources.value = list;
          _updateSelectedSourceKey(list);
        }
        break;

      case 'sourceProgresses':
        final progress = dict['sourceProgresses'];
        if (progress is Map<String, dynamic>) {
          final key = progress['key'] as String? ?? '';
          final currentMs = (progress['currentMs'] as int?) ?? 0;
          final durationMs = (progress['durationMs'] as int?) ?? 0;
          // Merge into existing map (replace entry for this key)
          final newMap = Map<String, VideoFilePlayProgress>.from(_state.sourceProgresses.value);
          newMap[key] = VideoFilePlayProgress(currentMs: currentMs, durationMs: durationMs);
          _state.sourceProgresses.value = newMap;
        }
        break;

      case 'canvasSize':
        final size = dict['canvasSize'];
        if (size is Map<String, dynamic>) {
          final w = (size['width'] as num?)?.toDouble() ?? 1280;
          final h = (size['height'] as num?)?.toDouble() ?? 720;
          _state.canvasSize.value = Size(w, h);
        }
        break;

      case 'mixedFillMode':
        final mode = dict['mixedFillMode'];
        if (mode is int) {
          _state.mixedFillMode.value = mode == 1 ? VideoFillMode.fit : VideoFillMode.fill;
        }
        break;

      default:
        break;
    }
  }

  // ========== JSON parsing helpers ==========

  static MixingSourceInfo _parseMixingSourceInfo(Map<String, dynamic> json) {
    Size? contentSize;
    final cs = json['contentSize'];
    if (cs is Map<String, dynamic>) {
      final w = (cs['width'] as num?)?.toDouble();
      final h = (cs['height'] as num?)?.toDouble();
      if (w != null && h != null && w > 0 && h > 0) {
        contentSize = Size(w, h);
      }
    }

    MixingLayout layout = const MixingLayout();
    final layoutJson = json['layout'];
    if (layoutJson is Map<String, dynamic>) {
      layout = MixingLayout.fromJson(layoutJson);
    }

    return MixingSourceInfo(
      key: (json['key'] as String?) ?? '',
      sourceType: MixingSourceType.fromValue((json['sourceType'] as int?) ?? 0),
      layout: layout,
      rotation: VideoRotation.fromValue((json['rotation'] as int?) ?? 0),
      fillMode: (json['fillMode'] as int?) == 1 ? VideoFillMode.fit : VideoFillMode.fill,
      mirrorType: _toMirrorType(json['mirrorType']),
      isSelected: (json['isSelected'] as bool?) ?? false,
      playoutVolume: (json['playoutVolume'] as int?) ?? 100,
      playState: _toPlayState((json['playState'] as int?) ?? 0),
      pauseReason: SourcePauseReason.fromValue((json['pauseReason'] as int?) ?? 0),
      lastError: MixingError.fromValue((json['lastError'] as int?) ?? 0),
      contentSize: contentSize,
    );
  }

  static SourcePlayState _toPlayState(int value) {
    switch (value) {
      case 1:
        return SourcePlayState.loading;
      case 2:
        return SourcePlayState.playing;
      case 3:
        return SourcePlayState.paused;
      case 4:
        return SourcePlayState.ended;
      default:
        return SourcePlayState.idle;
    }
  }

  static MirrorType _toMirrorType(Object? value) {
    if (value is! int) return MirrorType.auto;
    return MirrorType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MirrorType.auto,
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
