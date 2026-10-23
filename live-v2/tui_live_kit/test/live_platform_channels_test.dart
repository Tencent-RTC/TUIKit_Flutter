import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/platform/live_network_type_channel.dart';
import 'package:tencent_live_uikit/src/common/platform/live_thermal_state_channel.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();

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
