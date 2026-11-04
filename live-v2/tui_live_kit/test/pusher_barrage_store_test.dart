import 'dart:async';
import 'support/listener_probe.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_live_uikit/src/common/live_kit_resources.dart';
import 'package:tencent_live_uikit/src/common/barrage/barrage_ui_store.dart';
import 'package:tencent_live_uikit/src/common/gift/gift_barrage_store.dart';

class _Barrage extends ChangeNotifier implements BarrageStore, BarrageState {
  @override
  BarrageState get barrageState => this;
  @override
  final ValueProbe<List<Barrage>> messageList = ValueProbe<List<Barrage>>([]);
  final sends = <Completer<CompletionHandler>>[];
  @override
  Future<CompletionHandler> sendTextMessage(
      {required String text, Map<String, String>? extensionInfo}) {
    final result = Completer<CompletionHandler>();
    sends.add(result);
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
      'deduplicates pending sends and ignores errors from a previous activation',
      () async {
    final sdk = _Barrage();
    final store =
        BarrageUIStore(storeFactory: (_) => sdk, isMessageBanned: () => false);
    final errors = <String>[];
    store.onSendError = errors.add;
    store.activate(liveID: 'room', hostUserID: 'host');
    final first = store.sendComment(' hello ');
    await store.sendComment('hello');
    expect(sdk.sends, hasLength(1));
    store.deactivate();
    store.activate(liveID: 'room', hostUserID: 'host');
    final next = store.sendComment('hello');
    sdk.sends.first.complete(CompletionHandler()
      ..errorCode = 10017
      ..errorMessage = 'raw error');
    await first;
    expect(errors, isEmpty);
    sdk.sends.last.complete(CompletionHandler()
      ..errorCode = 7015
      ..errorMessage = 'raw error');
    await next;
    expect(errors, [
      LiveKitResources.localizedString('tuilivekit.comment.content_rejected')
    ]);
    store.deactivate();
    expect(sdk.messageList.isObserved, isFalse);
  });
  test('muted sender gets localized feedback without sending', () async {
    final sdk = _Barrage();
    final store =
        BarrageUIStore(storeFactory: (_) => sdk, isMessageBanned: () => true);
    final errors = <String>[];
    store.onSendError = errors.add;
    store.activate(liveID: 'room', hostUserID: 'host');
    await store.sendComment('blocked');
    expect(sdk.sends, isEmpty);
    expect(
        errors, [LiveKitResources.localizedString('tuilivekit.comment.muted')]);
    store.deactivate();
  });

  test('a platform failure uses generic feedback and releases the send lock',
      () async {
    final sdk = _Barrage();
    final store =
        BarrageUIStore(storeFactory: (_) => sdk, isMessageBanned: () => false);
    final errors = <String>[];
    store.onSendError = errors.add;
    store.activate(liveID: 'room', hostUserID: 'host');
    final failed = store.sendComment('hello');
    sdk.sends.single.completeError(StateError('native failure'));
    await failed;
    expect(errors, [BarrageUIStore.sendErrorMessage(-1)]);
    final retry = store.sendComment('hello');
    expect(sdk.sends, hasLength(2));
    sdk.sends.last.complete(CompletionHandler());
    await retry;
    expect(errors, hasLength(1));
    store.deactivate();
  });

  test('shared timeline preserves SDK levels and merges each local gift once',
      () {
    final sdk = _Barrage();
    final store = BarrageUIStore(storeFactory: (_) => sdk);
    store.activate(liveID: 'room', hostUserID: 'host');
    sdk.messageList.value = [
      Barrage(
          sender: LiveUserInfo(userID: 'host', level: 0),
          sequence: 1,
          timestampInSecond: 1,
          textContent: 'Host'),
      Barrage(
          sender: LiveUserInfo(userID: 'guest', level: 25),
          sequence: 2,
          timestampInSecond: 2,
          textContent: 'Guest'),
    ];
    final gift = LiveGiftBarrage(
        id: 'settled',
        giftID: 'gift',
        giftName: 'Gift',
        giftIconURL: '',
        count: 2,
        senderID: 'guest',
        senderName: '',
        senderLevel: null);
    store.appendGiftComment(gift);
    store.appendGiftComment(gift);
    expect(store.comments, hasLength(3));
    expect(store.comments.map((comment) => comment.level), [0, 25, null]);
    expect(
        store.comments.map((comment) => comment.isHost), [true, false, false]);
    expect(store.comments.last.gift, same(gift));
    expect(store.comments.last.userName, 'guest');
    expect(sdk.sends, isEmpty);
    store.deactivate();
    expect(store.comments, isEmpty);
    expect(sdk.messageList.isObserved, isFalse);
    store.activate(liveID: 'room', hostUserID: 'host');
    expect(store.comments, hasLength(2));
    store.deactivate();
  });

  test('merged timeline keeps the newest 100 entries across both sources', () {
    final sdk = _Barrage();
    final store = BarrageUIStore(storeFactory: (_) => sdk);
    store.activate(liveID: 'room', hostUserID: 'host');
    sdk.messageList.value = List.generate(
        105,
        (index) => Barrage(
            sequence: index,
            timestampInSecond: index,
            textContent: 'comment $index'));
    store.appendGiftComment(LiveGiftBarrage(
        id: 'latest',
        giftID: 'gift',
        giftName: 'Gift',
        giftIconURL: '',
        count: 1,
        senderID: 'guest',
        senderName: 'Guest',
        senderLevel: 25));
    expect(store.comments, hasLength(100));
    expect(store.comments.first.content, 'comment 6');
    expect(store.comments.last.id, 'gift-latest');
    store.deactivate();
  });

  test(
      'known network errors are classified without treating unknown as network',
      () {
    expect(BarrageUIStore.sendErrorMessage(9508),
        LiveKitResources.localizedString('tuilivekit.comment.network_error'));
    expect(BarrageUIStore.sendErrorMessage(9519),
        LiveKitResources.localizedString('tuilivekit.comment.timeout'));
    expect(
        BarrageUIStore.sendErrorMessage(80001),
        LiveKitResources.localizedString(
            'tuilivekit.comment.content_rejected'));
    expect(BarrageUIStore.sendErrorMessage(123456),
        LiveKitResources.localizedString('tuilivekit.comment.send_failed'));
  });
}
