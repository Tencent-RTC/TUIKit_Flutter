import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart'
    show AudioEntity, SpriteEntity;
import 'package:svgaplayer_flutter/proto/svga.pbenum.dart'
    show ShapeEntity_ShapeType;
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_svga_decoder.dart';

MovieParams _validParams() => MovieParams(
      viewBoxWidth: 3,
      viewBoxHeight: 2,
      fps: 30,
      frames: 4,
    );

Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF336699), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(3, 2);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<String> _writeMovie(MovieEntity movie) async {
  final directory = await Directory.systemTemp.createTemp('gift-svga-test-');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}/effect.svga');
  await file.writeAsBytes(ZLibEncoder().convert(movie.writeToBuffer()));
  return file.path;
}

MovieEntity _movie(Uint8List png, {int images = 3, MovieParams? params}) =>
    MovieEntity(
      params: params ?? _validParams(),
      images: {
        for (var index = 0; index < images; index++) 'image$index': png,
      },
    );

/// Wrap real PNG codecs so the tests check native image ownership as well as
/// decoder ordering. The gate makes concurrent creation observable without
/// relying on timings or a large fixture.
class _CodecTracker {
  final codecs = <_TrackingCodec>[];
  final images = <ui.Image>[];
  final firstFrameEntered = Completer<void>();
  Completer<void>? firstFrameGate;
  void Function()? onFrame;
  int? failFrameAt;
  int started = 0;
  int active = 0;
  int maxActive = 0;

  Future<ui.Codec> create(Uint8List bytes) async {
    final index = started++;
    active++;
    if (active > maxActive) maxActive = active;
    final codec = _TrackingCodec(
      await ui.instantiateImageCodec(bytes),
      this,
      index,
    );
    codecs.add(codec);
    return codec;
  }
}

class _TrackingCodec implements ui.Codec {
  _TrackingCodec(this.delegate, this.tracker, this.index);

  final ui.Codec delegate;
  final _CodecTracker tracker;
  final int index;
  int disposeCalls = 0;

  @override
  int get frameCount => delegate.frameCount;

