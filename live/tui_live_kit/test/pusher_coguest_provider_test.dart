import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/src/pusher/living/cohost/pusher_cohost_store.dart';
import 'package:tencent_live_uikit/src/pusher/living/cohost/pusher_cohost_candidate_list_view.dart';
import 'package:tencent_live_uikit/src/pusher/living/cohost/pusher_cohost_incoming_invite_view.dart';
import 'package:tencent_live_uikit/src/pusher/living/cohost/pusher_cohost_actions_view.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/theme/live_seat.dart';
import 'package:tencent_live_uikit/src/pusher/video/pusher_video_view.dart';

Finder get emptySeats => find.byWidgetPredicate((widget) => widget is LiveSeat && widget.isEmpty);
Finder get seatOverlays =>
    find.byWidgetPredicate((widget) => widget is LiveSeat && !widget.isEmpty && widget.showsOverlay);
Finder get noVideoSeats =>
    find.byWidgetPredicate((widget) => widget is LiveSeat && !widget.isEmpty && widget.showsNoVideo);

void main() {
  _testSpeakingVolumes();
  testWidgets('connection drawers fit a narrow short viewport and preserve real actions', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = PusherCoHostState();
    const peer = PusherCoHostUser('remote-room', 'remote-user', 'A very long host name that must truncate', '');
    state.connected = [peer];
    state.isConnected = true;
    int invites = 0, ends = 0, accepts = 0;
    Widget host(Widget child) => MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 480),
                disableAnimations: true,
                padding: EdgeInsets.only(bottom: 34),
                viewPadding: EdgeInsets.only(bottom: 34)),
            child: SizedBox.expand(child: child)));
    await tester.pumpWidget(host(PusherCoHostActionsView(
        state: state,
        onInviteMore: () {
          invites++;
        },
        onEnd: () {
          ends++;
        },
        onDismiss: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find more hosts'));
    await tester.tap(find.text('End connection'));
    expect(invites, 1);
    expect(ends, 1);
    expect(tester.takeException(), isNull);
    state.applicant = peer;
    state.applicantDeadline = DateTime.now().add(const Duration(seconds: 10));
    await tester.pumpWidget(host(PusherCoHostIncomingInviteView(
        state: state,
        onAccept: () {
          accepts++;
        },
        onReject: () {},
        onDismiss: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    expect(accepts, 1);
    expect(tester.takeException(), isNull);
    state.candidates = [peer];
    state.isConnected = false;
    state.applicant = null;
    state.hasMore = false;
    await tester.pumpWidget(host(PusherCoHostCandidateListView(
        state: state,
        hostAvatarURL: '',
        isAdding: false,
        onInvite: (_) {},
        onCancel: (_) {},
        onRefresh: () async {},
        onLoadMore: () {},
        onBack: () {},
        onDismiss: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Random connection'), findsOneWidget);
    expect(find.text('Recommended hosts'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cross-room hosts with equal indexes keep independent camera projections', (tester) async {
    final state = ValueNotifier(const PusherCoGuestVideoState(
        isLiving: true,
        showsEmptySeats: false,
        connectedGuestCount: 0,
        isCoHostConnected: true,
        showsHostOverlay: true,
        localCameraStatus: DeviceStatus.off));
    final adapter = PusherUnitAdapter(state, localUserID: () => 'host');
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                    width: 200,
                    height: 100,
                    child: Row(children: [
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: adapter.onCreateUnitView(UnitInfo(index: 0, liveID: 'room-a', userID: 'host'))),
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: adapter.onCreateUnitView(UnitInfo(index: 0, liveID: 'room-b', userID: 'remote'))),
                    ]))))));
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsNWidgets(2));
    expect(seatOverlays, findsNWidgets(2));
    adapter.onUpdateUnitView(
        UnitInfo(index: 0, liveID: 'room-b', userID: 'remote', cameraStatus: DeviceStatus.on), null);
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsOneWidget);
    expect(adapter.gridRegions, hasLength(2));
    expect(adapter.guestUserIDAt(const Offset(150, 50)), isNull,
        reason: 'a remote host must not open the local guest management drawer');
    await tester.pumpWidget(const SizedBox());
    adapter.dispose();
    state.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing SDK seat widgets react without another SDK builder callback', (tester) async {
    final state =
        ValueNotifier(const PusherCoGuestVideoState(isLiving: false, showsEmptySeats: false, connectedGuestCount: 0));
    final provider = PusherUnitAdapter(state, localUserID: () => 'host');
    int builds = 0;
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Builder(builder: (context) {
                    builds++;
                    return Row(children: [
                      SizedBox(width: 100, height: 100, child: provider.onCreateUnitView(UnitInfo(index: 0))),
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: provider.onCreateUnitView(UnitInfo(index: 1, userID: 'guest'))),
                    ]);
                  })),
            ))));
    expect(emptySeats, findsNothing);
    state.value = const PusherCoGuestVideoState(
        isLiving: true, showsEmptySeats: true, connectedGuestCount: 1, usesSmallWindows: true);
    await tester.pumpAndSettle();
    expect(builds, 1);
    expect(provider.regions, containsAll([const Rect.fromLTWH(0, 0, 100, 100), const Rect.fromLTWH(100, 0, 100, 100)]));
    expect(emptySeats, findsOneWidget);
    expect(seatOverlays, findsOneWidget);
    expect(provider.guestUserIDAt(const Offset(150, 50)), 'guest');
    provider.onUpdateUnitView(
        UnitInfo(
            index: 1, userID: 'guest', cameraStatus: DeviceStatus.on, userSuspendStatus: SuspendStatus.inBackground),
        null);
    await tester.pump();
    expect(noVideoSeats, findsOneWidget,
        reason: 'background guests must be covered even if their last camera snapshot is on');
    state.value = const PusherCoGuestVideoState(
        isLiving: true, showsEmptySeats: true, connectedGuestCount: 1, usesSmallWindows: false);
    await tester.pump();
    expect(provider.regions, isEmpty, reason: 'grid seats are not small-window avoidance regions');

    state.value = const PusherCoGuestVideoState(isLiving: false, showsEmptySeats: false, connectedGuestCount: 0);
    await tester.pump();
    expect(seatOverlays, findsNothing);
    expect(provider.guestUserIDAt(const Offset(150, 50)), isNull);
    expect(provider.regions, isEmpty);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    state.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('host projection overrides a stale seat camera and controls the grid overlay', (tester) async {
    final state = ValueNotifier(const PusherCoGuestVideoState(
        isLiving: true, showsEmptySeats: false, connectedGuestCount: 0, localCameraStatus: DeviceStatus.on));
    final provider = PusherUnitAdapter(state, localUserID: () => 'host');
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox.square(
                    dimension: 100,
                    child: provider
                        .onCreateUnitView(UnitInfo(index: 0, userID: 'host', cameraStatus: DeviceStatus.off)))))));
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsNothing);
    expect(seatOverlays, findsNothing);
    state.value = const PusherCoGuestVideoState(
        isLiving: true,
        showsEmptySeats: true,
        connectedGuestCount: 0,
        localCameraStatus: DeviceStatus.off,
        showsHostOverlay: true);
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsOneWidget);
    expect(seatOverlays, findsOneWidget);
    expect(provider.guestUserIDAt(const Offset(50, 50)), isNull);

    // Reuse the SDK unit for a guest, then the host again. The latest local
    // camera projection must survive layout changes and remain host-only.
    state.value =
        state.value.copyWith(connectedGuestCount: 1, usesSmallWindows: true, localCameraStatus: DeviceStatus.on);
    provider.onUpdateUnitView(UnitInfo(index: 0, userID: 'guest', cameraStatus: DeviceStatus.off), null);
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsOneWidget);
    expect(provider.guestUserIDAt(const Offset(50, 50)), 'guest');
    state.value = state.value.copyWith(connectedGuestCount: 0, usesSmallWindows: false, showsHostOverlay: false);
    provider.onUpdateUnitView(UnitInfo(index: 0, userID: 'host', cameraStatus: DeviceStatus.off), null);
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsNothing);
    expect(seatOverlays, findsNothing);
    expect(provider.guestUserIDAt(const Offset(50, 50)), isNull);
    expect(provider.regions, isEmpty);

    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    state.dispose();
    expect(tester.takeException(), isNull);
  });
}

