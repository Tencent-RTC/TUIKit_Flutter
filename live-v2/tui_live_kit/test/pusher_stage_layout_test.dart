import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/countdown_view.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/pusher_prepare_gradient_overlay_view.dart';

void main() {
  testWidgets(
      'countdown leaves stage undimmed and keeps geometry across safe areas',
      (tester) async {
    for (final height in [844.0, 960.0]) {
      for (final safeBottom in [0.0, 16.0, 34.0]) {
        await tester.binding.setSurfaceSize(Size(390, height));
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(390, height),
              padding: EdgeInsets.only(bottom: safeBottom),
              viewPadding: EdgeInsets.only(bottom: safeBottom),
              viewInsets: const EdgeInsets.only(bottom: 300),
            ),
            child: const CountdownView(number: 3),
          ),
        ));
        final stageBottom = height - 78 - safeBottom;
        final dim = find.byWidgetPredicate((widget) =>
            widget is ColoredBox && widget.color == const Color(0x1F000000));
        final bar = find.byWidgetPredicate((widget) =>
            widget is ColoredBox && widget.color == const Color(0xFF0A0A0F));
        // The current iOS countdown leaves the video uncovered. Only the
        // bottom control bar is opaque; keyboard insets never shrink the stage.
        expect(dim, findsNothing);
        expect(find.byType(PusherPrepareGradientOverlayView), findsNothing);
        expect(tester.getRect(bar).top, stageBottom);
        expect(tester.getRect(bar).bottom, height);
        expect(tester.getRect(bar).height, 78 + safeBottom);
        final cancel = find.byType(GestureDetector);
        expect(tester.getSize(cancel), const Size(200, 50));
        expect(tester.getRect(cancel).bottom, height - safeBottom - 8);
        expect(tester.getRect(cancel).top, greaterThan(stageBottom));
        final circle = find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle);
        expect(tester.getCenter(circle).dy, stageBottom / 2);
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
