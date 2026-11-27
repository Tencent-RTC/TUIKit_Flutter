import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:svgaplayer_flutter/proto/svga.pbenum.dart';

/// 保留原始图片精度，逐张解码并立即释放 Codec，避免同时保留整段动画的
/// 解码器及其临时像素缓冲。MovieEntity 的图片仍由播放资源持有方统一释放。
class GiftSVGADecoder {
  const GiftSVGADecoder({
    Future<ui.Codec> Function(Uint8List bytes)? createCodec,
  }) : _createCodec = createCodec ?? ui.instantiateImageCodec;

  final Future<ui.Codec> Function(Uint8List bytes) _createCodec;

  Future<MovieEntity> decodeFile(String path,
      {bool Function()? isCancelled}) async {
    final bytes = await File(path).readAsBytes();
    _checkActive(isCancelled);
    // 原生 zlib 产出紧凑字节缓冲，不经通用 archive 解压的整数列表。
    final movie = MovieEntity.fromBuffer(ZLibDecoder().convert(bytes));
    try {
      if (movie.params.frames < 1 ||
          movie.params.fps <= 0 ||
          !movie.params.viewBoxWidth.isFinite ||
          !movie.params.viewBoxHeight.isFinite ||
          movie.params.viewBoxWidth <= 0 ||
          movie.params.viewBoxHeight <= 0) {
        throw const FormatException('Invalid SVGA animation');
      }
      for (final sprite in movie.sprites) {
        List<ShapeEntity>? previousShapes;
        for (final frame in sprite.frames) {
          if (frame.shapes.isEmpty) continue;
          if (frame.shapes.first.type == ShapeEntity_ShapeType.KEEP &&
              previousShapes != null) {
            frame.shapes = previousShapes;
          } else {
            previousShapes = frame.shapes;
          }
        }
      }
      final audioKeys = movie.audios.map((audio) => audio.audioKey).toSet();
      for (final key in movie.images.keys.toList(growable: false)) {
        _checkActive(isCancelled);
        final encoded = movie.images.remove(key)!;
        // SVGA 的音频也存于 images 字段；当前只展示动画，不把音轨送入图片解码。
        if (audioKeys.contains(key)) continue;
        final codec = await _createCodec(
            encoded is Uint8List ? encoded : Uint8List.fromList(encoded));
        try {
          _checkActive(isCancelled);
          final frame = await codec.getNextFrame();
          // 先记录所有权，取消/失败时由外层统一释放刚返回的图片。
          movie.bitmapCache[key] = frame.image;
          _checkActive(isCancelled);
        } finally {
          codec.dispose();
        }
      }
      return movie;
    } on Object {
      movie.dispose();
      rethrow;
    } finally {
      movie.images.clear();
    }
  }

  static void _checkActive(bool Function()? isCancelled) {
    if (isCancelled?.call() == true) {
      throw const FormatException('SVGA preparation cancelled');
    }
  }
}
