import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class AudioPlayerPlatform {
  static const MethodChannel _methodChannel =
      MethodChannel('atomic_x/audio_player');
  static const EventChannel _eventChannel =
      EventChannel('atomic_x/audio_player_events');

  static StreamSubscription? _eventSubscription;
  static Function()? _onComplete;
  static Function(int currentPosition, int duration)? _onProgressUpdate;
  static Function()? _onPlay;
  static Function()? _onPause;
  static Function()? _onResume;
  static Function(String errorMessage)? _onError;

  /// Play audio file
  static Future<void> play({
    required String filePath,
    Function()? onComplete,
    Function(int currentPosition, int duration)? onProgressUpdate,
    Function()? onPlay,
    Function()? onPause,
    Function()? onResume,
    Function(String errorMessage)? onError,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
          'Native AudioPlayer is only supported on Android and iOS');
    }

    try {
      // Setup callbacks
      _onComplete = onComplete;
      _onProgressUpdate = onProgressUpdate;
      _onPlay = onPlay;
      _onPause = onPause;
      _onResume = onResume;
      _onError = onError;

      // Setup event channel for callbacks
      await _eventSubscription?.cancel();

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final eventType = event['type'] as String?;

            switch (eventType) {
              case 'onComplete':
                _onComplete?.call();
                break;
              case 'onProgressUpdate':
                final currentPosition = event['currentPosition'] as int? ?? 0;
                final duration = event['duration'] as int? ?? 0;
                _onProgressUpdate?.call(currentPosition, duration);
                break;
              case 'onPlay':
                _onPlay?.call();
                break;
              case 'onPause':
                _onPause?.call();
                break;
              case 'onResume':
                _onResume?.call();
                break;
              case 'onError':
                final errorMessage = event['errorMessage'] as String? ?? 'Unknown error';
                _onError?.call(errorMessage);
                break;
            }
          }
        },
        onError: (error) {
          print('AudioPlayerPlatform event error: $error');
          _onError?.call('Event stream error: $error');
        },
      );

      // Call native method to play
      await _methodChannel.invokeMethod('play', {
        'filePath': filePath,
      });
    } catch (e) {
      print('AudioPlayerPlatform.play error: $e');
      rethrow;
    }
  }

  /// Pause playback
  static Future<void> pause() async {
    try {
      await _methodChannel.invokeMethod('pause');
    } catch (e) {
      print('AudioPlayerPlatform.pause error: $e');
    }
  }

  /// Resume playback
  static Future<void> resume() async {
    try {
      await _methodChannel.invokeMethod('resume');
    } catch (e) {
      print('AudioPlayerPlatform.resume error: $e');
    }
  }

  /// Stop playback
  static Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
      await dispose();
    } catch (e) {
      print('AudioPlayerPlatform.stop error: $e');
    }
  }

  /// Get current position in milliseconds
  static Future<int> getCurrentPosition() async {
    try {
      final position = await _methodChannel.invokeMethod('getCurrentPosition');
      return position as int? ?? 0;
    } catch (e) {
      print('AudioPlayerPlatform.getCurrentPosition error: $e');
      return 0;
    }
  }

  /// Get duration in milliseconds
  static Future<int> getDuration() async {
    try {
      final duration = await _methodChannel.invokeMethod('getDuration');
      return duration as int? ?? 0;
    } catch (e) {
      print('AudioPlayerPlatform.getDuration error: $e');
      return 0;
    }
  }

  /// Check if playing
  static Future<bool> isPlaying() async {
    try {
      final playing = await _methodChannel.invokeMethod('isPlaying');
      return playing as bool? ?? false;
    } catch (e) {
      print('AudioPlayerPlatform.isPlaying error: $e');
      return false;
    }
  }

  /// Check if paused
  static Future<bool> isPaused() async {
    try {
      final paused = await _methodChannel.invokeMethod('isPaused');
      return paused as bool? ?? false;
    } catch (e) {
      print('AudioPlayerPlatform.isPaused error: $e');
      return false;
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _onComplete = null;
    _onProgressUpdate = null;
    _onPlay = null;
    _onPause = null;
    _onResume = null;
    _onError = null;
  }
}
