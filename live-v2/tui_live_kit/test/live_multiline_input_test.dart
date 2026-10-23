import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_input_view.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/pusher_live_info_editor_view.dart';

void main() {
  for (final width in [320.0, 390.0, 600.0]) {
    testWidgets(
        'comment wraps, reports height and warns beyond 200 at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      double height = 0;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: Size(width, 844),
            viewPadding: const EdgeInsets.only(bottom: 34),
            viewInsets: const EdgeInsets.only(bottom: 300)),
        child: BarrageInputView(
            onDismiss: () {},
            onInputBarHeightChanged: (value) => height = value),
      )));
      await tester.pumpAndSettle();
      expect(height, 36);
      final field = find.byType(TextField);
      final message = LiveKitResources.localizedFormat(
          'tuilivekit.comment.character_limit', 200);
      await tester.enterText(field, '文' * 200);
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
      expect(height, greaterThan(36));
      expect(height, lessThanOrEqualTo(100));
      expect(tester.widget<TextField>(field).maxLines, 4);
      final bar = find.byWidgetPredicate((widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color ==
              const Color(0xE00C0D12));
      expect(tester.getRect(bar).bottom, 844 - 300 - 4);
      expect(tester.getRect(field).width,
          closeTo(width - 24 - 36 - 8 - 60 - 6, .1));
      await tester.enterText(field, '文' * 201);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<TextField>(field).controller!.text.characters.length,
          200);
      expect(find.text(message), findsOneWidget);
      await tester.enterText(field, '短');
      await tester.pumpAndSettle();
      expect(height, 36);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'topic grows at fixed font size, caps at three lines and warns after composition commits',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PusherLiveInfoEditorController()
      ..textController.text = 'Hi';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PusherLiveInfoEditorView(
                controller: controller, coverURL: ''))));
    final field = find.byType(TextField);
    final initialHeight = tester.getSize(field).height;
    await tester.enterText(field, 'a' * 100);
    await tester.pumpAndSettle();
    expect(tester.getSize(field).height, greaterThan(initialHeight));
    expect(tester.widget<TextField>(field).style!.fontSize, 20);
    expect(tester.widget<TextField>(field).maxLines, 3);
    final message = LiveKitResources.localizedFormat(
        'tuilivekit.pusher.prepare.topic_byte_limit', 100);
    expect(find.text(message), findsNothing);
    final composing = TextEditingValue(
        text: '${'a' * 96}nihao',
        composing: const TextRange(start: 96, end: 101),
        selection: const TextSelection.collapsed(offset: 101));
    tester.testTextInput.updateEditingValue(composing);
    await tester.pump();
    expect(find.text(message), findsNothing);
    tester.testTextInput.updateEditingValue(TextEditingValue(
        text: '${'a' * 96}你好',
        selection: const TextSelection.collapsed(offset: 98)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.title.characters.length, 97);
    expect(controller.title.endsWith('你'), isTrue);
    expect(find.text(message), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}
