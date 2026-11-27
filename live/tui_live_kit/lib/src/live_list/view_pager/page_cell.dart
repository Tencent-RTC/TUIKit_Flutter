import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../player/player_view.dart';

class PageCell {
  static int _nextIdentity = 0;

  PageCell({
    required LiveInfo liveInfo,
    required VoidCallback onJoinLiveClicked,
    required VoidCallback onCloseClicked,
  })  : _liveInfo = liveInfo,
        _onJoinLiveClicked = onJoinLiveClicked,
        _onCloseClicked = onCloseClicked {
    controller.setLiveInfo(liveInfo);
    controller.onJoinLiveClicked = _onJoinLiveClicked;
    controller.onCloseClicked = _onCloseClicked;
  }

  final PlayerViewController controller = PlayerViewController();
  final int _identity = _nextIdentity++;
  final VoidCallback _onJoinLiveClicked;
  final VoidCallback _onCloseClicked;

  LiveInfo _liveInfo;
  EdgeInsets _safeAreaInsets = EdgeInsets.zero;
  Future<LiveInfo?>? _joinFuture;
  bool _isActive = true;
  bool _isDisposed = false;
  bool _disposeScheduled = false;
  Future<void>? _disposeFuture;

  String get liveID => _liveInfo.liveID;
  PlayerStatus get status => controller.status.value;

  void updateData(LiveInfo liveInfo) {
    if (!_isActive) return;
    _liveInfo = liveInfo;
    controller.setLiveInfo(liveInfo);
  }

  void updateSafeArea(EdgeInsets insets) {
    if (!_isActive || _safeAreaInsets == insets) return;
    _safeAreaInsets = insets;
    controller.setContentSafeAreaInsets(insets);
  }

  void setJoinLiveEntranceEnabled(bool enabled) {
    if (!_isActive) return;
    controller.setJoinLiveEntranceEnabled(enabled);
  }

  void startPreview() {
    if (!_isActive) return;
    controller.setVolume(PlayerViewController.previewVolume);
    controller.startPlay();
  }

  void stopPreview() {
    controller.stopPlay();
  }

  Future<LiveInfo?> joinChannel() {
    final Future<LiveInfo?>? pending = _joinFuture;
    if (pending != null) return pending;
    final Future<LiveInfo?> operation = _performJoin();
    _joinFuture = operation;
    return operation;
  }

  Future<LiveInfo?> _performJoin() async {
    LiveInfo? joinedLiveInfo;
    controller.setVolume(PlayerViewController.roomVolume);
    try {
      await controller.joinChannel(
        completion: (LiveInfo? liveInfo, Object? error) {
          if (error == null) joinedLiveInfo = liveInfo;
        },
      );
    } catch (_) {
      joinedLiveInfo = null;
    } finally {
      _joinFuture = null;
    }
    if (!_isActive) return null;
    return joinedLiveInfo;
  }

  Future<bool> leaveChannelIfNeeded() async {
    final PlayerStatus currentStatus = status;
    if (currentStatus != PlayerStatus.inRoom &&
        currentStatus != PlayerStatus.coGuest &&
        currentStatus != PlayerStatus.end) {
      return false;
    }
    try {
      await controller.leaveChannel();
    } catch (_) {
      return false;
    }
    return true;
  }

  Future<void> dispose() {
    final Future<void>? existing = _disposeFuture;
    if (existing != null) return existing;
    _isActive = false;
    controller.onJoinLiveClicked = null;
    controller.onCloseClicked = null;
    controller.stopPlay();
    final Future<void> operation = _leaveAndDispose();
    _disposeFuture = operation;
    return operation;
  }

  Future<void> _leaveAndDispose() async {
    try {
      final Future<LiveInfo?>? pendingJoin = _joinFuture;
      if (pendingJoin != null) {
        await pendingJoin;
      }
      await controller.leaveChannel();
    } catch (_) {
    } finally {
      _disposeController();
    }
  }

  void _disposeController() {
    if (_isDisposed || _disposeScheduled) return;
    _disposeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _isDisposed = true;
      controller.dispose();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Widget build() {
    return PlayerView(
      key: ValueKey<String>('player_item_${liveID}_$_identity'),
      liveInfo: _liveInfo,
      controller: controller,
      onJoinLiveClicked: _onJoinLiveClicked,
      onCloseClicked: _onCloseClicked,
    );
  }
}
