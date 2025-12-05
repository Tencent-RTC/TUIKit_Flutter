import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'album_picker.dart';

class AlbumPickerPlatform {
  static PickMediaType _convertMediaType(int mediaType) {
    switch (mediaType) {
      case 0:
        return PickMediaType.image;
      case 1:
        return PickMediaType.video;
      case 2:
        return PickMediaType.gif;
      default:
        return PickMediaType.image;
    }
  }

  static int _convertPickMode(PickMode pickMode) {
    switch (pickMode) {
      case PickMode.image:
        return 0;
      case PickMode.video:
        return 1;
      case PickMode.all:
        return 2;
    }
  }

  static const MethodChannel _methodChannel = MethodChannel('atomic_x/album_picker');
  static const EventChannel _eventChannel = EventChannel('atomic_x/album_picker_events');
  
  static StreamSubscription? _eventSubscription;

  static Future<void> pickMediaNative({
    required AlbumPickerConfig config,
    required Function(AlbumPickerModel model, int index, double progress) onProgress,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Native AlbumPicker is only supported on Android and iOS');
    }

    try {
      await _eventSubscription?.cancel();
      
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          print('AlbumPickerPlatform received event: $event');
          
          if (event is Map) {
            final eventType = event['type'] as String?;
            
            if (eventType == 'progress') {
              final data = event['data'] as Map;
              final mediaTypeInt = data['mediaType'] as int;
              final model = AlbumPickerModel(
                id: data['id'] as int,
                mediaType: _convertMediaType(mediaTypeInt),
                mediaPath: data['mediaPath'] as String,
                fileExtension: data['fileExtension'] as String,
                fileSize: data['fileSize'] as int,
                isOrigin: data['isOrigin'] as bool? ?? false,
                videoThumbnailPath: data['videoThumbnailPath'] as String?,
              );
              
              onProgress(
                model,
                event['index'] as int,
                (event['progress'] as num).toDouble(),
              );
            }
          }
        },
        onError: (error) {
          print('AlbumPickerPlatform event error: $error');
          _eventSubscription?.cancel();
          _eventSubscription = null;
        },
        cancelOnError: true,
      );

      await _methodChannel.invokeMethod(
        'pickMedia',
        {
          'pickMode': _convertPickMode(config.pickMode),
          'maxCount': config.maxCount ?? AlbumPicker.defaultMaxCount,
          'gridCount': config.gridCount ?? AlbumPicker.defaultGridCount,
          'primaryColor': config.primaryColor?.value ?? -1,
          'languageCode': config.locale?.languageCode,
          'countryCode': config.locale?.countryCode,
          'scriptCode': config.locale?.scriptCode,
        },
      );
    } catch (e) {
      print('AlbumPickerPlatform.pickMediaNative error: $e');
      _eventSubscription?.cancel();
      _eventSubscription = null;
      rethrow;
    }
  }
  
  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
