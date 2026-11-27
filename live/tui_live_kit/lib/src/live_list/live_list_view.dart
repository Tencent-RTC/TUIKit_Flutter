library;

import 'package:flutter/widgets.dart';

import 'view_pager/pager_view.dart';

export 'view_pager/pager_view.dart' show LiveListViewController;

class LiveListView extends StatelessWidget {
  LiveListView({
    super.key,
    this.controller,
    String liveID = '',
    String initialLiveID = '',
    this.onLoadMore,
  }) : liveID = initialLiveID.isEmpty ? liveID : initialLiveID;

  final LiveListViewController? controller;
  final String liveID;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return PagerView(
      controller: controller,
      initialLiveID: liveID,
      onLoadMore: onLoadMore,
    );
  }
}
