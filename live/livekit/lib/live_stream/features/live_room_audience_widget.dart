import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_mode.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/audience_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/live_list/audience_live_info_list_store.dart';
import 'package:tencent_live_uikit/live_stream/features/audience/pager/page_widget.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import '../../common/resources/live_theme_manager.dart';
import '../../common/widget/float_window/float_window_controller.dart';
import '../../component/float_window/global_float_window_manager.dart';

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
  late final AudienceLiveInfoListStore _liveInfoListStore = AudienceLiveInfoListStore();
  final Map<String, AudienceController> _audienceControllers = {};
  final ValueNotifier<bool> _isScrollEnabled = ValueNotifier<bool>(true);
  late final VoidCallback _fullScreenListener = _onFullScreenChanged;

  bool _hasEnteredThemeScene = false;
  String? _currentLiveID = '';
  int _currentPageIndex = 0;
  Orientation _currentOrientation = Orientation.portrait;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveKitLogger.info('TUILiveRoomAudienceWidget initState');
    KeyMetrics.reportComponent(LiveComponentType.liveRoom);
    _changeStatusBar2LightMode();
    _startWakeLock();
    widget.floatWindowController?.isFullScreen.addListener(_fullScreenListener);
    if (widget.liveInfo == null) {
      LiveListStore.shared.fetchLiveInfo(widget.roomId).then((result) {
        if (!mounted) return;
        if (result.isSuccess) _liveInfoListStore.setTopLiveInfo(result.liveInfo);
        _liveInfoListStore.fetchLiveList(true);
      });
    } else {
      _liveInfoListStore.setTopLiveInfo(widget.liveInfo!);
      _liveInfoListStore.fetchLiveList(true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only switch theme on first entry
    if (!_hasEnteredThemeScene) {
      _hasEnteredThemeScene = true;
      LiveThemeManager.instance.enterLiveKitScene(context);
    }
    final orientation = MediaQuery.of(context).orientation;
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;
      _onKeepLiveChanged(orientation == Orientation.landscape);
      LiveKitLogger.info("orientation=$orientation");
    }
  }

  @override
  void dispose() {
    LiveKitLogger.info('TUILiveRoomAudienceWidget dispose');
    // Exit LiveKit scene and restore theme
    LiveThemeManager.instance.exitLiveKitScene();
    _stopWakeLock();
    for (final controller in _audienceControllers.values) {
      controller.dispose();
    }
    _audienceControllers.clear();
    WidgetsBinding.instance.removeObserver(this);
    widget.floatWindowController?.isFullScreen.removeListener(_fullScreenListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DeviceLanguage.checkLocale(context);
    return Scaffold(
      backgroundColor: LiveColors.notStandardPureBlack,
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: true,
        child: ValueListenableBuilder<List<LiveInfo>>(
          valueListenable: _liveInfoListStore.liveInfoList,
          builder: (context, liveInfoList, _) {
            LiveKitLogger.info("build PageWidget, size=${liveInfoList.length}");
            return Stack(
              children: [
                ValueListenableBuilder<bool>(
                    valueListenable: _isScrollEnabled,
                    builder: (context, isScrollEnabled, _) {
                      return PageWidget<LiveInfo>(
                        items: liveInfoList,
                        scrollEnabled: isScrollEnabled,
                        slideInThreshold: 0.15,
                        onPageWillSlideIn: _onPageWillSlideIn,
                        onPageDidSlideIn: _onPageDidSlideIn,
                        onPageWillSlideOut: _onPageWillSlideOut,
                        onPageDidSlideOut: _onPageDidSlideOut,
                        onPageSlideInCancelled: _onPageSlideInCancelled,
                        onPageSlideOutCancelled: _onPageSlideOutCancelled,
                        itemBuilder: (ctx, liveInfo, index) {
                          return _buildPage(index, liveInfo);
                        },
                      );
                    }),
                IgnorePointer(
                  ignoring: liveInfoList.isNotEmpty,
                  child: AnimatedOpacity(
                    opacity: liveInfoList.isEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: _buildBackgroundPlaceholder(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundPlaceholder() {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Image.asset(LiveImages.defaultBackground, package: Constants.pluginName),
    );
  }

  Widget _buildPage(int index, LiveInfo liveInfo) {
    final controller = _obtainController(liveInfo.liveID);
    LiveKitLogger.info("_buildPage, index=$index, liveID=${liveInfo.liveID}");
    return AudienceWidget(
      key: ValueKey('audience_widget_${liveInfo.liveID}'),
      liveInfo: liveInfo,
      audienceController: controller,
      onInitState: () {
        LiveKitLogger.info("onInitState, index=$index, liveID=${liveInfo.liveID}");
        controller.onKeepLiveChanged = _onKeepLiveChanged;
        controller.onTapEnterFloatWindowInApp = _onTapEnterFloatWindowInApp;
        controller.onSwitchFloatWindowOutOfApp = _onSwitchFloatWindowOutOfApp;
        if (index == _currentPageIndex) {
          _currentLiveID = liveInfo.liveID;
          controller.joinLive();
        }
      },
      onDispose: () {
        LiveKitLogger.info("onDispose, index=$index, liveID=${liveInfo.liveID}");
        controller.onKeepLiveChanged = null;
        controller.onTapEnterFloatWindowInApp = null;
        controller.onSwitchFloatWindowOutOfApp = null;
        _audienceControllers.remove(liveInfo.liveID);
      },
    );
  }

  AudienceController _obtainController(String liveID) {
    return _audienceControllers.putIfAbsent(liveID, () {
      return AudienceController(roomId: liveID);
    });
  }

  void _onPageWillSlideIn(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageWillSlideIn error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageWillSlideIn: index=$index, liveID=${liveInfo.liveID}');

    _audienceControllers[liveInfo.liveID]?.startPreload();
  }

  void _onPageDidSlideIn(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageDidSlideIn error, index=$index, size=${liveList.length}");
      return;
    }
    _currentPageIndex = index;
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageDidSlideIn: index=$index, liveID=${liveInfo.liveID}');
    _currentLiveID = liveInfo.liveID;
    _audienceControllers[liveInfo.liveID]?.joinLive();

    const preloadThreshold = 2;
    if (index >= liveList.length - preloadThreshold) {
      _liveInfoListStore.fetchLiveList(false);
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

    _audienceControllers[liveInfo.liveID]?.stopPreload();
    _audienceControllers[liveInfo.liveID]?.leaveLive();
  }

  void _onPageSlideInCancelled(int index) {
    final liveList = _liveInfoListStore.liveInfoList.value;
    if (index >= liveList.length) {
      LiveKitLogger.error("onPageSlideInCancelled error, index=$index, size=${liveList.length}");
      return;
    }
    final liveInfo = liveList[index];
    LiveKitLogger.info('onPageSlideInCancelled: index=$index, liveID=${liveInfo.liveID}');

    _audienceControllers[liveInfo.liveID]?.stopPreload();
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

  void _onKeepLiveChanged(bool shouldDisableScroll) {
    // Disable scroll when self has take seat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LiveKitLogger.info("_onKeepLiveChanged: $shouldDisableScroll");
      _isScrollEnabled.value = !shouldDisableScroll;
    });
  }

  void _onTapEnterFloatWindowInApp() {
    // Click to enter float window in app.
    final liveInfo = LiveListStore.shared.liveState.currentLive.value;
    bool isLandscape = liveInfo.seatTemplate is VideoLandscape4Seats || liveInfo.seatTemplate is VideoLandscape10Seats;
    widget.floatWindowController?.setScreenOrientation(isLandscape);
    widget.floatWindowController?.onTapSwitchFloatWindowInApp(true);
  }

  void _onSwitchFloatWindowOutOfApp(bool isFloatMode) {
    widget.floatWindowController?.onSwitchFloatWindowOutOfApp.call(isFloatMode);
    GlobalFloatWindowManager.instance.setFloatWindowMode(isFloatMode ? FloatWindowMode.outOfApp : FloatWindowMode.none);
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

  void _onFullScreenChanged() {
    if (widget.floatWindowController == null) return;
    bool isFullScreen = widget.floatWindowController!.isFullScreen.value;
    if (isFullScreen) {
      LiveThemeManager.instance.resumeTheme();
    } else {
      LiveThemeManager.instance.pauseTheme();
    }
    _audienceControllers[_currentLiveID]?.setFullScreenChanged(isFullScreen);
    GlobalFloatWindowManager.instance.setFloatWindowMode(isFullScreen ? FloatWindowMode.none : FloatWindowMode.inApp);
  }
}
