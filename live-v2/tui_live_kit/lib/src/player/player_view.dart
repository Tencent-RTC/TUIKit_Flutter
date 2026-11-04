import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/key_metrics.dart';
import '../common/beauty/beauty_panel.dart';
import '../common/live_kit_resources.dart';
import '../common/theme/live_theme.dart';
import '../common/theme/live_toast_view.dart';
import 'summary/summary_view.dart';
import 'videoview/player_video_view.dart';
import 'preview/preview_view.dart';
import 'living/coguest/co_guest_icon.dart';
import 'living/living_view.dart';

part 'player_controller.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({
    super.key,
    required this.liveInfo,
    this.controller,
    this.onJoinLiveClicked,
    this.onCloseClicked,
  });

  final LiveInfo liveInfo;
  final PlayerViewController? controller;
  final VoidCallback? onJoinLiveClicked;
  final VoidCallback? onCloseClicked;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with WidgetsBindingObserver {
  late final PlayerViewController controller;
  late final bool ownsController;
  LiveInfo liveInfo = LiveInfo();
  final GlobalKey<LivingViewState> livingKey = GlobalKey<LivingViewState>();

  @override
  void initState() {
    super.initState();
    AdvancedBeautySession.shared.acquire(this);
    ownsController = widget.controller == null;
    controller = widget.controller ?? PlayerViewController();
    controller._attach(this);
    _applyHostCallbacks();
    controller.setLiveInfo(widget.liveInfo);
    controller.status.addListener(refresh);
    controller._joinLiveEntranceEnabled.addListener(refresh);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      controller.suspendCapture(livingKey);
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    unawaited(controller.restoreCaptureIfNeeded());
    unawaited(controller.restoreMicrophoneIfNeeded());
  }

  @override
  void didUpdateWidget(covariant PlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyHostCallbacks();
    if (oldWidget.liveInfo.liveID != widget.liveInfo.liveID || oldWidget.liveInfo != widget.liveInfo) {
      controller.setLiveInfo(widget.liveInfo);
    }
  }

  void _applyHostCallbacks() {
    final VoidCallback? onJoinLiveClicked = widget.onJoinLiveClicked;
    final VoidCallback? onCloseClicked = widget.onCloseClicked;
    if (onJoinLiveClicked != null) {
      controller.onJoinLiveClicked = onJoinLiveClicked;
    }
    if (onCloseClicked != null) {
      controller.onCloseClicked = onCloseClicked;
    }
  }

  void applyLiveInfo(LiveInfo value) {
    if (!mounted) return;
    setState(() => liveInfo = value);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void handleClose() {
    unawaited(controller._handleCloseClick());
  }

  void handleJoinLiveEntranceTap() {
    unawaited(controller._handleJoinLiveEntranceTap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdvancedBeautySession.shared.release(this);
    controller.status.removeListener(refresh);
    controller._joinLiveEntranceEnabled.removeListener(refresh);
    controller._detach(this);
    if (ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerStatus currentStatus = controller.status.value;
    final String presentedLiveID = liveInfo.liveID;
    final bool showsOverlay = currentStatus == PlayerStatus.inRoom || currentStatus == PlayerStatus.coGuest;
    final bool showsSummary = currentStatus == PlayerStatus.end;
    final bool showsEntrance = controller._joinLiveEntranceEnabled.value &&
        (currentStatus == PlayerStatus.idle || currentStatus == PlayerStatus.playing);
    return ColoredBox(
      color: LiveTheme.canvasBackground,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (!showsSummary) _buildCover(),
          if (!showsSummary) PlayerVideoView(controller: controller._videoController),
          if (showsSummary)
            SummaryView(
              liveInfo: liveInfo,
              reason: controller.endedReason,
            ),
          if (showsOverlay)
            LivingView(
              key: livingKey,
              videoGeometryChanges: controller._videoController.geometryChanges,
              videoSeatRegions: controller._videoController.seatRegions,
              adminDeviceRequestsEnabled: controller._adminDeviceRequestsEnabled,
              liveInfo: liveInfo,
              safeAreaInsets: controller._contentSafeAreaInsets,
              onCoGuestUiStateChanged: controller._handleCoGuestUiState,
              onToast: (message) {
                // Leaving or switching rooms takes effect before Living is
                // removed on the next frame. Ignore its late room callbacks.
                if (!mounted || controller.liveID != presentedLiveID) return;
                final PlayerStatus status = controller.status.value;
                if (status == PlayerStatus.inRoom || status == PlayerStatus.coGuest) {
                  controller.showToast(message);
                }
              },
            ),
          if (showsEntrance)
            PreviewView(
              liveInfo: liveInfo,
              onTapEnter: handleJoinLiveEntranceTap,
            ),
          if (showsOverlay)
            Positioned(
              right: 12,
              top: math.max(MediaQuery.paddingOf(context).top, controller._contentSafeAreaInsets.top) + 13,
              child: _PlayerCloseButton(onTap: handleClose),
            ),
          Positioned.fill(
            child: LiveToastView(controller: controller._toastController),
          ),
        ],
      ),
    );
  }

  /// 对应 iOS `PlayerVideoView.setBackground`：backgroundURL → coverURL → 默认封面。
  Widget _buildCover() {
    final String url = liveInfo.backgroundURL.isNotEmpty
        ? liveInfo.backgroundURL
        : (liveInfo.coverURL.isNotEmpty ? liveInfo.coverURL : LiveKitResources.defaultBackgroundURL);
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image(
            image: LiveKitResources.image('livekit_livelist_default_cover'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _PlayerCloseButton extends StatelessWidget {
  const _PlayerCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LiveKitResources.localizedString('tuilivekit.player.close_room'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0x2E0A0A0F),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Center(
            child: Image(
              image: LiveKitResources.image('livekit_living_close'),
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerViewControllerImpl implements PlayerViewController {
  final ValueNotifier<PlayerStatus> _status = ValueNotifier<PlayerStatus>(PlayerStatus.idle);
  final ValueNotifier<bool> _joinInProgress = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _joinLiveEntrance = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _adminDeviceRequests = ValueNotifier<bool>(false);
  final PlayerVideoViewController _video = PlayerVideoViewController();
  final LiveToastController _toast = LiveToastController();

  _PlayerViewControllerImpl() {
    _status.addListener(_syncPlayerStatusToVideo);
  }

  void _syncPlayerStatusToVideo() {
    _video.playerStatus.value = _status.value;
  }

  @override
  VoidCallback? onJoinLiveClicked;

  @override
  VoidCallback? onCloseClicked;

  LiveInfo? _liveInfo;
  _PlayerViewState? _state;
  PlayerListener? _playerListener;
  String? _joiningLiveID;
  bool _isJoinedChannel = false;
  bool _isPlaying = false;
  bool _isEntranceInitiatedJoin = false;
  bool _isClosing = false;
  EdgeInsets _safeAreaInsets = EdgeInsets.zero;

  /// 结束原因，非空时由 `SummaryView` 展示，对应 iOS `showSummaryView(reason:)`。
  @override
  String? endedReason;

  String? _backgroundCameraLiveID;
  bool _backgroundCameraIsFront = false;
  String? _backgroundMicrophoneLiveID;
  int _restoreRequestSeed = 0;
  int? _cameraRestoreRequestID;
  int? _microphoneRestoreRequestID;

  @override
  ValueListenable<PlayerStatus> get status => _status;

  @override
  LiveToastController get _toastController => _toast;

  @override
  void showToast(String message) => _toast.show(message);

  @override
  ValueListenable<bool> get joinInProgress => _joinInProgress;

  @override
  String get liveID => _liveInfo?.liveID ?? '';

  @override
  ValueListenable<bool> get _joinLiveEntranceEnabled => _joinLiveEntrance;

  @override
  ValueListenable<bool> get _adminDeviceRequestsEnabled => _adminDeviceRequests;

  @override
  PlayerVideoViewController get _videoController => _video;

  @override
  EdgeInsets get _contentSafeAreaInsets => _safeAreaInsets;

  @override
  @override
  void setLiveInfo(LiveInfo liveInfo) {
    if (_liveInfo?.liveID != liveInfo.liveID) {
      _toast.dismiss();
      stopPlay();
      if (_isJoinedChannel) _video.player.leaveChannel();
      _adminDeviceRequests.value = false;
      _isJoinedChannel = false;
      _isEntranceInitiatedJoin = false;
      endedReason = null;
      _clearBackgroundCapture();
      _status.value = PlayerStatus.idle;
    }
    _liveInfo = liveInfo;
    _video.setLiveInfo(liveInfo);
    _state?.applyLiveInfo(liveInfo);
  }

  void _clearBackgroundCapture() {
    _backgroundCameraLiveID = null;
    _backgroundMicrophoneLiveID = null;
    _cameraRestoreRequestID = null;
    _microphoneRestoreRequestID = null;
  }

  @override
  void setJoinLiveEntranceEnabled(bool enabled) {
    _joinLiveEntrance.value = enabled;
  }

  @override
  void setContentSafeAreaInsets(EdgeInsets insets) {
    _safeAreaInsets = insets;
    _state?.refresh();
  }

  @override
  void startPlay() {
    final String currentLiveID = liveID;
    if (currentLiveID.isEmpty) return;
    _clearEndedState();
    _video.startPreview(liveID: currentLiveID);
    _isPlaying = true;
    if (_status.value == PlayerStatus.idle) {
      _status.value = PlayerStatus.playing;
    }
  }

  @override
  void stopPlay() {
    _video.stopPreview();
    _isPlaying = false;
    if (_status.value == PlayerStatus.playing) {
      _status.value = PlayerStatus.idle;
    }
  }

  @override
  void setVolume(int volume) {
    _video.setVolume(volume);
  }

  void _clearEndedState() {
    if (_status.value != PlayerStatus.end) return;
    _status.value = _isPlaying ? PlayerStatus.playing : PlayerStatus.idle;
  }

  @override
  Future<bool> joinChannel({PlayerJoinCompletion? completion}) async {
    final String currentLiveID = liveID;
    if (currentLiveID.isEmpty) {
      completion?.call(null, StateError('liveID is empty'));
      return false;
    }
    if (_status.value == PlayerStatus.inRoom || _status.value == PlayerStatus.coGuest) {
      completion?.call(_liveInfo, null);
      return true;
    }
    if (_joiningLiveID == currentLiveID) return false;
    _joiningLiveID = currentLiveID;
    _joinInProgress.value = true;
    // 与 iOS `PageCell.joinChannel` 一致：进房前先解除静音，不等成功回调。
    setVolume(PlayerViewController.roomVolume);
    reportAtomicMetrics(liveIntegrationSuccessful);
    setComponent(componentLiveStream);
    final CompletionHandler result;
    try {
      result = await _video.player.joinChannel(currentLiveID);
    } catch (error) {
      if (_joiningLiveID == currentLiveID) {
        _joiningLiveID = null;
        _joinInProgress.value = false;
      }
      _isEntranceInitiatedJoin = false;
      completion?.call(null, error);
      return false;
    }
    if (_joiningLiveID != currentLiveID || liveID != currentLiveID) {
      if (result.isSuccess) _video.player.leaveChannel();
      if (_joiningLiveID == currentLiveID) {
        _joiningLiveID = null;
        _joinInProgress.value = false;
      }
      return false;
    }
    _joiningLiveID = null;
    _joinInProgress.value = false;
    if (!result.isSuccess) {
      _isEntranceInitiatedJoin = false;
      _status.value = PlayerStatus.end;
      _state?.refresh();
      completion?.call(null, result.errorMessage ?? result.errorCode);
      return false;
    }
    unawaited(CoGuestStore.create(currentLiveID).disconnect());
    _isJoinedChannel = true;
    final bool entranceInitiated = _isEntranceInitiatedJoin;
    _isEntranceInitiatedJoin = false;
    _adminDeviceRequests.value = true;
    _status.value = PlayerStatus.inRoom;
    _state?.applyLiveInfo(_liveInfo!);
    if (entranceInitiated) onJoinLiveClicked?.call();
    completion?.call(_liveInfo, null);
    return true;
  }

  @override
  Future<bool> leaveChannel({PlayerLeaveCompletion? completion}) async {
    final String currentLiveID = liveID;
    if (currentLiveID.isEmpty) {
      completion?.call(StateError('liveID is empty'));
      return false;
    }
    if (!_isJoinedChannel) {
      completion?.call(null);
      return true;
    }
    _toast.dismiss();
    _clearBackgroundCapture();
    _adminDeviceRequests.value = false;
    _isJoinedChannel = false;
    if (_status.value != PlayerStatus.end) {
      _status.value = _isPlaying ? PlayerStatus.playing : PlayerStatus.idle;
    }
    _state?.refresh();
    _video.player.leaveChannel();
    setVolume(PlayerViewController.previewVolume);
    completion?.call(null);
    return true;
  }

  @override
  Future<void> _handleJoinLiveEntranceTap() async {
    if (_isJoinedChannel) return;
    _isEntranceInitiatedJoin = true;
    await joinChannel();
  }

  /// 对应 iOS `PlayerViewImpl.handleClose`：先完成离房再回调，期间防重。
  @override
  Future<void> _handleCloseClick() async {
    if (_isClosing) return;
    _isClosing = true;
    await leaveChannel();
    _isClosing = false;
    onCloseClicked?.call();
  }

  @override
  void _handleCoGuestUiState(CoGuestStatus uiState) {
    if (_liveInfo == null || !_isJoinedChannel) return;
    switch (uiState) {
      case CoGuestStatus.requesting:
      case CoGuestStatus.coGuesting:
        _status.value = PlayerStatus.coGuest;
      case CoGuestStatus.idle:
        if (_status.value == PlayerStatus.coGuest) {
          _status.value = PlayerStatus.inRoom;
        }
    }
  }

  void _showEnded({String? reason}) {
    _toast.dismiss();
    _joiningLiveID = null;
    _joinInProgress.value = false;
    _adminDeviceRequests.value = false;
    _isEntranceInitiatedJoin = false;
    _isJoinedChannel = false;
    _clearBackgroundCapture();
    _video.player.leaveChannel();
    stopPlay();
    endedReason = reason;
    _status.value = PlayerStatus.end;
    _state?.refresh();
    if (reason != null && reason.isNotEmpty) {
      showToast(reason);
    }
  }

  /// 对应 iOS `PlayerViewImpl.suspendCapture`：退后台关闭摄像头并静音麦位。
  @override
  void suspendCapture(GlobalKey<LivingViewState> livingKey) {
    if (!_isJoinedChannel || _status.value != PlayerStatus.coGuest) return;
    final String liveID = this.liveID;
    if (liveID.isEmpty) return;
    final String selfID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    final SeatUserInfo? seat = _selfSeat(liveID, selfID);
    final bool onSeat = selfID.isNotEmpty && seat != null;
    final DeviceState state = DeviceStore.shared.state;
    if (onSeat && _backgroundCameraLiveID == null && state.cameraStatus.value == DeviceStatus.on) {
      _backgroundCameraLiveID = liveID;
      _backgroundCameraIsFront = state.isFrontCamera.value;
    }
    _cameraRestoreRequestID = null;
    final bool wasOpening =
        livingKey.currentState?.invalidateCoGuestCameraRequests(allowRestore: _backgroundCameraLiveID != null) ?? false;
    if ((onSeat && _backgroundCameraLiveID != null) || wasOpening) {
      DeviceStore.shared.closeLocalCamera();
    }
    _microphoneRestoreRequestID = null;
    if (seat?.microphoneStatus == DeviceStatus.on) {
      _backgroundMicrophoneLiveID ??= liveID;
      LiveSeatStore.create(liveID).muteMicrophone();
    }
  }

  /// 对应 iOS `restoreCaptureIfNeeded`：只为仍在本场麦位上的本人恢复摄像头。
  @override
  Future<void> restoreCaptureIfNeeded() async {
    final String? liveID = _backgroundCameraLiveID;
    if (liveID == null || _cameraRestoreRequestID != null) return;
    final String selfID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (selfID.isEmpty || this.liveID != liveID) return;
    if (!_isJoinedChannel || _status.value != PlayerStatus.coGuest) return;
    if (_selfSeat(liveID, selfID) == null) return;
    final int requestID = ++_restoreRequestSeed;
    _cameraRestoreRequestID = requestID;
    await DeviceStore.shared.openLocalCamera(_backgroundCameraIsFront);
    if (_cameraRestoreRequestID != requestID) {
      DeviceStore.shared.closeLocalCamera();
      return;
    }
    _cameraRestoreRequestID = null;
    final bool stillValid = _isJoinedChannel &&
        _status.value == PlayerStatus.coGuest &&
        this.liveID == liveID &&
        _selfSeat(liveID, selfID) != null;
    _backgroundCameraLiveID = null;
    if (!stillValid) {
      DeviceStore.shared.closeLocalCamera();
    }
  }

  /// 对应 iOS `restoreMicrophoneIfNeeded`：只为原本开麦且仍被允许开麦的本人恢复。
  @override
  Future<void> restoreMicrophoneIfNeeded() async {
    final String? liveID = _backgroundMicrophoneLiveID;
    if (liveID == null || _microphoneRestoreRequestID != null) return;
    final String selfID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (selfID.isEmpty || this.liveID != liveID) return;
    if (!_isJoinedChannel || _status.value != PlayerStatus.coGuest) return;
    final SeatUserInfo? seat = _selfSeat(liveID, selfID);
    if (seat == null || seat.allowOpenMicrophone != true) {
      _backgroundMicrophoneLiveID = null;
      return;
    }
    final int requestID = ++_restoreRequestSeed;
    _microphoneRestoreRequestID = requestID;
    await LiveSeatStore.create(liveID).unmuteMicrophone();
    if (_microphoneRestoreRequestID != requestID) return;
    _microphoneRestoreRequestID = null;
    _backgroundMicrophoneLiveID = null;
  }

  SeatUserInfo? _selfSeat(String liveID, String selfID) {
    if (selfID.isEmpty) return null;
    for (final SeatUserInfo user in CoGuestStore.create(liveID).coGuestState.connected.value) {
      if (user.userID == selfID) return user;
    }
    return null;
  }

  static String _interruptionMessage(KickedOutReason reason) {
    final String key;
    switch (reason) {
      case KickedOutReason.byLoggedOnOtherDevice:
        key = 'other_device';
      case KickedOutReason.byServer:
        key = 'server';
      case KickedOutReason.forNetworkDisconnected:
        key = 'network';
      case KickedOutReason.forLiveChannelExpired:
        key = 'expired';
      case KickedOutReason.byAdmin:
        key = 'removed';
    }
    return LiveKitResources.localizedString('tuilivekit.player.interruption.$key');
  }

  @override
  void _attach(_PlayerViewState state) {
    _state = state;
    final listener = PlayerListener(
      liveEnded: (_) => _showEnded(),
      kickedOut: (KickedOutReason reason, String _) => _showEnded(reason: _interruptionMessage(reason)),
    );
    _playerListener = listener;
    _video.player.addListener(listener);
    if (_liveInfo != null) {
      state.applyLiveInfo(_liveInfo!);
    }
  }

  @override
  void _detach(_PlayerViewState state) {
    if (_state != state) return;
    _state = null;
    final PlayerListener? listener = _playerListener;
    if (listener != null) {
      _video.player.removeListener(listener);
      _playerListener = null;
    }
  }

  @override
  void dispose() {
    _adminDeviceRequests.value = false;
    _adminDeviceRequests.dispose();
    _joinInProgress.dispose();
    _joinLiveEntrance.dispose();
    _joiningLiveID = null;
    _state = null;
    _toast.dispose();
    _video.dispose();
    _status.removeListener(_syncPlayerStatusToVideo);
    _status.dispose();
  }
}
