import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';

import '../../../../common/index.dart';
import '../store/live_list_state.dart';

class LiveListService {
  static const String tag = 'LiveListService';
  late final int fetchListCount = 20;
  final LiveListStore liveListStore = LiveListStore.shared;
  late final LSLiveListState roomListState = LSLiveListState();

  final StreamController<String> _toastController = StreamController<String>.broadcast();
  Stream<String> get toastStream => _toastController.stream;

  LiveListService();

  void dispose() {
    _toastController.close();
  }

  Future<void> refreshFetchList() async {
    if (roomListState.refreshStatus.value) {
      return;
    }
    roomListState.refreshStatus.value = true;
    roomListState.cursor = "";
    await _fetchLiveList();
    roomListState.refreshStatus.value = false;
  }

  Future<void> loadMoreData() async {
    if (roomListState.loadStatus.value ||
        roomListState.refreshStatus.value ||
        !roomListState.isHaveMoreData.value) {
      return;
    }
    roomListState.loadStatus.value = true;
    await _fetchLiveList();
    roomListState.loadStatus.value = false;
  }
}

extension LiveListServiceLogicExtension on LiveListService {
  Future<void> _fetchLiveList() async {
    final String cursor = roomListState.cursor;
    final result = await liveListStore.fetchLiveList(cursor: cursor, count: fetchListCount);
    if (!result.isSuccess) {
      final message = ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage ?? '');
      if (message != null) _toastController.add(message);
      roomListState.isHaveMoreData.value = false;
    } else {
      roomListState.liveInfoList.value = liveListStore.liveState.liveList.value;
      roomListState.cursor = liveListStore.liveState.liveListCursor.value;
      roomListState.isHaveMoreData.value = liveListStore.liveState.liveListCursor.value.isNotEmpty;
    }
  }
}