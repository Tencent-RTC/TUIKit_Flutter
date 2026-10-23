import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/living/pusher_living_settings_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';
import 'package:tencent_live_uikit/src/pusher/settings/audio_effect_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_item_view.dart';
import 'support/audio_effect_store_probe.dart';

class Actions implements PusherSettingsActionHandling {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class RecordingActions extends Actions {
  final List<Symbol> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return null;
  }
}

Map<String, Widget> consumers(WidgetTester tester) {
  final items = tester.widgetList<PusherSettingsItemView>(find.byType(PusherSettingsItemView, skipOffstage: false));
  return {for (final item in items) item.assetName: item};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('microphone exports include the original 44px circular background', () async {
    for (final state in ['on', 'off']) {
      for (final scale in [1, 2, 3]) {
        final directory = scale == 1 ? '' : '$scale.0x/';
        final data = await rootBundle
            .load('packages/${LiveKitResources.packageName}/assets/${directory}livekit_living_setting_mic_$state.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 44 * scale);
        expect(image.height, 44 * scale);
        final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        // This point is inside the source circle and outside the microphone.
        expect(rgba.getUint8(((3 * scale) * image.width + 22 * scale) * 4 + 3), greaterThan(0));
        image.dispose();
        codec.dispose();
      }
    }
  });

  testWidgets('mute states use one circle and keep the same image slot', (tester) async {
    final settings = PusherSettingsState();
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, update) {
        return PusherLivingSettingsView(
          settings: settings,
          settingsActionHandler: Actions(),
          isPresented: true,
          onDismiss: () {},
          onToggleMute: () => update(() => settings.isMuted = !settings.isMuted),
        );
      }),
    ));
    await tester.pumpAndSettle();
    Rect? imageSlot;
    for (final muted in [false, true, false]) {
      final item = find.byWidgetPredicate((widget) =>
          widget is PusherSettingsItemView && widget.assetName == 'livekit_living_setting_mic_${muted ? 'off' : 'on'}');
      expect(item, findsOneWidget);
      final view = tester.widget<PusherSettingsItemView>(item);
      expect(view.showsIconBackground, isFalse);
      expect(view.isSelected, isFalse);
      expect(
          view.title,
          LiveKitResources.localizedString(
              muted ? 'tuilivekit.pusher.living.unmute' : 'tuilivekit.pusher.living.mute'));
      final slot = tester.getRect(find.descendant(of: item, matching: find.byType(Image)));
      expect(slot.size, const Size(44, 44));
      imageSlot ??= slot;
      expect(slot, imageSlot);
      final circle = tester
          .widgetList<Container>(find.descendant(of: item, matching: find.byType(Container)))
          .singleWhere((container) => container.constraints?.maxWidth == 44);
      final decoration = circle.decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('beauty closes more before asking root to open the shared panel', (tester) async {
    final calls = <String>[];
    var presented = true;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
          builder: (context, update) => PusherLivingSettingsView(
                settings: PusherSettingsState(),
                settingsActionHandler: Actions(),
                isPresented: presented,
                onDismiss: () {
                  calls.add('dismiss');
                  update(() => presented = false);
                },
                onShowBeauty: () => calls.add('beauty'),
              )),
    ));
    await tester.pumpAndSettle();
    final items = consumers(tester);
    expect(items.keys.where((key) => key.contains('quality')), isEmpty);
    expect(items.length, 8);
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    expect(calls, isEmpty);
    await tester.pumpAndSettle();
    expect(calls, ['dismiss', 'beauty']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio subscriptions follow visible page and reopen on main', (tester) async {
    final store = AudioEffectStoreProbe();
    final settings = PusherSettingsState();
    late StateSetter update;
    var presented = true;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return PusherLivingSettingsView(
          settings: settings,
          settingsActionHandler: Actions(),
          audioEffectStore: store,
          isPresented: presented,
          onDismiss: () => update(() => presented = false),
        );
      }),
    ));
    await tester.pumpAndSettle();
    expect(store.audioChangerType.isObserved, isFalse);
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.audio_effects')));
    await tester.pumpAndSettle();
    expect(store.audioChangerType.isObserved, isTrue);
    update(() => settings.captureVolume = 52);
    await tester.pump();
    expect(tester.widget<AudioEffectView>(find.byType(AudioEffectView)).settings.captureVolume, 52);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(store.audioChangerType.isObserved, isFalse);
    await tester.pumpAndSettle();
    update(() => presented = true);
    await tester.pumpAndSettle();
    expect(find.byType(AudioEffectView), findsNothing);
    expect(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system dismissal cancels a pending panel action', (tester) async {
    var presented = true;
    var beautyRequests = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return PusherLivingSettingsView(
          settings: PusherSettingsState(),
          settingsActionHandler: Actions(),
          isPresented: presented,
          onDismiss: () => update(() => presented = false),
          onShowBeauty: () => beautyRequests++,
        );
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    await tester.pump(const Duration(milliseconds: 50));
    update(() => presented = false);
    await tester.pumpAndSettle();
    expect(beautyRequests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two actions during dismissal execute only the first action', (tester) async {
    final actions = <String>[];
    var presented = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return PusherLivingSettingsView(
          settings: PusherSettingsState(),
          settingsActionHandler: Actions(),
          isPresented: presented,
          onDismiss: () => update(() => presented = false),
          onShowComment: () => actions.add('comment'),
          onShowBeauty: () => actions.add('beauty'),
          onPause: () => actions.add('pause'),
        );
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.living.comment')));
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    expect(actions, isEmpty);
    await tester.pumpAndSettle();
    expect(actions, ['comment']);

    update(() => presented = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.living.pause')));
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.living.comment')));
    expect(actions, ['comment']);
    await tester.pumpAndSettle();
    expect(actions, ['comment', 'pause']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiding and reopening invalidates the previous dismissal action', (tester) async {
    final actions = <String>[];
    var presented = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return PusherLivingSettingsView(
          settings: PusherSettingsState(),
          settingsActionHandler: Actions(),
          isPresented: presented,
          onDismiss: () => update(() => presented = false),
          onShowBeauty: () => actions.add('beauty'),
          onPause: () => actions.add('pause'),
        );
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    await tester.pump(const Duration(milliseconds: 50));
    update(() => presented = false);
    await tester.pump();
    update(() => presented = true);
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.living.pause')));
    await tester.pumpAndSettle();
    expect(actions, ['pause']);
    update(() => presented = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.beautify')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(actions, ['pause']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated binds preserve main controls and latest handlers', (tester) async {
    final settings = PusherSettingsState();
    final first = RecordingActions();
    final latest = RecordingActions();
    var actions = first;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return PusherLivingSettingsView(
          settings: settings,
          settingsActionHandler: actions,
          isPresented: true,
          onDismiss: () {},
        );
      }),
    ));
    await tester.pumpAndSettle();
    var before = consumers(tester);
    for (var i = 0; i < 10; i++) {
      update(() {});
      await tester.pump();
      final after = consumers(tester);
      for (final entry in before.entries) {
        expect(identical(entry.value, after[entry.key]), isTrue);
      }
    }
    update(() {
      actions = latest;
      settings.isMirrorEnabled = false;
    });
    await tester.pump();
    final mirror = tester
        .widgetList<PusherSettingsItemView>(find.byType(PusherSettingsItemView))
        .singleWhere((item) => item.assetName == 'livekit_settings_mirror_off');
    mirror.onPressed!();
    expect(first.calls, isEmpty);
    expect(latest.calls, [#toggleMirror]);
    expect(tester.takeException(), isNull);
  });
}
