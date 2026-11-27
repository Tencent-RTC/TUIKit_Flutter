/// 对应 iOS `LiveKitAccess/LiveList/LiveSelectListStore.swift`。
///
/// 只保存列表加载、分页、防重和错误展示状态；直播列表业务事实来自 `LiveListStore`。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

import 'live_list_support.dart';

class LiveSelectListState {
  LiveSelectListState({
    this.liveList = const <LiveInfo>[],
    this.isLoading = false,
    this.canLoadMore = true,
    this.errorMessage,
  });

  List<LiveInfo> liveList;
  bool isLoading;
  bool canLoadMore;
  String? errorMessage;
}

class LiveSelectListStore extends ChangeNotifier {
  LiveSelectListStore({LiveListStore? liveListStore})
      : _liveListStore = liveListStore ?? LiveListStore.shared;

  static const int _pageSize = 6;

  final LiveListStore _liveListStore;
  final LiveSelectListState _state = LiveSelectListState();
  int _requestID = 0;

  LiveSelectListState get state => _state;

  void refresh() {
    _fetch('');
  }

  /// 供下拉刷新等待完成使用，语义与 [refresh] 一致。
  Future<void> refreshAndWait() {
    return _fetch('');
  }

  void loadMore() {
    if (!_state.canLoadMore || _state.isLoading) {
      return;
    }
    final String cursor = _liveListStore.liveState.liveListCursor.value;
    if (cursor.isEmpty) {
      _state.canLoadMore = false;
      notifyListeners();
      return;
    }
    _fetch(cursor);
  }

  Future<void> _fetch(String cursor) async {
    if (_state.isLoading) {
      return;
    }
    _state.isLoading = true;
    _state.errorMessage = null;
    final int currentRequestID = ++_requestID;
    notifyListeners();

    final CompletionHandler handler =
        await _liveListStore.fetchLiveList(cursor: cursor, count: _pageSize);
    if (currentRequestID != _requestID) {
      return;
    }
    _state.isLoading = false;
    if (handler.isSuccess) {
      _state.liveList = _deduplicated(_liveListStore.liveState.liveList.value);
      _state.canLoadMore =
          _liveListStore.liveState.liveListCursor.value.isNotEmpty;
    } else {
      _state.errorMessage = LiveSelectListErrorText.message(handler);
    }
    notifyListeners();
  }

  List<LiveInfo> _deduplicated(List<LiveInfo> list) {
    final Set<String> liveIDs = <String>{};
    return list
        .where((LiveInfo liveInfo) => liveIDs.add(liveInfo.liveID))
        .toList();
  }
}
