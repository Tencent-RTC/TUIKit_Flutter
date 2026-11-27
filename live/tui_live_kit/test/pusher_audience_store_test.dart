import 'support/listener_probe.dart';
import 'dart:async';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_friendship_manager.dart';
import 'package:tencent_live_uikit/src/pusher/living/audience/pusher_audience_store.dart';

class _AudienceState implements LiveAudienceState {
  @override
  final ValueProbe<List<LiveUserInfo>> audienceList =
      ValueProbe<List<LiveUserInfo>>([]);
  @override
  final ValueProbe<int> audienceCount = ValueProbe<int>(0);
  @override
  final ValueProbe<List<LiveUserInfo>> adminList =
      ValueProbe<List<LiveUserInfo>>([]);
  @override
  final ValueProbe<List<LiveUserInfo>> messageBannedUserList =
      ValueProbe<List<LiveUserInfo>>([]);
}

class _AudienceSDK implements LiveAudienceStore {
  @override
  final _AudienceState liveAudienceState = _AudienceState();
  final listeners = <LiveAudienceListener>[];
  final operation = Completer<CompletionHandler>();
  final refresh = Completer<CompletionHandler>();
  int writes = 0;
  int refreshes = 0;
  @override
  void addLiveAudienceListener(LiveAudienceListener listener) =>
      listeners.add(listener);
  @override
  void removeLiveAudienceListener(LiveAudienceListener listener) =>
      listeners.remove(listener);
  @override
  Future<CompletionHandler> disableSendMessage(
      {required String userID, required bool isDisable}) {
    writes++;
    return operation.future;
  }

  @override
  Future<CompletionHandler> fetchAudienceList() {
    refreshes++;
    return refresh.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Friends implements V2TIMFriendshipManager {
  final listeners = <V2TimFriendshipListener>[];
  @override
  Future<void> addFriendListener(
      {required V2TimFriendshipListener listener}) async {
    listeners.add(listener);
  }

  @override
  Future<void> removeFriendListener({V2TimFriendshipListener? listener}) async {
    listeners.remove(listener);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('audience rows and welcomes preserve current SDK levels', () {
    final sdk = _AudienceSDK();
    final store = PusherAudienceStore(
        liveID: 'room', audienceStore: sdk, friendshipManager: _Friends());
    final levels = <int?>[];
    store.onAudienceEntered = (welcome) => levels.add(welcome.level);
    store.activate();
    sdk.liveAudienceState.audienceList.value = [
      LiveUserInfo(userID: 'g', level: 25),
      LiveUserInfo(userID: 'invalid', level: -1),
    ];
    expect(store.state.users.map((user) => user.level), [25, 0]);
    sdk.listeners.single
        .onAudienceJoined!(LiveUserInfo(userID: 'g', level: 25));
    sdk.listeners.single
        .onAudienceJoined!(LiveUserInfo(userID: 'invalid', level: -1));
    expect(levels, [25, 0]);
    sdk.liveAudienceState.audienceList.value = [
      LiveUserInfo(userID: 'g', level: 26)
    ];
    expect(store.state.users.single.level, 26);
    store.dispose();
  });

  test(
      'Audience operations deduplicate and ignore completion after deactivation',
      () async {
    final sdk = _AudienceSDK();
    final friends = _Friends();
    final store = PusherAudienceStore(
        liveID: 'room', audienceStore: sdk, friendshipManager: friends);
    int completed = 0;
    store.onActionCompleted = (_, __, ___) => completed++;
    store.activate();
    store.activate();
    expect(sdk.listeners.length, 1);
    store.refresh();
    store.refresh();
    expect(sdk.refreshes, 1);
    sdk.liveAudienceState.audienceList.value = [
      LiveUserInfo(userID: 'g', userName: 'Guest')
    ];
    expect(store.state.users.single.userID, 'g');
    store.toggleMessagePermission('g');
    store.toggleMessagePermission('g');
    expect(sdk.writes, 1);
    expect(store.state.pendingUserIDs, {'g'});
    store.deactivate(resetState: true);
    sdk.operation.complete(CompletionHandler());
    sdk.refresh.complete(CompletionHandler());
    await Future<void>.delayed(Duration.zero);
    expect(completed, 0);
    expect(store.state.users, isEmpty);
    expect(store.state.pendingUserIDs, isEmpty);
    expect(sdk.listeners, isEmpty);
    expect(friends.listeners, isEmpty);
    expect(sdk.liveAudienceState.audienceList.isObserved, isFalse);
    store.dispose();
  });
}
