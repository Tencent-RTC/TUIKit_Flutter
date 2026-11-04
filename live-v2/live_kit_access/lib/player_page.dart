/// 对应 iOS `LiveKitAccess/PlayerViewController.swift`。
///
/// 观众端 Feed 承载：观察独立 `LiveSelectListStore`，把最新直播列表推给
/// `LiveListView.setData`；触底通过 `onLoadMore` 触发 store 的 `loadMore`；
/// 关闭 Feed 通过 `onClose` 回退路由。不持有任何直播业务状态。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import 'live_list/live_select_list_store.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.liveID});

  final String liveID;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final LiveSelectListStore _store = LiveSelectListStore();
  final LiveListViewController _liveListController = LiveListViewController();
  int _lastAppliedCount = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    if (_store.state.liveList.isEmpty) {
      _store.refresh();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushSnapshot());
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _pushSnapshot();
  }

  void _pushSnapshot() {
    if (!_liveListController.isAttached) return;
    final List<LiveInfo> list = _store.state.liveList;
    if (_lastAppliedCount == 0) {
      _liveListController.setData(list);
    } else if (list.length > _lastAppliedCount) {
      _liveListController.appendData(list.sublist(_lastAppliedCount));
    } else {
      _liveListController.setData(list);
    }
    _lastAppliedCount = list.length;
  }

  void _handleLoadMore() {
    _store.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: LiveListView(
                controller: _liveListController,
                initialLiveID: widget.liveID,
                onLoadMore: _handleLoadMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
