import 'package:tencent_live_uikit/src/common/platform/live_network_type_channel.dart';
import 'package:tencent_live_uikit/src/common/platform/live_thermal_state_channel.dart';
import 'package:tencent_live_uikit/src/pusher/living/live_header_view.dart';
import 'package:tencent_live_uikit/src/pusher/summary/pusher_summary_view.dart';
import 'support/listener_probe.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/common/theme/live_slider.dart';
import 'package:tencent_live_uikit/src/pusher/living/status/pusher_live_status_view.dart';
import 'package:tencent_live_uikit/src/pusher/settings/pusher_settings_action_handling.dart';

class Summary implements LiveSummaryStore, LiveSummaryState {
  @override
  final ValueProbe<LiveSummaryData> summaryData = ValueProbe(
      LiveSummaryData(totalGiftCoins: 51, totalGiftUniqueSenders: 3, totalGiftsSent: 7, totalMessageSent: 11));
  @override
  LiveSummaryState get liveSummaryState => this;
}

void main() {
  _testPusherLocalReduction();
  testWidgets('large statistics only shrink the value and keep units readable', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    for (final width in [320.0, 390.0, 430.0]) {
      await tester.pumpWidget(MaterialApp(
          home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: width,
                  height: 515,
                  child: const PusherLiveStatisticsView(values: [123456789012, 3, 7, 8, 13, 11])))));
      final value = find.text('123456789012');
      final unit = find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.unit.points'));
      expect(tester.widget<Text>(unit).style!.fontSize, 10);
      expect(tester.widget<Text>(value).style!.fontSize, inInclusiveRange(12, 24));
      expect(find.ancestor(of: unit, matching: find.byType(FittedBox)), findsNothing);
      final valueSlot = tester.getRect(find.ancestor(of: value, matching: find.byType(Positioned)).first);
      final unitSlot = tester.getRect(find.ancestor(of: unit, matching: find.byType(Positioned)).first);
      expect(unitSlot.left - valueSlot.right, 5);
      expect(unitSlot.top - valueSlot.top, 12);
      expect(tester.takeException(), isNull);
    }
  });

  test('device errors precede off state; low bitrate alone is not a stream error', () {
    final state = PusherDeviceStatusState(cameraError: DeviceError.noSystemPermission);
    expect(state.videoStatus, MediaStatus.deviceError);
    state.cameraError = DeviceError.noError;
    expect(state.videoStatus, MediaStatus.off);
    state.cameraStatus = DeviceStatus.on;
    state.hasAVStatistics = true;
    state.frameRate = 30;
    state.videoBitrate = 1;
    expect(state.videoStatus, MediaStatus.normal);
    state.videoBitrate = 1000;
    expect(state.videoStatus, MediaStatus.normal);
    state.frameRate = 14;
    expect(state.videoStatus, MediaStatus.streamError);
    state.frameRate = 30;
    state.networkQuality = NetworkQuality.down.value;
    expect(state.videoStatus, MediaStatus.streamError);
    expect(state.copy().isSameAs(state), isTrue);
  });
  testWidgets('status reads official counts and unsubscribes when removed', (tester) async {
    final sdk = Summary();
    await tester.pumpWidget(MaterialApp(
        home: PusherLiveStatusView(
            liveID: 'r',
            summaryStore: sdk,
            elapsedSeconds: 65,
            viewerCount: 8,
            likeCount: 13,
            settings: PusherSettingsState(),
            deviceStatus: PusherDeviceStatusState(),
            onDismiss: () {})));
    await tester.pumpAndSettle();
    for (final value in ['51', '3', '7', '11', '8', '13']) {
      expect(find.text(value), findsOneWidget);
    }
    sdk.summaryData.value = LiveSummaryData(totalMessageSent: 24);
    await tester.pump();
    expect(find.text('24'), findsOneWidget);
    expect(sdk.summaryData.isObserved, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(sdk.summaryData.isObserved, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('time, metrics and device update their consumers independently', (tester) async {
    final sdk = Summary();
    final settings = PusherSettingsState();
    final device = PusherDeviceStatusState(cameraStatus: DeviceStatus.on, microphoneStatus: DeviceStatus.on);
    var seconds = 0;
    var viewers = 8;
    var likes = 13;
    var captured = 0;
    void Function(int)? onVolume = (value) => captured = value;
    Widget view() => MaterialApp(
        home: PusherLiveStatusView(
            liveID: 'r',
            summaryStore: sdk,
            elapsedSeconds: seconds,
            viewerCount: viewers,
            likeCount: likes,
            settings: settings,
            deviceStatus: device,
            onSetCaptureVolume: onVolume,
            onDismiss: () {}));
    Finder consumer(String name) => find.byWidgetPredicate((widget) => widget.runtimeType.toString() == name);
    Widget metrics() => tester.widget(consumer('PusherLiveStatisticsView'));
    Widget deviceView() => tester.widget(consumer('PusherDeviceStatusView'));
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    final initialMetrics = metrics();
    for (seconds = 1; seconds <= 120; seconds++) {
      await tester.pumpWidget(view());
      expect(metrics(), same(initialMetrics));
      expect(find.text(PusherLiveStatusView.formatDuration(seconds)), findsOneWidget);
    }
    seconds = 120;
    // 同一个设备/设置实例原位变化，先更新另一标签的输入。
    device.delay = 37;
    settings.captureVolume = 42;
    await tester.pumpWidget(view());
    expect(metrics(), same(initialMetrics));
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.device')));
    await tester.pump();
    expect(find.text('37ms'), findsOneWidget);
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider)).value, 42);
    final initialDevice = deviceView();
    for (var index = 1; index <= 120; index++) {
      seconds++;
      settings.smoothLevel = index / 120;
      settings.whitenessLevel = index / 120;
      settings.ruddyLevel = index / 120;
      settings.isMirrorEnabled = !settings.isMirrorEnabled;
      await tester.pumpWidget(view());
      expect(deviceView(), same(initialDevice));
    }
    sdk.summaryData.value = LiveSummaryData(totalMessageSent: 29);
    await tester.pump();
    expect(deviceView(), same(initialDevice));
    viewers = 9;
    likes = 14;
    onVolume = (value) => captured = value * 2;
    await tester.pumpWidget(view());
    expect(deviceView(), same(initialDevice));
    tester.widget<LiveSlider>(find.byType(LiveSlider)).onChanged!(23);
    expect(captured, 46, reason: 'cached callbacks use the latest Widget');
    settings.captureVolume = 17;
    await tester.pumpWidget(view());
    expect(deviceView(), isNot(same(initialDevice)));
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider)).value, 17);
    var previousDevice = deviceView();
    settings.isMuted = true;
    await tester.pumpWidget(view());
    expect(deviceView(), isNot(same(previousDevice)));
    expect(find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.audio.off.title')), findsOneWidget);
    expect(find.text('--'), findsWidgets);
    device.hasAVStatistics = true;
    device.videoWidth = 720;
    await tester.pumpWidget(view());
    expect(find.text('720P'), findsOneWidget);
    previousDevice = deviceView();
    device.delay = 55;
    await tester.pumpWidget(view());
    expect(deviceView(), isNot(same(previousDevice)));
    expect(find.text('55ms'), findsOneWidget);
    onVolume = null;
    await tester.pumpWidget(view());
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider)).onChanged, isNull);
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.realtime')));
    await tester.pump();
    for (final text in ['29', '9', '14']) {
      expect(find.text(text), findsOneWidget);
    }
    final updatedMetrics = metrics();
    sdk.summaryData.value = LiveSummaryData(totalMessageSent: 29, totalLikesReceived: 1000);
    await tester.pump();
    expect(metrics(), same(updatedMetrics), reason: 'official likes are not a consumer of this metrics panel');
    await tester.pumpWidget(const SizedBox());
    expect(sdk.summaryData.isObserved, isFalse);
    seconds = 999;
    settings.captureVolume = 61;
    device.delay = 77;
    sdk.summaryData.value = LiveSummaryData(totalMessageSent: 31);
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(sdk.summaryData.isObserved, isTrue);
    expect(find.text('00:16:39'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.device')));
    await tester.pump();
    expect(find.text('77ms'), findsOneWidget);
    expect(tester.widget<LiveSlider>(find.byType(LiveSlider)).value, 61);
    expect(tester.takeException(), isNull);
  });
  testWidgets('English device rows wrap and stay scrollable on small screens', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    for (final size in [const Size(320, 568), const Size(390, 844), const Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  size: size,
                  padding: const EdgeInsets.only(top: 24, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                  textScaler: const TextScaler.linear(1.3)),
              child: PusherLiveStatusView(
                  liveID: 'r',
                  summaryStore: Summary(),
                  elapsedSeconds: 65,
                  viewerCount: 0,
                  likeCount: 0,
                  settings: PusherSettingsState(),
                  deviceStatus: PusherDeviceStatusState(
                      cameraStatus: DeviceStatus.on,
                      cameraError: DeviceError.noSystemPermission,
                      networkQuality: NetworkQuality.down.value),
                  onDismiss: () {}))));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LiveKitResources.localizedString('tuilivekit.pusher.status.device')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
  });
}

