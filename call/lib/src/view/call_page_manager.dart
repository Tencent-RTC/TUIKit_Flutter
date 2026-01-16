import 'dart:async';

import 'package:tuikit_atomic_x/call/common/i18n/i18n_utils.dart';
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

  const CallPageCallbacks({
    this.onShowCalling,
    this.onShowFloating,
    this.onShowPip,
    this.onShowInvitePage,
  });
}

class InviteUserCallbacks {
  final VoidCallback? onShowCalling;

  const InviteUserCallbacks({
    this.onShowCalling,
  });
}

class CallPageManager {
  final GlobalKey _callPageKey = GlobalKey();
  final NavigatorState? Function() _navigatorGetter;
  final AndroidPipFeature pipController = AndroidPipFeature();
 
  CallPageType _currentPageType = CallPageType.none;
  CallPageType getCurrentPageRoute() => _currentPageType;

  OverlayEntry? _currentOverlayEntry;
  OverlayEntry? _cachedCallingEntry;
  bool _hasManuallyShownCalling = false;
 
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
    _showPage(CallPageType.invite, isManualSwitch: true, cacheCurrentPage: true);
  }
  void showIncomingBanner() {
    if (_hasManuallyShownCalling) {
      return;
    }
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
    _removeCurrentOverlay();
    _clearCachedCallingEntry();
    _hasManuallyShownCalling = false;
  }

  void dispose() {
    _removeCurrentOverlay();
    _clearCachedCallingEntry();
    _hasManuallyShownCalling = false;
  }

  void _showPage(CallPageType pageType, {bool isManualSwitch = false, bool cacheCurrentPage = false}) {
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
    
    if (_currentPageType == pageType && _currentOverlayEntry != null) {
      _currentOverlayEntry?.markNeedsBuild();
      return;
    }

    if (cacheCurrentPage && 
        _currentPageType == CallPageType.calling && 
        _currentOverlayEntry != null) {
      _cacheCallingEntry();
    } else {
      _removeCurrentOverlay();
    }

    final widget = _buildWidgetFor(pageType);
    if (widget == null) return;

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    _currentOverlayEntry = OverlayEntry(builder: (context) => widget);
    overlay.insert(_currentOverlayEntry!);
    _currentPageType = pageType;
  }

  void _hidePage(CallPageType type) {
    if (_currentPageType == type) {
      if (type == CallPageType.invite && _cachedCallingEntry != null) {
        _restoreCachedCallingEntry();
      } else {
        _removeCurrentOverlay();
      }
    }
  }

  void _removeCurrentOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
    _currentPageType = CallPageType.none;
  }

  void _cacheCallingEntry() {
    _cachedCallingEntry = _currentOverlayEntry;
    _currentOverlayEntry?.opaque = false;
    _currentOverlayEntry = null;
    _currentPageType = CallPageType.none;
  }

  void _restoreCachedCallingEntry() {
    if (_cachedCallingEntry != null) {
      _currentOverlayEntry?.remove();

      _currentOverlayEntry = _cachedCallingEntry;
      _currentPageType = CallPageType.calling;
      _cachedCallingEntry = null;

      _currentOverlayEntry?.markNeedsBuild();
    } else {
      _removeCurrentOverlay();
    }
  }

  void _clearCachedCallingEntry() {
    _cachedCallingEntry?.remove();
    _cachedCallingEntry = null;
  }

  Widget? _buildWidgetFor(CallPageType pageType) {
    switch (pageType) {
      case CallPageType.calling:
      case CallPageType.floating:
      case CallPageType.pip:
        return CallMainWidget(
          key: _callPageKey,
          callPageType: pageType,
          callbacks: CallPageCallbacks(
            onShowCalling: () => showCallingPage(),
            onShowFloating: () => showFloatingPage(),
            onShowPip: () => showPipPage(),
            onShowInvitePage: () => showInvitePage(),
          ),
        );
      case CallPageType.invite:
        return InviteUserWidget(
          callbacks: InviteUserCallbacks(
            onShowCalling: () {
              closeInvitePage();
              showCallingPage();
            },
          ),
        );
      case CallPageType.none:
        return null;
      case CallPageType.banner:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IncomingBannerWidget(
                onShowCalling: () {
                  closeIncomingBanner();
                  showCallingPage();
                },
                onCloseAll: () => closeAllPage(),
              ),
            ),
          ),
        );
    }
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
      builder: (context) => Material(
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
                  CallKit_t("needToAccessMicrophoneAndCameraPermissions"),
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
                      child: Text(CallKit_t("cancel")),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () async {
                        overlayEntry?.remove();
                        completer.complete(true);
                      },
                      child: Text(CallKit_t("goToSettings")),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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