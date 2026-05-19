import 'dart:async';
import 'dart:math';

import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tencent_calls_uikit/src/common/utils/app_lifecycle.dart';
import '../common/metrics/key_metrics.dart';
import 'call_main_widget.dart';
import 'component/incoming_banner/incoming_banner_widget.dart';
import 'component/inviter/invite_user_widget.dart';

enum CallPageType {
  none,
  calling,
  floating,
  invite,
  banner,
  pip,
}

class CallPageCallbacks {
  final VoidCallback? onShowCalling;
  final VoidCallback? onShowFloating;
  final VoidCallback? onShowPip;
  final VoidCallback? onShowInvitePage;
  final void Function(DragUpdateDetails details, Size screenSize)? onFloatDragUpdate;
  final Size Function()? getOriginScreenSize;
  final void Function(Size size)? setOriginScreenSize;

  const CallPageCallbacks({
    this.onShowCalling,
    this.onShowFloating,
    this.onShowPip,
    this.onShowInvitePage,
    this.onFloatDragUpdate,
    this.getOriginScreenSize,
    this.setOriginScreenSize,
  });
}

class InviteUserCallbacks {
  final VoidCallback? onShowCalling;

  const InviteUserCallbacks({
    this.onShowCalling,
  });
}

class CallPageManager {
  final GlobalKey<NavigatorState> _callNavigatorKey = GlobalKey<NavigatorState>();
  final NavigatorState? Function() _navigatorGetter;
  final AndroidPipFeature pipController = AndroidPipFeature();
 
  CallPageType _currentPageType = CallPageType.none;
  CallPageType getCurrentPageRoute() => _currentPageType;

  CallPageType _pageTypeBeforeInvite = CallPageType.none;

  OverlayEntry? _callOverlayEntry;
  bool _hasManuallyShownCalling = false;
  bool _shouldAnimateRect = false;

  Size _originScreenSize = Size.zero;
  Size get originScreenSize => _originScreenSize;
  void setOriginScreenSize(Size size) {
    // Only grow, never shrink — prevents small-window constraints from polluting the value.
    _originScreenSize = Size(
      max(size.width, _originScreenSize.width),
      max(size.height, _originScreenSize.height),
    );
  }

  static const double _floatWindowWidth = 121.0;
  static const double _floatWindowHeight = 181.0;
  double _floatViewTop = 128.0;
  double _floatViewRight = 20.0;

  static const double _bannerContentHeight = 100.0;
  
  NavigatorState? get callNavigator => _callNavigatorKey.currentState;
 
  CallPageManager({
    required NavigatorState? Function() navigatorGetter,
  })  : _navigatorGetter = navigatorGetter;

  void showCallingPage() {
    pipController.onEnterPip = () {
      if (_currentPageType != CallPageType.none) {
        _showPage(CallPageType.pip, isManualSwitch: true);
      }
    };

    pipController.onLeavePip = () {
      if (_currentPageType != CallPageType.none) {
        _showPage(CallPageType.calling, isManualSwitch: true);
      }
    };

    pipController.enable();
    _showPage(CallPageType.calling, isManualSwitch: true);
  }
  
  void showFloatingPage() => _showPage(CallPageType.floating, isManualSwitch: true);
  void showPipPage() => _showPage(CallPageType.pip, isManualSwitch: true);
  void showInvitePage() {
    _showPage(CallPageType.invite, isManualSwitch: true);
  }
  void showIncomingBanner() {
    if (_hasManuallyShownCalling) return;
    _showPage(CallPageType.banner, isManualSwitch: false);
  }
  
  void closeCallingPage() => _hidePage(CallPageType.calling);
  void closeFloatingPage() => _hidePage(CallPageType.floating);
  void closeInvitePage() => _hidePage(CallPageType.invite);
  void closeIncomingBanner() => _hidePage(CallPageType.banner);
  
  void closeAllPage() {
    pipController.onEnterPip = null;
    pipController.onLeavePip = null;
    
    if (pipController.isInPipMode) {
      pipController.closePictureInPicture();
    }
    
    pipController.disable();
    _removeCallOverlay();
    _hasManuallyShownCalling = false;
    _originScreenSize = Size.zero;
  }

  void dispose() {
    _removeCallOverlay();
    _hasManuallyShownCalling = false;
  }

  void _showPage(CallPageType pageType, {bool isManualSwitch = false}) {
    KeyMetrics.instance.countUV(EventId.wakeup);

    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) return;
    if (AppLifecycle.instance.currentState.value == AppLifecycleState.detached) return;

