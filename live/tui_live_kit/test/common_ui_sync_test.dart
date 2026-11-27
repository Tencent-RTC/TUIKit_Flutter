import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/audience/audience_welcome_view.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_stream_view.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_background_view.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_view.dart';
import 'package:tencent_live_uikit/src/common/theme/level_badge_view.dart';
import 'package:tencent_live_uikit/src/common/theme/live_text_input_view.dart';
import 'package:tencent_live_uikit/src/common/theme/live_toast_view.dart';

void main() {
  testWidgets(
      'UTF8 input limits committed edits without splitting graphemes or losing suffixes',
      (tester) async {
    final controller = TextEditingController(text: '前后');
    final focus = FocusNode();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LiveTextInputView(
      controller: controller,
      focusNode: focus,
      characterLimit: 10,
      lengthUnit: LiveTextLengthUnit.utf8Bytes,
      maximumLines: 3,
      minimumHeight: 28,
      limitMessageKey: 'tuilivekit.pusher.prepare.topic_byte_limit',
      style: const TextStyle(fontSize: 20),
      textInputAction: TextInputAction.done,
      onSubmitted: () {},
    ))));
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection.collapsed(offset: 1);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '前你好后',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 3),
    ));
    expect(controller.text, '前你好后');
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '前你好后',
      selection: TextSelection.collapsed(offset: 3),
    ));
    expect(controller.text, '前你后');
    expect(controller.selection.baseOffset, 2);
    expect(utf8.encode(controller.text).length, 9);
    await tester.enterText(find.byType(TextField), '👨‍👩‍👧‍👦ab');
    expect(controller.text, isEmpty);
    await tester.enterText(find.byType(TextField), '😀😀😀');
    expect(controller.text, '😀😀');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focus.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('default comment limit remains grapheme based', (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LiveTextInputView(
      controller: controller,
      focusNode: focus,
      characterLimit: 3,
      maximumLines: 4,
      minimumHeight: 28,
      limitMessageKey: 'tuilivekit.comment.character_limit',
      style: const TextStyle(fontSize: 13),
      textInputAction: TextInputAction.send,
      onSubmitted: () {},
    ))));
    await tester.enterText(find.byType(TextField), '👨‍👩‍👧‍👦中文余');
    expect(controller.text, '👨‍👩‍👧‍👦中文');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focus.dispose();
  });

  testWidgets(
      'toast wraps, replacement owns its timer, and background clears it',
      (tester) async {
    final controller = LiveToastController();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
        home: SizedBox(
            width: 320, child: LiveToastView(controller: controller))));
    final long =
        'A long message with enough detail to wrap across multiple lines. ' * 4;
    controller.show(long);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(find.text(long)).height, greaterThan(16));
    await tester.pump(const Duration(milliseconds: 1500));
    controller.show('Replacement');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Replacement'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Replacement'), findsNothing);
    controller.show('Late background event');
    await tester.pump();
    expect(find.text('Late background event'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'inline gift text wraps and multi-digit badge expands at larger text scale',
      (tester) async {
    final gift = LiveGiftBarrage(
      giftID: 'g',
      giftName: 'A long gift title that remains visible',
      giftIconURL: '',
      count: 123,
      senderID: 'u',
      senderName: '👨‍👩‍👧‍👦' * 21,
      senderLevel: 123456,
    );
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: Center(
          child: SizedBox(width: 180, child: GiftCommentRow(comment: gift))),
    )));
    await tester.pumpAndSettle();
    expect(LevelBadgeView.sizeForLevel(123456).width, greaterThan(34));
    expect(tester.getSize(find.byType(GiftCommentRow)).height, greaterThan(28));
    expect(tester.getSize(find.byType(GiftCommentRow)).width, 180);
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.textSpan != null)
        .single;
    final plain = text.textSpan!.toPlainText().replaceAll('\u200B', '');
    expect(plain, contains('${'👨‍👩‍👧‍👦' * 20}…'));
    expect(plain, contains(gift.giftName));
    expect(plain, contains('×123'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed gift image removes its inline slot', (tester) async {
    Widget view(String url) => MaterialApp(
        home: Center(
            child: SizedBox(
                width: 300,
                child: GiftCommentRow(
                    comment: LiveGiftBarrage(
                        giftID: 'g',
                        giftName: 'Rose',
                        giftIconURL: url,
                        count: 1,
                        senderID: 'u',
                        senderName: 'U',
                        senderLevel: 2)))));
    await tester.pumpWidget(view(''));
    await tester.pumpAndSettle();
    final noImage = tester.getSize(find.byType(GiftCommentRow));
    await tester.pumpWidget(view('https://example.invalid/gift.png'));
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is RawImage && widget.width == null),
        findsNothing);
    expect(tester.getSize(find.byType(GiftCommentRow)), noImage);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'welcome allocates remaining width to name and hides unknown level',
      (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale("zh");
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final controller = AudienceWelcomeController();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
            child:
                Center(child: AudienceWelcomeView(controller: controller)))));
    controller.enqueue(const AudienceWelcome(
        userID: 'u', userName: 'A very long audience nickname'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(LevelBadgeView), findsNothing);
    expect(tester.getSize(find.text('A very long audience nickname')).width,
        greaterThan(55));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'themed sheet stays inside available height and scrolls its full content',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(320, 568),
          padding: EdgeInsets.only(top: 24),
          viewInsets: EdgeInsets.only(bottom: 200)),
      child: BottomSheetTheme(
          child: BottomSheetView(
              sheetHeight: 712,
              onDismiss: () {},
              child: const Stack(children: [
                Positioned(bottom: 0, child: Text('last row')),
              ]))),
    )));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(BottomSheetBackgroundView)).top, 24);
    expect(tester.getRect(find.byType(BottomSheetBackgroundView)).bottom, 368);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('last row').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
