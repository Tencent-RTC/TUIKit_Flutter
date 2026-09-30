// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   MediaMixingStore @ AtomicXCore
// Function: Media mixing related interfaces, managing multi-source mixing, layout and transcoding.

// <docgen-keep-start>
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Size;

import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/device/screen_share_store.dart';
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:flutter/foundation.dart';

part '../../impl/media_mixing/media_mixing_store_impl.dart';
// <docgen-keep-end>

enum MixingSourceType {
  camera(0),

  screen(1),

  image(2),

  phoneMirror(4),

  onlineVideo(5),

  videoFile(6);

  final int value;
  const MixingSourceType(this.value);

  static MixingSourceType fromValue(int value) {
    return MixingSourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MixingSourceType.camera,
    );
  }
}

enum MixingStatus {
  idle,

  starting,

  running,

  stopped,

  error,
}

enum MixingError {
  noError(0),

  error(-1),

  invalidParams(-2),

  notFoundSource(-3),

  imageSourceLoadFailed(-4),

  cameraNotAuthorized(-5),

  cameraIsOccupied(-6),

  cameraDisconnected(-7),

  unsupportedOnlineVideoProtocol(-8),

  unsupportedLocalVideoFileFormat(-9),

  onlineVideoConnectFailed(-10),

  onlineVideoConnectionLost(-11),

  noAvailableHevcDecoder(-12),

  videoFileNotExist(-13);

  final int value;
  const MixingError(this.value);

  static MixingError fromValue(int value) {
    return MixingError.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MixingError.error,
    );
  }
}

enum VideoFillMode {
  fill(0),

  fit(1);

  final int value;
  const VideoFillMode(this.value);
}

enum VideoRotation {
  rotation0(0),

  rotation90(90),

  rotation180(180),

  rotation270(270);

  final int value;
  const VideoRotation(this.value);

  static VideoRotation fromValue(int value) {
    return VideoRotation.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VideoRotation.rotation0,
    );
  }
}

enum SourcePlayState {
  idle,

  loading,

  playing,

  paused,

  ended,
}

enum SourcePauseReason {
  none(0),

  manual(1),

  invisible(2),

  minimized(3),

  hidden(4);

  final int value;
  const SourcePauseReason(this.value);

  static SourcePauseReason fromValue(int value) {
    return SourcePauseReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SourcePauseReason.none,
    );
  }
}

enum MixingStopReason {
  none(-1),

  userStopped(0),

  sourceLost(1);

  final int value;
  const MixingStopReason(this.value);

  static MixingStopReason fromValue(int value) {
    return MixingStopReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MixingStopReason.none,
    );
  }
}

enum VideoResolutionMode {
  landscape(0),

  portrait(1);

  final int value;
  const VideoResolutionMode(this.value);
}

enum MixingStreamType {
  big(0),

  sub(1);

  final int value;
  const MixingStreamType(this.value);
}

class MixingRect {
  final double x;

  final double y;

  final double width;

  final double height;
  const MixingRect({this.x = 0, this.y = 0, this.width = 1, this.height = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MixingRect &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'width': width, 'height': height};

  factory MixingRect.fromJson(Map<String, dynamic> json) => MixingRect(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        width: (json['width'] as num?)?.toDouble() ?? 1,
        height: (json['height'] as num?)?.toDouble() ?? 1,
      );
}

class MixingLayout {
  final MixingRect rect;

  final int zOrder;
  const MixingLayout({
    this.rect = const MixingRect(),
    this.zOrder = -1,
  });

  Map<String, dynamic> toJson() => {'rect': rect.toJson(), 'zOrder': zOrder};

  factory MixingLayout.fromJson(Map<String, dynamic> json) => MixingLayout(
        rect: json['rect'] is Map<String, dynamic>
            ? MixingRect.fromJson(json['rect'] as Map<String, dynamic>)
            : const MixingRect(),
        zOrder: (json['zOrder'] as int?) ?? -1,
      );
}

class MixingErrorInfo {
  final int seq;

  final MixingError error;

  final String message;

  final String? sourceKey;
  const MixingErrorInfo({
    required this.seq,
    required this.error,
    this.message = '',
    this.sourceKey,
  });

  static const MixingErrorInfo none = MixingErrorInfo(seq: 0, error: MixingError.noError);
}

class VideoFilePlayProgress {
  final int currentMs;

  final int durationMs;
  const VideoFilePlayProgress({this.currentMs = 0, this.durationMs = 0});
}

class CameraBeautyParam {
  final int beautyStyle;

  final double skinSmoothingLevel;

  final double whitenessLevel;

  final double sharpenLevel;

  final double ruddyLevel;
  const CameraBeautyParam({
    this.beautyStyle = 0,
    this.skinSmoothingLevel = 0.0,
    this.whitenessLevel = 0.0,
    this.sharpenLevel = 0.0,
    this.ruddyLevel = 0.0,
  });
}

class CameraCaptureParam {
  final int width;

  final int height;

  final int fps;
  const CameraCaptureParam({this.width = 1280, this.height = 720, this.fps = 30});
}

class VideoEncParam {
  final int width;

  final int height;

  final int fps;

  final int bitrateKbps;

  final VideoResolutionMode resolutionMode;
  const VideoEncParam({
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.bitrateKbps = 3000,
    this.resolutionMode = VideoResolutionMode.landscape,
  });
}

class MediaMixingParams {
  final VideoEncParam videoEncoderParams;

