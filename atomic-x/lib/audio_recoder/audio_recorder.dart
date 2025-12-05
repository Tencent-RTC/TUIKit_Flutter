import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart' as record;

class RecordInfo {
  int errorCode = AudioRecordCode.success;
  String errorMessage = "";
  String path;
  final int duration;

  RecordInfo({
    required this.duration,
    required this.path,
  });
}

typedef RecordingProgressCallback = void Function(int duration, double progress);

typedef RecordingStateCallback = void Function(bool isRecording);

class AudioRecordCode {
  static const int success = 0;
  static const int tooShort = -1;
}

class AudioRecorder {
  record.AudioRecorder? _audioRecorder;
  Timer? _timer;
  int _recordingDuration = 0;
  bool _isRecording = false;
  final int maxDuration = 60000; // 1 minute

  RecordingProgressCallback? onProgressUpdate;
  RecordingStateCallback? onStateChanged;

  bool get isRecording => _isRecording;

  int get recordingDuration => _recordingDuration;

  double get recordingProgress => _recordingDuration / maxDuration;

  void initialize({
    RecordingProgressCallback? onProgressUpdate,
    RecordingStateCallback? onStateChanged,
  }) {
    this.onProgressUpdate = onProgressUpdate;
    this.onStateChanged = onStateChanged;
  }

  Future<bool> startRecord({required String filePath}) async {
    try {
      _audioRecorder = record.AudioRecorder();
      _timer?.cancel();

      if (!await _audioRecorder!.hasPermission()) {
        return false;
      }

      _recordingDuration = 0;
      _isRecording = true;
      onStateChanged?.call(_isRecording);

      const encoder = record.AudioEncoder.aacLc;
      final isSupported = await _audioRecorder!.isEncoderSupported(encoder);
      debugPrint('${encoder.name} supported: $isSupported');

      final devs = await _audioRecorder!.listInputDevices();
      debugPrint(devs.toString());

      const androidConfig = record.AndroidRecordConfig(useLegacy: true, audioSource: record.AndroidAudioSource.mic);
      const config = record.RecordConfig(encoder: encoder, androidConfig: androidConfig);

      await _audioRecorder!.start(config, path: filePath);
      _startTimer();

      return true;
    } catch (e) {
      debugPrint('Start record failed: $e');
      _cleanup();
      return false;
    }
  }

  Future<RecordInfo?> stopRecord() async {
    try {
      final recordedFile = await _audioRecorder?.stop();

      final recordingDurationMs = _recordingDuration;
      _cleanup();

      if (recordedFile != null) {
        int duration = (recordingDurationMs / 1000).floor();
        RecordInfo recordInfo = RecordInfo(duration: duration, path: recordedFile);

        if (duration < 1) {
          recordInfo.errorCode = AudioRecordCode.tooShort;
          recordInfo.errorMessage = "record too short";
          File recordedFileInstance = File(recordedFile);
          if (await recordedFileInstance.exists()) {
            await recordedFileInstance.delete();
          }
          recordInfo.path = "";
        }

        return recordInfo;
      }
      return null;
    } catch (e) {
      debugPrint('Stop record failed: $e');
      _cleanup();
      return null;
    }
  }

  Future<void> cancelRecord() async {
    try {
      final recordedFile = await _audioRecorder?.stop();
      _cleanup();

      if (recordedFile != null) {
        File recordedFileInstance = File(recordedFile);
        if (await recordedFileInstance.exists()) {
          await recordedFileInstance.delete();
        }
      }
    } catch (e) {
      debugPrint('Cancel record failed: $e');
      _cleanup();
    }
  }

  bool isMaxDurationReached() {
    final adjustMaxDuration = maxDuration - 800;
    return _recordingDuration >= adjustMaxDuration;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _recordingDuration += 10;
      onProgressUpdate?.call(_recordingDuration, recordingProgress);

      if (isMaxDurationReached()) {
        timer.cancel();
      }
    });
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    _audioRecorder?.dispose();
    _audioRecorder = null;

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
  }
}
