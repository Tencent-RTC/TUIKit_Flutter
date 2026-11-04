import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';

class _GiftSDK implements GiftStore {
  final listeners = <GiftListener>[];
  @override
  void addGiftListener(GiftListener listener) => listeners.add(listener);
  @override
  void removeGiftListener(GiftListener listener) => listeners.remove(listener);
  @override
  void setLanguage(String language) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'Gift combo settles after quiet window and cancels on pause/background/dispose',
      (tester) async {
    final sdk = _GiftSDK();
    final store = GiftBarrageStore(liveID: 'r', giftStore: sdk);
    final comments = <LiveGiftBarrage>[];
    store.onGiftBarrageSettled = comments.add;
    store.activate();
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    final gift = Gift(giftID: 'g', name: 'Rose', coins: 5);
    final user = LiveUserInfo(userID: 'u', userName: 'U', level: 25);
    void receive(int count) =>
        sdk.listeners.single.onReceiveGift!('r', gift, count, user);
    receive(1);
    await tester.pump(const Duration(seconds: 1));
    receive(2);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(comments, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(comments.single.count, 3);
    expect(comments.single.senderLevel, 25);
    receive(1);
    store.setEnabled(false);
    await tester.pump(const Duration(seconds: 3));
    expect(comments.length, 1);
    store.setEnabled(true);
    receive(1);
    store.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(comments.length, 1);
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    receive(1);
    final oldListener = sdk.listeners.single;
    store.dispose();
    oldListener.onReceiveGift!('r', gift, 9, user);
    await tester.pump(const Duration(seconds: 3));
    expect(comments.length, 1);
    expect(sdk.listeners, isEmpty);
  });
  testWidgets(
      'all background states gate initial comment collection and cancel pending comments',
      (tester) async {
    for (final lifecycle in [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      final sdk = _GiftSDK();
      final store = GiftBarrageStore(liveID: 'room', giftStore: sdk)
        ..activate();
      final counts = <int>[];
      store.onGiftBarrageSettled = (comment) => counts.add(comment.count);
      // Exercise the callback registered by the current SDK adapter.
      // ignore: deprecated_member_use
      void receive() => sdk.listeners.single.onReceiveGift!(
          'room', Gift(giftID: 'g'), 1, LiveUserInfo(userID: 'u'));
      expect(sdk.listeners, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      expect(counts, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      receive();
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pump(const Duration(seconds: 2));
      expect(counts, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      receive();
      await tester.pump(const Duration(seconds: 2));
      expect(counts, [1]);
      store.dispose();
    }
  });
}
