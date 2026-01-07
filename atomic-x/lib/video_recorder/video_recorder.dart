import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'video_recorder_platform.dart';

enum RecordMode {
  mixed,
  photoOnly,
  videoOnly,
}

enum VideoRecordQuality {
  low,
  medium,
  high,
}

enum RecordMediaType {
  photo,
  video,
}

class VideoRecorderResult {
  final RecordMediaType mediaType;
  final String filePath;
  final int? durationMs;
  final String? thumbnailPath;

  VideoRecorderResult({
    required this.mediaType,
    required this.filePath,
    this.durationMs,
    this.thumbnailPath,
  });

  @override
  String toString() {
    if (mediaType == RecordMediaType.photo) {
      return 'VideoRecorderResult(mediaType: photo, filePath: $filePath)';
    } else {
      return 'VideoRecorderResult(mediaType: video, filePath: $filePath, durationMs: $durationMs, thumbnailPath: $thumbnailPath)';
    }
  }
}

class VideoRecorderConfig {
  final RecordMode? recordMode;
  final VideoRecordQuality? videoQuality;
  final int? minDurationMs;
  final int? maxDurationMs;
  final bool? isDefaultFrontCamera;
  final bool? isSupportTorch;

  const VideoRecorderConfig({
    this.recordMode,
    this.videoQuality,
    this.minDurationMs,
    this.maxDurationMs,
    this.isDefaultFrontCamera,
    this.isSupportTorch,
  });
}

class VideoRecorder {
  static final VideoRecorder instance = VideoRecorder._internal();

  VideoRecorder._internal();

  static Future<VideoRecorderResult> startRecord({
    required BuildContext context,
    VideoRecorderConfig? config,
  }) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final themeState = BaseThemeProvider.of(context);
    return VideoRecorderPlatform.startRecordNative(
      config: config ?? const VideoRecorderConfig(),
      locale: localeProvider.locale,
      primaryColor: themeState.currentPrimaryColor,
    );
  }
}
