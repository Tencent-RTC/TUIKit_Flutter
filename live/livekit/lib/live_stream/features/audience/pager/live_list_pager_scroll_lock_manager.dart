import 'package:flutter/foundation.dart';
import 'package:tencent_live_uikit/common/index.dart';

enum ScrollLockReason {
  joiningRoom,
  coGuest,
}

class LiveListPagerScrollLockManager {
  static const String tag = 'LiveListPagerScrollLockManager';

  final Set<ScrollLockReason> _activeLocks = {};

  final ValueNotifier<bool> isScrollEnabled = ValueNotifier<bool>(true);

  void acquireLock(ScrollLockReason reason) {
    if (_activeLocks.contains(reason)) {
      return;
    }
    _activeLocks.add(reason);
    _updateScrollEnabled();
    LiveKitLogger.info('$tag acquireLock: $reason, activeLocks: $_activeLocks');
  }

  void releaseLock(ScrollLockReason reason) {
    if (!_activeLocks.contains(reason)) {
      return;
    }
    _activeLocks.remove(reason);
    _updateScrollEnabled();
    LiveKitLogger.info('$tag releaseLock: $reason, activeLocks: $_activeLocks');
  }

  void releaseAllLocks() {
    if (_activeLocks.isEmpty) return;
    _activeLocks.clear();
    _updateScrollEnabled();
    LiveKitLogger.info('$tag releaseAllLocks');
  }

  bool hasLock(ScrollLockReason reason) {
    return _activeLocks.contains(reason);
  }

  void dispose() {
    _activeLocks.clear();
    LiveKitLogger.info('$tag disposed');
  }

  void _updateScrollEnabled() {
    final enabled = _activeLocks.isEmpty;
    if (isScrollEnabled.value != enabled) {
      isScrollEnabled.value = enabled;
    }
  }
}
