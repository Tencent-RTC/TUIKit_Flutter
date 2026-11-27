import 'dart:async';
import 'package:app_uikit/live/home/live_home_list_store.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _State extends Fake implements LiveListState {
  @override
  final ValueNotifier<List<LiveInfo>> liveList = ValueNotifier<List<LiveInfo>>([]);
  @override
  final ValueNotifier<String> liveListCursor = ValueNotifier('');
}

class _SDK extends Fake implements LiveListStore {
  @override
  final _State liveState = _State();
  final requests = <String>[];
  final pending = <Completer<CompletionHandler>>[];
  @override
  Future<CompletionHandler> fetchLiveList({required String cursor, required int count}) {
    expect(count, 6);
    requests.add(cursor);
    final completion = Completer<CompletionHandler>();
    pending.add(completion);
    return completion.future;
  }

  void complete(int index, List<LiveInfo> items, String next) {
    liveState.liveList.value = items;
    liveState.liveListCursor.value = next;
    pending[index].complete(CompletionHandler());
  }
}

void main() {
  test('independent feeds preserve their own cursor and detached snapshots', () async {
    final sdk = _SDK();
    final home = LiveHomeListStore(sdk: sdk);
    final first = home.refresh();
    final original = LiveInfo(
      liveID: 'a',
      liveName: 'A',
      liveOwner: LiveUserInfo(userID: 'host', userName: 'Host'),
    );
    sdk.complete(0, [original], 'next-a');
    await first;
    final pushed = home.independentCopy();
    original.liveName = 'Changed elsewhere';
    original.liveOwner.userName = 'Changed elsewhere';
    final refresh = home.refresh();
    sdk.complete(1, [LiveInfo(liveID: 'b')], 'next-b');
    await refresh;
    expect(pushed.state.items.single.liveName, 'A');
    expect(pushed.state.items.single.liveOwner.userName, 'Host');
    final more = pushed.loadMore();
    expect(sdk.requests.last, 'next-a');
    sdk.complete(2, [LiveInfo(liveID: 'a', liveName: 'Updated'), LiveInfo(liveID: 'c')], '');
    await more;
    expect(pushed.state.items.map((v) => v.liveID), ['a', 'c']);
    expect(home.state.items.single.liveID, 'b');
    expect(pushed.state.canLoadMore, false);
    home.dispose();
    pushed.dispose();
  });
  test('offscreen request cannot overwrite a newer request after resuming', () async {
    final sdk = _SDK();
    final store = LiveHomeListStore(sdk: sdk);
    final old = store.refresh();
    store.setActive(false);
    store.setActive(true);
    final next = store.refresh();
    sdk.complete(1, [LiveInfo(liveID: 'new')], '');
    await next;
    sdk.complete(0, [LiveInfo(liveID: 'stale')], 'stale-next');
    await old;
    expect(store.state.items.single.liveID, 'new');
    expect(store.state.canLoadMore, false);
    expect(store.state.loading, false);
    store.dispose();
  });
}