String text(String key) => LiveKitResources.localizedString('tuilivekit.pusher.status.$key');

void _testPusherLocalReduction() {
  test('duration consumers retain boundaries and distinct negative handling', () {
    const cases = {
      0: '00:00:00',
      59: '00:00:59',
      60: '00:01:00',
      3599: '00:59:59',
      3600: '01:00:00',
      360000: '100:00:00'
    };
    for (final entry in cases.entries) {
      expect(LiveHeaderView.formatDuration(entry.key), entry.value);
      expect(PusherLiveStatusView.formatDuration(entry.key), entry.value);
    }
    expect(LiveHeaderView.formatDuration(-1), '00:59:59');
    expect(PusherLiveStatusView.formatDuration(-1), '00:59:59');
  });

  testWidgets('Summary retains zero clamping and long duration rendering', (tester) async {
    for (final (seconds, value) in [
      (-1, '00:00:00'),
      (59, '00:00:59'),
      (60, '00:01:00'),
      (3600, '01:00:00'),
      (360000, '100:00:00')
    ]) {
      await tester.pumpWidget(MaterialApp(
          home: PusherSummaryView(
        liveID: 'test',
        summaryContext: PusherSummaryContext(startTime: null, endTime: DateTime(2026), pausedSeconds: 0),
        finalSummary: PusherSummary(liveDuration: seconds),
      )));
      await tester.pumpAndSettle();
      expect(find.text(value), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('device descriptions preserve media, thermal and network presentation', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    const normal = Color(0xFF4A9EFF);
    const warning = Color(0xFFFF8A3D);
    const critical = Color(0xFFFF5C61);
    const unknown = Color(0xFF8A94A8);
    Future<void> show(PusherDeviceStatusState status, {bool muted = false, int volume = 100}) async {
      await tester.pumpWidget(MaterialApp(
          home: SingleChildScrollView(
              child: PusherDeviceStatusView(
        isMuted: muted,
        captureVolume: volume,
        status: status,
      ))));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    Color? iconColor(String asset) => tester
        .widget<Image>(
            find.byWidgetPredicate((widget) => widget is Image && widget.image == LiveKitResources.image(asset)))
        .color;
    for (final (device, error, abnormal, title, detail, color) in [
      (DeviceStatus.on, DeviceError.noError, false, 'normal', 'normal', normal),
      (DeviceStatus.off, DeviceError.noError, false, 'off', 'off', warning),
      (DeviceStatus.on, DeviceError.noSystemPermission, false, 'error', 'device_error', warning),
      (DeviceStatus.on, DeviceError.noError, true, 'error', 'stream_error', critical),
    ]) {
      await show(PusherDeviceStatusState(
          cameraStatus: device,
          microphoneStatus: device,
          cameraError: error,
          microphoneError: error,
          hasAVStatistics: true,
          frameRate: abnormal ? 0 : 30,
          audioSampleRate: 48000,
          audioBitrate: abnormal ? 0 : 64));
      for (final kind in ['video', 'audio']) {
        expect(find.text(text('$kind.$title.title')), findsOneWidget);
        expect(find.text(text('$kind.$detail.detail')), findsOneWidget);
        expect(iconColor('livekit_status_$kind'), color);
      }
    }
    for (final (state, color) in [
      (LiveThermalState.normal, normal),
      (LiveThermalState.fair, warning),
      (LiveThermalState.serious, critical)
    ]) {
      await show(PusherDeviceStatusState(temperatureStatus: state));
      expect(find.text(text('temperature.${state.name}.title')), findsOneWidget);
      expect(find.text(text('temperature.${state.name}.detail')), findsOneWidget);
      expect(iconColor('livekit_status_temperature'), color);
    }
    for (final kind in LiveNetworkType.values) {
      for (final (quality, name, detail, color, icon) in [
        (1, 'excellent', 'keep', normal, 'livekit_status_network'),
        (2, 'good', 'keep', normal, 'livekit_status_network'),
        (3, 'poor', 'fluctuating', warning, 'livekit_status_network_poor'),
        (4, 'bad', 'switch', critical, 'livekit_status_network_bad'),
        (5, 'very_bad', 'switch', critical, 'livekit_status_network_bad'),
        (6, 'disconnected', 'disconnected_detail', critical, 'livekit_status_network_down'),
        (0, 'checking', 'checking_detail', unknown, 'livekit_status_network'),
        (99, 'checking', 'checking_detail', unknown, 'livekit_status_network'),
      ]) {
        await show(PusherDeviceStatusState(networkKind: kind, networkQuality: quality));
        expect(
            find.text(text('network.title')
                .replaceFirst('%@', text('network.${kind.name}'))
                .replaceFirst('%@', text('network.$name'))),
            findsOneWidget);
        expect(find.text(text('network.$detail')), findsOneWidget);
        expect(iconColor(icon), quality >= 3 && quality <= 6 ? isNull : color);
      }
    }
    final activeMicrophone = PusherDeviceStatusState(microphoneStatus: DeviceStatus.on);
    await show(activeMicrophone, muted: true);
    expect(find.text(text('audio.off.title')), findsOneWidget);
    await show(activeMicrophone, volume: 0);
    expect(find.text(text('audio.off.title')), findsOneWidget);
  });
}