void _testSpeakingVolumes() {
  for (final user in ['host', 'guest']) {
    testWidgets('Pusher $user SDK volume callback reaches the existing seat and returns to zero', (tester) async {
      final state =
          ValueNotifier(const PusherCoGuestVideoState(isLiving: true, showsEmptySeats: true, connectedGuestCount: 1));
      final provider = PusherUnitAdapter(state, localUserID: () => 'host');
      final info = UnitInfo(index: 1, liveID: 'room', userID: user, microphoneStatus: DeviceStatus.on);
      final widget = provider.onCreateUnitView(info);
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
              data: const MediaQueryData(), child: Center(child: SizedBox(width: 130, height: 120, child: widget)))));
      int volume() => tester.widget<LiveSeat>(find.byType(LiveSeat)).volume;
      expect(volume(), 0);
      provider.onVolumeChanged(info, 55, null);
      await tester.pump();
      expect(volume(), 55);
      provider.onVolumeChanged(info, 200, null);
      await tester.pump();
      expect(volume(), 100);
      provider.onVolumeChanged(info, -1, null);
      await tester.pump();
      expect(volume(), 0);
      provider.onVolumeChanged(info, 45, null);
      await tester.pump();
      expect(volume(), 45);
      provider.onVolumeChanged(info, 0, null);
      await tester.pump();
      expect(volume(), 0);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      state.dispose();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Pusher reused and muted seats reject stale user and room volume callbacks', (tester) async {
    final state =
        ValueNotifier(const PusherCoGuestVideoState(isLiving: true, showsEmptySeats: true, connectedGuestCount: 1));
    final provider = PusherUnitAdapter(state, localUserID: () => 'host');
    UnitInfo info(String user, {String room = 'room', bool mic = true}) =>
        UnitInfo(index: 1, liveID: room, userID: user, microphoneStatus: mic ? DeviceStatus.on : DeviceStatus.off);
    final original = info('first');
    final widget = provider.onCreateUnitView(original);
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(), child: Center(child: SizedBox(width: 130, height: 120, child: widget)))));
    int volume() => tester.widget<LiveSeat>(find.byType(LiveSeat)).volume;
    provider.onVolumeChanged(original, 55, null);
    await tester.pump();
    expect(volume(), 55);
    original.userID = 'second';
    provider.onUpdateUnitView(original, null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('first'), 90, null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('second', room: 'old-room'), 90, null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('second'), 40, null);
    await tester.pump();
    expect(volume(), 40);
    provider.onUpdateUnitView(info('second', mic: false), null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('second'), 90, null);
    await tester.pump();
    expect(volume(), 0);
    provider.onUpdateUnitView(info('second'), null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('second'), 40, null);
    await tester.pump();
    expect(volume(), 40);
    state.value = state.value.copyWith(isLiving: false);
    await tester.pump();
    state.value = state.value.copyWith(isLiving: true);
    await tester.pump();
    expect(volume(), 0);
    provider.onUpdateUnitView(info(''), null);
    await tester.pump();
    expect(volume(), 0);
    provider.onVolumeChanged(info('second'), 90, null);
    await tester.pump();
    expect(volume(), 0);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    provider.onVolumeChanged(info('second'), 90, null);
    provider.onUpdateUnitView(info('second'), null);
    state.dispose();
    expect(tester.takeException(), isNull);
  });
}
