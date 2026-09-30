import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../api/device/device_store.dart';
import '../../api/device/screen_share_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/log.dart';

class _ScreenShareStateImpl implements ScreenShareState {
  @override
  final ValueNotifier<DeviceStatus> screenStatus = ValueNotifier<DeviceStatus>(DeviceStatus.off);
}

const String _kStartScreenShare = 'DeviceModule.startScreenShare';
const String _kGetShareSources = 'DeviceModule.getShareSources';
const String _kStopScreenShare = 'DeviceModule.stopScreenShare';

const String _stateChannel = 'DeviceModule.stateChanged';
const String _shareSourcesChannel = 'DeviceModule.shareSources';

const String _kProperty = 'property';
const String _kScreenStatus = 'screenStatus';
const String _kHasImage = 'hasImage';

class ScreenShareStoreImpl extends ScreenShareStore {
  ScreenShareStoreImpl._() {
    _subscribePassiveChannels();
  }

  static final ScreenShareStoreImpl shared = ScreenShareStoreImpl._();

  final Log _logger = Log.getCommonLog("ScreenShareStore");

  final _ScreenShareStateImpl _state = _ScreenShareStateImpl();

  Completer<Uint8List>? _pendingSourcesBlob;
  String _pendingSourcesMeta = '';

  @override
  ScreenShareState get state => _state;

  @override
  void startScreenShare({String iOSAppGroup = '', String? sourceId, ShareConfig? property}) {
    final param = jsonEncode(<String, Object>{
      'appGroup': iOSAppGroup,
      'sourceId': sourceId ?? '',
      'enableCaptureMouse': property?.enableCaptureMouse ?? true,
    });
    unawaited(EngineBridge.invoke(_kStartScreenShare, param));
  }

  @override
  Future<List<ShareSource>> getShareSources({required Size thumbnailSize, required Size iconSize}) async {
    if (!AtomicPlatform.isDesktop) {
      return const [];
    }

    final blobCompleter = Completer<Uint8List>();
    _pendingSourcesBlob = blobCompleter;

    final param = jsonEncode(<String, Object>{
      'thumbnailWidth': thumbnailSize.width.toInt(),
      'thumbnailHeight': thumbnailSize.height.toInt(),
      'iconWidth': iconSize.width.toInt(),
      'iconHeight': iconSize.height.toInt(),
    });

    try {
      final result = await EngineBridge.invoke(_kGetShareSources, param);
      if (!result.isSuccess || result.data.isEmpty) {
        _pendingSourcesBlob = null;
        return const [];
      }
      final metaJson = _pendingSourcesMeta.isNotEmpty ? _pendingSourcesMeta : result.data;
      _pendingSourcesMeta = '';

      final hasImage =
          (jsonDecode(result.data) as Map<String, dynamic>)[_kHasImage] as bool? ?? false;
      Uint8List blob;
      if (hasImage) {
        try {
          blob = await blobCompleter.future.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          blob = Uint8List(0);
        }
      } else {
        blob = Uint8List(0);
      }
      _pendingSourcesBlob = null;

      return await _parseShareSources(metaJson, blob);
    } catch (_) {
      _pendingSourcesBlob = null;
      _pendingSourcesMeta = '';
      return const [];
    }
  }

  @override
  void stopScreenShare() {
    unawaited(EngineBridge.invoke(_kStopScreenShare, '{}'));
  }

  @override
  void reset() {
    stopScreenShare();
    _state.screenStatus.value = DeviceStatus.off;
  }

  // MARK: - Passive event dispatcher

  void _subscribePassiveChannels() {
    EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
    EngineBridge.subscribeBinary(_shareSourcesChannel, _onShareSourcesBinary);
  }

  void _onModuleStateChanged(String id, String jsonData) {
    try {
      final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
      final property = decoded[_kProperty] as String? ?? '';
      if (property == _kScreenStatus) {
        _applyScreenStatus(decoded[_kScreenStatus]);
      }
    } catch (e) {
      _logger.error("onModuleStateChanged, error=$e");
    }
  }

  void _applyScreenStatus(Object? raw) {
    final status = (raw as num?)?.toInt() == 1 ? DeviceStatus.on : DeviceStatus.off;
    if (_state.screenStatus.value != status) {
      _state.screenStatus.value = status;
    }
  }

  void _onShareSourcesBinary(String id, String jsonData, Uint8List binaryData) {
    _pendingSourcesMeta = jsonData;
    final completer = _pendingSourcesBlob;
    if (completer != null && !completer.isCompleted) {
      completer.complete(binaryData);
    }
  }

  // MARK: - Parsing

  Future<List<ShareSource>> _parseShareSources(String metaJson, Uint8List blob) async {
    final decoded = jsonDecode(metaJson) as Map<String, dynamic>;
    final list = decoded['list'] as List<dynamic>? ?? const [];
    // Decode thumbnails in parallel: a sequential await serializes two
    // decoder round trips per source (thumbnail + icon), which dominates
    // the parse time with dozens of windows. Future.wait preserves order.
    final sources = await Future.wait(
      list.whereType<Map<String, dynamic>>().map((raw) => _parseShareSource(raw, blob)),
    );
    return List<ShareSource>.unmodifiable(sources);
  }

  Future<ShareSource> _parseShareSource(Map<String, dynamic> item, Uint8List blob) async {
    final typeValue = (item['type'] as num?)?.toInt() ?? 0;
    final sourceId = item['sourceId'] as String? ?? '';
    return ShareSource(
      type: typeValue == ShareSourceType.screen.value ? ShareSourceType.screen : ShareSourceType.window,
      sourceId: sourceId,
      sourceName: item['sourceName'] as String? ?? '',
      isMinimizeWindow: item['isMinimizeWindow'] as bool? ?? false,
      thumbnail: await _decodeSegment(item['thumbnail'], blob),
      icon: await _decodeSegment(item['icon'], blob),
      x: (item['x'] as num?)?.toInt() ?? 0,
      y: (item['y'] as num?)?.toInt() ?? 0,
      width: (item['width'] as num?)?.toInt() ?? 0,
      height: (item['height'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ImageProvider?> _decodeSegment(Object? segment, Uint8List blob) async {
    if (segment is! Map<String, dynamic>) {
      return null;
    }
    final offset = (segment['offset'] as num?)?.toInt() ?? 0;
    final length = (segment['length'] as num?)?.toInt() ?? 0;
    final width = (segment['width'] as num?)?.toInt() ?? 0;
    final height = (segment['height'] as num?)?.toInt() ?? 0;
    if (length <= 0 || width <= 0 || height <= 0 || offset < 0 || offset + length > blob.length) {
      return null;
    }
    final pixels = Uint8List.sublistView(blob, offset, offset + length);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.bgra8888, completer.complete);
    final image = await completer.future;
    return _RawImageProvider(image);
  }
}

class _RawImageProvider extends ImageProvider<_RawImageProvider> {
  const _RawImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_RawImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_RawImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(_RawImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(SynchronousFuture<ImageInfo>(ImageInfo(image: image)));
  }

  @override
  bool operator ==(Object other) => other is _RawImageProvider && other.image == image;

  @override
  int get hashCode => image.hashCode;
}
