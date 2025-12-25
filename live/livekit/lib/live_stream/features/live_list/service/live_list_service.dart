import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import '../../../../common/index.dart';
import '../store/live_list_state.dart';

class LiveListService {
  static const String tag = 'LiveListService';
  late final int fetchListCount = 20;
  final LiveListStore liveListStore = LiveListStore.shared;
  late final LSLiveListState roomListState = LSLiveListState();

  LiveListService();

  Future<void> refreshFetchList() async {
    if (roomListState.refreshStatus.value) {
      return;
    }
    roomListState.refreshStatus.value = true;
    roomListState.cursor = "";
    await _fetchLiveList();
  }

  Future<void> loadMoreData() async {
    if (roomListState.loadStatus.value ||
        roomListState.refreshStatus.value ||
        !roomListState.isHaveMoreData.value) {
      return;
    }
    roomListState.loadStatus.value = true;
    _loadMoreData();
  }
}

extension LiveListServiceLogicExtension on LiveListService {
  Future<void> _fetchLiveList() async {
    final String cursor = roomListState.cursor;
    final result = await liveListStore.fetchLiveList(cursor: cursor, count: fetchListCount);
    if (!result.isSuccess) {
      if (result.errorCode != TUIError.errFailed.rawValue &&
          result.errorMessage != null &&
          result.errorMessage!.contains('exceed frequency limit')) {
        LiveKitLogger.error(
            "${LiveListService.tag} _initData [code:${result.errorCode},message:${result.errorMessage}]");
        ErrorHandler.onError(result.errorCode, result.errorMessage ?? '');
      }
      roomListState.loadStatus.value = false;
      roomListState.refreshStatus.value = false;
      roomListState.isHaveMoreData.value = false;
    } else {
      roomListState.liveInfoList.value = liveListStore.liveState.liveList.value;
      roomListState.cursor = liveListStore.liveState.liveListCursor.value;
      roomListState.loadStatus.value = false;
      roomListState.refreshStatus.value = false;
      roomListState.isHaveMoreData.value = liveListStore.liveState.liveListCursor.value.isNotEmpty;
    }
  }

  Future<void> _loadMoreData() async {
    final String cursor = roomListState.cursor;
    final result = await liveListStore.fetchLiveList(cursor: cursor, count: fetchListCount);
    if (!result.isSuccess) {
      LiveKitLogger.error(
          "${LiveListService.tag} _initData [code:${result.errorCode},message:${result.errorMessage}]");
      ErrorHandler.onError(result.errorCode, result.errorMessage);
      roomListState.loadStatus.value = false;
      roomListState.isHaveMoreData.value = false;
    } else {
      List<LiveInfo> liveInfoList = [
        ...roomListState.liveInfoList.value,
        ...liveListStore.liveState.liveList.value
      ];
      roomListState.liveInfoList.value = liveInfoList;
      roomListState.cursor = liveListStore.liveState.liveListCursor.value;
      roomListState.loadStatus.value = false;
      roomListState.isHaveMoreData.value = liveListStore.liveState.liveListCursor.value.isNotEmpty;
    }
  }
}
