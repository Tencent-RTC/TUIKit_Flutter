import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'audio_recorder.dart';

class AudioRecordResult {
  final AudioRecordResultCode resultCode;
  final String? filePath;
  final int durationMs;

  AudioRecordResult({
    required this.resultCode,
    this.filePath,
    required this.durationMs,
  });

  bool get isSuccess =>
      resultCode == AudioRecordResultCode.success ||
      resultCode == AudioRecordResultCode.successExceedMaxDuration;

  @override
  String toString() {
    return 'AudioRecordResult(resultCode: ${resultCode.name}, filePath: $filePath, durationMs: $durationMs)';
  }
}

class AudioRecorderConfig {
  final String? filepath;
  final bool enableAIDeNoise;
  final int minDurationMs;
  final int maxDurationMs;

  const AudioRecorderConfig({
    this.filepath,
    this.enableAIDeNoise = false,
    this.minDurationMs = 1000,
    this.maxDurationMs = 60000,
  });
}

class AudioRecorderPlatform {
  static const MethodChannel _methodChannel =
      MethodChannel('atomic_x/audio_recorder');
  static const EventChannel _eventChannel =
      EventChannel('atomic_x/audio_recorder_events');

  static StreamSubscription? _eventSubscription;
  static Function(int timeMs)? _onRecordTime;
  static Function(int powerLevel)? _onPowerLevel;

  /// Start recording with native implementation
  static Future<AudioRecordResult> startRecordNative({
    required AudioRecorderConfig config,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
          'Native AudioRecorder is only supported on Android and iOS');
    }

    try {
      // Setup event channel for progress updates
      await _eventSubscription?.cancel();

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final eventType = event['type'] as String?;

            if (eventType == 'recordTime') {
              final timeMs = event['timeMs'] as int;
              _onRecordTime?.call(timeMs);
            } else if (eventType == 'powerLevel') {
              final powerLevel = event['powerLevel'] as int;
              _onPowerLevel?.call(powerLevel);
            }
          }
        },
        onError: (error) {
          print('AudioRecorderPlatform event error: $error');
        },
      );

      // Call native method to start recording
      final result = await _methodChannel.invokeMethod(
        'startRecord',
        {
          'filepath': config.filepath,
          'enableAIDeNoise': config.enableAIDeNoise,
          'minDurationMs': config.minDurationMs,
          'maxDurationMs': config.maxDurationMs,
        },
      );

      if (result == null) {
        throw Exception('AudioRecorder returned null result');
      }

      final resultMap = result as Map;
      final resultCode = AudioRecordResultCode.fromCode(
        resultMap['resultCode'] as int? ?? -5,
      );

      return AudioRecordResult(
        resultCode: resultCode,
        filePath: resultMap['filePath'] as String?,
        durationMs: resultMap['durationMs'] as int? ?? 0,
      );
    } catch (e) {
      print('AudioRecorderPlatform.startRecordNative error: $e');
      rethrow;
    } finally {
      await dispose();
    }
  }

  /// Stop recording
  static Future<AudioRecordResult?> stopRecordNative() async {
    try {
      await _methodChannel.invokeMethod('stopRecord');
    } catch (e) {
      print('AudioRecorderPlatform.stopRecordNative error: $e');
      return null;
    }
  }

  /// Cancel recording
  static Future<void> cancelRecordNative() async {
    try {
      await _methodChannel.invokeMethod('cancelRecord');
    } catch (e) {
      print('AudioRecorderPlatform.cancelRecordNative error: $e');
    }
  }

  /// Set callback for recording time updates
  static void setOnRecordTime(Function(int timeMs)? callback) {
    _onRecordTime = callback;
  }

  /// Set callback for power level updates
  static void setOnPowerLevel(Function(int powerLevel)? callback) {
    _onPowerLevel = callback;
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _onRecordTime = null;
    _onPowerLevel = null;
  }
}
