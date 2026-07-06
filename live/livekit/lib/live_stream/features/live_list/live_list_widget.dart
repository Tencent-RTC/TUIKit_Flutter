import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tuikit_atomic_x/atomicx.dart' hide RoomType;

import '../../../common/index.dart';
import '../../../tencent_live_uikit.dart';
import '../audience/pager/live_core_preview_controller.dart';
import 'live_list_preview_manager.dart';
import 'service/live_list_service.dart';
import 'widget/single_column_widget.dart';

class LiveListWidget extends StatefulWidget {
  final LiveListViewStyle style;
  final VoidCallback? onBackPressed;
  final VoidCallback? onStyleToggle;

  const LiveListWidget({
    super.key,
    this.style = LiveListViewStyle.doubleColumn,
    this.onBackPressed,
    this.onStyleToggle,
  });

  @override
  LiveListWidgetState createState() {
    return LiveListWidgetState();
  }
}

class LiveListWidgetState extends State<LiveListWidget> with RouteAware {
  late final cellWidth = (1.screenWidth - 39.width) * 0.5;
  late final cellHeight = cellWidth / _childAspectRatio;
  final int _column = 2;
  final double _childAspectRatio = 168.width / 262.height;
  late final LiveListService _liveListService = LiveListService();
  late final LiveListPreviewManager _previewManager = LiveListPreviewManager();
  StreamSubscription<String>? _toastSubscription;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  late final VoidCallback _loginListener = _onLoginChange;

  late final ValueNotifier<LiveListViewStyle> _currentStyle = ValueNotifier<LiveListViewStyle>(widget.style);

  /// Whether the user is navigating into a live room.
  /// Prevents preload from being triggered while the audience page is active.
  bool _isEnteringRoom = false;

  /// Whether the current room entry uses Overlay mode (push + immediate pop).
  /// In Overlay mode, didPopNext is a "fake" pop and should not trigger _onRefresh;
  /// the real return is signaled via onOverlayClosed.
  bool _isOverlayMode = false;

  /// Tracks current page index in single-column mode.
  int _currentPageInSingleColumn = 0;

  /// In-flight refresh future used to dedupe concurrent _onRefresh() calls.
  /// While a refresh is running, subsequent calls reuse the same Future
  /// instead of triggering another network request / preload schedule.
  Future<void>? _refreshingFuture;

