import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/beauty/beauty_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory support;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    support = await Directory.systemTemp.createTemp('livekit-beauty-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => support.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await support.delete(recursive: true);
  });

  test('beauty persists disabled levels and isolates app/account choices', () async {
    const first = BeautyPreferences(isEnabled: false, smoothLevel: 7, whitenessLevel: 4, ruddyLevel: 2);
    await first.save('app1-user1');
    await const BeautyPreferences(smoothLevel: 3).save('app1-user2');
    final loaded = await BeautyPreferences.load('app1-user1');
    expect(loaded.isEnabled, isFalse);
    expect([loaded.smoothLevel, loaded.whitenessLevel, loaded.ruddyLevel], [7, 4, 2]);
    expect((await BeautyPreferences.load('app1-user2')).smoothLevel, 3);
    expect((await BeautyPreferences.load('app2-user1')).smoothLevel, 0);
  });

  test('serialized writes retain latest value and validate persisted levels', () async {
    final first = const BeautyPreferences(smoothLevel: 1).save('app-user');
    final latest = const BeautyPreferences(smoothLevel: 5).save('app-user');
    await Future.wait([first, latest]);
    expect((await BeautyPreferences.load('app-user')).smoothLevel, 5);
    await const BeautyPreferences(smoothLevel: -5, whitenessLevel: 80).save('invalid');
    final loaded = await BeautyPreferences.load('invalid');
    expect(loaded.smoothLevel, 0);
    expect(loaded.whitenessLevel, 9);
  });

  testWidgets('a late native close cannot dismiss a reopened beauty panel', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const native = MethodChannel('tui_live_kit/advanced_beauty');
    final requests = <int>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'show') {
        requests.add((call.arguments as Map)['presentation'] as int);
        // A hot restart must not reuse the small IDs held by a surviving native plugin.
        expect(requests.last, greaterThan(0x7fffffff));
        return true;
      }
      return null;
    });
    final panel = BeautyPanelController();
    try {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (value) {
        context = value;
        return const SizedBox();
      }));
      await panel.show(context);
      panel.dismiss();
      await panel.show(context);
      Future<void> close(int id) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          native.name,
          const StandardMethodCodec().encodeMethodCall(MethodCall('dismissed', {'presentation': id})),
          (_) {},
        );
        await tester.pump();
      }

      await close(requests.first);
      expect(panel.isShowing, isTrue);
      await close(requests.last);
      expect(panel.isShowing, isFalse);
    } finally {
      panel.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('disposing during native presentation cancels the late result', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const native = MethodChannel('tui_live_kit/advanced_beauty');
    final result = Completer<bool>();
    final dismissed = <int>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'show') return result.future;
      if (call.method == 'dismiss') dismissed.add((call.arguments as Map)['presentation'] as int);
      return null;
    });
    try {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (value) {
        context = value;
        return const SizedBox();
      }));
      final panel = BeautyPanelController();
      final opening = panel.show(context);
      await tester.pump();
      panel.dispose();
      result.complete(true);
      await opening;
      await tester.pump();
      expect(dismissed, isNotEmpty);
      expect(dismissed.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('opening while the native processor initializes waits for its ready event', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const native = MethodChannel('tui_live_kit/advanced_beauty');
    var ready = false;
    var shows = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'status') return 'pending';
      if (call.method == 'show') {
        shows++;
        return ready;
      }
      return null;
    });
    final panel = BeautyPanelController();
    try {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (value) {
        context = value;
        return const SizedBox();
      }));
      final opening = panel.show(context);
      await tester.pump();
      expect(shows, 1);
      ready = true;
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        native.name,
        const StandardMethodCodec().encodeMethodCall(const MethodCall('processing', {'ready': true})),
        (_) {},
      );
      await tester.pump();
      await opening;
      expect(shows, 2);
      expect(panel.isShowing, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      panel.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(native, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
