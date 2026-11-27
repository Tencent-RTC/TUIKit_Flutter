import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_resource_loader.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_animation_view.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_player.dart';

class _GiftPlayer extends GiftPlayer {
  _GiftPlayer({super.loader, super.decodeSVGA});

  void Function(bool)? completion;

  @override
  void play(GiftPreparedResource resource,
      {required void Function(bool failed) onFinished}) {
    completion = onFinished;
    super.play(resource, onFinished: onFinished);
  }

  void finish({bool failed = false}) => completion?.call(failed);
}

class Loader extends GiftResourceLoader {
  final loads = <String, List<Completer<String>>>{};
  final cancelled = <String>[];
  bool wasDisposed = false;
  @override
  Future<String> load(String url) {
    final pending = Completer<String>();
    loads.putIfAbsent(url, () => []).add(pending);
    return pending.future;
  }

  void complete(String url, [String? path]) =>
      loads[url]!.last.complete(path ?? '/${Uri.parse(url).pathSegments.last}');

  @override
  void cancel(String url) {
    cancelled.add(url);
  }

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

MovieEntity movie() => MovieEntity(
        params: MovieParams(
      viewBoxWidth: 100,
      viewBoxHeight: 200,
      fps: 30,
      frames: 60,
    ));

const a = 'https://test/a.mp4';
const b = 'https://test/b.mp4';
const c = 'https://test/c.mp4';
const svga = 'https://test/a.svga';

void main() {
  testWidgets(
      'prepares only the next actual entry once current playback starts',
      (tester) async {
    final loader = Loader();
    final player = _GiftPlayer(loader: loader);
    final controller = GiftAnimationController(player: player);
    expect(loader.loads, isEmpty);
    controller.enqueue(a);
    controller.enqueue(b);
    controller.enqueue(c);
    expect(loader.loads.keys, [a]);
    loader.complete(a);
    await tester.pump();
    expect(player.currentLocalPath, '/a.mp4');
    expect(loader.loads.keys, [a, b]);
    loader.complete(b);
    await tester.pump();
    expect(loader.loads.keys, [a, b]);
    final finishOld = player.completion!;
    finishOld(false);
    expect(player.currentLocalPath, '/b.mp4');
    expect(loader.loads.keys, [a, b, c]);
    finishOld(false);
    expect(player.currentLocalPath, '/b.mp4');
    controller.dispose();
  });

  testWidgets('consecutive same URL reuses the decoded SVGA asset',
      (tester) async {
    final loader = Loader();
    var decodes = 0;
    final asset = movie()..pathCache['retained'] = Path();
    final player = _GiftPlayer(
        loader: loader,
        decodeSVGA: (_) async {
          decodes++;
          return asset;
        });
    final controller = GiftAnimationController(player: player);
    controller.enqueue(svga);
    controller.enqueue(svga);
    controller.enqueue(svga);
    loader.complete(svga);
    await tester.pump();
    final finishFirst = player.completion!;
    finishFirst(false);
    await tester.pump();
    player.finish();
    await tester.pump();
    expect(loader.loads[svga], hasLength(1));
    expect(decodes, 1);
    expect(asset.pathCache, isNotEmpty);
    player.finish();
    await tester.pump();
    expect(asset.pathCache, isEmpty);
    controller.dispose();
  });

  testWidgets('reset cancels current and next loads and rejects old completion',
      (tester) async {
    final loader = Loader();
    final player = _GiftPlayer(loader: loader);
    final controller = GiftAnimationController(player: player);
    controller.enqueue(a);
    final old = loader.loads[a]!.single;
    controller.reset();
    expect(loader.cancelled, [a]);
    controller.enqueue(a);
    old.complete('/old.mp4');
    await tester.pump();
    expect(player.currentLocalPath, isNull);
    loader.complete(a);
    await tester.pump();
    controller.enqueue(b);
    controller.reset();
    expect(loader.cancelled, [a, b]);
    loader.complete(b);
    await tester.pump();
    expect(player.currentKind, isNull);
    controller.dispose();
    expect(loader.wasDisposed, isTrue);
    controller.enqueue(c);
    expect(loader.loads.containsKey(c), isFalse);
  });

  testWidgets('late SVGA decode releases its asset after reset',
      (tester) async {
    final loader = Loader();
    final parsed = Completer<MovieEntity>();
    final player =
        _GiftPlayer(loader: loader, decodeSVGA: (_) => parsed.future);
    final controller = GiftAnimationController(player: player);
    controller.enqueue(svga);
    loader.complete(svga);
    await tester.pump();
    controller.reset();
    final asset = movie()..pathCache['stale'] = Path();
    parsed.complete(asset);
    await tester.pump();
    expect(player.currentLocalPath, isNull);
    expect(asset.pathCache, isEmpty);
    controller.dispose();
  });

  testWidgets(
      'interruption discards the queue and ignores late player completion',
      (tester) async {
    final loader = Loader();
    final player = _GiftPlayer(loader: loader);
    final controller = GiftAnimationController(player: player);
    controller.enqueue(a);
    controller.enqueue(b);
    loader.complete(a);
    await tester.pump();
    final finishOld = player.completion!;
    controller.reset();
    loader.complete(b);
    await tester.pump();
    expect(player.currentKind, isNull);
    expect(player.currentLocalPath, isNull);
    controller.enqueue(c);
    loader.complete(c);
    await tester.pump();
    finishOld(true);
    expect(player.currentLocalPath, '/c.mp4');
    controller.dispose();
  });

  testWidgets('stalled download times out and advances to next resource',
      (tester) async {
    final loader = Loader();
    final player = _GiftPlayer(loader: loader);
    final controller = GiftAnimationController(player: player);
    controller.enqueue(a);
    controller.enqueue(b);
    await tester.pump(const Duration(seconds: 30));
    expect(loader.cancelled, [a]);
    expect(loader.loads.keys, [a, b]);
    loader.complete(a, '/late.mp4');
    loader.complete(b);
    await tester.pump();
    expect(player.currentLocalPath, '/b.mp4');
    controller.dispose();
  });

  testWidgets('failed prepared next resource is skipped without blocking queue',
      (tester) async {
    final loader = Loader();
    final player = _GiftPlayer(
        loader: loader, decodeSVGA: (_) async => throw const FormatException());
    final controller = GiftAnimationController(player: player);
    controller.enqueue(a);
    controller.enqueue(svga);
    controller.enqueue(b);
    loader.complete(a);
    await tester.pump();
    loader.complete(svga);
    await tester.pump();
    expect(player.currentLocalPath, '/a.mp4');
    player.finish();
    await tester.pump();
    expect(loader.loads.containsKey(b), isTrue);
    loader.complete(b);
    await tester.pump();
    expect(player.currentLocalPath, '/b.mp4');
    controller.dispose();
  });

  testWidgets(
      'replacing controllers with equal tokens replaces the player and retains each asset correctly',
      (tester) async {
    final firstLoader = Loader();
    final secondLoader = Loader();
    final firstAsset = movie()..pathCache['first'] = Path();
    final secondAsset = movie()..pathCache['second'] = Path();
    final firstPlayback =
        _GiftPlayer(loader: firstLoader, decodeSVGA: (_) async => firstAsset);
    final first = GiftAnimationController(player: firstPlayback);
    final secondPlayback =
        _GiftPlayer(loader: secondLoader, decodeSVGA: (_) async => secondAsset);
    final second = GiftAnimationController(player: secondPlayback);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget host(GiftAnimationController controller) => Directionality(
          textDirection: TextDirection.ltr,
          child: GiftAnimationView(controller: controller),
        );

    await tester.pumpWidget(host(first));
    first.enqueue(svga);
    firstLoader.complete(svga);
    await tester.pump();
    await tester.pump();
    final firstPlayer = tester.state(find.byType(SVGAImage));

    second.enqueue(svga);
    secondLoader.complete(svga);
    await tester.pump();
    await tester.pumpWidget(host(second));
    expect(
        identical(tester.state(find.byType(SVGAImage)), firstPlayer), isFalse);
    first.dispose();
    expect(firstAsset.pathCache, isEmpty);
    expect(secondAsset.pathCache, isNotEmpty);

    // 控制器先销毁时，在树中的播放器继续持有图像，移除后才最后释放。
    second.dispose();
    expect(secondAsset.pathCache, isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(secondAsset.pathCache, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'SVGA fills its canvas with aspect fit and releases on completion',
      (tester) async {
    final loader = Loader();
    final asset = movie()..pathCache['alive'] = Path();
    final player = _GiftPlayer(loader: loader, decodeSVGA: (_) async => asset);
    final controller = GiftAnimationController(player: player);
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
            width: 320,
            height: 600,
            child: GiftAnimationView(controller: controller))));
    controller.enqueue(svga);
    loader.complete(svga);
    await tester.pump();
    expect(player.currentLocalPath, isNotNull);
    // 文件下载和解码各有一次异步续接；处理完通知后再绘制播放器。
    await tester.pump();
    final image = tester.widget<SVGAImage>(find.byType(SVGAImage));
    expect(image.fit, BoxFit.contain);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(player.currentLocalPath, isNull);
    expect(asset.pathCache, isEmpty);
    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
