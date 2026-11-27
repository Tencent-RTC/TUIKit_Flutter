import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/display/playback/gift_resource_loader.dart';

void main() {
  test(
      'Concurrent downloads create complete cache and cancelled downloads leave no partial file',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('gift-loader-test-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final firstChunk = Completer<void>();
    final release = Completer<void>();
    server.listen((request) async {
      if (request.uri.path == '/slow.mp4') {
        request.response.add([1, 2]);
        await request.response.flush();
        firstChunk.complete();
        await release.future;
      } else {
        request.response.add(List.generate(4096, (i) => i % 255));
      }
      await request.response.close();
    });
    final loader = GiftResourceLoader(cacheDirectory: directory);
    final url = 'http://127.0.0.1:${server.port}/gift.MP4';
    try {
      final paths = await Future.wait([loader.load(url), loader.load(url)]);
      expect(paths[0], paths[1]);
      expect(paths[0], endsWith('.mp4'));
      expect(await File(paths[0]).length(), 4096);
      final slowURL = 'http://127.0.0.1:${server.port}/slow.mp4';
      final pending = loader.load(slowURL);
      final cancelled =
          expectLater(pending, throwsA(isA<GiftResourceLoaderException>()));
      await firstChunk.future;
      loader.cancel(slowURL);
      release.complete();
      await cancelled;
      expect(await directory.list().length, 1);
      await expectLater(loader.load('file:///tmp/private.mp4'),
          throwsA(isA<GiftResourceLoaderException>()));
      expect(await loader.load(url), paths[0]);
    } finally {
      if (!release.isCompleted) release.complete();
      loader.dispose();
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