  @override
  int get repetitionCount => delegate.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    if (index == 0) {
      tracker.firstFrameEntered.complete();
      final gate = tracker.firstFrameGate;
      if (gate != null) await gate.future;
    }
    if (tracker.failFrameAt == index) {
      throw StateError('Test frame decode failed');
    }
    final frame = await delegate.getNextFrame();
    tracker.images.add(frame.image);
    tracker.onFrame?.call();
    return frame;
  }

  @override
  void dispose() {
    disposeCalls++;
    tracker.active--;
    delegate.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List png;
  setUpAll(() async => png = await _png());

  test('decodes one PNG at a time and releases each codec before the next',
      () async {
    final path = await _writeMovie(_movie(png));
    final tracker = _CodecTracker()..firstFrameGate = Completer<void>();
    final decoder = GiftSVGADecoder(createCodec: tracker.create);
    final pending = decoder.decodeFile(path);

    await tracker.firstFrameEntered.future;
    expect(tracker.started, 1);
    expect(tracker.active, 1);
    tracker.firstFrameGate!.complete();

    final movie = await pending;
    try {
      expect(tracker.started, 3);
      expect(tracker.maxActive, 1);
      expect(tracker.active, 0);
      expect(
          tracker.codecs.map((codec) => codec.disposeCalls), everyElement(1));
      expect(movie.images, isEmpty);
      expect(movie.bitmapCache, hasLength(3));
      for (final image in movie.bitmapCache.values) {
        expect(image.width, 3);
        expect(image.height, 2);
        expect(image.debugDisposed, isFalse);
      }
    } finally {
      movie.dispose();
    }
    expect(
        tracker.images.map((image) => image.debugDisposed), everyElement(true));
  });

  test('failed getNextFrame releases its codec and all earlier images',
      () async {
    final path = await _writeMovie(_movie(png));
    final tracker = _CodecTracker()..failFrameAt = 1;
    final decoder = GiftSVGADecoder(createCodec: tracker.create);

    await expectLater(decoder.decodeFile(path), throwsStateError);

    expect(tracker.started, 2);
    expect(tracker.maxActive, 1);
    expect(tracker.active, 0);
    expect(tracker.codecs.map((codec) => codec.disposeCalls), everyElement(1));
    expect(tracker.images, hasLength(1));
    expect(tracker.images.single.debugDisposed, isTrue);
  });

  test('cancellation after a frame releases it without decoding later images',
      () async {
    final path = await _writeMovie(_movie(png));
    var cancelled = false;
    final tracker = _CodecTracker()..onFrame = () => cancelled = true;
    final decoder = GiftSVGADecoder(createCodec: tracker.create);

    await expectLater(
      decoder.decodeFile(path, isCancelled: () => cancelled),
      throwsA(isA<FormatException>()),
    );

    expect(tracker.started, 1);
    expect(tracker.active, 0);
    expect(tracker.codecs.single.disposeCalls, 1);
    expect(tracker.images, hasLength(1));
    expect(tracker.images.single.debugDisposed, isTrue);
  });

  test('KEEP frames reuse the previous nonempty shape list', () async {
    final source = MovieEntity(
      params: _validParams(),
      sprites: [
        SpriteEntity(imageKey: 'shape', frames: [
          FrameEntity(shapes: [ShapeEntity(type: ShapeEntity_ShapeType.RECT)]),
          FrameEntity(shapes: [ShapeEntity(type: ShapeEntity_ShapeType.KEEP)]),
          FrameEntity(),
          FrameEntity(shapes: [ShapeEntity(type: ShapeEntity_ShapeType.KEEP)]),
        ]),
      ],
    );
    final path = await _writeMovie(source);
    final movie = await const GiftSVGADecoder().decodeFile(path);
    try {
      final frames = movie.sprites.single.frames;
      expect(frames[0].shapes.single.type, ShapeEntity_ShapeType.RECT);
      expect(identical(frames[1].shapes, frames[0].shapes), isTrue);
      expect(frames[2].shapes, isEmpty);
      expect(identical(frames[3].shapes, frames[0].shapes), isTrue);
    } finally {
      movie.dispose();
    }
  });

  test('audio entries are skipped while the actual PNG is decoded', () async {
    final source = MovieEntity(
      params: _validParams(),
      images: {
        // SVGA stores audio bytes in the same map as its PNG resources.
        'soundtrack': [0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0, 0],
        'image': png,
      },
      audios: [AudioEntity(audioKey: 'soundtrack')],
    );
    final path = await _writeMovie(source);
    final tracker = _CodecTracker();
    final decoder = GiftSVGADecoder(createCodec: tracker.create);

    final movie = await decoder.decodeFile(path);
    try {
      expect(tracker.started, 1);
      expect(tracker.active, 0);
      expect(tracker.codecs.single.disposeCalls, 1);
      expect(movie.bitmapCache.keys, ['image']);
      expect(movie.images, isEmpty);
      expect(movie.audios.single.audioKey, 'soundtrack');
      expect(movie.bitmapCache['image']!.width, 3);
      expect(movie.bitmapCache['image']!.height, 2);
    } finally {
      movie.dispose();
    }
    expect(tracker.images.single.debugDisposed, isTrue);
  });

  final invalidParams = {
    'no frames': _validParams()..frames = 0,
    'zero fps': _validParams()..fps = 0,
    'zero width': _validParams()..viewBoxWidth = 0,
    'negative height': _validParams()..viewBoxHeight = -1,
    'infinite width': _validParams()..viewBoxWidth = double.infinity,
    'NaN height': _validParams()..viewBoxHeight = double.nan,
  };
  for (final entry in invalidParams.entries) {
    test('rejects ${entry.key} before creating an image codec', () async {
      final path = await _writeMovie(_movie(png, params: entry.value));
      final tracker = _CodecTracker();
      final decoder = GiftSVGADecoder(createCodec: tracker.create);

      await expectLater(
          decoder.decodeFile(path), throwsA(isA<FormatException>()));

      expect(tracker.started, 0);
      expect(tracker.images, isEmpty);
    });
  }
}
