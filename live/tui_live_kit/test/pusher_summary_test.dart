import 'support/listener_probe.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/pusher/summary/pusher_summary_view.dart';

class Summary implements LiveSummaryStore, LiveSummaryState {
  @override
  final ValueProbe<LiveSummaryData> summaryData = ValueProbe(LiveSummaryData(
      totalDuration: 65000,
      totalGiftCoins: 51,
      totalGiftUniqueSenders: 3,
      totalGiftsSent: 7,
      totalMessageSent: 11,
      totalViewers: 19,
      totalLikesReceived: 23));
  @override
  LiveSummaryState get liveSummaryState => this;
}

void main() {
  testWidgets('summary fits English pause text and large statistics on narrow screens', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const count = 999999999999;
    for (final width in [320.0, 390.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(MaterialApp(
        home: PusherSummaryView(
          liveID: 'r',
          summaryContext:
              PusherSummaryContext(startTime: DateTime(2026), endTime: DateTime(2026, 1, 1, 1), pausedSeconds: 65),
          finalSummary: PusherSummary(
            liveDuration: 75,
            totalViewers: count,
            totalMessageCount: count,
            totalGiftsSent: count,
            totalGiftCoins: count,
            totalUniqueGiftSenders: count,
            totalLikesReceived: count,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Paused 1m5s'), findsOneWidget);
      expect(find.text('Gift value (coins)'), findsOneWidget);
      expect(find.text('Interactions'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.value == '999,999,999,999'),
          findsNWidgets(6));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('final event snapshot is authoritative and missing data stays unknown', (tester) async {
    final context = PusherSummaryContext(
        startTime: DateTime(2026),
        endTime: DateTime(2026, 1, 1, 1),
        pausedSeconds: 0,
        interruptionMessage: 'server ended');
    await tester.pumpWidget(MaterialApp(home: PusherSummaryView(liveID: 'r', summaryContext: context)));
    await tester.pumpAndSettle();
    expect(find.text('--'), findsNWidgets(6));
    expect(find.textContaining('Total --'), findsOneWidget);
    expect(find.text('server ended'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
        home: PusherSummaryView(
            liveID: 'r',
            summaryContext: context,
            finalSummary: PusherSummary(liveDuration: 75, totalViewers: 123, totalMessageCount: 321))));
    await tester.pump();
    expect(find.textContaining('Total 1m15s'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('321'), findsOneWidget);
    expect(find.text('--'), findsNothing);
  });

  testWidgets('summary uses official duration and six counts, retains only time context', (tester) async {
    final sdk = Summary();
    await tester.pumpWidget(MaterialApp(
        home: PusherSummaryView(
            liveID: 'r',
            summaryStore: sdk,
            summaryContext: PusherSummaryContext(
                startTime: DateTime(2026, 9, 5, 10), endTime: DateTime(2026, 9, 5, 11), pausedSeconds: 4))));
    await tester.pumpAndSettle();
    for (final value in ['51', '3', '7', '11', '19', '23', '10:00 – 11:00  ·  Total 1m5s', 'Paused 4s']) {
      expect(find.text(value), findsOneWidget);
    }
    expect(find.text('Gift value (coins)'), findsOneWidget);
    sdk.summaryData.value = LiveSummaryData(totalDuration: 100000);
    await tester.pump();
    expect(find.textContaining('Total 1m40s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(sdk.summaryData.isObserved, isFalse);
    expect(tester.takeException(), isNull);
  });
}
