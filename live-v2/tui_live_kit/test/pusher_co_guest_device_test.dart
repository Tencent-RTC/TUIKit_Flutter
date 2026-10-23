import 'dart:async';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/pusher/living/coguest/pusher_coguest_store.dart';

class TrackedValue<T> extends ValueNotifier<T> {
  TrackedValue(super.value);
  bool get isObserved => hasListeners;
}

class Seats implements LiveSeatStore {
  @override
  final SeatsState liveSeatState = SeatsState();
  final calls = <String>[];
  Completer<CompletionHandler>? pending;
  Future<CompletionHandler> record(String call) {
    calls.add(call);
    return pending?.future ?? Future.value(CompletionHandler());
  }

  @override
  Future<CompletionHandler> closeRemoteCamera(String userID) => record('closeCamera');
  @override
  Future<CompletionHandler> closeRemoteMicrophone(String userID) => record('closeMicrophone');
  @override
  Future<CompletionHandler> openRemoteCamera({required String userID, required DeviceControlPolicy policy}) {
    expect(policy, DeviceControlPolicy.unlockOnly);
    return record('unlockCamera');
  }

  @override
  Future<CompletionHandler> openRemoteMicrophone({required String userID, required DeviceControlPolicy policy}) {
    expect(policy, DeviceControlPolicy.unlockOnly);
    return record('unlockMicrophone');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SeatsState implements LiveSeatState {
  @override
  final TrackedValue<List<SeatInfo>> seatList = TrackedValue<List<SeatInfo>>([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Guests implements CoGuestStore {
  @override
  final GuestsState coGuestState = GuestsState();
  final layouts = <int>[];
  @override
  Future<CompletionHandler> setLayoutTemplate({required CoGuestLayoutTemplate template}) async {
    layouts.add(template.templateId);
    return CompletionHandler();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GuestsState implements CoGuestState {
  @override
  final TrackedValue<List<SeatUserInfo>> connected = TrackedValue<List<SeatUserInfo>>([]);
  @override
  final TrackedValue<List<LiveUserInfo>> applicants = TrackedValue<List<LiveUserInfo>>([]);
  @override
  final TrackedValue<List<LiveUserInfo>> invitees = TrackedValue<List<LiveUserInfo>>([]);
  @override
  final TrackedValue<List<LiveUserInfo>> candidates = TrackedValue<List<LiveUserInfo>>([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('all five state subscriptions detach on deactivation and disposal without disposal notification', () {
    final guests = Guests();
    final seats = Seats();
    final signals = [
      guests.coGuestState.connected,
      guests.coGuestState.applicants,
      guests.coGuestState.invitees,
      guests.coGuestState.candidates,
      seats.liveSeatState.seatList
    ];
    final store = PusherCoGuestStore(
      liveID: 'room',
      localUserID: () => 'host',
      seatStore: seats,
      coGuestStore: guests,
    );
    var notifications = 0;
    store.addListener(() => notifications++);
    store.activate();
    expect(signals.every((signal) => signal.isObserved), isTrue);
    expect(notifications, 1);
    guests.coGuestState.connected.value = [SeatUserInfo(userID: 'guest')];
    expect(store.state.connected.single.userID, 'guest');
    store.deactivate();
    expect(signals.every((signal) => !signal.isObserved), isTrue);
    expect(store.state.connected, isEmpty);
    final afterDeactivation = notifications;
    guests.coGuestState.connected.value = [SeatUserInfo(userID: 'next')];
    expect(notifications, afterDeactivation);
    store.activate();
    expect(store.state.connected.single.userID, 'next');
    expect(signals.every((signal) => signal.isObserved), isTrue);
    final beforeSignal = notifications;
    guests.coGuestState.candidates.value = [LiveUserInfo(userID: 'candidate')];
    expect(notifications, beforeSignal + 1);
    store.dispose();
    expect(signals.every((signal) => !signal.isObserved), isTrue);
    expect(notifications, beforeSignal + 1);
    guests.coGuestState.connected.value = [];
    expect(notifications, beforeSignal + 1);
  });

  test('layout connection is latched until the live session deactivates', () async {
    final guests = Guests();
    final store =
        PusherCoGuestStore(liveID: 'room', localUserID: () => 'host', seatStore: Seats(), coGuestStore: guests);
    store.didConnect();
    expect(guests.layouts, isEmpty);
    store.activate();
    store.selectLayout(CoGuestLayoutTemplate.columnLayout);
    expect(guests.layouts, isEmpty);
    expect(store.state.layout, CoGuestLayoutTemplate.dynamicLayout);
    store.didConnect();
    await Future<void>.delayed(Duration.zero);
    expect(guests.layouts, [801]);
    expect(store.state.layout, CoGuestLayoutTemplate.columnLayout);
    // Once this session has connected, a current transport status is not used
    // to queue later user actions forever while the transport reconnects.
    store.selectLayout(CoGuestLayoutTemplate.gridLayout);
    await Future<void>.delayed(Duration.zero);
    expect(guests.layouts, [801, 800]);
    expect(store.state.layout, CoGuestLayoutTemplate.gridLayout);
    store.deactivate();
    store.activate();
    store.selectLayout(CoGuestLayoutTemplate.floatLayout);
    expect(guests.layouts, [801, 800]);
    store.didConnect();
    await Future<void>.delayed(Duration.zero);
    expect(guests.layouts, [801, 800, 601]);
    store.dispose();
  });

  for (final allowed in [false, true]) {
    for (final on in [false, true]) {
      test('host actual seat branch allow=$allowed on=$on', () async {
        final seats = Seats();
        final guests = Guests();
        // CoGuest snapshot intentionally stale: seatList is authoritative.
        guests.coGuestState.connected.value = [SeatUserInfo(userID: 'guest')];
        seats.liveSeatState.seatList.value = [
          SeatInfo(
              userInfo: SeatUserInfo(
                  userID: 'guest',
                  allowOpenMicrophone: allowed,
                  allowOpenCamera: allowed,
                  microphoneStatus: on ? DeviceStatus.on : DeviceStatus.off,
                  cameraStatus: on ? DeviceStatus.on : DeviceStatus.off))
        ];
        final store =
            PusherCoGuestStore(liveID: 'room', localUserID: () => 'host', seatStore: seats, coGuestStore: guests);
        final toasts = <String>[];
        store.onToast = toasts.add;
        store.activate();
        await store.toggleRemoteMicrophone('guest');
        expect(toasts.length, 1);
        if (!allowed || on) expect(toasts.single, contains('guest'));
        expect(seats.calls, allowed && !on ? <String>[] : ['${allowed ? "close" : "unlock"}Microphone']);
        expect(store.state.pendingUserIDs, isEmpty);
        store.dispose();
      });
    }
  }
  test('missing seat, pending and deactivated operations are ignored', () async {
    final seats = Seats();
    final guests = Guests();
    guests.coGuestState.connected.value = [SeatUserInfo(userID: 'guest')];
    final store = PusherCoGuestStore(liveID: 'room', localUserID: () => 'host', seatStore: seats, coGuestStore: guests);
    final toasts = <String>[];
    store.onToast = toasts.add;
    store.activate();
    await store.toggleRemoteMicrophone('guest');
    expect(seats.calls, isEmpty);
    seats.liveSeatState.seatList.value = [
      SeatInfo(userInfo: SeatUserInfo(userID: 'guest', allowOpenMicrophone: false))
    ];
    seats.pending = Completer<CompletionHandler>();
    final operation = store.toggleRemoteMicrophone('guest');
    await store.toggleRemoteMicrophone('guest');
    expect(seats.calls.length, 1);
    store.deactivate();
    seats.pending!.complete(CompletionHandler());
    await operation;
    await store.toggleRemoteMicrophone('guest');
    expect(seats.calls.length, 1);
    expect(store.state.pendingUserIDs, isEmpty);
    expect(toasts, isEmpty);
    store.dispose();
  });
  for (final name in <String, String>{
    '小明': '小明',
    '12345678': '12345678',
    '123456789': '12345678…',
    '1234567👨‍👩‍👧‍👦9': '1234567👨‍👩‍👧‍👦…',
    '1234567e\u03019': '1234567e\u0301…',
    '  小明\n 同学  ': '小明 同学',
    '   ': 'guest',
  }.entries) {
    for (final locked in [false, true]) {
      test('microphone toast name ${name.key}, locked=$locked', () async {
        final seats = Seats();
        final guests = Guests();
        final user = SeatUserInfo(
            userID: 'guest', userName: name.key, allowOpenMicrophone: !locked, microphoneStatus: DeviceStatus.on);
        guests.coGuestState.connected.value = [user];
        seats.liveSeatState.seatList.value = [SeatInfo(userInfo: user)];
        final store =
            PusherCoGuestStore(liveID: 'room', localUserID: () => 'host', seatStore: seats, coGuestStore: guests);
        final toasts = <String>[];
        store.onToast = toasts.add;
        store.activate();
        seats.pending = Completer<CompletionHandler>();
        final operation = store.toggleRemoteMicrophone('guest');
        expect(toasts, isEmpty);
        seats.pending!.complete(CompletionHandler());
        await operation;
        expect(toasts, [
          LiveKitResources.localizedFormat(
              locked ? 'tuilivekit.pusher.coguest.microphone_unlocked' : 'tuilivekit.pusher.coguest.microphone_closed',
              name.value)
        ]);
        store.dispose();
      });
    }
  }
}
