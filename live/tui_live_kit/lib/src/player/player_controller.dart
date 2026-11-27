part of 'player_view.dart';

typedef PlayerJoinCompletion = void Function(LiveInfo? liveInfo, Object? error);

typedef PlayerLeaveCompletion = void Function(Object? error);

enum PlayerStatus {
  idle,
  playing,
  inRoom,
  coGuest,
  end,
}

abstract class PlayerViewController {
  factory PlayerViewController() = _PlayerViewControllerImpl;

  /// 房外预览音量，对应 iOS `PageCell.startPreview` 的 `setVolume(0)`。
  static const int previewVolume = 0;

  /// 房内播放音量，对应 iOS `PageCell.joinChannel` 的 `setVolume(100)`。
  static const int roomVolume = 100;

  ValueListenable<PlayerStatus> get status;

  ValueListenable<bool> get joinInProgress;

  String get liveID;

  /// 结束原因，非空时由 `SummaryView` 展示。
  String? endedReason;

  /// 房内提示统一入口，对应 iOS `PlayerViewImpl.showToast`。
  void showToast(String message);

  LiveToastController get _toastController;

  void suspendCapture(GlobalKey<LivingViewState> livingKey);

  Future<void> restoreCaptureIfNeeded();

  Future<void> restoreMicrophoneIfNeeded();

  VoidCallback? get onJoinLiveClicked;
  set onJoinLiveClicked(VoidCallback? value);

  VoidCallback? get onCloseClicked;
  set onCloseClicked(VoidCallback? value);

  void setLiveInfo(LiveInfo liveInfo);

  void startPlay();

  void stopPlay();

  /// 设置播放音量，对应 iOS `PlayerView.setVolume`；由入口在预览与进房时显式调用。
  void setVolume(int volume);

  Future<bool> joinChannel({PlayerJoinCompletion? completion});

  Future<bool> leaveChannel({PlayerLeaveCompletion? completion});

  void setJoinLiveEntranceEnabled(bool enabled);

  void setContentSafeAreaInsets(EdgeInsets insets);

  void dispose();

  ValueListenable<bool> get _joinLiveEntranceEnabled;

  ValueListenable<bool> get _adminDeviceRequestsEnabled;

  PlayerVideoViewController get _videoController;

  EdgeInsets get _contentSafeAreaInsets;

  void _handleCoGuestUiState(CoGuestStatus uiState);

  Future<void> _handleJoinLiveEntranceTap();

  Future<void> _handleCloseClick();

  void _attach(_PlayerViewState state);

  void _detach(_PlayerViewState state);
}
