import 'package:flutter/cupertino.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'support/audio_effect_store_probe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/theme/live_slider.dart';
import 'package:tencent_live_uikit/src/pusher/settings/audio_effect_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_item_view.dart';

class _BackgroundPaintProbe implements Canvas {
  final List<Paint> paints = [];
  @override
  void drawRRect(RRect rrect, Paint paint) => paints.add(paint);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('sound selection paints the blue fill and switches independently', (tester) async {
    final settings = PusherSettingsState();
    final store = AudioEffectStoreProbe();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
          data: const MediaQueryData(),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 358,
                    height: 372,
                    child: AudioEffectView(
                      settings: settings,
                      audioEffectStore: store,
                    ),
                  ));
            },
          )),
    ));
    await tester.pumpAndSettle();
    final items = find.byType(PusherSettingsItemView);
    void checkSelection(Set<int> selected) {
      for (int i = 0; i < 10; i++) {
        final item = items.at(i);
        expect(tester.widget<PusherSettingsItemView>(item).isSelected, selected.contains(i));
        final decoration = tester
            .widget<DecoratedBox>(find.descendant(of: item, matching: find.byType(DecoratedBox)).first)
            .decoration as BoxDecoration;
        if (selected.contains(i)) {
          expect((decoration.gradient as LinearGradient).colors, [const Color(0x6B4A9EFF), const Color(0x420052D9)]);
          final probe = _BackgroundPaintProbe();
          final painter = decoration.createBoxPainter();
          painter.paint(probe, Offset.zero, const ImageConfiguration(size: Size(48, 48)));
          // The shader already contains alpha: the paint must not erase it.
          expect(probe.paints.firstWhere((paint) => paint.shader != null).color.alpha, 255);
          painter.dispose();
        } else {
          expect(decoration.gradient, isNull);
          expect(decoration.color, const Color(0x0BFFFFFF));
        }
      }
    }

    checkSelection({0, 5});
    await tester.tap(items.at(1));
    await tester.pump();
    checkSelection({1, 5});
    await tester.tap(items.at(7));
    await tester.pump();
    checkSelection({1, 7});
    expect(tester.takeException(), isNull);
  });

  for (final width in [288.0, 358.0, 398.0]) {
    testWidgets('audio at width $width keeps slider anchors and actions', (tester) async {
      final store = AudioEffectStoreProbe();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: width,
                  height: 372,
                  child: AudioEffectView(
                    settings: PusherSettingsState(),
                    audioEffectStore: store,
                  )),
            )),
      ));
      await tester.pumpAndSettle();
      final sliders = find.byType(LiveSlider);
      expect(sliders, findsNWidgets(2));
      expect(tester.getTopLeft(sliders.first).dx, 176);
      expect(tester.getSize(sliders.first).width, width - 192);
      await tester.tapAt(tester.getTopLeft(sliders.first) + const Offset(9, 22));
      expect(store.earMonitorVolume.value, 0);
      final items = find.byType(PusherSettingsItemView);
      expect(items, findsNWidgets(10));
      await tester.tap(items.at(1));
      expect(store.audioChangerType.value, AudioChangerType.child);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('audio stops subscriptions and ignores taps when hidden', (tester) async {
    final store = AudioEffectStoreProbe();
    var active = true;
    int? capture;
    late StateSetter update;
    await tester.pumpWidget(CupertinoApp(
        home: Center(
            child: SizedBox(
      width: 358,
      height: 372,
      child: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return AudioEffectView(
          settings: PusherSettingsState(captureVolume: 67),
          audioEffectStore: store,
          isActive: active,
          onSetCaptureVolume: (value) => capture = value,
        );
      }),
    ))));
    expect(store.earMonitorVolume.isObserved, isTrue);
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider).last).value, 67);
    tester.widget<LiveSlider>(find.byType(LiveSlider).last).onChanged!(35);
    expect(capture, 35);
    update(() => active = false);
    await tester.pump();
    expect(store.earMonitorVolume.isObserved, isFalse);
    await tester.tap(find.byType(PusherSettingsItemView).at(1));
    expect(store.calls, isEmpty);
    update(() => active = true);
    await tester.pump();
    store.setVoiceEarMonitorVolume(17);
    await tester.pump();
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider).first).value, 17);
    await tester.pumpWidget(const SizedBox());
    expect(store.earMonitorVolume.isObserved, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio keeps its product choices, SDK fallback and inactive write guard', (tester) async {
    final store = AudioEffectStoreProbe();
    const changers = {
      AudioChangerType.none: 'livekit_voice_original',
      AudioChangerType.child: 'livekit_voice_child',
      AudioChangerType.littleGirl: 'livekit_voice_loli',
      AudioChangerType.man: 'livekit_voice_uncle',
      AudioChangerType.ethereal: 'livekit_voice_spirit',
    };
    const reverbs = {
      AudioReverbType.none: 'livekit_reverb_none',
      AudioReverbType.ktv: 'livekit_reverb_ktv',
      AudioReverbType.metallic: 'livekit_reverb_metal',
      AudioReverbType.deep: 'livekit_reverb_deep',
      AudioReverbType.loud: 'livekit_reverb_bright',
    };
    Widget view(bool active) => CupertinoApp(
          home: SizedBox(
            height: 380,
            child: AudioEffectView(
              settings: PusherSettingsState(),
              audioEffectStore: store,
              isActive: active,
            ),
          ),
        );
    Map<String, PusherSettingsItemView> items() => {
          for (final item in tester.widgetList<PusherSettingsItemView>(find.byType(PusherSettingsItemView)))
            item.assetName: item,
        };
    await tester.pumpWidget(view(true));
    expect(items().keys, unorderedEquals([...changers.values, ...reverbs.values]));
    expect(store.calls, isEmpty, reason: 'Opening only reads SDK state');
    for (final value in AudioChangerType.values) {
      store.audioChangerType.value = value;
      await tester.pump();
      final selected = items().values.where((item) => item.isSelected && changers.values.contains(item.assetName));
      expect(selected.single.assetName, changers[value] ?? changers[AudioChangerType.none]);
    }
    for (final value in AudioReverbType.values) {
      store.audioReverbType.value = value;
      await tester.pump();
      final selected = items().values.where((item) => item.isSelected && reverbs.values.contains(item.assetName));
      expect(selected.single.assetName, reverbs[value] ?? reverbs[AudioReverbType.none]);
    }
    for (final entry in changers.entries) {
      items()[entry.value]!.onPressed!();
      expect(store.audioChangerType.value, entry.key);
      await tester.pump();
    }
    for (final entry in reverbs.entries) {
      items()[entry.value]!.onPressed!();
      expect(store.audioReverbType.value, entry.key);
      await tester.pump();
    }
    await tester.pumpWidget(view(false));
    expect(store.audioChangerType.isObserved, isFalse);
    final previousCalls = store.calls.length;
    for (final item in items().values) {
      item.onPressed!();
    }
    expect(store.calls.length, previousCalls);
    await tester.pumpWidget(const SizedBox());
    expect(store.audioReverbType.isObserved, isFalse);
    expect(tester.takeException(), isNull);
  });
}
