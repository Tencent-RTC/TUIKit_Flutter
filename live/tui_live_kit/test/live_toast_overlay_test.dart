import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/theme/live_toast_view.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets(
      'dismiss cancels the old request without expiring its replacement',
      (tester) async {
    final toast = LiveToastController();
    await tester
        .pumpWidget(MaterialApp(home: LiveToastView(controller: toast)));
    expect(toast.isShowing, isFalse);
    toast.show('Old', duration: const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(toast.isShowing, isTrue);
    toast.dismiss();
    expect(toast.isShowing, isFalse);
    toast.show('Replacement', duration: const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Old'), findsNothing);
    expect(find.text('Replacement'), findsOneWidget);
    expect(toast.isShowing, isTrue);
    toast.dismiss();
    await tester.pump();
    expect(toast.isShowing, isFalse);
    expect(find.text('Replacement'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    toast.dispose();
    toast.show('After disposal');
    expect(toast.isShowing, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'one root replaces toasts across controllers and isolates cleanup',
      (tester) async {
    final first = LiveToastController();
    final second = LiveToastController();
    late StateSetter update;
    var includeFirst = true;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return Stack(children: [
        if (includeFirst)
          LiveToastView(key: const ValueKey('first'), controller: first),
        LiveToastView(key: const ValueKey('second'), controller: second),
      ]);
    })));
    first.show('First', duration: const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    second.show('Second');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    first.dismiss();
    update(() => includeFirst = false);
    await tester.pump();
    first.dispose();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Second'), findsOneWidget);
    // The second controller's request expires exactly two seconds after show,
    // independent of the earlier controller's timer, dismiss, and disposal.
    await tester.pump(const Duration(milliseconds: 1199));
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    final fadeFrames =
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(fadeFrames, lessThanOrEqualTo(6));
    expect(find.text('Second'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    second.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('toast stays above component sheets inserted before or after it',
      (tester) async {
    final toast = LiveToastController();
    late OverlayState overlay;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      overlay = Overlay.of(context, rootOverlay: true);
      return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
              width: 100,
              height: 100,
              child: LiveToastView(controller: toast)));
    })));
    toast.show('Above sheets');
    await tester.pump(const Duration(milliseconds: 200));
    final sheet = OverlayEntry(
        builder: (_) => const Positioned.fill(
            child: ColoredBox(color: Colors.black, child: Text('Sheet'))));
    LiveToastView.insertBelowToast(overlay, sheet);
    await tester.pump();
    List<String?> paintedTexts() => tester.allWidgets
        .whereType<Text>()
        .map((widget) => widget.data)
        .toList();
    expect(paintedTexts().indexOf('Above sheets'),
        greaterThan(paintedTexts().indexOf('Sheet')));
    expect(tester.getCenter(find.text('Above sheets')),
        tester.getSize(find.byType(Overlay)).center(Offset.zero));
    toast.show('New above sheets');
    await tester.pump(const Duration(milliseconds: 200));
    expect(paintedTexts().indexOf('New above sheets'),
        greaterThan(paintedTexts().indexOf('Sheet')));
    sheet.remove();
    sheet.dispose();
    await tester.pumpWidget(const SizedBox());
    toast.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'removing the host or disposing the controller releases its toast',
      (tester) async {
    final first = LiveToastController();
    final second = LiveToastController();
    late StateSetter update;
    LiveToastController? visible = first;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return visible == null
          ? const SizedBox()
          : LiveToastView(controller: visible!);
    })));
    first.show('Removed host');
    await tester.pump(const Duration(milliseconds: 200));
    update(() => visible = null);
    await tester.pump();
    // The host unmounts at the end of the frame; Overlay then removes its entry.
    await tester.pump();
    expect(find.text('Removed host'), findsNothing);
    first.dispose();
    second.show('Before mount');
    update(() => visible = second);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Before mount'), findsOneWidget);
    second.dispose();
    await tester.pump();
    expect(find.text('Before mount'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('reparenting within one root preserves the original timeout',
      (tester) async {
    final toast = LiveToastController();
    final anchor = GlobalKey();
    late StateSetter update;
    var onLeft = true;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      Widget side(bool isLeft) => Expanded(
          child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  viewInsets: EdgeInsets.only(bottom: isLeft ? 0 : 200)),
              child: onLeft == isLeft
                  ? LiveToastView(key: anchor, controller: toast)
                  : const SizedBox()));
      return Row(children: [side(true), side(false)]);
    })));
    final originalState = anchor.currentState;
    toast.show('Original deadline');
    await tester.pump(const Duration(milliseconds: 1500));
    update(() => onLeft = false);
    await tester.pump();
    expect(anchor.currentState, same(originalState));
    expect(find.text('Original deadline'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('Original deadline'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    toast.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'independent root overlays isolate replacement and clear in background',
      (tester) async {
    final first = LiveToastController();
    final second = LiveToastController();
    final firstEntry =
        OverlayEntry(builder: (_) => LiveToastView(controller: first));
    final secondEntry =
        OverlayEntry(builder: (_) => LiveToastView(controller: second));
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Row(children: [
              Expanded(child: Overlay(initialEntries: [firstEntry])),
              Expanded(child: Overlay(initialEntries: [secondEntry])),
            ]))));
    first.show('Window one');
    second.show('Window two');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Window one'), findsOneWidget);
    expect(find.text('Window two'), findsOneWidget);
    first.show('New window one');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Window one'), findsNothing);
    expect(find.text('New window one'), findsOneWidget);
    expect(find.text('Window two'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('New window one'), findsNothing);
    expect(find.text('Window two'), findsNothing);
    second.show('Late background event');
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Late background event'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    firstEntry.remove();
    secondEntry.remove();
    firstEntry.dispose();
    secondEntry.dispose();
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  });
}
