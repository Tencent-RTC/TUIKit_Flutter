import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';

class LiveListPagerState {
  final ValueNotifier<List<LiveInfo>> liveInfoList = ValueNotifier<List<LiveInfo>>([]);

  String cursor = '';

  final ValueNotifier<bool> isLoadingMore = ValueNotifier<bool>(false);

  final ValueNotifier<bool> hasMoreData = ValueNotifier<bool>(true);

  final ValueNotifier<int> currentPageIndex = ValueNotifier<int>(0);
}
