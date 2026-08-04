import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'video_recorder.dart';

class VideoRecorderPlatform {
  static const MethodChannel _methodChannel = MethodChannel('tencent_chat_uikit/video_recorder');

  /// HarmonyOS detection. `Platform.isOhos` only exists in the Flutter-OH SDK,
  /// so we compare the OS string to stay compilable under standard Flutter.
  static bool get _isOhos => Platform.operatingSystem == 'ohos';

  static Future<VideoRecorderResult> startRecordNative({
    required VideoRecorderConfig config,
    Locale? locale,
    String? primaryColor,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && !_isOhos) {
      throw UnsupportedError('Native VideoRecorder is only supported on Android, iOS and HarmonyOS');
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
