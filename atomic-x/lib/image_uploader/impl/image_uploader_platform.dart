import 'dart:async';
import 'package:flutter/services.dart';

/// Platform bridge for native image picking (camera/album only).
/// Cropping and COS upload are handled in Dart.
class ImageUploaderPlatform {
  static const MethodChannel _methodChannel = MethodChannel('atomic_x/image_uploader');
  static const EventChannel _eventChannel = EventChannel('atomic_x/image_uploader_events');

  static StreamSubscription? _eventSubscription;
  static Completer<String?>? _activeCompleter;

  /// Pick an image from native.
  /// [source] must be 'camera' or 'gallery'.
  /// Returns the local file path of the selected image, or null if cancelled.
  static Future<String?> pickImageNative({required String source}) async {
    // If a pick operation is already in progress, cancel it
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete(null);
      _eventSubscription?.cancel();
      _eventSubscription = null;
    }

    final completer = Completer<String?>();
    _activeCompleter = completer;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'] is String ? event['type'] as String : null;
          if (type == 'pickCompleted') {
            final localPath = event['localPath'] is String ? event['localPath'] as String : null;
            if (!completer.isCompleted) {
              completer.complete(localPath);
            }
            _eventSubscription?.cancel();
            _eventSubscription = null;
            _activeCompleter = null;
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        _eventSubscription?.cancel();
        _eventSubscription = null;
        _activeCompleter = null;
      },
    );

    try {
      await _methodChannel.invokeMethod('pick', {'source': source});
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      _eventSubscription?.cancel();
      _eventSubscription = null;
      _activeCompleter = null;
    }

    return completer.future;
  }
}