  /// GlobalKeys for double-column items (index → key) to find top visible row.
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null) return;
    TUILiveKitNavigatorObserver.instance.subscribe(this, route);
  }

  @override
  void didUpdateWidget(covariant LiveListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _switchStyle(widget.style);
    }
  }

  @override
  void initState() {
    super.initState();
    _initData();
    _addListener();
    _toastSubscription = _liveListService.toastStream.listen((toast) {
      if (!mounted) return;
      makeToast(context, toast, type: ToastType.error);
    });
    GlobalFloatWindowManager.instance.setOverlayClosedCallback(() {
      _isOverlayMode = false;
      _onRefresh();
    });
    _onRefresh();
  }

  @override
  void dispose() {
    GlobalFloatWindowManager.instance.setOverlayClosedCallback(null);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _pageController.dispose();
    _previewManager.dispose();
    _currentStyle.dispose();
    _removeListener();
    _toastSubscription?.cancel();
    _liveListService.dispose();
    TUILiveKitNavigatorObserver.instance.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (_isOverlayMode) {
      // In Overlay mode the route pops immediately after pushing (fake pop).
      // The real return is handled by the onOverlayClosed callback, so skip
      // refreshing here to avoid a premature _onRefresh while the user is
      // still watching the live stream in the Overlay.
      return;
    }
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    DeviceLanguage.checkLocale(context);
    return ValueListenableBuilder<LiveListViewStyle>(
      valueListenable: _currentStyle,
      builder: (context, currentStyle, _) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: OrientationBuilder(
            builder: (context, orientation) {
              return SizedBox(
                height: 1.screenHeight,
                child: ValueListenableBuilder<List<LiveInfo>>(
                  valueListenable: _liveListService.roomListState.liveInfoList,
                  builder: (context, liveInfoList, _) {
                    if (currentStyle == LiveListViewStyle.singleColumn) {
                      return _buildSingleColumnView(liveInfoList);
                    }
                    return _buildDoubleColumnView(liveInfoList);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _switchStyle(LiveListViewStyle newStyle) {
    if (_currentStyle.value == newStyle) return;
    LiveKitLogger.info('LiveListWidget switchStyle: ${_currentStyle.value} -> $newStyle');

    newStyle == LiveListViewStyle.singleColumn ? _switchToSingleColumnStyle() : _switchToDoubleColumnStyle();
  }

  void _switchToSingleColumnStyle() {
    final liveInfoList = _liveListService.roomListState.liveInfoList.value;
    // Find the first item currently being previewed in double-column mode.
    // Falls back to the most visible item if no preview is active.
    final targetIndex = _findFirstDoublePlayingIndex(liveInfoList) ?? _findMostVisibleDoubleColumnIndex(liveInfoList);
    _previewManager.stopAllPreviews();
    _currentPageInSingleColumn = targetIndex;
    _currentStyle.value = LiveListViewStyle.singleColumn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
      // Start preview for current page.
      if (targetIndex < liveInfoList.length) {
        _previewManager.startPreview(liveInfoList[targetIndex], isMuteAudio: false);
      }
    });
  }

  void _switchToDoubleColumnStyle() {
    // Switching to double-column: stop all single-column previews.
    _previewManager.stopAllPreviews();
    final targetIndex = _currentPageInSingleColumn;
    _currentStyle.value = LiveListViewStyle.doubleColumn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scroll to approximate position of the item that was visible.
      if (targetIndex > 0 && _scrollController.hasClients) {
        final rowIndex = targetIndex ~/ 2;
        final estimatedOffset = rowIndex * (cellHeight + 8.height);
        _scrollController.jumpTo(estimatedOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ));
      }
      // Wait one more frame so the sliver finishes re-laying out after
      // jumpTo; otherwise item local offsets read by _triggerDoubleColumnPreload
      // still reflect the pre-jump positions.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerDoubleColumnPreload();
      });
    });
  }

  /// Find the most visible item index in double-column mode.
  int _findMostVisibleDoubleColumnIndex(List<LiveInfo> liveInfoList) {
    if (!_scrollController.hasClients || liveInfoList.isEmpty) return 0;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final viewportTop = scrollOffset;
    final viewportBottom = scrollOffset + viewportHeight;

    int bestIndex = 0;
    double bestVisibleArea = 0;

    for (final entry in _itemKeys.entries) {
      final key = entry.value;
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderBox) continue;
      if (!renderObject.attached) continue;

      final offset = renderObject.localToGlobal(Offset.zero,
          ancestor: _scrollController.position.context.storageContext.findRenderObject());
      final itemTop = scrollOffset + offset.dy;
      final itemBottom = itemTop + renderObject.size.height;

      final visibleTop = itemTop.clamp(viewportTop, viewportBottom);
      final visibleBottom = itemBottom.clamp(viewportTop, viewportBottom);
      final visibleArea = (visibleBottom - visibleTop).clamp(0.0, double.infinity);

      if (visibleArea > bestVisibleArea) {
        bestVisibleArea = visibleArea;
        bestIndex = entry.key;
      }
    }

    return bestIndex.clamp(0, liveInfoList.length - 1);
  }

  /// Find the index of the first item currently being previewed in double-column mode.
  /// Returns null if no double-column preview is active.
  int? _findFirstDoublePlayingIndex(List<LiveInfo> liveInfoList) {
    final playingRoomIds = _previewManager.doublePlayingRoomIds;
    if (playingRoomIds.isEmpty) return null;

    for (int i = 0; i < liveInfoList.length; i++) {
      if (playingRoomIds.contains(liveInfoList[i].liveID)) {
        return i;
      }
    }
    return null;
  }

  /// Tracks pointer-down position to distinguish tap from drag in single-column mode.
  Offset? _pointerDownPosition;

  Widget _buildSingleColumnView(List<LiveInfo> liveInfoList) {
    if (liveInfoList.isEmpty) {
      return Stack(children: [
        _buildSingleColumnEmptyWidget(),
        if (widget.onBackPressed != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 10,
            child: GestureDetector(
              onTap: widget.onBackPressed,
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (widget.onStyleToggle != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: widget.onStyleToggle,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  LiveImages.liveDoubleColumn,
                  package: Constants.pluginName,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
      ]);
    }

    return Stack(
      children: [
        Listener(
          onPointerDown: (event) {
            _pointerDownPosition = event.position;
          },
          onPointerUp: (event) {
            final downPos = _pointerDownPosition;
            _pointerDownPosition = null;
            if (downPos == null) return;
            final distance = (event.position - downPos).distance;
            // Treat as tap if finger moved less than 20 logical pixels.
            if (distance < 20) {
              _clickItem(_currentPageInSingleColumn);
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                _onSingleColumnScrollEnd(liveInfoList);
              }
              return false;
            },
            child: ValueListenableBuilder<int>(
              valueListenable: _previewManager.previewStateNotifier,
              builder: (context, _, __) {
                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: liveInfoList.length,
                  onPageChanged: (index) {
                    final previousIndex = _currentPageInSingleColumn;
                    _currentPageInSingleColumn = index;
                    // Mute the previous page's audio.
                    if (previousIndex != index && previousIndex < liveInfoList.length) {
                      final previousRoomId = liveInfoList[previousIndex].liveID;
                      final previousController = _previewManager.getPreviewController(previousRoomId);
                      previousController?.startPreview(previousRoomId, true);
                    }
                    // Start preview for the new current page.
                    if (index < liveInfoList.length) {
                      final currentLiveInfo = liveInfoList[index];
                      if (TUILiveKitNavigatorObserver.instance.enteringRoomID.value == currentLiveInfo.liveID) {
                        LiveKitLogger.info(
                            'entering room, startPreload ignore, roomId: ${currentLiveInfo.liveID}');
                      } else if (!_isCurrentRoomInFloatWindowMode(currentLiveInfo.liveID)) {
                        if (!_previewManager.isPreviewActive(currentLiveInfo.liveID)) {
                          _previewManager.startPreview(currentLiveInfo, isMuteAudio: false);
                        } else {
                          // Unmute the current page's preview.
                          final controller = _previewManager.getPreviewController(currentLiveInfo.liveID);
                          controller?.startPreview(currentLiveInfo.liveID, false);
                        }
                      } else {
                        LiveKitLogger.info(
                            'float window view is showing, startPreload ignore, roomId: ${currentLiveInfo
                                .liveID}');
                      }
                    }
                    // Load more when approaching end.
                    if (liveInfoList.length - index <= 3) {
                      _liveListService.loadMoreData();
                    }
                  },
                  itemBuilder: (context, index) {
                    return _buildSingleColumnItem(index, liveInfoList[index]);
                  },
                );
              },
            ),
          ),
        ),
        // Back button in top-left corner.
        if (widget.onBackPressed != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 10,
            child: GestureDetector(
              onTap: widget.onBackPressed,
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Style toggle button in top-right corner.
        if (widget.onStyleToggle != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: widget.onStyleToggle,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  LiveImages.liveDoubleColumn,
                  package: Constants.pluginName,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleColumnItem(int index, LiveInfo liveInfo) {
    final coverUrl = liveInfo.coverURL.isNotEmpty ? liveInfo.coverURL.split(';').first : '';

    final previewController = _previewManager.getPreviewController(liveInfo.liveID);
    final liveCoreController =
        (previewController is LiveCorePreviewController) ? previewController.coreController : null;

    return Container(
      color: LiveColors.notStandardPureBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image with blur effect (like iOS blurView).
          if (coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Image.asset(
                LiveImages.streamDefaultCover,
                fit: BoxFit.cover,
                package: Constants.pluginName,
              ),
            ),
          // Blur layer.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.white.withAlpha(50)),
              ),
            ),
          ),
          // Live preview stream.
          if (liveCoreController != null)
            LiveCoreWidget(
              key: ValueKey('preview_single_${liveInfo.liveID}_${liveCoreController.hashCode}'),
              controller: liveCoreController,
            ),
          // Single column info overlay.
          SingleColumnWidget(
            roomName: liveInfo.liveName.isNotEmpty ? liveInfo.liveName : liveInfo.liveID,
            ownerName: liveInfo.liveOwner.userName.isNotEmpty ? liveInfo.liveOwner.userName : liveInfo.liveOwner.userID,
            ownerAvatarUrl: liveInfo.liveOwner.avatarURL,
          ),
        ],
      ),
    );
  }

  void _onSingleColumnScrollEnd(List<LiveInfo> liveInfoList) {
    // Unmute the current page's preview.
    final currentIndex = _currentPageInSingleColumn;
    if (currentIndex < liveInfoList.length) {
      final roomId = liveInfoList[currentIndex].liveID;
      final controller = _previewManager.getPreviewController(roomId);
      if (controller != null) {
        // Restart with audio enabled.
        controller.startPreview(roomId, false);
      }
    }
  }

  Widget _buildDoubleColumnView(List<LiveInfo> liveInfoList) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _triggerDoubleColumnPreload();
        }
        // Handle drag-end without deceleration (matches iOS scrollViewDidEndDragging(!decelerate)).
        if (notification is UserScrollNotification && notification.direction == ScrollDirection.idle) {
          _triggerDoubleColumnPreload();
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildEmptyLiveListWidget(),
          _buildDoubleColumnLiveListGridWidget(),
          _buildLoadMoreIndicatorWidget(),
        ],
      ),
    );
  }

  /// Triggers double-column preload for the top fully visible row.
  void _triggerDoubleColumnPreload() {
    if (_currentStyle.value != LiveListViewStyle.doubleColumn) return;
    if (_isEnteringRoom) return;
    if (!_scrollController.hasClients) return;

    final liveInfoList = _liveListService.roomListState.liveInfoList.value;
    if (liveInfoList.isEmpty) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    // Use the scrollable's RenderObject as the ancestor so item offsets are
    // resolved in the scrollable's local coordinate space. In this space the
    // visible viewport is [0, viewportHeight] regardless of scrollOffset,
    // which avoids mixing global screen coordinates with scroll coordinates.
    final scrollableRenderObject = _scrollController.position.context.storageContext.findRenderObject();

    final allVisibleRoomIds = <String>[];
    final fullyVisibleItems = <_VisibleItemInfo>[];

    for (final entry in _itemKeys.entries) {
      final index = entry.key;
      final key = entry.value;
      if (index >= liveInfoList.length) continue;
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderBox || !renderObject.attached) continue;

      final offset = renderObject.localToGlobal(Offset.zero, ancestor: scrollableRenderObject);
      final itemTop = offset.dy;
      final itemBottom = itemTop + renderObject.size.height;

      // Check if the item is visible at all within the viewport.
      if (itemBottom > 0 && itemTop < viewportHeight) {
        allVisibleRoomIds.add(liveInfoList[index].liveID);
      }

      // Check if fully visible within the viewport.
      if (itemTop >= 0 && itemBottom <= viewportHeight + 1) {
        fullyVisibleItems.add(_VisibleItemInfo(
          index: index,
          roomId: liveInfoList[index].liveID,
          top: itemTop,
        ));
      }
    }

    // Find the top row among fully visible items.
    List<String> topRowRoomIds = [];
    if (fullyVisibleItems.isNotEmpty) {
      fullyVisibleItems.sort((a, b) => a.top.compareTo(b.top));
      final minTop = fullyVisibleItems.first.top;
      topRowRoomIds =
          fullyVisibleItems.where((item) => (item.top - minTop).abs() < 1).map((item) => item.roomId).toList();
    }

    final filterTopRowRoomIDs = _filterPreloadRoomIDsIfNeeded(topRowRoomIds);

    _previewManager.preloadTopRow(
      topRowRoomIds: filterTopRowRoomIDs,
      allVisibleRoomIds: allVisibleRoomIds,
    );
  }

  List<String> _filterPreloadRoomIDsIfNeeded(List<String> preloadRoomIDs) {
    final enteringID = TUILiveKitNavigatorObserver.instance.enteringRoomID.value;
    if (enteringID.isNotEmpty && preloadRoomIDs.contains(enteringID)) {
      preloadRoomIDs.remove(enteringID);
      LiveKitLogger.info('entering room, startPreload ignore, roomId: $enteringID');
    }

    final currentLiveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (preloadRoomIDs.contains(currentLiveID)) {
      preloadRoomIDs.remove(currentLiveID);
      LiveKitLogger.info('has entered same room, startPreload ignore, roomId: $currentLiveID');
    }
    return preloadRoomIDs;
  }

  /// Ensures the current page's preview is active and unmuted in single-column mode.
  ///
  /// If no preview is active for the current page (e.g., after _onRefresh stopped
  /// all previews), starts the preview and notifies via [previewStateNotifier]
  /// so the [ValueListenableBuilder] wrapping the PageView rebuilds — allowing
  /// [_buildSingleColumnItem] to pick up the newly created controller and mount
  /// [LiveCoreWidget] in the same build pass.
  ///
  /// If a preview is already active, just unmutes it.
  void _triggerSingleColumnPreload() {
    if (_currentStyle.value != LiveListViewStyle.singleColumn) return;
    if (_isEnteringRoom) return;

    final liveInfoList = _liveListService.roomListState.liveInfoList.value;
    if (liveInfoList.isEmpty) return;

    final currentIndex = _currentPageInSingleColumn;
    if (currentIndex >= liveInfoList.length) return;

    final roomId = liveInfoList[currentIndex].liveID;

    if (TUILiveKitNavigatorObserver.instance.enteringRoomID.value == roomId) {
      LiveKitLogger.info('entering room, startPreload ignore, roomId: $roomId');
      return;
    }

    if (_isCurrentRoomInFloatWindowMode(roomId)) {
      LiveKitLogger.info('float window view is showing, startPreload ignore, roomId: $roomId');
      return;
    }

    if (_previewManager.isPreviewActive(roomId)) {
      // Preview exists, just ensure audio is unmuted.
      final controller = _previewManager.getPreviewController(roomId);
      controller?.startPreview(roomId, false);
    } else {
      // No active preview — start preview, which will trigger
      // previewStateNotifier change and cause the PageView to rebuild.
      _previewManager.startPreview(liveInfoList[currentIndex], isMuteAudio: false);
    }
  }

  bool _isCurrentRoomInFloatWindowMode(String roomId) {
    if (!GlobalFloatWindowManager.instance.isFloating()) {
      return false;
    }
    return GlobalFloatWindowManager.instance.state.roomId.value == roomId;
  }

  void _initData() {
    _scrollController.addListener(_scrollListener);
    _onLoginChange();
  }

  void _addListener() {
    LoginStore.shared.addListener(_loginListener);
  }

  void _removeListener() {
    LoginStore.shared.removeListener(_loginListener);
  }

  void _onLoginChange() {
    if (LoginStore.shared.loginState.loginStatus == LoginStatus.logined) {
      _onRefresh();
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _liveListService.loadMoreData();
    }
  }

  Future<void> _onRefresh() {
    // Dedupe: if a refresh is already in flight, reuse the same Future.
    if (_refreshingFuture != null) {
      return _refreshingFuture!;
    }
    final future = _doRefresh();
    _refreshingFuture = future;
    future.whenComplete(() {
      // Only clear when the cleared future is still the latest one.
      if (identical(_refreshingFuture, future)) {
        _refreshingFuture = null;
      }
    });
    return future;
  }

  Future<void> _doRefresh() async {
    if (TUILiveKitNavigatorObserver.instance.enteringRoomID.value.isNotEmpty) return;
    _previewManager.stopAllPreviews();
    await _liveListService.refreshFetchList();
    if (!mounted) return;
    // After refresh, trigger preload based on current view style.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentStyle.value == LiveListViewStyle.singleColumn) {
        _triggerSingleColumnPreload();
      } else {
        _triggerDoubleColumnPreload();
      }
    });
  }

  void _clickItem(int index) async {
    if (_isEnteringRoom) return;

    final liveInfo = _liveListService.roomListState.liveInfoList.value[index];
    final roomType = LiveIdentityGenerator.instance.getIDType(liveInfo.liveID);
    _isOverlayMode = GlobalFloatWindowManager.instance.isEnableFloatWindowFeature();

    _preventPreload();
    _isEnteringRoom = true;
    if (roomType == RoomType.voice) {
      await TUILiveKitNavigatorObserver.instance.enterVoiceRoomPage(context, liveInfo);
    } else {
      await TUILiveKitNavigatorObserver.instance.enterLiveRoomPage(context, liveInfo);
    }
    _isEnteringRoom = false;
    _allowPreload();
  }

  void _preventPreload() {
    _previewManager.setBlocked(true);
    _previewManager.stopAllPreviews();
  }

  void _allowPreload() {
    _previewManager.setBlocked(false);
  }

  Widget _buildSingleColumnEmptyWidget() {
    return Center(
      child: Text(LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
          style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128))),
    );
  }

  Widget _buildDoubleColumnLiveListGridWidget() {
    return ValueListenableBuilder(
      valueListenable: _liveListService.roomListState.liveInfoList,
      builder: (BuildContext context, value, Widget? child) {
        return ValueListenableBuilder<int>(
          valueListenable: _previewManager.previewStateNotifier,
          builder: (context, _, __) {
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: _childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  // Ensure a GlobalKey exists for this index.
                  _itemKeys.putIfAbsent(index, () => GlobalKey());
                  return Padding(
                    key: _itemKeys[index],
                    padding: EdgeInsets.only(
                      left: index % _column == 0 ? 16.width : 3.5.width,
                      right: index % _column == 1 ? 16.width : 3.5.width,
                      top: 8.height,
                    ),
                    child: _buildDoubleColumnItemWidget(index),
                  );
                },
                childCount: _liveListService.roomListState.liveInfoList.value.length,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoubleColumnItemWidget(int index) {
    final item = _liveListService.roomListState.liveInfoList.value[index];
    final url =
        _isValidUrl(item.coverURL.split(';').first) ? item.coverURL.split(';').first : Constants.defaultCoverUrl;

    // Check if this item has an active preview.
    final previewController = _previewManager.getPreviewController(item.liveID);
    final liveCoreController =
        (previewController is LiveCorePreviewController) ? previewController.coreController : null;

    return GestureDetector(
      onTap: () {
        _clickItem(index);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12.radius)),
        child: SizedBox(
          width: cellWidth,
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) {
                    return Image.asset(LiveImages.streamDefaultCover, fit: BoxFit.cover, package: Constants.pluginName);
                  },
                  errorWidget: (context, url, error) {
                    return Image.asset(LiveImages.streamDefaultCover, fit: BoxFit.cover, package: Constants.pluginName);
                  },
                ),
              ),
              // Live preview overlay (only when preloading).
              // Wrapped in IgnorePointer so the native PlatformView inside
              // LiveCoreWidget does not consume touch events, allowing the
              // outer GestureDetector's onTap to fire.
              if (liveCoreController != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: LiveCoreWidget(controller: liveCoreController),
                  ),
                ),
              // Watching count.
              Positioned(
                left: 8.width,
                top: 6.height,
                child: Row(
                  children: [
                    SizedBox(
                      height: 8.radius,
                      width: 8.radius,
                      child: Image.asset(
                        fit: BoxFit.fill,
                        LiveImages.roomListItemLiveStatus,
                        package: Constants.pluginName,
                      ),
                    ),
                    SizedBox(width: 5.width),
                    Text(
                      LiveKitLocalizations.of(Global.appContext())!
                          .livelist_viewed_audience_count
                          .replaceAll('xxx', "${item.totalViewerCount}"),
                      style: const TextStyle(
                        color: LiveColors.designStandardFlowkitWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Room name.
              Positioned(
                left: 8.width,
                bottom: 32.height,
                right: 8.width,
                child: Container(
                  constraints: BoxConstraints(maxHeight: 26.height, maxWidth: 152.width),
                  child: Text(
                    item.liveName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: LiveColors.designStandardFlowkitWhite.withAlpha(0xE6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Owner avatar + name.
              Positioned(
                left: 8.width,
                bottom: 10.height,
                right: 8.width,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8.radius)),
                      child: SizedBox(
                        height: 16.radius,
                        width: 16.radius,
                        child: Image.network(
                          item.liveOwner.avatarURL,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              fit: BoxFit.fill,
                              LiveImages.defaultAvatar,
                              package: Constants.pluginName,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 4.width),
                    Container(
                      constraints: BoxConstraints(maxWidth: 132.width, maxHeight: 20.height),
                      child: Text(
                        item.liveOwner.userName.isNotEmpty ? item.liveOwner.userName : item.liveOwner.userID,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LiveColors.designStandardFlowkitWhite.withAlpha(0x8C),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicatorWidget() {
    return ValueListenableBuilder<List<LiveInfo>>(
      valueListenable: _liveListService.roomListState.liveInfoList,
      builder: (BuildContext context, liveInfoList, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _liveListService.roomListState.isHaveMoreData,
          builder: (BuildContext context, hasMoreData, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _liveListService.roomListState.loadStatus,
              builder: (BuildContext context, isLoading, _) {
                Widget footer;
                if (hasMoreData && isLoading) {
                  footer = Container(
                    padding: EdgeInsets.all(16.radius),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                } else if (!hasMoreData && liveInfoList.isNotEmpty) {
                  // Show "no more data" hint when the list
                  // has reached the bottom and there is nothing left to load.
                  footer = Container(
                    padding: EdgeInsets.symmetric(vertical: 16.height),
                    alignment: Alignment.center,
                    child: Text(
                      LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
                      style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128)),
                    ),
                  );
                } else {
                  footer = SizedBox(height: 12.height);
                }
                return SliverToBoxAdapter(child: footer);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyLiveListWidget() {
    return ValueListenableBuilder(
      valueListenable: _liveListService.roomListState.refreshStatus,
      builder: (BuildContext context, value, Widget? child) {
        final isShow = _liveListService.roomListState.liveInfoList.value.isEmpty &&
            !_liveListService.roomListState.refreshStatus.value;
        if (!isShow) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
                style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128))),
          ),
        );
      },
    );
  }

  bool _isValidUrl(String urlString) {
    try {
      Uri parsedUri = Uri.parse(urlString);
      return parsedUri.scheme.isNotEmpty && parsedUri.host.isNotEmpty;
    } on FormatException {
      return false;
    }
  }
}

/// Helper class for tracking visible items during double-column preload.
class _VisibleItemInfo {
  final int index;
  final String roomId;
  final double top;

  _VisibleItemInfo({required this.index, required this.roomId, required this.top});
}
