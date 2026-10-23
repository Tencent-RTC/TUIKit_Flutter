import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_background_view.dart';
import 'package:tencent_live_uikit/src/common/theme/bottom_sheet_view.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/prepare/prepare_more_settings_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_item_view.dart';
import 'support/audio_effect_store_probe.dart';

class _Actions implements PusherSettingsActionHandling {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('reopening more never exposes the previous audio sheet height',
      (tester) async {
    late StateSetter update;
    bool presented = true;
    final store = AudioEffectStoreProbe();
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return PrepareMoreSettingsView(
        settings: PusherSettingsState(),
        actionHandler: _Actions(),
        audioEffectStore: store,
        isPresented: presented,
        onDismiss: () => update(() => presented = false),
      );
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text(
        LiveKitResources.localizedString('tuilivekit.pusher.audio_effects')));
    await tester.pumpAndSettle();
    final background = find.byType(BottomSheetBackgroundView);
    expect(tester.getSize(background).height, 466);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<BottomSheetView>(find.byType(BottomSheetView))
            .isPresented,
        isFalse);
    update(() => presented = true);
    await tester.pump();
    // Opening starts entirely below the viewport, already at the main height.
    expect(tester.getSize(background).height, 191);
    expect(tester.getTopLeft(background).dy, 600);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(background).height, 191);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(background).dy, 600 - 191);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prepare more has mirror and audio only', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PrepareMoreSettingsView(
        settings: PusherSettingsState(),
        actionHandler: _Actions(),
        initialPage: PrepareMoreSettingsPage.beauty,
        onDismiss: () {},
      ),
    ));
    await tester.pumpAndSettle();
    final items = tester.widgetList<PusherSettingsItemView>(
        find.byType(PusherSettingsItemView));
    expect(items.map((item) => item.assetName),
        ['livekit_settings_mirror_on', 'livekit_settings_audio_effect']);
    expect(
        tester
            .widget<BottomSheetView>(find.byType(BottomSheetView))
            .sheetHeight,
        191);
    expect(tester.takeException(), isNull);
  });
}
