import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/countdown_view.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/pusher_prepare_view.dart';
import 'package:tencent_live_uikit/src/pusher/pusher_view.dart' show PusherBackNavigation;
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';

class _Actions implements PusherSettingsActionHandling {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _openRoute(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: page),
        )),
        child: const Text('open pusher'),
      ),
    ),
  ));
  await tester.tap(find.text('open pusher'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('system back closes Prepare UI and cancels countdown before exit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prepare = GlobalKey<PusherPrepareViewState>();
    var exits = 0;
    var starts = 0;
    await _openRoute(tester, StatefulBuilder(builder: (context, update) {
      return PusherBackNavigation(
        isLiving: false,
        isEnding: false,
        hasTransientUI: prepare.currentState?.hasTransientUI ?? false,
        onDismissTransientUI: () => prepare.currentState?.handleBackPressed(),
        onDidPop: () => exits++,
        child: PusherPrepareView(
          key: prepare,
          liveTitle: 'Retained title',
          coverURL: '',
          settings: PusherSettingsState(),
          actionHandler: _Actions(),
          onBackStateChanged: () => update(() {}),
          onCountdownFinished: (_) => starts++,
        ),
      );
    }));
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.common.more')));
    await tester.pumpAndSettle();
    expect(prepare.currentState!.hasTransientUI, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(prepare.currentState!.hasTransientUI, isFalse);
    expect(find.byType(PusherPrepareView), findsOneWidget);

    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.change_cover')));
    await tester.pumpAndSettle();
    expect(prepare.currentState!.hasTransientUI, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(prepare.currentState!.hasTransientUI, isFalse);
    expect(exits, 0);

    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.start_live')));
    await tester.pump();
    expect(find.byType(CountdownView), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(CountdownView), findsNothing);
    expect(starts, 0);
    expect(exits, 0);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Retained title');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 1);
    expect(find.byType(PusherPrepareView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed countdown removes Prepare back protection', (tester) async {
    final prepare = GlobalKey<PusherPrepareViewState>();
    var exits = 0;
    var starts = 0;
    await _openRoute(tester, StatefulBuilder(builder: (context, update) {
      return PusherBackNavigation(
        isLiving: false,
        isEnding: false,
        hasTransientUI: prepare.currentState?.hasTransientUI ?? false,
        onDismissTransientUI: () => prepare.currentState?.handleBackPressed(),
        onDidPop: () => exits++,
        child: PusherPrepareView(
          key: prepare,
          liveTitle: 'draft',
          coverURL: '',
          settings: PusherSettingsState(),
          actionHandler: _Actions(),
          onBackStateChanged: () => update(() {}),
          onCountdownFinished: (_) => starts++,
        ),
      );
    }));
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.start_live')));
    await tester.pump();
    for (var second = 0; second < 3; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(starts, 1);
    expect(prepare.currentState!.hasTransientUI, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  testWidgets('Living and pause consume back, ending ignores it, Summary exits', (tester) async {
    late StateSetter update;
    var living = true;
    var ending = false;
    var paused = false;
    var settings = true;
    var exits = 0;
    var handled = 0;
    await _openRoute(tester, StatefulBuilder(builder: (context, setState) {
      update = setState;
      return PusherBackNavigation(
        isLiving: living,
        isEnding: ending,
        hasTransientUI: settings,
        onDismissTransientUI: () {
          handled++;
          if (!paused) setState(() => settings = false);
        },
        onDidPop: () => exits++,
        child: Text(paused
            ? 'paused'
            : living
                ? 'living'
                : 'summary'),
      );
    }));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(settings, isFalse);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 0);
    update(() => paused = true);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('paused'), findsOneWidget);
    expect(exits, 0);

    update(() => ending = true);
    await tester.pump();
    final before = handled;
    await tester.binding.handlePopRoute();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, before);
    expect(exits, 0);

    update(() {
      living = false;
      ending = false;
      paused = false;
    });
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 1);
    expect(find.text('summary'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('independent beauty presentation consumes back before Prepare exits', (tester) async {
    var beautyPresented = true;
    var exits = 0;
    await _openRoute(tester, StatefulBuilder(builder: (context, update) {
      return PusherBackNavigation(
        isLiving: false,
        isEnding: false,
        hasTransientUI: beautyPresented,
        onDismissTransientUI: () => update(() => beautyPresented = false),
        onDidPop: () => exits++,
        child: const Text('prepare'),
      );
    }));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(beautyPresented, isFalse);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 1);
  });
}
