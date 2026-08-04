import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'album_picker.dart';

class _CallbackGroup {
  final Function(List<AlbumMedia> pickedAlbumMedias, String? textMessage)?
      onPickConfirm;
  final Function(AlbumMedia albumMedia, double progress, bool error)?
      onMediaProcessing;
  final Function()? onMediaProcessed;
  final Function()? onCancel;

  _CallbackGroup({
    this.onPickConfirm,
    this.onMediaProcessing,
    this.onMediaProcessed,
    this.onCancel,
  });
}

class AlbumPickerPlatform {
  static AlbumMediaType _convertMediaType(int mediaType) {
    if (mediaType >= 0 && mediaType < AlbumMediaType.values.length) {
      return AlbumMediaType.values[mediaType];
    }
    return AlbumMediaType.image;
  }

  static int _convertMediaFilter(AlbumPickerMediaFilter mediaFilter) {
    return mediaFilter.index;
  }

  static int _convertStyle(AlbumPickerStyle style) {
    return style.index;
  }

  static String? _convertColor(Color? color) {
    if (color == null) return null;
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static int? _convertLanguage(AlbumPickerLanguage? language) {
    if (language == null) return null;
    return language.index;
  }

  static AlbumMedia _parseAlbumMedia(Map data) {
    return AlbumMedia(
      id: data['id'] as int? ?? 0,
      uri: data['uri'] as String? ?? '',
      mediaType: _convertMediaType(data['mediaType'] as int? ?? 0),
      mediaPath: data['mediaPath'] as String? ?? '',
      fileExtension: data['fileExtension'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      videoThumbnailPath: data['videoThumbnailPath'] as String?,
      duration: data['duration'] as int? ?? 0,
    );
  }

  static const MethodChannel _methodChannel =
      MethodChannel('atomic_x/album_picker');
  static const EventChannel _eventChannel =
      EventChannel('atomic_x/album_picker_events');

  /// HarmonyOS detection. `Platform.isOhos` only exists in the Flutter-OH SDK,
  /// so we compare the OS string to stay compilable under standard Flutter.
  static bool get _isOhos => Platform.operatingSystem == 'ohos';

  /// Persistent event subscription — set up once, never canceled.
  static StreamSubscription? _eventSubscription;

  /// Session-based callback storage. Each pickMediaNative call generates a
  /// unique sessionId and stores its callbacks here. Native events carry the
  /// sessionId back, allowing correct routing even when multiple pick sessions
  /// overlap (e.g., video transcoding from session A continues while session B
  /// starts).
  static final Map<String, _CallbackGroup> _callbacksBySession = {};

  static int _sessionCounter = 0;

  /// Ensure the EventChannel listener is established exactly once.
  static void _ensureEventListenerSetup() {
    if (_eventSubscription != null) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final eventType = event['type'] as String?;
          final sessionId = event['sessionId'] as String?;

          if (sessionId == null) {
            debugPrint('AlbumPickerPlatform: event missing sessionId, type=$eventType');
            return;
          }

          final callbacks = _callbacksBySession[sessionId];
          if (callbacks == null) {
            debugPrint('AlbumPickerPlatform: no callbacks for sessionId=$sessionId, type=$eventType');
            return;
          }

          switch (eventType) {
            case 'onPickConfirm':
              final dataList = event['pickedAlbumMedias'] as List? ?? [];
              final medias = dataList
                  .map((item) => _parseAlbumMedia(item as Map))
                  .toList();
              final textMessage = event['textMessage'] as String?;
              callbacks.onPickConfirm?.call(medias, textMessage);
              break;

            case 'onMediaProcessing':
              final data = event['data'] as Map;
              final model = _parseAlbumMedia(data);
              final progress = (event['progress'] as num).toDouble();
              final error = event['error'] as bool? ?? false;
              callbacks.onMediaProcessing?.call(model, progress, error);
              break;

            case 'onMediaProcessed':
              callbacks.onMediaProcessed?.call();
              _callbacksBySession.remove(sessionId);
              break;

            case 'onCancel':
              callbacks.onCancel?.call();
              _callbacksBySession.remove(sessionId);
              break;
          }
        }
      },
      onError: (error) {
        debugPrint('AlbumPickerPlatform event error: $error');
      },
    );
  }

  static Future<void> pickMediaNative({
    AlbumPickerConfig? config,
    AlbumPickerTheme? theme,
    Function(List<AlbumMedia> pickedAlbumMedias, String? textMessage)?
        onPickConfirm,
    Function(AlbumMedia albumMedia, double progress, bool error)?
        onMediaProcessing,
    Function()? onMediaProcessed,
    Function()? onCancel,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && !_isOhos) {
      throw UnsupportedError(
          'Native AlbumPicker is only supported on Android, iOS and HarmonyOS');
    }

    // Set up the persistent event listener (no-op if already active).
    _ensureEventListenerSetup();

    // Generate unique sessionId and store callbacks.
    final sessionId = 'ps_${++_sessionCounter}_${DateTime.now().millisecondsSinceEpoch}';
    _callbacksBySession[sessionId] = _CallbackGroup(
      onPickConfirm: onPickConfirm,
      onMediaProcessing: onMediaProcessing,
      onMediaProcessed: onMediaProcessed,
      onCancel: onCancel,
    );

    try {
      await _methodChannel.invokeMethod(
        'pickMedia',
        {
          'sessionId': sessionId,
          'pickMode': config?.mediaFilter != null
              ? _convertMediaFilter(config!.mediaFilter!)
              : null,
          'maxCount': config?.maxSelectionCount,
          'gridCount': config?.itemsPerRow,
          'showsCameraItem': config?.showsCameraItem,
          'style': config?.style != null
              ? _convertStyle(config!.style!)
              : null,
          'language': config?.language != null
              ? _convertLanguage(config!.language!)
              : null,
          'compressQuality': config?.compressQuality?.index,
          'maxVideoDurationInSeconds': config?.maxVideoDurationInSeconds,
          'maxOutputFileSizeInMB': config?.maxOutputFileSizeInMB,
          'primaryColor': _convertColor(theme?.primaryColor),
          'backgroundColor': _convertColor(theme?.backgroundColor),
          'backgroundColorSecondary':
              _convertColor(theme?.backgroundColorSecondary),
          'textColor': _convertColor(theme?.textColor),
          'textColorSecondary': _convertColor(theme?.textColorSecondary),
          'confirmButtonIconAsset': theme?.confirmButtonIconAsset,
          'bigFontSize': theme?.bigFontSize,
          'normalFontSize': theme?.normalFontSize,
          'smallFontSize': theme?.smallFontSize,
          'bigRadius': theme?.bigRadius,
          'normalRadius': theme?.normalRadius,
          'smallRadius': theme?.smallRadius,
        },
      );
    } catch (e) {
      debugPrint('AlbumPickerPlatform.pickMediaNative error: $e');
      _callbacksBySession.remove(sessionId);
      rethrow;
    }
  }

  static Future<void> dispose() async {
    _callbacksBySession.clear();
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
