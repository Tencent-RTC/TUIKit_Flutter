import 'dart:async';

import 'package:flutter/material.dart';

import 'audio_recorder_platform.dart';

enum AudioRecordResultCode {
  successExceedMaxDuration(1),
  success(0),
  errorCancel(-1),
  errorRecording(-2),
  errorStorageUnavailable(-3),
  errorLessThanMinDuration(-4),
  errorRecordInnerFail(-5),
  errorRecordPermissionDenied(-6);

  final int code;
  const AudioRecordResultCode(this.code);

  static AudioRecordResultCode fromCode(int code) {
    return AudioRecordResultCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AudioRecordResultCode.errorRecordInnerFail,
    );
  }
}

class RecordInfo {
  AudioRecordResultCode errorCode = AudioRecordResultCode.success;
  String path;
  final int duration;

  RecordInfo({
    required this.duration,
    required this.path,
  });

  @override
  String toString() {
    return 'RecordInfo(errorCode: ${errorCode.name}, path: $path, duration: $duration)';
  }
}

typedef RecordingProgressCallback = void Function(int duration, double progress);

typedef RecordingStateCallback = void Function(bool isRecording);

typedef AudioRecordCompleteCallback = void Function(RecordInfo? recordInfo);

class AudioRecorder {
  bool _isRecording = false;
  final int maxDuration = 60000; // 1 minute
  final int minDuration = 1000; // 1 second

  RecordingProgressCallback? onProgressUpdate;
  RecordingStateCallback? onStateChanged;

  bool get isRecording => _isRecording;

  int _recordingDuration = 0;
  int get recordingDuration => _recordingDuration;

  double get recordingProgress => _recordingDuration / maxDuration;

  void initialize({
    RecordingProgressCallback? onProgressUpdate,
    RecordingStateCallback? onStateChanged,
  }) {
    this.onProgressUpdate = onProgressUpdate;
    this.onStateChanged = onStateChanged;
  }

  Future<bool> startRecord({
    required String filePath,
    required AudioRecordCompleteCallback onComplete,
  }) async {
    if (_isRecording) {
      debugPrint('Already recording');
      return false;
    }

    try {
      _isRecording = true;
      _recordingDuration = 0;

      onStateChanged?.call(_isRecording);

      // Set up callbacks for native platform
      AudioRecorderPlatform.setOnRecordTime((timeMs) {
        _recordingDuration = timeMs;
        onProgressUpdate?.call(_recordingDuration, recordingProgress);
      });

      AudioRecorderPlatform.setOnPowerLevel((powerLevel) {
        // Power level can be used for UI visualization if needed
        debugPrint('Power level: $powerLevel');
      });

      // Start native recording asynchronously
      _startNativeRecording(
        filePath: filePath,
        onComplete: onComplete,
      );

      return true;
    } catch (e) {
      debugPrint('Start record failed: $e');
      _cleanup();
      return false;
    }
  }

  Future<void> _startNativeRecording({
    required String filePath,
    required AudioRecordCompleteCallback onComplete,
  }) async {
    try {
      final result = await AudioRecorderPlatform.startRecordNative(
        config: AudioRecorderConfig(
          filepath: filePath,
          enableAIDeNoise: false,
          minDurationMs: minDuration,
          maxDurationMs: maxDuration,
        ),
      );

      RecordInfo? recordInfo;

      if (result.isSuccess && result.filePath != null) {
        recordInfo = RecordInfo(
          duration: (result.durationMs / 1000).floor(),
          path: result.filePath!,
        )..errorCode = AudioRecordResultCode.success;
      } else if (result.resultCode == AudioRecordResultCode.errorLessThanMinDuration) {
        recordInfo = RecordInfo(
          duration: result.durationMs,
          path: '',
        )
          ..errorCode = result.resultCode;
      } else {
        recordInfo = RecordInfo(
          duration: result.durationMs,
          path: result.filePath ?? '',
        )
          ..errorCode = result.resultCode;
      }

      _cleanup();
      onComplete(recordInfo);
    } catch (e) {
      debugPrint('Native recording error: $e');
      _cleanup();
      onComplete(null);
    }
  }

  void stopRecord() {
    if (!_isRecording) {
      return;
    }

    try {
      AudioRecorderPlatform.stopRecordNative();
    } catch (e) {
      debugPrint('Stop record failed: $e');
    }
  }

  Future<void> cancelRecord() async {
    if (!_isRecording) {
      return;
    }

    try {
      await AudioRecorderPlatform.cancelRecordNative();
      _cleanup();
    } catch (e) {
      debugPrint('Cancel record failed: $e');
      _cleanup();
    }
  }

  bool isMaxDurationReached() {
    final adjustMaxDuration = maxDuration - 800;
    return _recordingDuration >= adjustMaxDuration;
  }

  void _cleanup() {
    final wasRecording = _isRecording;
    _isRecording = false;
    _recordingDuration = 0;

    if (wasRecording) {
      onStateChanged?.call(_isRecording);
      onProgressUpdate?.call(_recordingDuration, recordingProgress);
    }
  }

  void dispose() {
    _cleanup();
    AudioRecorderPlatform.dispose();
  }
}
