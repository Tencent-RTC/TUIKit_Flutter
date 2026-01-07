import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'video_recorder.dart';

class VideoRecorderPlatform {
  static const MethodChannel _methodChannel = MethodChannel('atomic_x/video_recorder');

  static Future<VideoRecorderResult> startRecordNative({
    required VideoRecorderConfig config,
    Locale? locale,
    String? primaryColor,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Native VideoRecorder is only supported on Android and iOS');
    }

    try {
      final result = await _methodChannel.invokeMethod(
        'startRecord',
        {
          'recordMode': config.recordMode?.index,
          'videoQuality': config.videoQuality?.index,
          'minDurationMs': config.minDurationMs,
          'maxDurationMs': config.maxDurationMs,
          'isDefaultFrontCamera': config.isDefaultFrontCamera,
          'isSupportEdit': false,
          'isSupportBeauty': false,
          'isSupportRecordScrollFilter': false,
          'isSupportTorch': config.isSupportTorch,
          'isSupportAspect': false,
          'primaryColor': primaryColor ?? '',
          'languageCode': locale?.languageCode ?? '',
          'countryCode': locale?.countryCode ?? '',
          'scriptCode': locale?.scriptCode ?? '',
        },
      );

      if (result == null) {
        throw Exception('VideoRecorder returned null result');
      }

      final resultMap = result as Map;
      final typeStr = resultMap['type'] as String;
      
      if (typeStr == 'photo') {
        return VideoRecorderResult(
          mediaType: RecordMediaType.photo,
          filePath: resultMap['filePath'] as String? ?? '',
        );
      } else {
        return VideoRecorderResult(
          mediaType: RecordMediaType.video,
          filePath: resultMap['filePath'] as String? ?? '',
          durationMs: resultMap['durationMs'] as int?,
          thumbnailPath: resultMap['thumbnailPath'] as String?,
        );
      }
    } catch (e) {
      print('VideoRecorderPlatform.startRecordNative error: $e');
      rethrow;
    }
  }
}
