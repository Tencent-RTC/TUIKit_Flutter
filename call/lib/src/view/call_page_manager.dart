import 'dart:async';

import 'package:atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:atomic_x/atomicx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_main_widget.dart';
import 'component/incoming_banner/incoming_banner_widget.dart';
import 'component/inviter/invite_user_widget.dart';

enum CallPageType {
  none,
  calling,
  floating,
  invite,
  banner,
}

class CallPageCallbacks {
  final VoidCallback? onShowCalling;
  final VoidCallback? onShowFloating;
  final VoidCallback? onShowInvitePage;

  const CallPageCallbacks({
    this.onShowCalling,
    this.onShowFloating,
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
  final Map<CallPageType, OverlayEntry> _overlayEntries = {};
 
  CallPageType _currentPageType = CallPageType.none;
  CallPageType getCurrentPageRoute() => _currentPageType;
 
  CallPageManager({
    required NavigatorState? Function() navigatorGetter,
  })  : _navigatorGetter = navigatorGetter;


  void showCallingPage() => _showCallPageOverlay(CallPageType.calling);
  void showFloatingPage() => _showCallPageOverlay(CallPageType.floating);
  void showInvitePage() => _showInviteOverlay();
  void showIncomingBanner() => _showIncomingBannerOverlay();
  void closeCallingPage() => _hideOverlay(CallPageType.calling);
  void closeFloatingPage() => _hideOverlay(CallPageType.floating);
  void closeInvitePage() => _hideOverlay(CallPageType.invite);
  void closeIncomingBanner() => _hideOverlay(CallPageType.banner);
  void closeAllPage() => _hideAll();

  void dispose() {
    _hideAll();
  }

  void _showInviteOverlay() {
    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) return;

    if (_overlayEntries.containsKey(CallPageType.invite)) {
      final existing = _overlayEntries[CallPageType.invite]!;
      existing.remove();
      overlay.insert(existing);
      return;
    }

    final widget = _buildWidgetFor(CallPageType.invite);
    if (widget == null) return;
    final entry = OverlayEntry(builder: (context) => widget);
    _overlayEntries[CallPageType.invite] = entry;
    overlay.insert(entry);
  }

  void _showIncomingBannerOverlay() {
    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) return;

    if (_overlayEntries.containsKey(CallPageType.banner)) {
      final existing = _overlayEntries[CallPageType.banner]!;
      existing.remove();
      overlay.insert(existing);
      return;
    }

    final widget = _buildWidgetFor(CallPageType.banner);
    if (widget == null) return;
    final entry = OverlayEntry(builder: (context) => widget);
    _overlayEntries[CallPageType.banner] = entry;
    overlay.insert(entry);
  }

  void _showCallPageOverlay(CallPageType pageType) {
    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) return;

    if (_currentPageType == pageType && _overlayEntries.containsKey(pageType)) {
      return;
    }

    _hideCallAndFloatingOverlays();

    final widget = _buildWidgetFor(pageType);
    if (widget == null) return;
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    final entry = OverlayEntry(builder: (context) => widget);
    _overlayEntries[pageType] = entry;
    overlay.insert(entry);

    _currentPageType = pageType;
  }

  void _hideCallAndFloatingOverlays() {
    for (final type in [CallPageType.calling, CallPageType.floating]) {
      if (_overlayEntries.containsKey(type)) {
        _overlayEntries[type]?.remove();
        _overlayEntries.remove(type);
      }
    }
    if (_currentPageType == CallPageType.calling || _currentPageType == CallPageType.floating) {
      _currentPageType = CallPageType.none;
    }
  }

  void _hideAll() {
    for (var entry in _overlayEntries.values) {
      entry.remove();
    }
    _overlayEntries.clear();
    _currentPageType = CallPageType.none;
  }

  void _hideOverlay(CallPageType type) {
    if (_overlayEntries.containsKey(type)) {
      _overlayEntries[type]?.remove();
      _overlayEntries.remove(type);
    }
    if (_currentPageType == type) {
      _currentPageType = CallPageType.none;
    }
  }

  Widget? _buildWidgetFor(CallPageType pageType) {
    switch (pageType) {
      case CallPageType.calling:
        return CallMainWidget(
          key: _callPageKey,
          callPageType: CallPageType.calling,
          callbacks: CallPageCallbacks(
            onShowCalling: () => showCallingPage(),
            onShowFloating: () => showFloatingPage(),
            onShowInvitePage: () => showInvitePage(),
          ),
        );
      case CallPageType.floating:
        return CallMainWidget(
          key: _callPageKey,
          callPageType: CallPageType.floating,
          callbacks: CallPageCallbacks(
            onShowCalling: () => showCallingPage(),
            onShowFloating: () => showFloatingPage(),
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
        return IncomingBannerWidget(
          onShowCalling: () {
            closeIncomingBanner();
            showCallingPage();
          },
          onCloseAll: () => closeAllPage(),
        );
    }
  }

  void handleNoPermissionAndEndCall(TUICallRole role) async {
    final overlay = _navigatorGetter()?.overlay;
    if (overlay == null) {
      if (role == TUICallRole.called) {
        CallListStore.shared.hangup();
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
      await openAppSettings();
    }

    if (role == TUICallRole.called) {
      CallListStore.shared.reject();
    }
  }

}