    if (isManualSwitch && 
        (pageType == CallPageType.calling || 
         pageType == CallPageType.floating || 
         pageType == CallPageType.pip)) {
      _hasManuallyShownCalling = true;
    }
    
    if (_currentPageType == pageType && _callOverlayEntry != null) {
      _shouldAnimateRect = false;
      _callOverlayEntry?.markNeedsBuild();
      return;
    }

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (_callOverlayEntry == null) {
      _currentPageType = pageType;
      _callOverlayEntry = OverlayEntry(
        builder: (context) => _buildCallNavigator(),
      );
      overlay.insert(_callOverlayEntry!);
      return;
    }

    final previousPageType = _currentPageType;
    final targetPageType = pageType;
    final isFromSmallToFull = _isSmallWindow(previousPageType) && !_isSmallWindow(targetPageType);
    
    if (isFromSmallToFull) {
      // Small window → Fullscreen:
      // Immediately update page type and rebuild overlay, then navigate route.
      _shouldAnimateRect = true;
      _currentPageType = targetPageType;
      _callOverlayEntry?.markNeedsBuild();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(targetPageType);
      });
      // Reset after AnimatedPositioned finishes (250ms), so subsequent
      // rebuilds (e.g. drag updates) use Duration.zero instead of animating.
      Future.delayed(const Duration(milliseconds: 250), () {
        _shouldAnimateRect = false;
      });
    } else {
      // Fullscreen → Small window, or same-size switch:
      // Animate when at least one side is not a small window;
      // skip animation for small↔small transitions (e.g. floating → banner).
      _shouldAnimateRect = !_isSmallWindow(previousPageType) || !_isSmallWindow(targetPageType);
      _currentPageType = targetPageType;
      _callOverlayEntry?.markNeedsBuild();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(targetPageType);
      });
      if (_shouldAnimateRect) {
        Future.delayed(const Duration(milliseconds: 250), () {
          _shouldAnimateRect = false;
        });
      }
    }
  }

  void _hidePage(CallPageType type) {
    if (_currentPageType != type) return;
    
    if (type == CallPageType.invite) {
      final navigator = _callNavigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
        _currentPageType = _pageTypeBeforeInvite;
        _pageTypeBeforeInvite = CallPageType.none;
        _callOverlayEntry?.markNeedsBuild();
        return;
      }
    }
    
    _removeCallOverlay();
  }

  void _removeCallOverlay() {
    _callOverlayEntry?.remove();
    _callOverlayEntry = null;
    _currentPageType = CallPageType.none;
  }

  void _navigateToPage(CallPageType pageType) {
    final navigator = _callNavigatorKey.currentState;
    if (navigator == null) return;

    final routeName = _getRouteName(pageType);
    
    if (pageType == CallPageType.invite) {
      _pageTypeBeforeInvite = _currentPageType;
      navigator.pushNamed(routeName);
    } else {
      if (!navigator.canPop()) {
        navigator.pushNamed(routeName);
      } else {
        navigator.pushReplacementNamed(routeName);
      }
    }
  }

  String _getRouteName(CallPageType pageType) {
    switch (pageType) {
      case CallPageType.calling:
        return '/calling';
      case CallPageType.floating:
        return '/floating';
      case CallPageType.pip:
        return '/pip';
      case CallPageType.invite:
        return '/invite';
      case CallPageType.banner:
        return '/banner';
      case CallPageType.none:
        return '/';
    }
  }

  Widget _buildCallNavigator() {
    return _CallOverlayLayout(
      rectGetter: _getPageRect,
      borderRadiusGetter: _getPageBorderRadius,
      isAnimatingGetter: () => _shouldAnimateRect,
      child: Navigator(
        key: _callNavigatorKey,
        initialRoute: _getRouteName(_currentPageType),
        onGenerateRoute: (settings) {
          return _buildRoute(settings);
        },
      ),
    );
  }

  Rect _getPageRect(Size screenSize, EdgeInsets viewPadding) {
    switch (_currentPageType) {
      case CallPageType.floating:
        final left = screenSize.width - _floatViewRight - _floatWindowWidth;
        final top = _floatViewTop - 40;
        return Rect.fromLTWH(left, top, _floatWindowWidth, _floatWindowHeight);
      case CallPageType.banner:
        final bannerHeight = viewPadding.top + _bannerContentHeight;
        return Rect.fromLTWH(0, 0, screenSize.width, bannerHeight);
      case CallPageType.calling:
      case CallPageType.invite:
      case CallPageType.pip:
      case CallPageType.none:
        return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }
  }

  BorderRadius _getPageBorderRadius() {
    switch (_currentPageType) {
      case CallPageType.floating:
        return BorderRadius.circular(12.0);
      case CallPageType.banner:
        return BorderRadius.zero;
      default:
        return BorderRadius.zero;
    }
  }

  bool _isSmallWindow(CallPageType type) {
    return type == CallPageType.floating || type == CallPageType.banner || type == CallPageType.pip;
  }

  void updateFloatPosition(DragUpdateDetails details, Size screenSize) {
    _floatViewRight -= details.delta.dx;
    _floatViewTop += details.delta.dy;
    if (_floatViewTop < 100) {
      _floatViewTop = 100;
    }
    if (_floatViewTop > screenSize.height - 216) {
      _floatViewTop = screenSize.height - 216;
    }
    if (_floatViewRight < 0) {
      _floatViewRight = 0;
    }
    if (_floatViewRight > screenSize.width - 110) {
      _floatViewRight = screenSize.width - 110;
    }
    _callOverlayEntry?.markNeedsBuild();
  }

  Route<dynamic>? _buildRoute(RouteSettings settings) {
    Widget page;
    bool fullscreenDialog = false;

    switch (settings.name) {
      case '/calling':
        page = CallMainWidget(
          callPageType: CallPageType.calling,
          callbacks: _buildCallPageCallbacks(),
        );
        break;
      case '/floating':
        page = CallMainWidget(
          callPageType: CallPageType.floating,
          callbacks: _buildCallPageCallbacks(),
        );
        break;
      case '/pip':
        page = CallMainWidget(
          callPageType: CallPageType.pip,
          callbacks: _buildCallPageCallbacks(),
        );
        break;
      case '/invite':
        fullscreenDialog = true;
        page = InviteUserWidget(
          callbacks: InviteUserCallbacks(
            onShowCalling: () {
              closeInvitePage();
            },
          ),
        );
        break;
      case '/banner':
        page = SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: IncomingBannerWidget(
              onShowCalling: () {
                showCallingPage();
              },
              onCloseAll: () => closeAllPage(),
            ),
          ),
        );
        break;
      default:
        page = const SizedBox.shrink();
    }

    final bool noAnimation = settings.name == '/calling' ||
                              settings.name == '/pip';
    
    final bool isFloating = settings.name == '/floating';

    if (isFloating) {
      return PageRouteBuilder(
        settings: settings,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    if (noAnimation) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    if (settings.name == '/banner') {
      return PageRouteBuilder(
        settings: settings,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }

    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  CallPageCallbacks _buildCallPageCallbacks() {
    return CallPageCallbacks(
      onShowCalling: () => showCallingPage(),
      onShowFloating: () => showFloatingPage(),
      onShowPip: () => showPipPage(),
      onShowInvitePage: () => showInvitePage(),
      onFloatDragUpdate: (details, screenSize) => updateFloatPosition(details, screenSize),
      getOriginScreenSize: () => originScreenSize,
      setOriginScreenSize: (size) => setOriginScreenSize(size),
    );
  }

  void handleNoPermissionAndEndCall(bool isCalled) async {
    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) {
      if (isCalled) {
        CallStore.shared.hangup();
      }
      return;
    }

    final completer = Completer<bool?>();
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final l10n = AtomicLocalizations.of(context);
        return Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.callNeedToAccessMicrophoneAndCameraPermissions,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        overlayEntry?.remove();
                        completer.complete(false);
                      },
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () async {
                        overlayEntry?.remove();
                        completer.complete(true);
                      },
                      child: Text(l10n.callGoToSettings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      },
    );

    overlay.insert(overlayEntry);

    final goSettings = await completer.future;

    if (goSettings == true) {
      await Permission.openAppSettings();
    }

    if (isCalled) {
      CallStore.shared.reject();
    }
  }

}

class _CallOverlayLayout extends StatelessWidget {
  final Rect Function(Size screenSize, EdgeInsets viewPadding) rectGetter;
  final BorderRadius Function() borderRadiusGetter;
  final bool Function() isAnimatingGetter;
  final Widget child;

  const _CallOverlayLayout({
    required this.rectGetter,
    required this.borderRadiusGetter,
    required this.isAnimatingGetter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenSize = mq.size;
    final rect = rectGetter(screenSize, mq.viewPadding);
    final borderRadius = borderRadiusGetter();
    final shouldAnimate = isAnimatingGetter();
    final duration = shouldAnimate
        ? const Duration(milliseconds: 250)
        : Duration.zero;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: duration,
          curve: Curves.easeOutCubic,
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: child,
          ),
        ),
      ],
    );
  }
}