import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:tencent_live_uikit/common/index.dart';

import 'audience_live_list_define.dart';

class AudienceLiveInfoListStore {
  final int kFetchCount = 20;
  final ValueNotifier<List<LiveInfo>> liveInfoList = ValueNotifier<List<LiveInfo>>([]);
  String _cursor = '';

  final LiveListDataSource? dataSource;
  LiveInfo? _topLiveInfo;

  Future<CompletionHandler>? _pendingFuture;

  AudienceLiveInfoListStore({this.dataSource});

  void setTopLiveInfo(LiveInfo liveInfo) {
    _topLiveInfo = liveInfo;
  }

  Future<CompletionHandler> fetchLiveList(bool isRefresh) {
    if (_pendingFuture != null) {
      LiveKitLogger.info("fetchLiveList is in progress, reuse pending future. isRefresh=$isRefresh");
      return _pendingFuture!;
    }
    if (!isRefresh && _cursor.isEmpty) {
      CompletionHandler completionHandler = CompletionHandler();
      completionHandler.errorCode = -1;
      completionHandler.errorMessage = 'load more but cursor is empty';
      return Future.value(completionHandler);
    }
    final future = (dataSource == null ? _fetchLiveListDefault(isRefresh) : _fetchLiveList(isRefresh)).whenComplete(() {
      _pendingFuture = null;
    });
    _pendingFuture = future;
    return future;
  }

  bool hasMoreData() => _cursor.isNotEmpty;

  bool get isFetching => _pendingFuture != null;

  Future<CompletionHandler> _fetchLiveListDefault(bool isRefresh) async {
    LiveKitLogger.info("_fetchLiveListDefault, isRefresh=$isRefresh, _cursor=$_cursor");
    _cursor = isRefresh ? '' : _cursor;
    final result = await LiveListStore.shared.fetchLiveList(cursor: _cursor, count: kFetchCount);
    _cursor = LiveListStore.shared.liveState.liveListCursor.value;
    updateLiveList(LiveListStore.shared.liveState.liveList.value);
    CompletionHandler completionHandler = CompletionHandler();
    completionHandler.errorCode = result.errorCode;
    completionHandler.errorMessage = result.errorMessage;
    return completionHandler;
  }

  Future<CompletionHandler> _fetchLiveList(bool isRefresh) async {
    LiveKitLogger.info("_fetchLiveList, isRefresh=$isRefresh, _cursor=$_cursor");
    _cursor = isRefresh ? '' : _cursor;
    FetchLiveListParam param = FetchLiveListParam(cursor: _cursor, count: kFetchCount);
    final result = await dataSource!.fetchLiveList(param);
    if (result.isSuccess) {
      _cursor = result.liveListResult.cursor;
      List<LiveInfo> list = isRefresh ? [] : [...liveInfoList.value];
      list.addAll(result.liveListResult.liveInfoList);
      updateLiveList(list);
    } else {
      LiveKitLogger.error("fetchLiveList error: errorCode=${result.errorCode}, errorMessage=${result.errorMessage}");
    }
    CompletionHandler completionHandler = CompletionHandler();
    completionHandler.errorCode = result.errorCode;
    completionHandler.errorMessage = result.errorMessage;
    return completionHandler;
  }

  void updateLiveList(List<LiveInfo> list) {
    final String? pinnedID = _topLiveInfo?.liveID;
    if (pinnedID != null && pinnedID.isNotEmpty) {
      final int index = list.indexWhere((e) => e.liveID == pinnedID);
      if (index > 0) {
        final LiveInfo pinned = list.removeAt(index);
        list.insert(0, pinned);
      } else if (index < 0 && _topLiveInfo != null) {
        list.insert(0, _topLiveInfo!);
      }
    }
    liveInfoList.value = list;
  }

  void dispose() {
    liveInfoList.dispose();
  }
}
