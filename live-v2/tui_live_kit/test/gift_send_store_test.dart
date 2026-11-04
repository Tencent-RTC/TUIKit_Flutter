import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/display/gift_display_view.dart';
import 'package:tencent_live_uikit/src/common/gift/send/gift_send_store.dart';

class _GiftList extends ValueNotifier<List<GiftCategory>> {
  _GiftList() : super([]);

  bool get isObserved => hasListeners;
}

class _GiftSDK implements GiftStore, GiftState {
  final listeners = <GiftListener>[];
  final sends = <Completer<CompletionHandler>>[];
  final counts = <int>[];
  Completer<CompletionHandler>? refresh;

  @override
  final _GiftList usableGifts = _GiftList();

  @override
  GiftState get giftState => this;

  @override
  void addGiftListener(GiftListener listener) => listeners.add(listener);

  @override
  void removeGiftListener(GiftListener listener) => listeners.remove(listener);

  @override
  void setLanguage(String language) {}

  @override
  Future<CompletionHandler> refreshUsableGifts() =>
      refresh?.future ?? Future.value(CompletionHandler());

  @override
  Future<CompletionHandler> sendGift({
    required String giftID,
    required int count,
    String receiver = '',
  }) {
    final result = Completer<CompletionHandler>();
    sends.add(result);
    counts.add(count);
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'catalog transport error finishes loading and retains the SDK subscription',
      (tester) async {
    final sdk = _GiftSDK()..refresh = Completer<CompletionHandler>();
    final store = GiftSendStore(giftStoreFactory: (_) => sdk)..activate('room');
    expect(store.state.isLoading, isTrue);
    sdk.refresh!.completeError(StateError('catalog unavailable'));
    await tester.pump();
    expect(store.state.isLoading, isFalse);
    expect(store.state.liveID, 'room');
    expect(tester.takeException(), isNull);
    sdk.usableGifts.value = [
      GiftCategory(giftList: [Gift(giftID: 'cached')])
    ];
    expect(store.state.categories.single.giftList.single.giftID, 'cached');
    store.dispose();
    sdk.usableGifts.dispose();
  });

  testWidgets('old catalog failure cannot finish a new room loading',
      (tester) async {
    final firstSDK = _GiftSDK()..refresh = Completer<CompletionHandler>();
    final secondSDK = _GiftSDK()..refresh = Completer<CompletionHandler>();
    final store = GiftSendStore(
        giftStoreFactory: (room) => room == 'first' ? firstSDK : secondSDK);
    store.activate('first');
    store.activate('second');
    firstSDK.refresh!.completeError(StateError('old catalog unavailable'));
    await tester.pump();
    expect(store.state.liveID, 'second');
    expect(store.state.isLoading, isTrue);
    secondSDK.refresh!.complete(CompletionHandler()..errorCode = -1);
    await tester.pump();
    expect(store.state.isLoading, isFalse);
    expect(tester.takeException(), isNull);
    store.dispose();
    firstSDK.usableGifts.dispose();
    secondSDK.usableGifts.dispose();
  });

  test('concurrent send results retain their own completion in reversed order',
      () async {
    final sdk = _GiftSDK();
    final store = GiftSendStore(giftStoreFactory: (_) => sdk)..activate('room');
    final results = <String>[];
    final first = store.sendGift(
        id: 'g', count: 0, completion: (value) => results.add('first:$value'));
    final second = store.sendGift(
        id: 'g', count: 3, completion: (value) => results.add('second:$value'));
    expect(sdk.counts, [1, 3]);
    sdk.sends[1].complete(CompletionHandler());
    await second;
    sdk.sends[0].complete(CompletionHandler()..errorCode = -1);
    await first;
    expect(results, ['second:true', 'first:false']);
    store.dispose();
    expect(sdk.listeners, isEmpty);
    expect(sdk.usableGifts.isObserved, isFalse);
    sdk.usableGifts.dispose();
  });

  test('old room results never reach the next room or a disposed sender',
      () async {
    final firstSDK = _GiftSDK();
    final secondSDK = _GiftSDK();
    final store = GiftSendStore(
        giftStoreFactory: (room) => room == 'first' ? firstSDK : secondSDK);
    final results = <bool>[];
    store.activate('first');
    final oldSend = store.sendGift(id: 'g', completion: results.add);
    store.activate('second');
    final nextSend = store.sendGift(id: 'g', completion: results.add);
    firstSDK.sends.single.complete(CompletionHandler());
    await oldSend;
    expect(results, isEmpty);
    store.dispose();
    secondSDK.sends.single.complete(CompletionHandler());
    await nextSend;
    expect(results, isEmpty);
    expect(firstSDK.listeners, isEmpty);
    expect(secondSDK.listeners, isEmpty);
    firstSDK.usableGifts.dispose();
    secondSDK.usableGifts.dispose();
  });

  test('transport exceptions and inactive sends resolve as failures', () async {
    final sdk = _GiftSDK();
    final store = GiftSendStore(giftStoreFactory: (_) => sdk);
    final results = <bool>[];
    await store.sendGift(id: 'g', completion: results.add);
    store.activate('room');
    final send = store.sendGift(id: 'g', completion: results.add);
    sdk.sends.single.completeError(StateError('transport closed'));
    await send;
    expect(results, [false, false]);
    store.dispose();
    sdk.usableGifts.dispose();
  });

  test(
      'a late completion cannot confirm the same reservation ID in a new overlay',
      () async {
    final sdk = _GiftSDK();
    final store = GiftSendStore(giftStoreFactory: (_) => sdk)
      ..activate('first');
    var overlay = GiftDisplayController(liveID: '');
    const gift = GiftDisplayItem(
      giftID: 'g',
      name: 'Gift',
      iconURL: '',
      resourceURL: '',
      coins: 1,
      count: 1,
      senderID: 'u',
      senderName: 'Sender',
      senderAvatarURL: '',
    );
    final oldReservation = overlay.reserveLocalGift(gift)!;
    final oldSend = store.sendGift(
        id: 'g',
        completion: (success) {
          if (success) overlay.confirmLocalGift(oldReservation);
        });
    overlay.dispose();
    store.activate('second');
    overlay = GiftDisplayController(liveID: '');
    final currentReservation = overlay.reserveLocalGift(gift)!;
    expect(currentReservation, oldReservation);
    sdk.sends.single.complete(CompletionHandler());
    await oldSend;
    expect(overlay.notice.activeEntries, isEmpty);
    overlay.confirmLocalGift(currentReservation);
    expect(overlay.notice.activeEntries.single.count, 1);
    overlay.dispose();
    store.dispose();
    sdk.usableGifts.dispose();
  });
}
