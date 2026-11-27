import 'dart:async';
import 'dart:io' show Platform;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../common/theme/live_theme.dart';
import '../../player/player_view.dart';
import 'page_cell.dart';

class LiveListViewController {
  _PagerViewState? _state;
  List<LiveInfo>? _pendingData;
  final List<LiveInfo> _pendingAppendedData = <LiveInfo>[];

  bool get isAttached => _state != null;

  void setData(List<LiveInfo> list) {
    final _PagerViewState? state = _state;
    if (state != null) {
      state._setData(list);
      return;
    }
    _pendingData = List<LiveInfo>.of(list);
    _pendingAppendedData.clear();
  }

  void appendData(List<LiveInfo> list) {
    if (list.isEmpty) return;
    final _PagerViewState? state = _state;
    if (state != null) {
      state._appendData(list);
      return;
    }
    _pendingAppendedData.addAll(list);
  }

  void _attach(_PagerViewState state) {
    _state = state;
    final List<LiveInfo>? pendingData = _pendingData;
    final List<LiveInfo> pendingAppendedData =
        List<LiveInfo>.of(_pendingAppendedData);
    _pendingData = null;
    _pendingAppendedData.clear();
    if (pendingData != null) {
      state._setData(pendingData);
    }
    if (pendingAppendedData.isNotEmpty) {
      state._appendData(pendingAppendedData);
    }
  }

  void _detach(_PagerViewState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }
}

enum _SwipeBehavior {
  previewOnly,
  autoEnterRoom,
}

class PagerView extends StatefulWidget {
  const PagerView({
    super.key,
    this.controller,
    this.initialLiveID = '',
    this.onLoadMore,
  });

  final LiveListViewController? controller;
  final String initialLiveID;
  final VoidCallback? onLoadMore;

  @override
  State<PagerView> createState() => _PagerViewState();
}

class _PagerWidgetsBindingObserver with WidgetsBindingObserver {
  AppLifecycleState appLifecycleState = AppLifecycleState.resumed;

  void register(WidgetsBinding binding) {
    appLifecycleState = binding.lifecycleState ?? AppLifecycleState.resumed;
    binding.addObserver(this);
  }

  void unregister(WidgetsBinding binding) {
    binding.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLifecycleState = state;
  }
}

class _PagerViewState extends State<PagerView> {
  static const int _loadMoreThreshold = 2;
  static const double _slideInThreshold = 0.1;

  final Map<String, PageCell> _pageCells = <String, PageCell>{};
  final PageController _pageController = PageController();

  _PagerWidgetsBindingObserver? _bindingObserver;
  List<LiveInfo> _liveList = <LiveInfo>[];
  List<LiveInfo>? _deferredData;
  final List<LiveInfo> _deferredAppendedData = <LiveInfo>[];
  _SwipeBehavior _swipeBehavior = _SwipeBehavior.previewOnly;
  bool _swipeDisabledByJoin = false;
  bool _swipeDisabledByCoGuest = false;
  bool _swipeDisabledByTransition = false;
  PageCell? _currentPageCell;
  VoidCallback? _currentStatusListener;
  VoidCallback? _currentJoinListener;
  EdgeInsets _safeAreaInsets = EdgeInsets.zero;
  int _currentIndex = 0;
  PageCell? _pendingSlideInPageCell;
  bool _willSlideCallbacksDispatched = false;
  bool _initialCallbacksDispatched = false;
  int _joinOperationID = 0;
  int _dataOperationID = 0;
  int _pageTransitionID = 0;
  PageCell? _joiningPageCell;
  int? _suppressedPageChangedIndex;

  @override
  void initState() {
    super.initState();
    _bindingObserver = Platform.isIOS ? _PagerWidgetsBindingObserver() : null;
    _bindingObserver?.register(WidgetsBinding.instance);
    _pageController.addListener(_handleScrollUpdate);
    _prependInitialLiveIDIfNeeded();
    widget.controller?._attach(this);
    _scheduleInitialCallbacks();
  }