  final int canvasColor;

  final MixingStreamType streamType;

  final int selectedBorderColor;
  const MediaMixingParams({
    required this.videoEncoderParams,
    this.canvasColor = 0x000000,
    this.streamType = MixingStreamType.big,
    this.selectedBorderColor = 0xFFFF00,
  });
}

class PhoneMirrorParam {
  final int platformType;

  final int connectType;

  final String deviceId;

  final String deviceName;

  final String placeholderImagePath;

  final int frameRate;

  final int bitrateKbps;
  const PhoneMirrorParam({
    this.platformType = 0,
    this.connectType = 0,
    this.deviceId = '',
    this.deviceName = '',
    this.placeholderImagePath = '',
    this.frameRate = 60,
    this.bitrateKbps = 10000,
  });
}

class MixingSourceInfo {
  final String key;

  final MixingSourceType sourceType;

  final MixingLayout layout;

  final VideoRotation rotation;

  final VideoFillMode fillMode;

  final MirrorType mirrorType;

  final bool isSelected;

  final int? playoutVolume;

  final SourcePlayState? playState;

  final SourcePauseReason? pauseReason;

  final MixingError lastError;

  final Size? contentSize;
  const MixingSourceInfo({
    required this.key,
    required this.sourceType,
    this.layout = const MixingLayout(),
    this.rotation = VideoRotation.rotation0,
    this.fillMode = VideoFillMode.fill,
    this.mirrorType = MirrorType.auto,
    this.isSelected = false,
    this.playoutVolume,
    this.playState,
    this.pauseReason,
    this.lastError = MixingError.noError,
    this.contentSize,
  });
}

abstract class MediaMixingState {
  /// Current media mixing params (encoder params / canvas color / stream type).
  ///
  /// This is the single source of truth for the mixing configuration:
  /// updated on successful [MediaMixingStore.startMixing],
  /// [MediaMixingStore.updateVideoEncoderParams] and
  /// [MediaMixingStore.setCanvasColor] calls, and restored to defaults on
  /// [MediaMixingStore.reset]. Orientation (landscape / portrait) is derived
  /// from `params.videoEncoderParams.resolutionMode`.
  ValueListenable<MediaMixingParams> get params;

  ValueListenable<MixingStatus> get status;

  ValueListenable<MixingStopReason> get stopReason;

  ValueListenable<MixingErrorInfo> get lastError;

  ValueListenable<List<MixingSourceInfo>> get sources;

  ValueListenable<String?> get selectedSourceKey;

  /// Fill mode of the mixed preview surface. The editing layer combines it
  /// with [canvasSize] to map normalized source coordinates onto the widget:
  /// fill covers the widget (content may be cropped), fit letterboxes it.
  ValueListenable<VideoFillMode> get mixedFillMode;

  ValueListenable<Map<String, VideoFilePlayProgress>> get sourceProgresses;

  ValueListenable<Size> get canvasSize;
}

abstract class MediaMixingStore {
  static final MediaMixingStore _instance = _MediaMixingStoreImpl();
  static MediaMixingStore get shared => _instance;

  MediaMixingState get state;

  Future<CompletionHandler> startMixing(MediaMixingParams params);

  void stopMixing();

  void reset();

  void attachToLive();

  void detachFromLive();

  void updateVideoEncoderParams(VideoEncParam params);

  void setCanvasColor(int color);

  void setMixedRenderView(int viewPtr);

  void setMixedFillMode(VideoFillMode mode);

  Future<CompletionHandler> addCameraSource({
    required String key,
    required String deviceId,
    MixingLayout? layout,
  });

  Future<CompletionHandler> addScreenSource({
    required String key,
    required ShareSource source,
    MixingLayout? layout,
    MixingRect? captureRect,
  });

  Future<CompletionHandler> addImageSource({
    required String key,
    required String imagePath,
    MixingLayout? layout,
    int fps = 0,
  });

  Future<CompletionHandler> addOnlineVideoSource({
    required String key,
    required String url,
    MixingLayout? layout,
    int playoutVolume = 100,
    int networkCacheSizeKB = 1024,
  });

  Future<CompletionHandler> addVideoFileSource({
    required String key,
    required String filePath,
    MixingLayout? layout,
    int playoutVolume = 100,
  });

  void removeSource(String key);

  void selectSource(String? key);

  Future<CompletionHandler> updateSourceLayout(String key, MixingLayout layout);

  void setRotation(String key, VideoRotation rotation);

  void setMirror(String key, MirrorType mirrorType);

  void setFillMode(String key, VideoFillMode fillMode);

  void setCameraBeauty(String key, CameraBeautyParam param);

  void setCameraCaptureParam(String key, CameraCaptureParam param);

  void setSourceVolume(String key, int volume);

  void seekVideoFile(String key, int positionMs);

  void pauseVideoFile(String key);

  void resumeVideoFile(String key);

  void enableCameraGreenScreen(String key, bool enable);

  Future<CompletionHandler> addPhoneMirrorSource({
    required String key,
    required PhoneMirrorParam param,
    MixingLayout? layout,
  });

  void setPhoneMirrorParam(String key, PhoneMirrorParam param);

  void updateScreenCaptureProperty(String key, ShareConfig property);
}
