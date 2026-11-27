import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/pusher_prepare_view.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/countdown_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';

class _Actions implements PusherSettingsActionHandling {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
      'Prepare counts down once, cancels without losing input, and places actions from safe area',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int started = 0;
    String? title;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(390, 844), padding: EdgeInsets.only(top: 47, bottom: 34)),
      child: PusherPrepareView(
        liveTitle: 'Before',
        coverURL: '',
        settings: PusherSettingsState(),
        actionHandler: _Actions(),
        onCountdownFinished: (value) {
          started++;
          title = value;
        },
      ),
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Retained title');
    final start = find.text(LiveKitResources.localizedString(
        'tuilivekit.pusher.prepare.start_live'));
    final editor = tester.getRect(find.byType(TextField));
    expect(editor.top, 47 + 85 + 90);
    await tester.tap(start);
    await tester.pump();
    expect(find.byType(CountdownView), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find
        .text(LiveKitResources.localizedString('tuilivekit.common.cancel')));
    await tester.pump();
    expect(started, 0);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Retained title');
    await tester.tap(start);
    await tester.pump();
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(started, 1);
    expect(title, 'Retained title');
    await tester.pump(const Duration(seconds: 3));
    expect(started, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets('draft survives cover/settings rebuilds and shared beauty entry',
      (tester) async {
    late StateSetter update;
    var title = 'Before';
    var cover = '';
    final settings = PusherSettingsState();
    var beautyRequests = 0;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return PusherPrepareView(
        liveTitle: title,
        coverURL: cover,
        settings: settings,
        actionHandler: _Actions(),
        onTitleChanged: (value) => title = value,
        onShowBeauty: () => beautyRequests++,
      );
    })));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My retained title');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    update(() {
      cover = 'invalid-cover';
      settings.isMirrorEnabled = false;
    });
    await tester.pump();
    expect(title, 'My retained title');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        title);
    await tester.tap(find
        .text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    await tester.pump();
    expect(beautyRequests, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        title);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
