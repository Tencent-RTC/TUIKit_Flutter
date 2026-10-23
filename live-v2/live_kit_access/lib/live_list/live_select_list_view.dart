/// 对应 iOS `LiveKitAccess/LiveList/LiveSelectListView.swift`。
///
/// 接入层公开入口：两列直播列表、下拉刷新、触底加载与选中回调。
/// 接入层自带独立数据获取，不依赖组件库内部实现。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'live_list_support.dart';
import 'live_select_list_store.dart';

/// 对应 iOS `LiveSelectListViewDelegate` 的选中回调。
typedef LiveSelectListSelectCallback = void Function(LiveInfo liveInfo);

class LiveSelectListView extends StatefulWidget {
  const LiveSelectListView({super.key, this.onSelectLive, this.refreshTrigger});

  final LiveSelectListSelectCallback? onSelectLive;

  /// 每次 [Listenable.notifyListeners] 触发都会调 `refresh()`，供外部（例如从 Player/Pusher 返回时）刷新列表。
  final Listenable? refreshTrigger;

  @override
  State<LiveSelectListView> createState() => _LiveSelectListViewState();
}

class _LiveSelectListViewState extends State<LiveSelectListView> {
  final LiveSelectListStore _store = LiveSelectListStore();
  final LiveSelectListDataSource _dataSource = LiveSelectListDataSource();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStateChanged);
    _scrollController.addListener(_onScroll);
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
    if (_dataSource.liveList.isEmpty) {
      _store.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant LiveSelectListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTriggered);
      widget.refreshTrigger?.addListener(_onRefreshTriggered);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    _store.removeListener(_onStateChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _store.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    if (!mounted) return;
    _store.refresh();
  }

  void _onStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _dataSource.liveList = _store.state.liveList;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 200) {
      _store.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LiveSelectListState state = _store.state;
    final bool isEmpty = _dataSource.numberOfItems == 0;
    final String statusText =
        state.errorMessage ?? (state.isLoading ? '加载中…' : '暂无直播');

    return ColoredBox(
      color: LiveSelectListPalette.background,
      child: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _store.refreshAndWait,
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 1 / 1.35,
              ),
              itemCount: _dataSource.numberOfItems,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onSelectItem(index),
                  child: _dataSource.buildItem(context, index),
                );
              },
            ),
          ),
          if (isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: LiveSelectListPalette.secondaryText,
                          fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onSelectItem(int index) {
    if (index < 0 || index >= _dataSource.liveList.length) {
      return;
    }
    widget.onSelectLive?.call(_dataSource.liveList[index]);
  }
}
