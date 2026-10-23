import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_effect_player/ftceffect_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_kit_access/effect_license.dart';
import 'package:live_kit_access/generate_test_user_sig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.flutter_effect_player.FTCMediaXBaseApi.setLicense',
    FTCMediaXBaseApi.pigeonChannelCodec,
  );
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final logs = <String>[];
  late DebugPrintCallback originalDebugPrint;
  FTCMediaLicenseListener? originalLicenseListener;

  const beauty = MethodChannel('tui_live_kit/advanced_beauty');
  setUp(() {
    messenger.setMockMethodCallHandler(beauty, (_) async => 0);
    logs.clear();
    originalDebugPrint = debugPrint;
    originalLicenseListener = FTCMediaXBase.instance.curLicenseListener;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(beauty, null);
    messenger.setMockDecodedMessageHandler<Object?>(channel, null);
    FTCMediaXBase.instance.curLicenseListener = originalLicenseListener;
    debugPrint = originalDebugPrint;
  });

  test('beauty authorization finishes before gift authorization and repeated submissions are coalesced', () async {
    final beautyReply = Completer<int>();
    var giftCalls = 0;
    var beautyCalls = 0;
    messenger.setMockMethodCallHandler(beauty, (_) {
      beautyCalls++;
      return beautyReply.future;
    });
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
      giftCalls++;
      return <Object?>[null];
    });
    final first = initializeEffectLicense();
    final second = initializeEffectLicense();
    await Future<void>.delayed(Duration.zero);
    expect(beautyCalls, 1);
    expect(giftCalls, 0);
    beautyReply.complete(0);
    await Future.wait([first, second]);
    expect(giftCalls, 1);
  });

  test('submits the configured license through the plugin channel', () async {
    var submissions = 0;
    var submittedConfiguredValues = false;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (message) async {
      submissions += 1;
      final arguments = message as List<Object?>;
      submittedConfiguredValues = arguments.length == 2 &&
          arguments[0] == GenerateTestUserSig.tencentEffectLicenseURL &&
          arguments[1] == GenerateTestUserSig.tencentEffectLicenseKey;
      return <Object?>[null];
    });

    await initializeEffectLicense();

    expect(submissions, 1);
    // Assert a boolean so a failure cannot print either configured credential.
    expect(submittedConfiguredValues, isTrue);
    expect(logs.isEmpty, isTrue);
  });

  test('submission completes before the asynchronous license result', () async {
    final hostReply = Completer<Object?>();
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) => hostReply.future);
    var completed = false;

    final initialization = initializeEffectLicense().then((_) {
      completed = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    hostReply.complete(<Object?>[null]);
    await initialization.timeout(const Duration(seconds: 1));
    expect(completed, isTrue);
    // A submitted request is not a successful authorization result.
    expect(logs.isEmpty, isTrue);

    FTCMediaXBase.instance.onLicenseResult(0, 'private native result');
    expectSafeLogs(logs, const ['[LiveKitAccess][EffectLicense] result=0']);
  });

  test('logs a failed result code without credentials or native details', () async {
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async => <Object?>[null]);

    await initializeEffectLicense();
    FTCMediaXBase.instance.onLicenseResult(-10009, 'private native result: https://license.invalid secret-key');

    expectSafeLogs(logs, const ['[LiveKitAccess][EffectLicense] result=-10009']);
  });

  test('a platform submission error completes safely and can be retried', () async {
    var submissions = 0;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
      submissions += 1;
      return submissions == 1
          ? <Object?>[
              'channel-unavailable',
              'private native error: https://license.invalid secret-key',
              <String, Object?>{'private-details': 'do not log'},
            ]
          : <Object?>[null];
    });

    await initializeEffectLicense().timeout(const Duration(seconds: 1));
    expectSafeLogs(logs, const [
      '[LiveKitAccess][EffectLicense] submit failed: channel-unavailable',
    ]);

    await initializeEffectLicense();
    expect(submissions, 2);
    expectSafeLogs(logs, const [
      '[LiveKitAccess][EffectLicense] submit failed: channel-unavailable',
    ]);
  });

  test('a failed authorization does not prevent a later submission', () async {
    var submissions = 0;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (_) async {
      submissions += 1;
      return <Object?>[null];
    });

    await initializeEffectLicense();
    FTCMediaXBase.instance.onLicenseResult(-10009, 'private native result');
    await initializeEffectLicense();
    expect(submissions, 2);
    expectSafeLogs(logs, const ['[LiveKitAccess][EffectLicense] result=-10009']);

    FTCMediaXBase.instance.onLicenseResult(0, 'private native result');
    expectSafeLogs(logs, const [
      '[LiveKitAccess][EffectLicense] result=-10009',
      '[LiveKitAccess][EffectLicense] result=0',
    ]);
  });
}

void expectSafeLogs(List<String> actual, List<String> expected) {
  // Never include captured messages in assertion output: a logging regression
  // could otherwise disclose credentials while reporting this test's failure.
  expect(listEquals(actual, expected), isTrue,
      reason: 'Only the expected result or submission error code may be logged.');
}
