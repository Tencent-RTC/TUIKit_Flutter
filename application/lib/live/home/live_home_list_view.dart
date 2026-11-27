import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';
import 'live_home_list_store.dart';
import 'live_home_item_view.dart';

class LiveHomeListView extends StatelessWidget {
  const LiveHomeListView({
    super.key,
    required this.store,
    required this.onSelect,
    required this.controller,
    this.active = true,
    this.itemKey,
  });
  final LiveHomeListStore store;
  final ValueChanged<LiveInfo> onSelect;
  final ScrollController controller;
  final bool active;
  final Key Function(String liveID)? itemKey;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff0f121a),
    child: AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final state = store.state;
        return RefreshIndicator(
          onRefresh: store.refresh,
          color: Colors.white,
          backgroundColor: const Color(0xff20232c),
          child: NotificationListener<ScrollNotification>(
            onNotification: (event) {
              if (active &&
                  event is ScrollUpdateNotification &&
                  event.metrics.extentAfter < 200 &&
                  state.error == null) {
                store.loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.loading) const CircularProgressIndicator(color: Colors.white70),
                            const SizedBox(height: 12),
                            Text(
                              state.error ?? AppStrings.of(context, state.loading ? 'loading' : 'emptyLive'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            if (!state.loading && state.error != null)
                              TextButton(
                                onPressed: store.refresh,
                                child: Text(
                                  AppStrings.of(context, 'retry'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1 / 1.35,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => LiveHomeItemView(
                          key: itemKey?.call(state.items[index].liveID) ?? ValueKey(state.items[index].liveID),
                          info: state.items[index],
                          active: active,
                          onTap: active ? () => onSelect(state.items[index]) : null,
                        ),
                        childCount: state.items.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: state.loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                              )
                            : TextButton(
                                onPressed: state.error != null
                                    ? (state.refreshFailed ? store.refresh : store.loadMore)
                                    : state.canLoadMore
                                    ? store.loadMore
                                    : null,
                                child: Text(
                                  state.error ?? AppStrings.of(context, state.canLoadMore ? 'loadMore' : 'noMore'),
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
