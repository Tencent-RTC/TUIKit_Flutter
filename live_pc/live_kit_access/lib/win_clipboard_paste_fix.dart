import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Workaround for a Flutter Windows engine bug where pasting from the
/// Windows clipboard history (Win+V) does nothing in text fields
/// (flutter/flutter#143997, still open, Windows 11 only).
///
/// When an entry is picked in the Win+V flyout, Windows synthesizes a
/// Ctrl+V via Win32 messages, but the Windows embedder converts those
/// synthesized messages into malformed key data:
///
/// - every event carries an invalid physical key `0x1600000000`, and
/// - a premature synthesized `Ctrl up` arrives before `V down`, so the
///   framework never sees "V pressed while Ctrl is down" and the default
///   paste shortcut never fires (real Ctrl+V goes through a normal path
///   and works, which is why only Win+V is broken).
///
/// [install] wraps `PlatformDispatcher.instance.onKeyData` once, for the
/// whole app lifetime, and rewrites the malformed 6-event sequence into a
/// clean `Ctrl down -> V down -> V up -> Ctrl up`, so the framework's
/// default paste shortcut triggers normally in every text field.
///
/// Two rules must never be violated (both were tried in the wild and
/// broke input entirely, see the issue comments):
/// 1. All-zero KeyData events (physical == 0 && logical == 0) are the
///    engine's transit-mode probes and MUST be passed through unchanged;
///    swallowing them trips the framework's
///    "Should never encounter KeyData when transitMode is rawKeyData"
///    assertion and makes every text field uneditable.
/// 2. Unrelated events must be forwarded to the original callback as-is.
///
/// Reference implementation: "WindowsPasteFix" by cup113 (verified on
/// Flutter 3.44.2 / Windows 11) in flutter/flutter#143997. Delete this
/// file once the engine-side fix ships.
class WinClipboardPasteFix {
  WinClipboardPasteFix._();

  static final WinClipboardPasteFix instance = WinClipboardPasteFix._();

  /// Malformed physical key stamped on every Win+V synthesized event.
  static const int _junkPhysical = 0x1600000000;
  static const int _cleanPhysicalCtrl = 0x700e0; // CtrlLeft USB HID usage
  static const int _cleanPhysicalV = 0x70019; // KeyV USB HID usage
  static const int _logicalCtrl = 0x200000100;
  static const int _logicalV = 0x76; // 'v'
  static const int _maxInstallRetries = 5;

  KeyDataCallback? _original;
  int _installAttempts = 0;
  int _step = 0;
  bool _isInstalled = false;

  /// Installs the key-data wrapper for the app lifetime.
  /// No-op on non-Windows platforms and when already installed.
  void install() {
    if (!Platform.isWindows) {
      return;
    }
    _installAttempts = 0;
    _install();
  }

  /// Restores the original key-data callback. Only needed if the host
  /// ever wants to disable the fix; the normal app flow never calls it.
  void uninstall() {
    if (!_isInstalled) {
      return;
    }
    _isInstalled = false;
    _step = 0;
    if (PlatformDispatcher.instance.onKeyData == _handleKeyData) {
      PlatformDispatcher.instance.onKeyData = _original;
    }
    _original = null;
  }

  // The framework installs its own onKeyData handler lazily; retry on
  // post-frame callbacks until it exists, then wrap it.
  void _install() {
    if (_isInstalled) {
      return;
    }
    final original = PlatformDispatcher.instance.onKeyData;
    if (original == null) {
      _installAttempts++;
      if (_installAttempts >= _maxInstallRetries) {
        debugPrint(
          '[WinClipboardPasteFix] onKeyData still null after '
          '$_maxInstallRetries attempts, giving up.',
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _install());
      return;
    }
    _original = original;
    PlatformDispatcher.instance.onKeyData = _handleKeyData;
    _isInstalled = true;
  }

  bool _handleKeyData(KeyData data) {
    final original = _original;
    if (original == null) {
      return false;
    }
    final rewritten = _rewrite(data);
    if (rewritten == null) {
      return true;
    }
    return original(rewritten);
  }

  KeyData _copyWith(
    KeyData data, {
    required KeyEventType type,
    required int physical,
    required int logical,
  }) {
    return KeyData(
      timeStamp: data.timeStamp,
      type: type,
      physical: physical,
      logical: logical,
      character: null,
      synthesized: false,
    );
  }

  /// Rewrites the malformed Win+V sequence. Returns the (possibly
  /// original) event to forward, or null to swallow it.
  KeyData? _rewrite(KeyData data) {
    // All-zero events are transit-mode probes — MUST pass through (see
    // class docs rule 1).
    if (data.physical == 0 && data.logical == 0) {
      return data;
    }

    // Normal hardware keys: pass through and reset the state machine.
    if (data.physical != _junkPhysical) {
      _step = 0;
      return data;
    }

    final down = data.type == KeyEventType.down;
    final up = data.type == KeyEventType.up;
    final isCtrl = data.logical == _logicalCtrl;
    final isV = data.logical == _logicalV;

    switch (_step) {
      case 0:
        // Ctrl down (synthesized=false) -> emit clean Ctrl down.
        if (isCtrl && down && !data.synthesized) {
          _step = 1;
          return _copyWith(
            data,
            type: KeyEventType.down,
            physical: _cleanPhysicalCtrl,
            logical: _logicalCtrl,
          );
        }
      case 1:
        // Premature synthesized Ctrl up: swallow, keep Ctrl "pressed".
        if (isCtrl && up && data.synthesized) {
          _step = 2;
          return null;
        }
      case 2:
        // V down -> emit clean V down (paste shortcut fires here).
        if (isV && down) {
          _step = 3;
          return _copyWith(
            data,
            type: KeyEventType.down,
            physical: _cleanPhysicalV,
            logical: _logicalV,
          );
        }
      case 3:
        // V up -> emit clean V up.
        if (isV && up) {
          _step = 4;
          return _copyWith(
            data,
            type: KeyEventType.up,
            physical: _cleanPhysicalV,
            logical: _logicalV,
          );
        }
      case 4:
        // Duplicate synthesized Ctrl down: swallow.
        if (isCtrl && down && data.synthesized) {
          _step = 5;
          return null;
        }
      case 5:
        // Synthesized Ctrl up -> emit clean Ctrl up, sequence complete.
        if (isCtrl && up && data.synthesized) {
          _step = 0;
          return _copyWith(
            data,
            type: KeyEventType.up,
            physical: _cleanPhysicalCtrl,
            logical: _logicalCtrl,
          );
        }
    }

    // Sequence broken: reset and pass through unchanged.
    _step = 0;
    return data;
  }
}
