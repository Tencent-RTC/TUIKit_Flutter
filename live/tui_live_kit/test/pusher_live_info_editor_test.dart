import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/pusher_live_info_editor_view.dart';

void main() {
  testWidgets('edit topic uses the full 25 high button hit area',
      (tester) async {
    final controller = PusherLiveInfoEditorController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: PusherLiveInfoEditorView(
        controller: controller,
        coverURL: '',
      )),
    ));
    final label = find.text(LiveKitResources.localizedString(
        'tuilivekit.pusher.prepare.edit_topic'));
    final gesture =
        find.ancestor(of: label, matching: find.byType(GestureDetector)).first;
    final bounds = tester.getRect(gesture);
    expect(bounds.height, 25);
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + 1));
    await tester.pump();
    expect(controller.focusNode.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'cover retains its last frame through loading failure and stale results',
      (tester) async {
    final controller = PusherLiveInfoEditorController();
    final requests = <Completer<ImageInfo>>[];
    final urls = List.generate(
        4, (index) => 'https://example.com/review-cover-$index.png');
    for (final url in urls) {
      final pending = Completer<ImageInfo>();
      requests.add(pending);
      PaintingBinding.instance.imageCache.putIfAbsent(NetworkImage(url),
          () => OneFrameImageStreamCompleter(pending.future));
    }
    ui.Image frame(Color color) {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(color, BlendMode.src);
      final picture = recorder.endRecording();
      final result = picture.toImageSync(2, 2);
      picture.dispose();
      return result;
    }

    var selectedURL = urls[0];
    late StateSetter updateCover;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      updateCover = setState;
      return PusherLiveInfoEditorView(
          controller: controller, coverURL: selectedURL);
    }))));
    Future<void> show(String url) async {
      updateCover(() => selectedURL = url);
      await tester.pump();
      expect(
          tester
              .widget<PusherLiveInfoEditorView>(
                  find.byType(PusherLiveInfoEditorView))
              .coverURL,
          url);
    }

    ui.Image? rendered() =>
        tester.widget<RawImage>(find.byType(RawImage)).image;
    requests[0].complete(ImageInfo(image: frame(Colors.red)));
    await tester.pumpAndSettle();
    final first = rendered();
    expect(first, isNotNull);
    expect(tester.getSize(find.byType(RawImage)), const Size(58, 58));
    await show(urls[1]);
    expect(rendered(), same(first));
    requests[1].completeError(StateError('failed replacement'));
    await tester.pumpAndSettle();
    expect(rendered(), same(first));
    await show(urls[2]);
    await show(urls[3]);
    requests[2].complete(ImageInfo(image: frame(Colors.green)));
    await tester.pumpAndSettle();
    expect(rendered(), same(first));
    requests[3].complete(ImageInfo(image: frame(Colors.blue)));
    // An idle test pump first flushes the Future and schedules a frame;
    // settle also paints that frame before examining RawImage.
    await tester.pumpAndSettle();
    expect(rendered(), isNot(same(first)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    for (final url in urls) {
      PaintingBinding.instance.imageCache.evict(NetworkImage(url));
    }
  });

  testWidgets(
      'title limit counts UTF8 bytes, preserves graphemes and IME composition',
      (tester) async {
    final controller = PusherLiveInfoEditorController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: PusherLiveInfoEditorView(controller: controller, coverURL: ''),
    )));
    final field = tester.widget<TextField>(find.byType(TextField));
    final TextInputFormatter formatter = field.inputFormatters!.single;
    final String emoji = List.filled(101, '👨‍👩‍👧‍👦').join();
    final trimmed = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text: emoji,
            selection: TextSelection.collapsed(offset: emoji.length)));
    expect(utf8.encode(trimmed.text).length, 100);
    expect(trimmed.text.characters.length, 4);
    expect(trimmed.selection.baseOffset, trimmed.text.length);

    final oldText = '${List.filled(98, 'a').join()}Z';
    final old = TextEditingValue(
        text: oldText, selection: const TextSelection.collapsed(offset: 98));
    final pasted = '${List.filled(98, 'a').join()}123Z';
    final replaced = formatter.formatEditUpdate(
        old,
        TextEditingValue(
            text: pasted,
            selection: const TextSelection.collapsed(offset: 101)));
    expect(replaced.text, '${List.filled(98, 'a').join()}1Z');
    expect(replaced.selection.baseOffset, 99);

    final composing = TextEditingValue(
        text: emoji, composing: TextRange(start: 0, end: emoji.length));
    expect(formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing);
    expect(
        formatter
            .formatEditUpdate(
                composing, composing.copyWith(composing: TextRange.empty))
            .text
            .characters
            .length,
        4);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  test('programmatic title binding applies byte limit without splitting emoji',
      () {
    final controller = PusherLiveInfoEditorController();
    controller.bind(title: List.filled(40, '中').join());
    expect(controller.title.characters.length, 33);
    expect(utf8.encode(controller.title).length, 99);
    controller.bind(title: List.filled(10, '👨‍👩‍👧‍👦').join());
    expect(controller.title.characters.length, 4);
    expect(utf8.encode(controller.title).length, 100);
    controller.dispose();
  });
}
