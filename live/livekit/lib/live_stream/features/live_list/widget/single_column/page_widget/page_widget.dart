import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

typedef PageItemBuilder<T> = Widget Function(
    BuildContext context,
    T item,
    int index,
    );

typedef PageLifecycleCallback = void Function(int index);

class PageWidget<T> extends StatefulWidget {
  final List<T> items;

  final PageItemBuilder<T> itemBuilder;

  final Axis scrollDirection;

  final double slideInThreshold;

  final PageController? controller;

  final bool scrollEnabled;

  final PageLifecycleCallback? onPageWillSlideIn;

  final PageLifecycleCallback? onPageDidSlideIn;

  final PageLifecycleCallback? onPageWillSlideOut;

  final PageLifecycleCallback? onPageDidSlideOut;

  final PageLifecycleCallback? onPageSlideInCancelled;

  final PageLifecycleCallback? onPageSlideOutCancelled;

  const PageWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.slideInThreshold = 0.1,
    this.controller,
    this.scrollEnabled = true,
    this.onPageWillSlideIn,
    this.onPageDidSlideIn,
    this.onPageWillSlideOut,
    this.onPageDidSlideOut,
    this.onPageSlideInCancelled,
    this.onPageSlideOutCancelled,
  });

  @override
  State<PageWidget<T>> createState() => _PageWidgetState<T>();
}

class _PageWidgetsBindingObserver with WidgetsBindingObserver {
  AppLifecycleState appLifecycleState = AppLifecycleState.detached;

  void register(WidgetsBinding binding) => binding.addObserver(this);

  void unRegister(WidgetsBinding binding) => binding.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLifecycleState = state;
  }
}

class _PageWidgetState<T> extends State<PageWidget<T>> {
  _PageWidgetsBindingObserver? _pageWidgetsBindingObserver;
  late PageController _pageController;
  bool _ownController = false;
  double _slideInThreshold = 0;
  int _currentIndex = 0;

  int? _pendingSlideInIndex;

  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    LiveKitLogger.info("slideInThreshold=${widget.slideInThreshold}");
    _pageWidgetsBindingObserver = Platform.isIOS ? _PageWidgetsBindingObserver() : null;
    _pageWidgetsBindingObserver?.register(WidgetsBinding.instance);
    _slideInThreshold = widget.slideInThreshold.clamp(0.0, 1.0);
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant PageWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController(widget.controller);
    }
    if (oldWidget.items.length != widget.items.length) {
      _reconcilePendingAfterItemsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: widget.scrollDirection,
        physics: widget.scrollEnabled ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        onPageChanged: _handlePageChanged,
        itemBuilder: (context, index) {
          return widget.itemBuilder(context, widget.items[index], index);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageWidgetsBindingObserver?.unRegister(WidgetsBinding.instance);
    _detachController();
    super.dispose();
  }

  void _attachController(PageController? external) {
    _pageController = external ?? PageController();
    _ownController = external == null;
    _currentIndex = _pageController.initialPage;
    _pageController.addListener(_onPageScroll);
  }

  void _detachController() {
    _pageController.removeListener(_onPageScroll);
    if (_ownController) {
      _pageController.dispose();
    }
  }

  void _reconcilePendingAfterItemsChanged() {
    final length = widget.items.length;
    final pending = _pendingSlideInIndex;
    if (pending != null && (pending < 0 || pending >= length)) {
      if (_currentIndex >= 0 && _currentIndex < length) {
        widget.onPageSlideOutCancelled?.call(_currentIndex);
      }
      widget.onPageSlideInCancelled?.call(pending);
      _pendingSlideInIndex = null;
    }
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == null) return;

    if (!_isUserDragging) return;

    _detectSlideIntent(page);
  }

  void _detectSlideIntent(double page) {
    final delta = page - _currentIndex;

    if (delta.abs() < _slideInThreshold) {
      _cancelPendingIfAny();
      return;
    }

    final targetIndex = delta > 0 ? _currentIndex + 1 : _currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= widget.items.length) return;

    if (_pendingSlideInIndex == targetIndex) return;

    _pendingSlideInIndex = targetIndex;
    widget.onPageWillSlideOut?.call(_currentIndex);
    widget.onPageWillSlideIn?.call(targetIndex);
  }

  void _cancelPendingIfAny() {
    final pending = _pendingSlideInIndex;
    if (pending == null) return;
    _pendingSlideInIndex = null;
    if (pending < 0 || pending >= widget.items.length) return;
    if (_currentIndex < 0 || _currentIndex >= widget.items.length) return;
    widget.onPageSlideOutCancelled?.call(_currentIndex);
    widget.onPageSlideInCancelled?.call(pending);
  }

  void _handlePageChanged(int index) {
    final appStateName = _pageWidgetsBindingObserver?.appLifecycleState.name ?? '';
    LiveKitLogger.info("handlePageChanged, appStateName=$appStateName, index=$index, currentIndex=$_currentIndex");
    final oldIndex = _currentIndex;
    if (appStateName == 'inactive' && oldIndex != index) {
      _pageController.jumpToPage(oldIndex);
      LiveKitLogger.warning("Break page changed and jump back from $index to $oldIndex");
      return;
    }
    if (oldIndex == index) return;
    _currentIndex = index;

    final pending = _pendingSlideInIndex;
    if (pending != null && pending != index) {
      if (oldIndex >= 0 && oldIndex < widget.items.length) {
        widget.onPageSlideOutCancelled?.call(oldIndex);
      }
      if (pending >= 0 && pending < widget.items.length) {
        widget.onPageSlideInCancelled?.call(pending);
      }
    }
    _pendingSlideInIndex = null;

    if (oldIndex >= 0 && oldIndex < widget.items.length) {
      widget.onPageDidSlideOut?.call(oldIndex);
    }
    if (index >= 0 && index < widget.items.length) {
      widget.onPageDidSlideIn?.call(index);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isUserDragging = notification.dragDetails != null;
    } else if (notification is ScrollUpdateNotification) {
      _isUserDragging = notification.dragDetails != null;
    } else if (notification is ScrollEndNotification) {
      _isUserDragging = false;
      _handleScrollEnd();
    }
    return false;
  }

  void _handleScrollEnd() {
    if (!_pageController.hasClients) {
      _pendingSlideInIndex = null;
      return;
    }
    final page = _pageController.page;
    if (page == null) {
      _pendingSlideInIndex = null;
      return;
    }
    final landedIndex = page.round();
    if (landedIndex == _currentIndex) {
      _cancelPendingIfAny();
    }
  }
}
