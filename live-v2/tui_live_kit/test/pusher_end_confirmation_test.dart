import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/living/end_confirm/pusher_end_confirmation_view.dart';

void main() {
  testWidgets(
      'end buttons share an adaptive width and bounded single-line text',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final language in ['zh', 'en']) {
      tester.platformDispatcher.localeTestValue = Locale(language);
      for (final width in [320.0, 390.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 844));
        await tester.pumpWidget(MaterialApp(
            home: PusherEndConfirmationView(
                viewerCount: 123456789012,
                onDismiss: () {},
                onConfirmEnd: () {})));
        await tester.pumpAndSettle();
        final continueLabel = find.text(
            LiveKitResources.localizedString('tuilivekit.pusher.end.continue'));
        final endLabel = find.text(
            LiveKitResources.localizedString('tuilivekit.pusher.end.end'));
        Rect button(Finder label) => tester.getRect(find
            .ancestor(of: label, matching: find.byType(GestureDetector))
            .first);
        final first = button(continueLabel);
        final second = button(endLabel);
        expect(first.width, second.width);
        expect(second.left - first.right, 24);
        expect(first.left, greaterThanOrEqualTo(20));
        expect(second.right, lessThanOrEqualTo(width - 20));
        if (language == 'en') expect(first.width, greaterThan(108));
        for (final label in [continueLabel, endLabel]) {
          final text = tester.widget<Text>(label);
          expect(text.maxLines, 1);
          expect(text.softWrap, isFalse);
          expect(text.style!.fontSize, inInclusiveRange(12.75, 15));
        }
        final audience = tester.widget<Text>(find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains('123456789012') == true));
        final span = audience.textSpan! as TextSpan;
        expect(span.style!.fontSize, inInclusiveRange(11.2, 14));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('ending hides before callback and ignores repeated taps',
      (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: PusherEndConfirmationView(
            viewerCount: 2,
            onDismiss: () => calls.add('hide'),
            onConfirmEnd: () => calls.add('end'))));
    await tester.pumpAndSettle();
    final end = find
        .text(LiveKitResources.localizedString('tuilivekit.pusher.end.end'));
    await tester.tap(end);
    await tester.tap(end);
    expect(calls, ['hide', 'end']);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
