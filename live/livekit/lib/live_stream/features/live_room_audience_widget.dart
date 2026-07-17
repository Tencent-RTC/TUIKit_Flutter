import 'dart:async';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_navigator_observer.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/audience_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/living_widget/background_image_widget.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';

import '../../common/resources/live_theme_manager.dart';
import '../../common/widget/float_window/float_window_controller.dart';
import '../../common/widget/float_window/float_window_mode.dart';
import '../../component/beauty/live_beauty_store.dart';
import '../../component/float_window/global_float_window_manager.dart';
import '../features/audience/pager/live_core_preview_controller.dart';
import '../features/audience/pager/live_list_pager_preview_manager.dart';
import '../features/audience/pager/live_list_pager_scroll_lock_manager.dart';
import '../features/audience/pager/live_list_pager_service.dart';

class TUILiveRoomAudienceWidget extends StatefulWidget {
  final String roomId;
  final LiveInfo? liveInfo;
  final FloatWindowController? floatWindowController;

  const TUILiveRoomAudienceWidget({
    super.key,
    required this.roomId,
    this.liveInfo,
    this.floatWindowController,
  });

  @override
  State<TUILiveRoomAudienceWidget> createState() => _TUILiveRoomAudienceWidgetState();
}

class _TUILiveRoomAudienceWidgetState extends State<TUILiveRoomAudienceWidget> with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  late final LiveListPagerService _pagerService;
  late final PageController _pageController;
  late final LiveListPagerPreviewManager _previewManager;
  late final LiveListPagerScrollLockManager _scrollLockManager;
  final ValueNotifier<int> _currentPageIndex = ValueNotifier<int>(0);

  final Map<int, _PageResources> _pageResources = {};

  bool _hasEnteredThemeScene = false;

  /// Tracks where PageView is currently heading during a scroll gesture.
  /// Updated by onPageChanged (page cross-threshold), but does NOT trigger
  /// widget rebuild. Only consulted on ScrollEndNotification to decide
  /// whether a real page-switch should be committed.
  int _settlingPageIndex = 0;

  /// Whether a scroll gesture / inertial animation is currently in progress.
  /// Prevents committing a page-switch before the animation fully settles.
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveKitLogger.info('TUILiveRoomAudienceWidget initState');
    KeyMetrics.reportComponent(LiveComponentType.liveRoom);
    _changeStatusBar2LightMode();
    _pagerService = LiveListPagerService();
    _pageController = PageController(initialPage: 0);
    _previewManager = LiveListPagerPreviewManager(
      controllerFactory: LiveCorePreviewControllerFactory(),
    );
    _scrollLockManager = LiveListPagerScrollLockManager();
    assert(
      widget.liveInfo == null || widget.liveInfo!.liveID == widget.roomId,
      'liveInfo.liveID must equal roomId when both are provided',
    );
    if (widget.liveInfo != null) {
      _pagerService.initWithCurrentLive(widget.liveInfo!);
    } else {
      _pagerService.initWithRoomId(widget.roomId);
    }
    _startWakeLock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only switch theme on first entry
    if (!_hasEnteredThemeScene) {
      _hasEnteredThemeScene = true;
      LiveThemeManager.instance.enterLiveKitScene(context);
    }
  }

  @override
  void dispose() {
    LiveKitLogger.info('TUILiveRoomAudienceWidget dispose');
    // Exit LiveKit scene and restore theme
    LiveThemeManager.instance.exitLiveKitScene();
    _stopWakeLock();
    _pageController.dispose();
    _currentPageIndex.dispose();
    _previewManager.dispose();
    _scrollLockManager.dispose();
    for (final resources in _pageResources.values) {
      resources.dispose();
    }
    _pageResources.clear();
    LiveBeautyStore.shared.reset();
    BarrageDisplayController.resetState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasNotResumed = _lifecycleState != AppLifecycleState.resumed;
    _lifecycleState = state;

    // When returning from background / PIP, reconcile PageView's physical
    // position with the committed _currentPageIndex.
    //
    // ROOT CAUSE: when entering PIP, iOS/Android may dispatch a "spurious"
    // full scroll on the PageView (page 0 -> page 1) right around the moment
    // lifecycle is leaving 'resumed'. The lifecycle != resumed guard in
    // _onScrollNotification prevents us from calling leaveLive/joinLive, but
    // PageController.position.pixels has already been moved to page 1's
    // offset. After PIP exit, even though we never committed, the user would
    // see the next room because PageView renders whatever pixels points to.
    //
    // Fix: after lifecycle returns to resumed, hard-reset PageController back
    // to the last committed page in a post-frame callback. Doing it here
    // (rather than in _onScrollNotification while paused) is safer because:
    //  - Flutter engine is fully alive,
    //  - widget tree, controllers and tickers are all in known-good state,
    //  - jumpToPage's side effects (onPageChanged, ScrollEnd) are predictable.
    if (state == AppLifecycleState.resumed && wasNotResumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        final committed = _currentPageIndex.value;
        final actual = _pageController.page?.round();
        if (actual != null && actual != committed) {
          LiveKitLogger.info(
              'TUILiveRoomAudienceWidget post-resume reconcile: PageView at $actual, jump back to $committed');
          _pageController.jumpToPage(committed);
          _settlingPageIndex = committed;
          _isScrolling = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DeviceLanguage.checkLocale(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: true,
        child: ValueListenableBuilder<List<LiveInfo>>(
          valueListenable: _pagerService.state.liveInfoList,
          builder: (context, liveInfoList, _) {
            if (liveInfoList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ValueListenableBuilder<bool>(
              valueListenable: _scrollLockManager.isScrollEnabled,
              builder: (context, isScrollEnabled, _) {
                return Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: isScrollEnabled ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
                        itemCount: liveInfoList.length,
                        onPageChanged: (index) {
                          // Only record where the PageView is heading.
                          // Do NOT update _currentPageIndex here, otherwise
                          // the widget tree (AudienceWidget <-> preview page)
                          // would be swapped mid-scroll and interrupt the gesture.
                          _settlingPageIndex = index;
                          _pagerService.onPageChanged(index);
                        },
                        allowImplicitScrolling: true,
                        itemBuilder: (context, index) {
                          return _buildPage(index, liveInfoList[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(int index, LiveInfo liveInfo) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageIndex,
      builder: (context, currentIndex, _) {
        if (index != currentIndex) {
          return _buildPreviewPage(liveInfo);
        }
        // The preview for this roomId was already stopped in _commitPageChange
        // before _currentPageIndex flipped. AudienceWidget takes full ownership
        // of the LiveCoreController here.
        final resources = _getOrCreateResources(index, liveInfo);
        return AudienceWidget(
          key: ValueKey('audience_page_${liveInfo.liveID}'),
          roomId: liveInfo.liveID,
          liveCoreController: resources.liveCoreController,
          liveStreamManager: resources.liveStreamManager,
          onJoinLiveStateChanged: _onJoinLiveStateChanged,
          onCoGuestStateChanged: _onCoGuestStateChanged,
          onTapEnterFloatWindowInApp: () {
            final isLandscape = resources.liveStreamManager.floatWindowState.isLandscape.value;
            widget.floatWindowController?.setScreenOrientation(isLandscape);
            widget.floatWindowController?.onTapSwitchFloatWindowInApp(true);
          },
          onDispose: () {
            _clearInvalidResources(index);
          },
        );
      },
    );
  }

  Widget _buildPreviewPage(LiveInfo liveInfo) {
    // NOTE: do NOT call startPreview here. Starting a preview mid-scroll would
    // violate the "nothing starts/stops during scroll" rule (see q6). The
    // preview set is maintained in initState warmup and _commitPageChange.
    // If this page has no active preview (e.g. exposed briefly during a fast
    // fling through multiple pages), we simply show cover + loading.
    final previewController = _previewManager.getPreviewController(liveInfo.liveID);
    final coverUrl = liveInfo.coverURL.isNotEmpty ? liveInfo.coverURL : liveInfo.backgroundURL;

    final liveCoreController =
        (previewController is LiveCorePreviewController) ? previewController.coreController : null;

    return Container(
      color: LiveColors.notStandardPureBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl.isNotEmpty) BackgroundImageWidget(backgroundURL: coverUrl),
          if (liveCoreController != null)
            LiveCoreWidget(
              key: ValueKey('preview_pager_${liveInfo.liveID}_${liveCoreController.hashCode}'),
              controller: liveCoreController,
            ),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  _PageResources _getOrCreateResources(int index, LiveInfo liveInfo) {
    if (_pageResources.containsKey(index)) {
      return _pageResources[index]!;
    }
    final resources = _PageResources(
      liveInfo.liveID,
      showToast: (toast) => makeToast(context, toast),
    );
    if (widget.floatWindowController != null) {
      resources.addFloatWindowObserver(widget.floatWindowController!);
    }
    _pageResources[index] = resources;
    return resources;
  }

  void _clearInvalidResources(int index) {
    _pageResources.remove(index);
  }

  /// Listens to PageView scroll lifecycle so we only commit a page-switch
  /// (pause old audio, leaveLive, mount new AudienceWidget, joinLive) once
  /// the fling/drag animation has fully settled. During the scroll the widget
  /// tree for the current/adjacent pages stays stable and the gesture is
  /// not interrupted.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification && notification.direction != ScrollDirection.idle) {
      _isScrolling = true; // user`s real drag
    } else if (notification is ScrollEndNotification) {
      if (!_isScrolling) return false;
      _isScrolling = false;
      // Defensive: ignore page changes triggered while app is not in foreground.
      // PIP / background transitions on iOS may resize the viewport and produce
      // a spurious implicit scroll, which would otherwise call leaveLive() and
      // trigger SDK auto-close PIP.
      if (_lifecycleState != AppLifecycleState.resumed) {
        // CRITICAL: also revert _settlingPageIndex back to the committed page.
        // Otherwise the settling value left over by the spurious scroll becomes
        // a time-bomb: when the user resumes from PIP, the next ScrollEnd
        // (triggered by PIP-exit transition) would commit this stale settling
        // and silently switch to the wrong room.
        _settlingPageIndex = _currentPageIndex.value;
        return false;
      }
      final targetIndex = _settlingPageIndex;
      if (targetIndex != _currentPageIndex.value) {
        _commitPageChange(targetIndex);
      }
    }
    return false;
  }

  /// Executes the real page-switch work after the scroll animation settles:
  ///  1. Stop the old room's stream and leave the live room.
  ///  2. Turn the old page into a muted preview (so scrolling back is instant).
  ///  3. Stop preview for the new page (AudienceWidget will take full ownership).
  ///  4. Maintain the preview set around the new current page.
  ///  5. Update _currentPageIndex (which swaps the AudienceWidget into the tree).
  Future<void> _commitPageChange(int newIndex) async {
    final previousIndex = _currentPageIndex.value;
    LiveKitLogger.info('TUILiveRoomAudienceWidget commitPageChange: $previousIndex -> $newIndex');

    // 1. Stop the old room's stream and leave the live room to prevent sound
    //    overlap. stopPreviewLiveStream cuts the media pipeline immediately,
    //    then leaveLive formally exits the room.
    final oldResources = _pageResources[previousIndex];
    if (oldResources != null) {
      oldResources.liveCoreController.stopPreviewLiveStream(oldResources.roomId);

      await LiveListStore.shared.leaveLive();
    }

    final liveInfoList = _pagerService.state.liveInfoList.value;

    // 2. Turn the old page into a muted preview (so scrolling back is instant).
    if (previousIndex >= 0 && previousIndex < liveInfoList.length) {
      _previewManager.startPreview(liveInfoList[previousIndex]);
    }

    // 3. Stop preview for the new page — AudienceWidget will create its own
    //    full controller and joinLive.
    if (newIndex >= 0 && newIndex < liveInfoList.length) {
      _previewManager.stopPreview(liveInfoList[newIndex].liveID);
    }

    _cleanupDistantPages(newIndex);

    // 4. Keep preview set tight around the new current page.
    final adjacentRoomIds = <String>[];
    if (newIndex > 0) adjacentRoomIds.add(liveInfoList[newIndex - 1].liveID);
    if (newIndex < liveInfoList.length - 1) adjacentRoomIds.add(liveInfoList[newIndex + 1].liveID);
    _previewManager.onPageChanged(
      newCurrentRoomId: liveInfoList[newIndex].liveID,
      adjacentRoomIds: adjacentRoomIds,
    );

    // 5. Finally swap the widget tree: _buildPage will now return
    //    AudienceWidget for `newIndex` and a preview page for the rest.
    _currentPageIndex.value = newIndex;

    LiveKitLogger.info(
        'TUILiveRoomAudienceWidget commitPageChange done, active resources: ${_pageResources.keys.toList()}');
  }

  void _cleanupDistantPages(int currentIndex) {
    final keysToRemove = <int>[];
    for (final key in _pageResources.keys) {
      if ((key - currentIndex).abs() > 2) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      LiveKitLogger.info('TUILiveRoomAudienceWidget cleanup page resources at index $key');
      _pageResources[key]?.dispose();
      _pageResources.remove(key);
    }
  }

  void _onJoinLiveStateChanged(bool isJoining) {
    if (isJoining) {
      _scrollLockManager.acquireLock(ScrollLockReason.joiningRoom);
    } else {
      _scrollLockManager.releaseLock(ScrollLockReason.joiningRoom);
      _warmupAdjacentPreviews();
    }
  }

  void _warmupAdjacentPreviews() {
    final liveInfoList = _pagerService.state.liveInfoList.value;
    final currentIndex = _currentPageIndex.value;
    final currentRoomId = currentIndex < liveInfoList.length ? liveInfoList[currentIndex].liveID : '';

    if (currentIndex + 1 < liveInfoList.length) {
      final adjacentInfo = liveInfoList[currentIndex + 1];
      if (adjacentInfo.liveID != currentRoomId) {
        _previewManager.startPreview(adjacentInfo);
      }
    }

    if (currentIndex - 1 >= 0) {
      final adjacentInfo = liveInfoList[currentIndex - 1];
      if (adjacentInfo.liveID != currentRoomId) {
        _previewManager.startPreview(adjacentInfo);
      }
    }
  }

  void _onCoGuestStateChanged(bool shouldDisableScroll) {
    if (shouldDisableScroll) {
      _scrollLockManager.acquireLock(ScrollLockReason.coGuest);
    } else {
      _scrollLockManager.releaseLock(ScrollLockReason.coGuest);
    }
  }

  void _changeStatusBar2LightMode() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _startWakeLock() {
    TUILiveKitPlatform.instance.enableWakeLock(true);
  }

  void _stopWakeLock() {
    TUILiveKitPlatform.instance.enableWakeLock(false);
  }
}

class _PageResources {
  final String roomId;
  final LiveCoreController liveCoreController;
  final LiveStreamManager liveStreamManager;
  final void Function(String toast) showToast;
  StreamSubscription? _toastSubscription;

  VoidCallback? _onFloatWindowModeChangedListener;
  VoidCallback? _onFullScreenChangedListener;
  FloatWindowController? _floatWindowController;

  bool _isDisposed = false;

  _PageResources(this.roomId, {required this.showToast})
      : liveCoreController = LiveCoreController.create(CoreViewType.playView),
        liveStreamManager = LiveStreamManager() {
    _init();
  }

  void addFloatWindowObserver(FloatWindowController controller) {
    _floatWindowController = controller;
    _onFloatWindowModeChangedListener = _onFloatWindowModeChanged;
    _onFullScreenChangedListener = _onFullScreenChanged;
    liveStreamManager.floatWindowState.floatWindowMode.addListener(_onFloatWindowModeChangedListener!);
    controller.isFullScreen.addListener(_onFullScreenChangedListener!);
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (_onFloatWindowModeChangedListener != null) {
      liveStreamManager.floatWindowState.floatWindowMode.removeListener(_onFloatWindowModeChangedListener!);
    }
    if (_onFullScreenChangedListener != null && _floatWindowController != null) {
      _floatWindowController!.isFullScreen.removeListener(_onFullScreenChangedListener!);
    }

    _toastSubscription?.cancel();
    liveStreamManager.dispose();
  }

  void _init() {
    liveCoreController.setLiveID(roomId);
    liveStreamManager.setLiveID(roomId);
    _toastSubscription = liveStreamManager.toastSubject.stream.listen(showToast);
    _startForegroundService();
  }

  void _startForegroundService() async {
    String description = LiveKitLocalizations.of(TUILiveKitNavigatorObserver.instance.getContext())!.common_app_running;

    final hasCameraPermission = await Permission.camera.status == PermissionStatus.granted;
    if (!hasCameraPermission) {
      LiveKitLogger.error(
          '[ForegroundService] failed to start video foreground service. reason: without camera permission');
      return;
    }
    TUILiveKitPlatform.instance.startForegroundService(ForegroundServiceType.video, "", description);
  }

  void _onFloatWindowModeChanged() {
    FloatWindowMode floatWindowMode = liveStreamManager.floatWindowState.floatWindowMode.value;
    if (floatWindowMode == FloatWindowMode.outOfApp) {
      _floatWindowController?.onSwitchFloatWindowOutOfApp.call(true);
    } else if (floatWindowMode == FloatWindowMode.none) {
      _floatWindowController?.onSwitchFloatWindowOutOfApp.call(false);
    }
    GlobalFloatWindowManager.instance.setFloatWindowMode(floatWindowMode);
  }

  void _onFullScreenChanged() {
    if (_floatWindowController == null) return;
    bool isFullScreen = _floatWindowController!.isFullScreen.value;
    FloatWindowMode floatWindowMode = liveStreamManager.floatWindowState.floatWindowMode.value;
    if (isFullScreen) {
      LiveThemeManager.instance.resumeTheme();
      if (floatWindowMode != FloatWindowMode.outOfApp) {
        liveStreamManager.setFloatWindowMode(FloatWindowMode.none);
      }
    } else {
      liveStreamManager.setFloatWindowMode(FloatWindowMode.inApp);
      LiveThemeManager.instance.pauseTheme();
    }
  }
}
