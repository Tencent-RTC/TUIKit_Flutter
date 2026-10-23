import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/store/live_info_list_store.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/widget/double_column/scroll_widget/scroll_widget.dart';

import '../../live_list_define.dart';
import 'double_column_item_widget.dart';

class DoubleColumnListWidget extends StatefulWidget {
  final LiveInfoListStore liveInfoListStore;
  final OnItemClick? onItemClick;

  const DoubleColumnListWidget({
    super.key,
    required this.liveInfoListStore,
    this.onItemClick,
  });

  @override
  State<StatefulWidget> createState() {
    return DoubleColumnListWidgetState();
  }
}

class DoubleColumnListWidgetState extends State<DoubleColumnListWidget> {
  final double _childAspectRatio = 168.width / 262.height;
  late final LiveInfoListStore _liveInfoListStore;

  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<bool> _offstageListenable = ValueNotifier(false);

  bool _hasTriggeredLoadMore = false;

  final Map<String, LiveCoreController> _controllers = {};

  final List<String> _preloadLiveIDList = [];

  late final VoidCallback _liveInfoListListener = _pruneStaleControllers;

  @override
  void initState() {
    super.initState();
    _liveInfoListStore = widget.liveInfoListStore;
    _liveInfoListStore.liveInfoList.addListener(_liveInfoListListener);
  }

  @override
  void dispose() {
    _liveInfoListStore.liveInfoList.removeListener(_liveInfoListListener);
    pausePreload();
    _controllers.clear();
    _isLoadingMore.dispose();
    _offstageListenable.dispose();
    super.dispose();
  }

  void pausePreload() {
    LiveKitLogger.info('pausePreload');
    _offstageListenable.value = true;
    _stopAllPreload();
    _preloadLiveIDList.clear();
  }

  void resumePreload() {
    LiveKitLogger.info('resumePreload');
    _offstageListenable.value = false;
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(),
      child: buildScrollView(context),
    );
  }

  Widget buildScrollView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _liveInfoListStore.liveInfoList,
        builder: (context, liveInfoList, _) {
          return ScrollWidget<LiveInfo>(
            childAspectRatio: _childAspectRatio,
            items: liveInfoList,
            itemBuilder: (context, liveInfo, index) {
              final controller = _obtainController(liveInfo.liveID);
              return DoubleColumnItemWidget(
                key: ValueKey('double_column_item_${liveInfo.liveID}'),
                index: index,
                liveInfo: liveInfo,
                liveCoreController: controller,
                offstageListenable: _offstageListenable,
                onItemClick: (liveInfo) {
                  widget.onItemClick?.call(liveInfo);
                },
                onDispose: () {
                  final removed = _controllers.remove(liveInfo.liveID);
                  removed?.stopPreviewLiveStream(liveInfo.liveID);
                  _preloadLiveIDList.remove(liveInfo.liveID);
                },
              );
            },
            footerBuilder: (context) {
              return _buildFooter();
            },
            onFirstVisibleItemsChanged: (left, right) => _onFirstVisibleItemsChanged(left, right),
            onScrollChanged: (position) => _onScroll(position),
            onNotification: (notification) => _onNotification(notification),
          );
        });
  }

  Widget _buildFooter() {
    return ListenableBuilder(
      listenable: Listenable.merge([_liveInfoListStore.liveInfoList, _isLoadingMore]),
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.height),
          alignment: Alignment.center,
          child: _isLoadingMore.value
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: LiveColors.designStandardWhite7.withAlpha(128),
                      ),
                    ),
                    Text(
                      LiveKitLocalizations.of(Global.appContext())!.livelist_loading,
                      style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128)),
                    ),
                  ],
                )
              : (_liveInfoListStore.hasMoreData()
                  ? SizedBox.shrink()
                  : Text(
                      LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
                      style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128)),
                    )),
        );
      },
    );
  }

  void _onFirstVisibleItemsChanged(int leftIndex, int rightIndex) {
    LiveKitLogger.info('onFirstVisibleItemsChanged: leftIndex=$leftIndex, rightIndex=$rightIndex');
    final liveInfoList = _liveInfoListStore.liveInfoList.value;
    if (leftIndex < 0 || rightIndex >= liveInfoList.length) {
      LiveKitLogger.error("index is invalid!");
      return;
    }
    LiveInfo leftLive = liveInfoList[leftIndex];
    LiveInfo rightLive = liveInfoList[rightIndex];
    if (_preloadLiveIDList.contains(leftLive.liveID) && _preloadLiveIDList.contains(rightLive.liveID)) {
      return;
    }
    // Stop old preload
    _stopAllPreload();
    _preloadLiveIDList.clear();

    // Start new preload
    _preloadLiveIDList.add(leftLive.liveID);
    _preloadLiveIDList.add(rightLive.liveID);
    _startAllPreload();
  }

  void _onScroll(ScrollPosition position) {
    final atBottom = position.pixels >= position.maxScrollExtent;
    if (!atBottom) return;
    if (_hasTriggeredLoadMore) return;
    _hasTriggeredLoadMore = true;
    _loadMore();
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _hasTriggeredLoadMore = false;
    }
    return false;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore.value) return;
    if (!_liveInfoListStore.hasMoreData()) return;
    _isLoadingMore.value = true;
    _liveInfoListStore.fetchLiveList(false).then((result) {
      if (!mounted) return;
      _isLoadingMore.value = false;
    });
  }

  Future<void> _onRefresh() async {
    LiveKitLogger.info("onRefresh");
    _stopAllPreload();
    _preloadLiveIDList.clear();
    _liveInfoListStore.fetchLiveList(true);
  }

  LiveCoreController _obtainController(String liveID) {
    return _controllers.putIfAbsent(liveID, () {
      final controller = LiveCoreController.create(CoreViewType.playView);
      return controller;
    });
  }

  /// Removes cached controllers whose liveID is no longer in the current list
  /// (e.g. after refresh). Safe for append-only changes: it becomes a no-op.
  void _pruneStaleControllers() {
    if (_controllers.isEmpty) return;
    final validIDs = _liveInfoListStore.liveInfoList.value.map((e) => e.liveID).toSet();
    _controllers.removeWhere((liveID, controller) {
      if (validIDs.contains(liveID)) return false;
      LiveKitLogger.info('pruneStaleController, liveID=$liveID');
      controller.stopPreviewLiveStream(liveID);
      return true;
    });
    _preloadLiveIDList.removeWhere((id) => !validIDs.contains(id));
  }

  void _startAllPreload() {
    LiveKitLogger.info("_startAllPreload: $_preloadLiveIDList");
    for (var liveID in _preloadLiveIDList) {
      final controller = _controllers[liveID];
      controller?.startPreviewLiveStream(liveID, true, null);
    }
  }

  void _stopAllPreload() {
    LiveKitLogger.info("_stopAllPreload: $_preloadLiveIDList");
    for (var liveID in _preloadLiveIDList) {
      final controller = _controllers[liveID];
      controller?.stopPreviewLiveStream(liveID);
    }
  }
}
