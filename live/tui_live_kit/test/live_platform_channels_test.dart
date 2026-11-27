import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tencent_live_uikit/src/common/platform/screen_awake_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/platform/live_network_type_channel.dart';
import 'package:tencent_live_uikit/src/common/platform/live_thermal_state_channel.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();

  test(
      'screen awake leases release for background and detach without colliding owners',
      () async {
    const channel = MethodChannel('tui_live_kit/screen_awake');
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final pusher = ScreenAwakeLease();
    final player = ScreenAwakeLease();
    void update(ScreenAwakeLease lease, bool requested, bool attached,
        AppLifecycleState state) {
      lease.update(requested: requested, attached: attached, lifecycle: state);
    }

    update(pusher, false, true, AppLifecycleState.resumed);
    expect(calls, isEmpty);
    update(pusher, true, true, AppLifecycleState.resumed);
    update(pusher, true, true, AppLifecycleState.inactive);
    update(player, true, true, AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls.length, 2);
    final pusherOwner = calls[0].arguments['owner'];
    final playerOwner = calls[1].arguments['owner'];
    expect(pusherOwner, isNot(playerOwner));
    update(pusher, true, true, AppLifecycleState.paused);
    update(player, true, true, AppLifecycleState.hidden);
    update(pusher, true, true, AppLifecycleState.resumed);
    update(pusher, true, false, AppLifecycleState.resumed);
    update(pusher, false, false, AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((call) => call.arguments['enabled']),
        [true, true, false, false, true, false]);
    expect(calls.map((call) => call.arguments['owner']), [
      pusherOwner,
      playerOwner,
      pusherOwner,
      playerOwner,
      pusherOwner,
      pusherOwner
    ]);
  });

  test('screen awake tolerates an unsupported platform bridge', () async {
    const channel = MethodChannel('tui_live_kit/screen_awake');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      throw MissingPluginException();
    });
    addTearDown(() =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    expect(await ScreenAwakeChannel.setEnabled('player', true), isFalse);
  });

  void verifyChannel<T>(String name, Stream<T> Function() stream, T firstValue,
      T fallback, T reconnectedValue) {
    test('$name releases native listener and reconnects with error fallback',
        () async {
      final calls = <String>[];
      final messenger = binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(
          () => messenger.setMockMethodCallHandler(MethodChannel(name), null));
      Future<void> emit(ByteData data) async {
        final completed = Completer<void>();
        messenger.handlePlatformMessage(
            name, data, (_) => completed.complete());
        await completed.future;
      }

      final first = <T>[];
      final second = <T>[];
      final firstSubscription = stream().listen(first.add);
      final secondSubscription = stream().listen(second.add);
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen']);
      await emit(codec.encodeSuccessEnvelope(1));
      expect(first, [firstValue]);
      expect(second, [firstValue]);
      await firstSubscription.cancel();
      expect(calls, ['listen']);
      await emit(codec.encodeErrorEnvelope(code: 'unavailable'));
      expect(second, [firstValue, fallback]);
      await secondSubscription.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen', 'cancel']);

      final reconnected = <T>[];
      final subscription = stream().listen(reconnected.add);
      await Future<void>.delayed(Duration.zero);
      await emit(codec.encodeSuccessEnvelope(2));
      expect(calls, ['listen', 'cancel', 'listen']);
      expect(reconnected, [reconnectedValue]);
      await subscription.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['listen', 'cancel', 'listen', 'cancel']);
    });
  }

  verifyChannel(
      'tui_live_kit/thermal_state',
      () => LiveThermalStateChannel.states,
      LiveThermalState.fair,
      LiveThermalState.normal,
      LiveThermalState.serious);
  verifyChannel('tui_live_kit/network_type', () => LiveNetworkTypeChannel.types,
      LiveNetworkType.wifi, LiveNetworkType.unknown, LiveNetworkType.cellular);
}
