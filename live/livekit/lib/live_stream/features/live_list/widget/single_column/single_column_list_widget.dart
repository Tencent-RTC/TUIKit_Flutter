import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/widget/single_column/single_column_empty_item_widget.dart';
import '../../live_list_define.dart';
import '../../store/live_info_list_store.dart';
import 'page_widget/page_widget.dart';
import 'single_column_item_widget.dart';

class SingleColumnListWidget extends StatefulWidget {
  final LiveInfoListStore liveInfoListStore;
  final OnItemClick? onItemClick;

  const SingleColumnListWidget({
    super.key,
    required this.liveInfoListStore,
    this.onItemClick,
  });

  @override
  State<StatefulWidget> createState() {
    return SingleColumnListWidgetState();
  }
}

class SingleColumnListWidgetState extends State<SingleColumnListWidget> {
  late final LiveInfoListStore _liveInfoListStore;

  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  final ValueNotifier<bool> _offstageListenable = ValueNotifier(false);

  final Map<String, LiveCoreController> _controllers = {};

  final PageController _pageController = PageController();

  /// Tracks the currently visible page index. Used to enable expensive
  /// [BackdropFilter] blur only for the current item and its two neighbours.
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

  late final VoidCallback _liveInfoListListener = _pruneStaleControllers;

  String _currentLiveID = "";

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
    _pageController.dispose();
    _isLoadingMore.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(),
      child: OrientationBuilder(
        builder: (context, orientation) => _buildPageView(context),
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _liveInfoListStore.liveInfoList,
      builder: (context, liveInfoList, _) {
        if (liveInfoList.isEmpty) {
          return const SingleColumnEmptyItemWidget();
        }
        return PageWidget<LiveInfo>(
          items: liveInfoList,
          controller: _pageController,
          onPageWillSlideIn: _onPageWillSlideIn,
          onPageDidSlideIn: _onPageDidSlideIn,
          onPageWillSlideOut: _onPageWillSlideOut,
          onPageDidSlideOut: _onPageDidSlideOut,
          onPageSlideInCancelled: _onPageSlideInCancelled,
          onPageSlideOutCancelled: _onPageSlideOutCancelled,
          itemBuilder: (ctx, liveInfo, index) {
            final controller = _obtainController(liveInfo.liveID);
            return ValueListenableBuilder<int>(
              valueListenable: _currentIndexNotifier,
              builder: (context, currentIndex, _) {
                final bool enableBlur = (index - currentIndex).abs() <= 1;
                return SingleColumnItemWidget(
                  key: ValueKey("single_column_item_${liveInfo.liveID}"),
                  liveInfo: liveInfo,
                  liveCoreController: controller,
                  offstageListenable: _offstageListenable,
                  enableBlur: enableBlur,
                  onTap: () => _onItemTap(index),
                  onInitState: () {
                    if (index == currentIndex) {
                      _startPreload(liveInfo.liveID, false);
                      _currentLiveID = liveInfo.liveID;
                    }
                  },
                  onDispose: () {
                    final removed = _controllers.remove(liveInfo.liveID);
                    removed?.stopPreviewLiveStream(liveInfo.liveID);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void pausePreload() {
    LiveKitLogger.info('pausePreload, liveID=$_currentLiveID');
    _offstageListenable.value = true;
    if (_currentLiveID.isEmpty) return;
    final controller = _controllers[_currentLiveID];
    controller?.stopPreviewLiveStream(_currentLiveID);
  }

  void resumePreload() {
    LiveKitLogger.info('resumePreload, liveID=$_currentLiveID');
    _offstageListenable.value = false;
    if (_currentLiveID.isEmpty) return;
    final controller = _controllers[_currentLiveID];
    controller?.startPreviewLiveStream(_currentLiveID, false, null);
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
  }

  void _onItemTap(int index) {
    LiveKitLogger.info("onItemTap, index=$index");
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onItemTap error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    widget.onItemClick?.call(liveInfo);
  }

  void _onPageWillSlideIn(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageWillSlideIn error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageWillSlideIn: index=$index, liveID=${liveInfo.liveID}');
    _startPreload(liveInfo.liveID, true);
  }

  void _onPageDidSlideIn(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageDidSlideIn error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageDidSlideIn: index=$index, liveID=${liveInfo.liveID}');
    _startPreload(liveInfo.liveID, false);

    _currentLiveID = liveInfo.liveID;
    _currentIndexNotifier.value = index;

    const preloadThreshold = 2;
    if (index >= liveList.length - preloadThreshold) {
      _loadMore();
    }
  }

  void _onPageWillSlideOut(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageWillSlideOut error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageWillSlideOut: index=$index, liveID=${liveInfo.liveID}');
  }

  void _onPageDidSlideOut(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageDidSlideOut error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageDidSlideOut: index=$index, liveID=${liveInfo.liveID}');
    _stopPreload(liveInfo.liveID);
  }

  void _onPageSlideInCancelled(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageSlideInCancelled error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageSlideInCancelled: index=$index, liveID=${liveInfo.liveID}');
    _stopPreload(liveInfo.liveID);
  }

  void _onPageSlideOutCancelled(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageSlideOutCancelled error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageSlideOutCancelled: index=$index, liveID=${liveInfo.liveID}');
  }

  void _startPreload(String liveID, bool isMuteAudio) {
    final controller = _controllers[liveID];
    controller?.startPreviewLiveStream(liveID, isMuteAudio, null);
  }

  void _stopPreload(String liveID) {
    final controller = _controllers[liveID];
    controller?.stopPreviewLiveStream(liveID);
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
    if (_currentLiveID.isNotEmpty) {
      _stopPreload(_currentLiveID);
      _currentLiveID = "";
    }
    await _liveInfoListStore.fetchLiveList(true);
  }
}
