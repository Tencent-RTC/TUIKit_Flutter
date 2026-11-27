import 'package:app_uikit/live/home/live_home_header_view.dart';
import 'package:app_uikit/live/home/live_home_preview_item_view.dart';
import 'package:app_uikit/live/home/live_home_room_transition.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact and wide preview layouts remain usable and block duplicate entry', (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    var entries = 0;
    for (final width in [320.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 568);
      Widget page(bool joining) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 568),
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            textScaler: const TextScaler.linear(1.3),
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: LiveHomePreviewItemView(
                    info: LiveInfo(liveName: 'A long live stream title'),
                    player: const SizedBox.shrink(),
                    bottomInset: 72,
                    joining: joining,
                    onEnter: () => entries++,
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: LiveHomeHeaderView(mode: LiveHomeMode.preview, onModeChanged: (_) {}, onStartLive: () {}),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(false));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Enter live room'));
      expect(entries, greaterThan(0));
      final count = entries;
      await tester.pumpWidget(page(true));
      await tester.tap(find.text('Enter live room'));
      expect(entries, count);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('card route starts at its source and fades back without recreating the destination', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final lifecycle = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('grid')),
      ),
    );
    navigator.currentState!.push(
      LiveHomeRoomTransition(
        page: _Destination(lifecycle: lifecycle),
        info: LiveInfo(liveID: 'fixture'),
        source: const Rect.fromLTWH(12, 110, 178, 240),
        visibleSource: const Rect.fromLTWH(12, 110, 178, 240),
      ),
    );
    await tester.pump();
    expect(find.text('grid'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(lifecycle, ['init']);
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(lifecycle, ['init']);
    await tester.pumpAndSettle();
    expect(lifecycle, ['init', 'dispose']);
    expect(find.text('grid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Destination extends StatefulWidget {
  const _Destination({required this.lifecycle});
  final List<String> lifecycle;
  @override
  State<_Destination> createState() => _DestinationState();
}

class _DestinationState extends State<_Destination> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.add('init');
  }

  @override
  void dispose() {
    widget.lifecycle.add('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}
