import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../live_list_define.dart';

class LiveInfoListStore {
  final int kFetchCount = 20;
  final ValueNotifier<List<LiveInfo>> liveInfoList = ValueNotifier<List<LiveInfo>>([]);
  String _cursor = '';

  final LiveListDataSource? dataSource;

  Future<CompletionHandler>? _pendingFuture;

  LiveInfoListStore({this.dataSource});

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
    final future = (dataSource == null ? _fetchLiveListDefault(isRefresh) : _fetchLiveList(isRefresh))
        .whenComplete(() {
      _pendingFuture = null;
    });
    _pendingFuture = future;
    return future;
  }

  bool hasMoreData() => _cursor.isNotEmpty;

  bool get isFetching => _pendingFuture != null;

  Future<CompletionHandler> _fetchLiveListDefault(bool isRefresh) async {
    LiveKitLogger.info("fetchLiveListDefault, isRefresh=$isRefresh, _cursor=$_cursor");
    _cursor = isRefresh ? '' : _cursor;
    final result = await LiveListStore.shared.fetchLiveList(cursor: _cursor, count: kFetchCount);
    _cursor = LiveListStore.shared.liveState.liveListCursor.value;
    liveInfoList.value = LiveListStore.shared.liveState.liveList.value;
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
      liveInfoList.value = list;
    } else {
      LiveKitLogger.error("fetchLiveList error: errorCode=${result.errorCode}, errorMessage=${result.errorMessage}");
    }
    CompletionHandler completionHandler = CompletionHandler();
    completionHandler.errorCode = result.errorCode;
    completionHandler.errorMessage = result.errorMessage;
    return completionHandler;
  }

  void dispose() {
    liveInfoList.dispose();
  }

}