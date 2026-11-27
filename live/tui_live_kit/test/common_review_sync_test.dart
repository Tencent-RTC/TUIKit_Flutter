import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_stream_view.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_combo_button.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_notice_view.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_display_view.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';

void main() {
  testWidgets(
      'late gift image failure updates comment height without rebinding',
      (tester) async {
    const url = 'https://example.invalid/late-comment-image.png';
    final pending = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.putIfAbsent(const NetworkImage(url),
        () => OneFrameImageStreamCompleter(pending.future));
    addTearDown(() => PaintingBinding.instance.imageCache.clear());
    final heights = <double>[];
    final gift = LiveGiftBarrage(
        giftID: 'gift',
        giftName: 'Rose',
        giftIconURL: url,
        count: 2,
        senderID: 'sender',
        senderName: 'U',
        senderLevel: null);
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 200,
          height: 400,
          child: BarrageStreamView(
            onVisibleContentHeightChanged: heights.add,
            messages: [
              LiveMessage(
                  id: 'gift',
                  userName: 'U',
                  content: '',
                  level: null,
                  gift: gift)
            ],
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    final before = tester.getSize(find.byType(GiftCommentRow)).height;
    expect(heights.last, before);
    pending.completeError(StateError('late image failure'));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byType(GiftCommentRow)).height;
    expect(after, lessThan(before));
    expect(heights.last, after);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('late gift image reflow keeps a following comment list at bottom',
      (tester) async {
    const url = 'https://example.invalid/late-following-image.png';
    final pending = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.putIfAbsent(const NetworkImage(url),
        () => OneFrameImageStreamCompleter(pending.future));
    addTearDown(() => PaintingBinding.instance.imageCache.clear());
    final gift = LiveGiftBarrage(
        giftID: 'gift',
        giftName: 'Rose',
        giftIconURL: url,
        count: 2,
        senderID: 'sender',
        senderName: 'U',
        senderLevel: null);
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
      width: 200,
      height: 100,
      child: BarrageStreamView(messages: [
        for (var index = 0; index < 20; index++)
          LiveMessage(
              id: '$index',
              userName: 'U',
              content: 'Message $index',
              level: null),
        LiveMessage(
            id: 'gift',
            userName: 'U',
            content: '',
            level: null,
            gift: gift),
      ]),
    ))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    pending.completeError(StateError('late image failure'));
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, .5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('gift capsule uses center line anchors and a bounded count font',
      (tester) async {
    final controller = GiftNoticeController();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
      width: 234,
      child: GiftNoticeView(controller: controller),
    ))));
    controller.enqueue(const GiftDisplayItem(
      giftID: 'g',
      name: 'Rose',
      iconURL: '',
      resourceURL: '',
      coins: 1,
      count: 9223372036854775807,
      senderID: 'u',
      senderName: 'Sender',
      senderAvatarURL: '',
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final row = tester.getRect(find.byType(GiftNoticeView));
    final detail =
        LiveKitResources.localizedString('tuilivekit.pusher.gift.sent')
            .replaceFirst('%@', 'Rose');
    expect(tester.getRect(find.text('Sender')).bottom,
        closeTo(row.center.dy - 1, .01));
    expect(
        tester.getRect(find.text(detail)).top, closeTo(row.center.dy + 1, .01));
    final count = tester.widget<Text>(find.text('9223372036854775807'));
    expect(count.style!.fontSize, closeTo(15.6, .01));
    expect(count.maxLines, 1);
    expect(count.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text('9223372036854775807')).width,
        greaterThanOrEqualTo(28));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('gift capsule keeps its fallback until the remote image is ready',
      (tester) async {
    const url = 'https://example.invalid/late-capsule-image.png';
    final pending = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.putIfAbsent(const NetworkImage(url),
        () => OneFrameImageStreamCompleter(pending.future));
    final controller = GiftNoticeController();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
      width: 300,
      child: GiftNoticeView(controller: controller),
    ))));
    controller.enqueue(const GiftDisplayItem(
      giftID: 'g',
      name: 'Rose',
      iconURL: url,
      resourceURL: '',
      coins: 1,
      count: 1,
      senderID: 'u',
      senderName: 'Sender',
      senderAvatarURL: '',
    ));
    await tester.pump();
    final fallback = find.text(
        LiveKitResources.localizedString('tuilivekit.pusher.gift.fallback'));
    expect(fallback, findsOneWidget);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.red, BlendMode.src);
    final image = await recorder.endRecording().toImage(1, 1);
    pending.complete(ImageInfo(image: image));
    await tester.pump();
    expect(fallback, findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    PaintingBinding.instance.imageCache.clear();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'combo face stays 4 below its cell top in a taller accessible row',
      (tester) async {
    final controller = GiftSendComboButtonController();
    final gift = Gift(
        giftID: 'gift', name: 'Gift', coins: 1, iconURL: '', resourceURL: '');
    for (final height in [104.0, 140.0]) {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: SizedBox(
        width: 90,
        height: height,
        child: GiftSendComboButton(controller: controller),
      ))));
      controller.begin(gift);
      await tester.pump();
      final face = find.descendant(
          of: find.byType(GiftSendComboButton),
          matching: find.byWidgetPredicate((widget) =>
              widget is SizedBox && widget.width == 68 && widget.height == 68));
      expect(
          tester.getTopLeft(face).dy -
              tester.getTopLeft(find.byType(GiftSendComboButton)).dy,
          4);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
