import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../../../../../../common/logger/logger.dart';

typedef ScrollItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

typedef OnFirstVisibleItemsChanged = void Function(int leftIndex, int rightIndex);

typedef OnScrollChanged = void Function(ScrollPosition position);

class ScrollWidget<T> extends StatefulWidget {
  final List<T> items;
  final ScrollItemBuilder<T> itemBuilder;
  final WidgetBuilder? footerBuilder;
  final double childAspectRatio;
  final OnFirstVisibleItemsChanged? onFirstVisibleItemsChanged;
  final OnScrollChanged? onScrollChanged;
  final NotificationListenerCallback<ScrollNotification>? onNotification;

  const ScrollWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.childAspectRatio,
    this.footerBuilder,
    this.onFirstVisibleItemsChanged,
    this.onScrollChanged,
    this.onNotification,
  });

  @override
  State<StatefulWidget> createState() {
    return _ScrollWidgetState<T>();
  }
}

class _ScrollWidgetState<T> extends State<ScrollWidget<T>> {
  final ScrollController _scrollController = ScrollController();
  late final VoidCallback _onScrollListener = _onScroll;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.items.isEmpty) return;
      _checkFirstVisibleItems(_scrollController);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_onScrollListener);
    _scrollController.dispose();
  }

  @override
  void didUpdateWidget(covariant ScrollWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkFirstVisibleItems(_scrollController);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification ||
            (notification is UserScrollNotification && notification.direction == ScrollDirection.idle)) {
          // Check visible items when the scroller is idle.
          _checkFirstVisibleItems(_scrollController);
        }
        return widget.onNotification?.call(notification) ?? false;
      },
      child: buildScrollView(context),
    );
  }

  Widget buildScrollView(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: widget.childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return widget.itemBuilder(context, widget.items[index], index);
            },
            childCount: widget.items.length,
          ),
        ),
        if (widget.footerBuilder != null) SliverToBoxAdapter(child: widget.footerBuilder?.call(context))
      ],
    );
  }

  void _checkFirstVisibleItems(ScrollController scrollController) {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final scrollOffset = position.pixels;
    final viewportHeight = position.viewportDimension;
    if (viewportHeight <= 0) return;

    final viewportWidth = context.size?.width ?? MediaQuery.of(context).size.width;
    final columnWidth = viewportWidth / 2;
    final itemHeight = columnWidth / widget.childAspectRatio;
    if (itemHeight <= 0) return;

    int firstVisibleRow = (scrollOffset / itemHeight).floor().clamp(0, 1 << 30);
    int delta = (scrollOffset - firstVisibleRow * itemHeight).floor().clamp(0, 1 << 30);
    if (delta > 0) firstVisibleRow++;
    int leftIndex = 2 * firstVisibleRow;
    int rightIndex = leftIndex + 1;
    LiveKitLogger.info('checkFirstVisibleItems: leftIndex=$leftIndex, rightIndex=$leftIndex');
    if (leftIndex < 0 || rightIndex >= widget.items.length) {
      LiveKitLogger.error("index is invalid!");
      return;
    }
    widget.onFirstVisibleItemsChanged?.call(leftIndex, rightIndex);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    widget.onScrollChanged?.call(_scrollController.position);
  }
}
