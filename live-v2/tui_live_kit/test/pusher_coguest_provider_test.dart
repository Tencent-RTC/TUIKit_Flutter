import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/theme/live_seat.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/seat/pusher_coguest_seat_view_provider.dart';

Finder get emptySeats =>
    find.byWidgetPredicate((widget) => widget is LiveSeat && widget.isEmpty);
Finder get seatOverlays => find.byWidgetPredicate((widget) =>
    widget is LiveSeat && !widget.isEmpty && widget.showsOverlay);
Finder get noVideoSeats => find.byWidgetPredicate((widget) =>
    widget is LiveSeat && !widget.isEmpty && widget.showsNoVideo);

void main() {
  testWidgets(
      'existing SDK seat widgets react without another SDK builder callback',
      (tester) async {
    final state = ValueNotifier(const PusherCoGuestVideoState(
        isLiving: false, showsEmptySeats: false, connectedGuestCount: 0));
    final provider =
        PusherCoGuestSeatViewProvider(state, localUserID: () => 'host');
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
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: provider.onCreateUnitView(UnitInfo(index: 0))),
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: provider.onCreateUnitView(
                              UnitInfo(index: 1, userID: 'guest'))),
                    ]);
                  })),
            ))));
    expect(emptySeats, findsNothing);
    state.value = const PusherCoGuestVideoState(
        isLiving: true,
        showsEmptySeats: true,
        connectedGuestCount: 1,
        usesSmallWindows: true);
    await tester.pumpAndSettle();
    expect(builds, 1);
    expect(
        provider.regions,
        containsAll([
          const Rect.fromLTWH(0, 0, 100, 100),
          const Rect.fromLTWH(100, 0, 100, 100)
        ]));
    expect(emptySeats, findsOneWidget);
    expect(seatOverlays, findsOneWidget);
    expect(provider.guestUserIDAt(const Offset(150, 50)), 'guest');
    provider.onUpdateUnitView(
        UnitInfo(
            index: 1,
            userID: 'guest',
            cameraStatus: DeviceStatus.on,
            userSuspendStatus: SuspendStatus.inBackground),
        null);
    await tester.pump();
    expect(noVideoSeats, findsOneWidget,
        reason:
            'background guests must be covered even if their last camera snapshot is on');
    state.value = const PusherCoGuestVideoState(
        isLiving: true,
        showsEmptySeats: true,
        connectedGuestCount: 1,
        usesSmallWindows: false);
    await tester.pump();
    expect(provider.regions, isEmpty,
        reason: 'grid seats are not small-window avoidance regions');

    state.value = const PusherCoGuestVideoState(
        isLiving: false, showsEmptySeats: false, connectedGuestCount: 0);
    await tester.pump();
    expect(seatOverlays, findsNothing);
    expect(provider.guestUserIDAt(const Offset(150, 50)), isNull);
    expect(provider.regions, isEmpty);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    state.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'host projection overrides a stale seat camera and controls the grid overlay',
      (tester) async {
    final state = ValueNotifier(const PusherCoGuestVideoState(
        isLiving: true,
        showsEmptySeats: false,
        connectedGuestCount: 0,
        localCameraStatus: DeviceStatus.on));
    final provider =
        PusherCoGuestSeatViewProvider(state, localUserID: () => 'host');
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox.square(
                    dimension: 100,
                    child: provider.onCreateUnitView(UnitInfo(
                        index: 0,
                        userID: 'host',
                        cameraStatus: DeviceStatus.off)))))));
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
    state.value = state.value.copyWith(
        connectedGuestCount: 1,
        usesSmallWindows: true,
        localCameraStatus: DeviceStatus.on);
    provider.onUpdateUnitView(
        UnitInfo(index: 0, userID: 'guest', cameraStatus: DeviceStatus.off), null);
    await tester.pumpAndSettle();
    expect(noVideoSeats, findsOneWidget);
    expect(provider.guestUserIDAt(const Offset(50, 50)), 'guest');
    state.value = state.value.copyWith(
        connectedGuestCount: 0,
        usesSmallWindows: false,
        showsHostOverlay: false);
    provider.onUpdateUnitView(
        UnitInfo(index: 0, userID: 'host', cameraStatus: DeviceStatus.off), null);
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