  @override
  void didUpdateWidget(covariant PagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.initialLiveID != widget.initialLiveID) {
      _resetInitialLiveID();
    }
  }

  void _resetInitialLiveID() {
    _detachCurrentStatusListener();
    _stopPlaybackAndLeaveRoom();
    _liveList = <LiveInfo>[];
    _currentIndex = 0;
    _initialCallbacksDispatched = false;
    _prependInitialLiveIDIfNeeded();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _suppressedPageChangedIndex = 0;
        _pageController.jumpToPage(0);
      }
      _scheduleInitialCallbacks();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EdgeInsets newInsets = MediaQuery.paddingOf(context);
    if (newInsets == _safeAreaInsets) return;
    _safeAreaInsets = newInsets;
    _updateVisibleItemSafeAreas();
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _bindingObserver?.unregister(WidgetsBinding.instance);
    _pageController.removeListener(_handleScrollUpdate);
    _detachCurrentStatusListener();
    _stopPlaybackAndLeaveRoom();
    _pageController.dispose();
    super.dispose();
  }

  void _setData(List<LiveInfo> list) {
    if (!mounted) return;
    if (_isPageScrolling) {
      _dataOperationID++;
      _deferredData = List<LiveInfo>.of(list);
      _deferredAppendedData.clear();
      return;
    }
    _applyData(list);
  }

  void _applyData(List<LiveInfo> list) {
    final int operationID = ++_dataOperationID;
    final PageCell? previousPageCell = _currentPageCell;
    final int previousIndex = _currentIndex;
    final List<LiveInfo> merged = _mergeWithInitialLiveID(_deduplicated(list));
    _cancelPendingIfAny();
    setState(() {
      _liveList = merged;
    });
    final Future<void>? previousRelease = _prunePageCells(previousPageCell);
    _rebindPageCells();
    _resyncCurrentPageAfterDataChange(
      previousPageCell,
      previousIndex,
      operationID,
      previousRelease,
    );
  }

  void _appendData(List<LiveInfo> list) {
    if (!mounted) return;
    if (_isPageScrolling) {
      _deferredAppendedData.addAll(list);
      return;
    }
    _applyAppendedData(list);
  }

  void _applyAppendedData(List<LiveInfo> list) {
    final List<LiveInfo> deduplicated = _deduplicated(list);
    if (deduplicated.isEmpty) return;

    final Map<String, int> existingIndexByID = <String, int>{
      for (int index = 0; index < _liveList.length; index++)
        _liveList[index].liveID: index,
    };
    final List<LiveInfo> next = List<LiveInfo>.of(_liveList);
    bool changed = false;
    for (final LiveInfo info in deduplicated) {
      final int? existingIndex = existingIndexByID[info.liveID];
      if (existingIndex == null) {
        existingIndexByID[info.liveID] = next.length;
        next.add(info);
      } else {
        next[existingIndex] = info;
        _pageCells[info.liveID]?.updateData(info);
      }
      changed = true;
    }
    if (!changed) return;
    setState(() {
      _liveList = next;
    });
    _handleItemsChanged();
  }

  bool get _isPageScrolling {
    return _pageController.hasClients &&
        _pageController.position.isScrollingNotifier.value;
  }

  void _flushDeferredData() {
    if (!mounted || _isPageScrolling) return;
    final List<LiveInfo>? data = _deferredData;
    final List<LiveInfo> appended = List<LiveInfo>.of(_deferredAppendedData);
    _deferredData = null;
    _deferredAppendedData.clear();
    if (data != null) {
      _applyData(data);
    }
    if (appended.isNotEmpty) {
      _applyAppendedData(appended);
    }
  }

  void _prependInitialLiveIDIfNeeded() {
    final String initialLiveID = widget.initialLiveID;
    if (initialLiveID.isEmpty) return;
    final List<LiveInfo> currentList =
        LiveListStore.shared.liveState.liveList.value;
    LiveInfo? initialLiveInfo;
    for (final LiveInfo info in currentList) {
      if (info.liveID == initialLiveID) {
        initialLiveInfo = info;
        break;
      }
    }
    initialLiveInfo ??= LiveInfo()..liveID = initialLiveID;
    _liveList = <LiveInfo>[initialLiveInfo];
  }

  List<LiveInfo> _mergeWithInitialLiveID(List<LiveInfo> list) {
    final String liveID = widget.initialLiveID;
    if (liveID.isEmpty) return list;
    final int index = list.indexWhere((LiveInfo info) => info.liveID == liveID);
    if (index < 0) {
      return <LiveInfo>[_placeholderLiveInfo(liveID), ...list];
    }
    final List<LiveInfo> reordered = List<LiveInfo>.of(list);
    final LiveInfo target = reordered.removeAt(index);
    reordered.insert(0, target);
    return reordered;
  }

  LiveInfo _placeholderLiveInfo(String liveID) {
    final List<LiveInfo> currentList =
        LiveListStore.shared.liveState.liveList.value;
    LiveInfo? initialLiveInfo;
    for (final LiveInfo info in currentList) {
      if (info.liveID == liveID) {
        initialLiveInfo = info;
        break;
      }
    }
    initialLiveInfo ??= LiveInfo()..liveID = liveID;
    return initialLiveInfo;
  }

  List<LiveInfo> _deduplicated(List<LiveInfo> list) {
    final Set<String> liveIDs = <String>{};
    return list.where((LiveInfo info) => liveIDs.add(info.liveID)).toList();
  }

  Future<void>? _prunePageCells(PageCell? previousPageCell) {
    Future<void>? previousRelease;
    final Set<String> liveIDs = <String>{
      for (final LiveInfo info in _liveList) info.liveID,
    };
    final List<String> removedLiveIDs = _pageCells.keys
        .where((String liveID) => !liveIDs.contains(liveID))
        .toList();
    for (final String liveID in removedLiveIDs) {
      final PageCell? pageCell = _pageCells.remove(liveID);
      if (pageCell == null) continue;
      if (identical(_pendingSlideInPageCell, pageCell)) {
        _pendingSlideInPageCell = null;
        _willSlideCallbacksDispatched = false;
      }
      if (identical(_currentPageCell, pageCell)) {
        _detachCurrentStatusListener();
        _currentPageCell = null;
      }
      _invalidateJoinIfNeeded(pageCell);
      final Future<void> release = pageCell.dispose();
      if (identical(previousPageCell, pageCell)) {
        previousRelease = release;
      } else {
        unawaited(release);
      }
    }
    return previousRelease;
  }

  void _rebindPageCells() {
    for (final LiveInfo info in _liveList) {
      _pageCells[info.liveID]?.updateData(info);
    }
  }

  void _setSwipeBehavior(_SwipeBehavior behavior) {
    if (_swipeBehavior == behavior) return;
    _swipeBehavior = behavior;
    _applyJoinLiveEntranceEnabled();
  }

  void _applyJoinLiveEntranceEnabled() {
    final bool enabled = _swipeBehavior == _SwipeBehavior.previewOnly;
    for (final PageCell pageCell in _pageCells.values) {
      pageCell.setJoinLiveEntranceEnabled(enabled);
    }
  }

  PageCell _pageCellFor(LiveInfo liveInfo) {
    return _pageCells.putIfAbsent(liveInfo.liveID, () {
      late final PageCell pageCell;
      pageCell = PageCell(
        liveInfo: liveInfo,
        onJoinLiveClicked: () => _handleManualJoinSucceeded(pageCell),
        onCloseClicked: _handleClose,
      );
      pageCell.setJoinLiveEntranceEnabled(
          _swipeBehavior == _SwipeBehavior.previewOnly);
      pageCell.updateSafeArea(_safeAreaInsets);
      return pageCell;
    });
  }

  void _handleManualJoinSucceeded(PageCell pageCell) {
    final bool isCurrent = identical(_currentPageCell, pageCell);
    final bool isCached = identical(_pageCells[pageCell.liveID], pageCell);
    if (!isCurrent || !isCached) {
      pageCell.stopPreview();
      unawaited(pageCell.leaveChannelIfNeeded());
      return;
    }
    _setSwipeBehavior(_SwipeBehavior.autoEnterRoom);
  }

  PageCell? _pageCellAt(int index) {
    if (index < 0 || index >= _liveList.length) return null;
    return _pageCellFor(_liveList[index]);
  }

  void _observeCurrentPlayerStatus(PageCell pageCell) {
    _detachCurrentStatusListener();
    _currentPageCell = pageCell;

    void listener() {
      if (!mounted || !identical(_currentPageCell, pageCell)) return;
      final bool isCoGuest = pageCell.status == PlayerStatus.coGuest;
      if (isCoGuest == _swipeDisabledByCoGuest) return;
      _swipeDisabledByCoGuest = isCoGuest;
      _updateSwipeEnabled();
    }

    void joinListener() {
      if (!mounted || !identical(_currentPageCell, pageCell)) return;
      final bool isJoining = pageCell.controller.joinInProgress.value;
      if (isJoining == _swipeDisabledByJoin) return;
      _swipeDisabledByJoin = isJoining;
      _updateSwipeEnabled();
    }

    _currentStatusListener = listener;
    _currentJoinListener = joinListener;
    pageCell.controller.status.addListener(listener);
    pageCell.controller.joinInProgress.addListener(joinListener);
    listener();
    joinListener();
  }

  void _detachCurrentStatusListener() {
    final PageCell? pageCell = _currentPageCell;
    final VoidCallback? statusListener = _currentStatusListener;
    final VoidCallback? joinListener = _currentJoinListener;
    if (pageCell != null && statusListener != null) {
      pageCell.controller.status.removeListener(statusListener);
    }
    if (pageCell != null && joinListener != null) {
      pageCell.controller.joinInProgress.removeListener(joinListener);
    }
    _currentStatusListener = null;
    _currentJoinListener = null;
    _swipeDisabledByJoin = false;
    _swipeDisabledByCoGuest = false;
  }

  bool get _scrollEnabled => !(_swipeDisabledByJoin ||
      _swipeDisabledByCoGuest ||
      _swipeDisabledByTransition);

  void _updateSwipeEnabled() {
    if (mounted) setState(() {});
  }

  void _stopPlaybackAndLeaveRoom() {
    _joinOperationID++;
    _dataOperationID++;
    _pageTransitionID++;
    _joiningPageCell = null;
    for (final PageCell pageCell in _pageCells.values) {
      unawaited(pageCell.dispose());
    }
    _pageCells.clear();
    _currentPageCell = null;
    _pendingSlideInPageCell = null;
    _swipeDisabledByJoin = false;
    _swipeDisabledByCoGuest = false;
    _swipeDisabledByTransition = false;
    _swipeBehavior = _SwipeBehavior.previewOnly;
  }

  void _updateVisibleItemSafeAreas() {
    for (final PageCell pageCell in _pageCells.values) {
      pageCell.updateSafeArea(_safeAreaInsets);
    }
  }

  void _handleClose() {
    _setSwipeBehavior(_SwipeBehavior.previewOnly);
  }

  void _handleWillSlideIn(int index) {
    _pageCellAt(index)?.startPreview();
  }

  void _handleDidSlideIn(int index) {
    final PageCell? pageCell = _pageCellAt(index);
    if (pageCell == null) return;
    _observeCurrentPlayerStatus(pageCell);
    pageCell.updateSafeArea(_safeAreaInsets);
    if (_swipeBehavior == _SwipeBehavior.autoEnterRoom) {
      _joinCurrentPageCell(pageCell);
    }
    final int remainingCount = _liveList.length - 1 - index;
    if (remainingCount <= _loadMoreThreshold) {
      widget.onLoadMore?.call();
    }
  }

  Future<void> _joinCurrentPageCell(PageCell pageCell) async {
    if (identical(_joiningPageCell, pageCell)) return;
    final PageCell? previousJoiningPageCell = _joiningPageCell;
    if (previousJoiningPageCell != null) {
      _invalidateJoinIfNeeded(previousJoiningPageCell);
    }
    final int operationID = ++_joinOperationID;
    _joiningPageCell = pageCell;
    _swipeDisabledByJoin = true;
    _updateSwipeEnabled();
    final LiveInfo? liveInfo = await pageCell.joinChannel();
    if (!mounted || operationID != _joinOperationID) {
      if (liveInfo != null) {
        pageCell.stopPreview();
        unawaited(pageCell.leaveChannelIfNeeded());
      }
      return;
    }
    _joiningPageCell = null;
    _swipeDisabledByJoin = false;
    _updateSwipeEnabled();
    final bool isCurrent = identical(_currentPageCell, pageCell);
    final bool isCached = identical(_pageCells[pageCell.liveID], pageCell);
    if (liveInfo == null || !isCurrent || !isCached) {
      if (liveInfo != null) {
        pageCell.stopPreview();
        unawaited(pageCell.leaveChannelIfNeeded());
      }
      return;
    }
    if (pageCell.liveID != liveInfo.liveID) return;
    final int liveIndex = _liveList.indexWhere(
      (LiveInfo info) => info.liveID == liveInfo.liveID,
    );
    if (liveIndex < 0) {
      pageCell.stopPreview();
      unawaited(pageCell.leaveChannelIfNeeded());
      return;
    }
    setState(() {
      _liveList[liveIndex] = liveInfo;
    });
    pageCell.updateData(liveInfo);
  }

  void _invalidateJoinIfNeeded(PageCell pageCell) {
    if (!identical(_joiningPageCell, pageCell)) return;
    _joinOperationID++;
    _joiningPageCell = null;
    _swipeDisabledByJoin = false;
    _updateSwipeEnabled();
  }

  Future<void> _handlePageCellDidSlideOut(PageCell pageCell) async {
    _invalidateJoinIfNeeded(pageCell);
    pageCell.stopPreview();
    if (identical(_currentPageCell, pageCell)) {
      _detachCurrentStatusListener();
      _currentPageCell = null;
    }
    if (_swipeBehavior == _SwipeBehavior.autoEnterRoom) {
      await pageCell.leaveChannelIfNeeded();
    }
  }

  void _handleItemsChanged() {
    if (_liveList.isEmpty) {
      _cancelPendingIfAny();
      _currentIndex = 0;
      _initialCallbacksDispatched = false;
      return;
    }
    _scheduleInitialCallbacks();
  }

  void _resyncCurrentPageAfterDataChange(
    PageCell? previousPageCell,
    int previousIndex,
    int operationID,
    Future<void>? previousRelease,
  ) {
    if (_liveList.isEmpty) {
      _pageTransitionID++;
      _currentIndex = 0;
      _initialCallbacksDispatched = false;
      _currentPageCell = null;
      _swipeDisabledByTransition = false;
      _updateSwipeEnabled();
      return;
    }
    final int targetIndex = previousIndex.clamp(0, _liveList.length - 1);
    _currentIndex = targetIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_completeDataResync(
        previousPageCell: previousPageCell,
        targetIndex: targetIndex,
        operationID: operationID,
        previousRelease: previousRelease,
      ));
    });
  }

  Future<void> _completeDataResync({
    required PageCell? previousPageCell,
    required int targetIndex,
    required int operationID,
    required Future<void>? previousRelease,
  }) async {
    if (!mounted || operationID != _dataOperationID || _liveList.isEmpty) {
      return;
    }
    final int resolvedIndex = targetIndex.clamp(0, _liveList.length - 1);
    if (_pageController.hasClients &&
        _pageController.page?.round() != resolvedIndex) {
      _suppressedPageChangedIndex = resolvedIndex;
      _pageController.jumpToPage(resolvedIndex);
    }
    final String targetLiveID = _liveList[resolvedIndex].liveID;
    final bool previousRemainsTarget = previousPageCell != null &&
        previousPageCell.liveID == targetLiveID &&
        identical(_pageCells[targetLiveID], previousPageCell);
    _swipeDisabledByTransition = true;
    _updateSwipeEnabled();
    if (previousRelease != null) {
      await previousRelease;
    } else if (!previousRemainsTarget &&
        previousPageCell != null &&
        identical(_pageCells[previousPageCell.liveID], previousPageCell)) {
      await _handlePageCellDidSlideOut(previousPageCell);
    }
    if (!mounted || operationID != _dataOperationID || _liveList.isEmpty) {
      return;
    }
    final PageCell? targetPageCell = _pageCellAt(resolvedIndex);
    if (targetPageCell == null) return;
    if (!identical(previousPageCell, targetPageCell)) {
      targetPageCell.startPreview();
      _handleDidSlideIn(resolvedIndex);
    } else if (!identical(_currentPageCell, targetPageCell)) {
      _observeCurrentPlayerStatus(targetPageCell);
    }
    _initialCallbacksDispatched = true;
    _swipeDisabledByTransition = false;
    _updateSwipeEnabled();
  }

  void _scheduleInitialCallbacks() {
    if (_initialCallbacksDispatched || _liveList.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchInitialCallbacksIfNeeded();
    });
  }

  void _dispatchInitialCallbacksIfNeeded() {
    if (!mounted || _initialCallbacksDispatched || _liveList.isEmpty) return;
    _currentIndex = _currentIndex.clamp(0, _liveList.length - 1);
    _initialCallbacksDispatched = true;
    _handleWillSlideIn(_currentIndex);
    _handleDidSlideIn(_currentIndex);
  }

  void _handleScrollUpdate() {
    if (!_pageController.hasClients || _liveList.isEmpty) return;
    final double? page = _pageController.page;
    if (page == null) return;
    final double delta = page - _currentIndex;
    if (delta.abs() < _slideInThreshold) {
      _cancelPendingIfAny();
      return;
    }
    final int targetIndex = delta > 0 ? _currentIndex + 1 : _currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= _liveList.length) return;
    final PageCell? targetPageCell = _pageCellAt(targetIndex);
    if (targetPageCell == null ||
        identical(_pendingSlideInPageCell, targetPageCell)) {
      return;
    }
    _cancelPendingIfAny();
    _pendingSlideInPageCell = targetPageCell;
    _willSlideCallbacksDispatched = true;
    targetPageCell.startPreview();
  }

  void _cancelPendingIfAny() {
    if (!_willSlideCallbacksDispatched) return;
    final PageCell? pendingPageCell = _pendingSlideInPageCell;
    _pendingSlideInPageCell = null;
    _willSlideCallbacksDispatched = false;
    pendingPageCell?.stopPreview();
  }

  void _handlePageChanged(int index) {
    if (_suppressedPageChangedIndex == index) {
      _suppressedPageChangedIndex = null;
      return;
    }
    if (_bindingObserver != null &&
        _bindingObserver!.appLifecycleState != AppLifecycleState.resumed) {
      final int previousIndex = _currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(previousIndex);
      });
      _cancelPendingIfAny();
      return;
    }
    final int previousIndex = _currentIndex;
    final PageCell? previousPageCell = _pageCellAt(previousIndex);
    final PageCell? nextPageCell = _pageCellAt(index);
    final PageCell? pendingPageCell = _pendingSlideInPageCell;
    _currentIndex = index;
    _pendingSlideInPageCell = null;
    _willSlideCallbacksDispatched = false;
    unawaited(_completePageChange(
      previousIndex: previousIndex,
      nextIndex: index,
      previousPageCell: previousPageCell,
      nextPageCell: nextPageCell,
      pendingPageCell: pendingPageCell,
    ));
  }

  Future<void> _completePageChange({
    required int previousIndex,
    required int nextIndex,
    required PageCell? previousPageCell,
    required PageCell? nextPageCell,
    required PageCell? pendingPageCell,
  }) async {
    final int transitionID = ++_pageTransitionID;
    final bool changed = previousIndex != nextIndex;
    if (changed) {
      _swipeDisabledByTransition = true;
      _updateSwipeEnabled();
    }
    if (pendingPageCell != null && !identical(pendingPageCell, nextPageCell)) {
      pendingPageCell.stopPreview();
    }
    if (changed && previousPageCell != null) {
      await _handlePageCellDidSlideOut(previousPageCell);
    }
    if (!mounted || transitionID != _pageTransitionID) return;
    if (nextPageCell != null && !identical(pendingPageCell, nextPageCell)) {
      nextPageCell.startPreview();
    }
    _handleDidSlideIn(nextIndex);
    _swipeDisabledByTransition = false;
    _updateSwipeEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LiveTheme.canvasBackground,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _flushDeferredData();
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: _scrollEnabled
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: _liveList.length,
          onPageChanged: _handlePageChanged,
          itemBuilder: (BuildContext context, int index) {
            final PageCell pageCell = _pageCellFor(_liveList[index]);
            return pageCell.build();
          },
        ),
      ),
    );
  }
}
