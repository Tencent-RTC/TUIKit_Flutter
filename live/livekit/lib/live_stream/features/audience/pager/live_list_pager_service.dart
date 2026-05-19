import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:tencent_live_uikit/common/index.dart';

import 'live_list_pager_state.dart';

class LiveListPagerService {
  static const String tag = 'LiveListPagerService';
  static const int fetchCount = 20;
  static const int preloadThreshold = 3;

  final LiveListPagerState state = LiveListPagerState();
  final LiveListStore _liveListStore;

  LiveListPagerService({LiveListStore? liveListStore})
      : _liveListStore = liveListStore ?? LiveListStore.shared;

  Future<void> initWithCurrentLive(LiveInfo currentLiveInfo) async {
    state.liveInfoList.value = [currentLiveInfo];
    state.currentPageIndex.value = 0;
    state.cursor = '';
    state.hasMoreData.value = true;
    state.isLoadingMore.value = false;

    await _fetchNextPage(excludeLiveId: currentLiveInfo.liveID);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore.value || !state.hasMoreData.value) {
      return;
    }
    await _fetchNextPage();
  }

  void checkAndPreload(int currentIndex) {
    final listLength = state.liveInfoList.value.length;
    if (listLength - currentIndex <= preloadThreshold) {
      loadMore();
    }
  }

  void onPageChanged(int index) {
    state.currentPageIndex.value = index;
    checkAndPreload(index);
  }

  Future<void> _fetchNextPage({String? excludeLiveId}) async {
    state.isLoadingMore.value = true;
    try {
      final result = await _liveListStore.fetchLiveList(
        cursor: state.cursor,
        count: fetchCount,
      );

      if (!result.isSuccess) {
        LiveKitLogger.error(
            '$tag _fetchNextPage failed [code:${result.errorCode}, message:${result.errorMessage}]');
        state.hasMoreData.value = false;
        state.isLoadingMore.value = false;
        return;
      }

      final fetchedList = _liveListStore.liveState.liveList.value;
      final newCursor = _liveListStore.liveState.liveListCursor.value;

      final existingIds = state.liveInfoList.value.map((info) => info.liveID).toSet();
      List<LiveInfo> deduplicatedList = fetchedList
          .where((info) => !existingIds.contains(info.liveID))
          .toList();

      if (excludeLiveId != null) {
        deduplicatedList = deduplicatedList
            .where((info) => info.liveID != excludeLiveId)
            .toList();
      }

      state.liveInfoList.value = [
        ...state.liveInfoList.value,
        ...deduplicatedList,
      ];
      state.cursor = newCursor;
      state.hasMoreData.value = newCursor.isNotEmpty;
    } catch (e) {
      LiveKitLogger.error('$tag _fetchNextPage error: $e');
      state.hasMoreData.value = false;
    } finally {
      state.isLoadingMore.value = false;
    }
  }
}
