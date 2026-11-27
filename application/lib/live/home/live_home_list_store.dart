import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';

class LiveHomeListState {
  const LiveHomeListState({
    this.items = const [],
    this.loading = false,
    this.loaded = false,
    this.canLoadMore = true,
    this.error,
    this.refreshFailed = false,
    this.refreshing = false,
    this.revision = 0,
    this.refreshRevision = 0,
  });
  final List<LiveInfo> items;
  final bool loading;
  final bool loaded;
  final bool canLoadMore;
  final String? error;
  final bool refreshFailed;
  final bool refreshing;
  final int revision;
  final int refreshRevision;
  LiveHomeListState copyWith({
    List<LiveInfo>? items,
    bool? loading,
    bool? loaded,
    bool? canLoadMore,
    String? error,
    bool clearError = false,
    bool? refreshFailed,
    bool? refreshing,
    int? revision,
    int? refreshRevision,
  }) => LiveHomeListState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    canLoadMore: canLoadMore ?? this.canLoadMore,
    error: clearError ? null : error ?? this.error,
    refreshFailed: clearError ? false : refreshFailed ?? this.refreshFailed,
    refreshing: refreshing ?? this.refreshing,
    revision: revision ?? this.revision,
    refreshRevision: refreshRevision ?? this.refreshRevision,
  );
}

class LiveHomeListStore extends ChangeNotifier {
  LiveHomeListStore({LiveListStore? sdk}) : _sdk = sdk ?? LiveListStore.shared;
  final LiveListStore _sdk;
  LiveHomeListState state = const LiveHomeListState();
  String _cursor = '';
  int _request = 0;
  bool _active = true;
  bool _disposed = false;
  LiveHomeListStore independentCopy() {
    final copy = LiveHomeListStore(sdk: _sdk);
    copy._cursor = _cursor;
    copy.state = state.copyWith(
      items: List.unmodifiable(state.items.map(_snapshot)),
      loading: false,
      refreshing: false,
      clearError: true,
    );
    return copy;
  }

  void setActive(bool active) {
    if (_active == active || _disposed) return;
    _active = active;
    if (!active) {
      ++_request;
      state = state.copyWith(loading: false, refreshing: false);
      notifyListeners();
    }
  }

  Future<void> refresh() => _fetch('');
  Future<void> loadMore() async {
    if (state.loaded && state.canLoadMore && _cursor.isNotEmpty) await _fetch(_cursor);
  }

  Future<void> _fetch(String cursor) async {
    if (!_active || _disposed || state.loading) return;
    final token = ++_request;
    state = state.copyWith(loading: true, refreshing: cursor.isEmpty, clearError: true);
    notifyListeners();
    try {
      final sdk = _sdk;
      final result = await sdk.fetchLiveList(cursor: cursor, count: 6);
      final incoming = sdk.liveState.liveList.value.map(_snapshot).toList(growable: false);
      final next = sdk.liveState.liveListCursor.value;
      if (_disposed || !_active || token != _request) return;
      if (!result.isSuccess) {
        state = state.copyWith(
          loading: false,
          refreshing: false,
          refreshFailed: cursor.isEmpty,
          error: result.errorMessage ?? '${result.errorCode}',
        );
      } else {
        final merged = <String, LiveInfo>{
          if (cursor.isNotEmpty)
            for (final info in state.items) info.liveID: info,
        };
        for (final info in incoming) {
          if (info.liveID.isNotEmpty) merged[info.liveID] = info;
        }
        _cursor = next;
        state = state.copyWith(
          items: List.unmodifiable(merged.values),
          loading: false,
          refreshing: false,
          loaded: true,
          canLoadMore: next.isNotEmpty,
          clearError: true,
          revision: state.revision + 1,
          refreshRevision: state.refreshRevision + (cursor.isEmpty ? 1 : 0),
        );
      }
    } catch (e) {
      if (_disposed || !_active || token != _request) return;
      state = state.copyWith(loading: false, refreshing: false, refreshFailed: cursor.isEmpty, error: e.toString());
    }
    notifyListeners();
  }

  static LiveInfo _snapshot(LiveInfo info) => LiveInfo(
    liveID: info.liveID,
    liveName: info.liveName,
    status: info.status,
    notice: info.notice,
    isMessageDisable: info.isMessageDisable,
    isPublicVisible: info.isPublicVisible,
    keepOwnerOnSeat: info.keepOwnerOnSeat,
    seatMode: info.seatMode,
    seatTemplate: info.seatTemplate,
    coverURL: info.coverURL,
    backgroundURL: info.backgroundURL,
    categoryList: List.of(info.categoryList),
    activityStatus: info.activityStatus,
    createTime: info.createTime,
    totalViewerCount: info.totalViewerCount,
    isGiftEnabled: info.isGiftEnabled,
    metaData: Map.of(info.metaData),
    liveOwner: LiveUserInfo(
      userID: info.liveOwner.userID,
      userName: info.liveOwner.userName,
      avatarURL: info.liveOwner.avatarURL,
      level: info.liveOwner.level,
    ),
  );
  @override
  void dispose() {
    _disposed = true;
    ++_request;
    super.dispose();
  }
}
