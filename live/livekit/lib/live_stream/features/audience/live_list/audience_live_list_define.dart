
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';

class FetchLiveListParam {
  final String cursor;
  final int count;

  const FetchLiveListParam({required this.cursor, required this.count});
}

class FetchLiveListResult {
  String cursor = "";
  List<LiveInfo> liveInfoList = [];
}

class FetchLiveListCompletionHandler extends CompletionHandler {
  final FetchLiveListResult liveListResult;

  FetchLiveListCompletionHandler({required this.liveListResult});
}

abstract class LiveListDataSource {
  Future<FetchLiveListCompletionHandler> fetchLiveList(FetchLiveListParam param);
}