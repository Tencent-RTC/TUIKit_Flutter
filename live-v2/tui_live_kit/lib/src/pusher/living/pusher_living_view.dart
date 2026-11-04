import '../settings/pusher_settings_action_handling.dart';
import '../video/pusher_video_view.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/atomicxcore.dart' show CoGuestLayoutTemplate, LikeStore, LoginStore;

import '../../common/gift/display/gift_display_view.dart';
import '../../common/gift/gift_barrage_store.dart';
import '../../common/barrage/barrage_input_view.dart';
import '../../common/barrage/barrage_stream_view.dart';
import '../../common/barrage/barrage_ui_store.dart';
import '../../common/like/like_animation_view.dart';
import '../../common/theme/live_toast_view.dart';
import '../../common/live_kit_resources.dart';
import 'audience/pusher_audience_manage_view.dart';
import '../../common/audience/audience_welcome_view.dart';
import 'audience/pusher_audience_store.dart';
import 'audience/pusher_audience_list_view.dart';
import 'coguest/control_panel/pusher_coguest_settings_view.dart';
import 'coguest/control_panel/pusher_coguest_audience_manage_view.dart';
import 'coguest/pusher_coguest_store.dart';
import 'end_confirm/pusher_end_confirmation_view.dart';
import 'live_bottom_toolbar_view.dart';
import 'live_header_view.dart';
import 'music/pusher_music_view.dart';
import 'pause/pusher_pause_overlay_view.dart';
import 'pusher_living_settings_view.dart';
import 'status/pusher_live_status_view.dart';

class PusherLivingView extends StatefulWidget {
  const PusherLivingView({
    super.key,
    required this.liveID,
    required this.coGuestActionHandler,
    required this.hostName,
    required this.hostAvatarURL,
    required this.elapsedSeconds,
    required this.pauseState,
    required this.settings,
    required this.settingsActionHandler,
    required this.deviceStatus,
    required this.coGuestState,
    required this.coGuestChanges,
    required this.coGuestLayout,
    this.onCoGuestStageTap,
    this.coGuestGeometryChanges,
    this.coGuestSmallWindowRegions,
    this.coGuestGridRegions,
    this.hasConnected = false,
    required this.selectedCoGuestUserID,
    this.onDismissCoGuestActions,
    this.onShowSettings,
    this.onShowBeauty,
    this.onToggleMute,
    this.onPause,
    this.onResume,
    this.onEnd,
    this.onFlipCamera,
  });

  final String liveID;
  final bool hasConnected;
  final PusherCoGuestActionHandling coGuestActionHandler;
  final String hostName;
  final String hostAvatarURL;
  final ValueListenable<int> elapsedSeconds;
  final ValueListenable<(bool, int)> pauseState;
  final ValueListenable<PusherSettingsState> settings;
  final PusherSettingsActionHandling settingsActionHandler;
  final ValueListenable<PusherDeviceStatusState> deviceStatus;

  final PusherCoGuestState coGuestState;

  final Listenable coGuestChanges;
  final ValueListenable<(CoGuestLayoutTemplate, int)> coGuestLayout;

  final bool Function(Offset globalPosition)? onCoGuestStageTap;
  final Listenable? coGuestGeometryChanges;
  final List<Rect> Function()? coGuestSmallWindowRegions;
  final List<Rect> Function()? coGuestGridRegions;
  final ValueListenable<String?> selectedCoGuestUserID;
  final VoidCallback? onDismissCoGuestActions;

  final VoidCallback? onShowSettings;
  final VoidCallback? onShowBeauty;

  final VoidCallback? onToggleMute;
  final VoidCallback? onPause;

  final VoidCallback? onResume;

  final VoidCallback? onEnd;

  final VoidCallback? onFlipCamera;

  @override
  State<PusherLivingView> createState() => PusherLivingViewState();
}

class PusherLivingViewState extends State<PusherLivingView> with WidgetsBindingObserver {
  bool _isForeground = true;
  late bool _isPaused;
  final _likes = ValueNotifier<int>(0);
  final _audience = ValueNotifier(AudienceState());
  final _comments = ValueNotifier<List<LiveMessage>>(const []);
  final _coGuestUnread = ValueNotifier<bool>(false);

  /// Keep the same precedence as Android PusherLivingView.handleBackPressed.
  /// Only the topmost active UI closes; a paused broadcast remains paused.
  void handleBackPressed() {
    if (_isPaused) return;
    if (widget.selectedCoGuestUserID.value != null) {
      widget.onDismissCoGuestActions?.call();
    } else if (_isCoGuestSettingsVisible) {
      setState(() => _isCoGuestSettingsVisible = false);
    } else if (_isLiveStatusVisible) {
      setState(() => _isLiveStatusVisible = false);
    } else if (_isEndConfirmationVisible) {
      setState(() => _isEndConfirmationVisible = false);
    } else if (_selectedAudience != null) {
      setState(() => _selectedAudience = null);
    } else if (_isAudienceListVisible) {
      setState(() => _isAudienceListVisible = false);
    } else if (_isMusicVisible) {
      setState(() => _isMusicVisible = false);
    } else if (_isSettingsVisible) {
      setState(() => _isSettingsVisible = false);
    } else if (_isCommentComposerVisible) {
      setState(() => _isCommentComposerVisible = false);
    }
  }

  bool get _isCoGuestStageActive =>
      widget.coGuestLayout.value.$2 > 0 || widget.coGuestLayout.value.$1 != CoGuestLayoutTemplate.floatLayout;

  /// 底部工具栏在安全区之上的高度。
  static const double _toolbarHeight = 68;

  /// Input keeps the currently visible viewport and the normal notice anchors.
  double? _composerHeight;
  double? _composerContentHeight;
  bool _hasAnnouncement = false;

  void showSystemAnnouncement() {
    if (_hasAnnouncement) return;
    _hasAnnouncement = true;
    _onCommentsChanged();
  }

  static const Duration _continuousTapInterval = Duration(milliseconds: 420);

  final LikeAnimationController _likeAnimationController = LikeAnimationController();
  final LiveToastController _toastController = LiveToastController();
  final GlobalKey _likeLayerKey = GlobalKey();
  final GlobalKey _moreActionKey = GlobalKey();

  late final LikeStore _likeStore;
  bool _isLikeActive = false;
  final _likeSender = LikeSender();

  void _activateLikes() {
    _likeStore = LikeStore.create(widget.liveID);
    _isLikeActive = true;
    final store = _likeStore;
    _likeSender.activate((count) => store.sendLike(count).ignore());
    _likes.value = _likeStore.likeState.totalLikeCount.value;
    _likeStore.likeState.totalLikeCount.addListener(_onLikeCountChanged);
  }

  void _onLikeCountChanged() {
    if (!mounted || !_isLikeActive) return;
    _likes.value = _likeStore.likeState.totalLikeCount.value;
  }

  void _registerLike() {
    if (!_isLikeActive || _isPaused || !_isForeground) return;
    _likeSender.sendLike();
  }

  void deactivateLikes({bool discardPending = false}) {
    if (!_isLikeActive) return;
    _isLikeActive = false;
    _likeSender.deactivate(discardPending: discardPending);
    _likeStore.likeState.totalLikeCount.removeListener(_onLikeCountChanged);
  }

  late final BarrageUIStore _barrageStore;
  bool _isCommentActive = false;

  void _activateComments() {
    _barrageStore = BarrageUIStore();
    _barrageStore.onSendError = (message) {
      if (_isCommentActive && mounted) _toastController.show(message);
    };
    _isCommentActive = true;
    _barrageStore.onStateChanged = _onCommentsChanged;
    _barrageStore.activate(
      liveID: widget.liveID,
      hostUserID: LoginStore.shared.loginState.loginUserInfo?.userID ?? '',
    );
  }

  void _onCommentsChanged() {
    if (!_isCommentActive || !mounted) return;
    _comments.value = [
      if (_hasAnnouncement)
        LiveMessage(
            id: 'pusher-system-${widget.liveID}',
            userName: '',
            content: LiveKitResources.localizedString('tuilivekit.pusher.system_announcement'),
            level: 0,
            isSystemAnnouncement: true),
      ..._barrageStore.comments,
    ];
  }

  Future<void> _sendComment(String text) => _barrageStore.sendComment(text);

  void deactivateComments() {
    if (!_isCommentActive) return;
    _isCommentActive = false;
    _barrageStore.onStateChanged = null;
    _barrageStore.onSendError = null;
    _barrageStore.deactivate();
    _toastController.dismiss();
    deactivateGiftComments();
  }

  late final GiftBarrageStore _giftBarrageStore;
  bool _isGiftCommentActive = false;

  void _activateGiftComments() {
    _giftBarrageStore = GiftBarrageStore(liveID: widget.liveID);
    _isGiftCommentActive = true;
    _giftBarrageStore.onGiftBarrageSettled = _appendGiftComment;
    _giftBarrageStore.activate();
    _giftBarrageStore.setEnabled(!_isPaused);
  }

  void deactivateGiftComments() {
    if (!_isGiftCommentActive) return;
    _isGiftCommentActive = false;
    _giftBarrageStore.deactivate();
  }

  void _appendGiftComment(LiveGiftBarrage gift) {
    if (!_isGiftCommentActive || !_isCommentActive) {
      return;
    }
    _barrageStore.appendGiftComment(gift);
  }

  late final PusherAudienceStore _audienceStore;
  AudienceState get _audienceState => _audience.value;

  void refreshAudience() => _audienceStore.refresh();
  void deactivateAudience() {
    _audienceStore.deactivate(resetState: false);
    _audienceEntranceController.reset();
  }

  void _onAudienceStateChanged() {
    if (!mounted) return;
    final state = _audienceStore.state.copy();
    if (!_audience.value.isSameAs(state)) _audience.value = state;
    _dismissDepartedAudience();
  }

  final AudienceWelcomeController _audienceEntranceController = AudienceWelcomeController();

  late final GiftDisplayController _giftDisplayController;

  final _messageVisibleContentHeight = ValueNotifier<double>(0);
  final Stopwatch _stageTapClock = Stopwatch();
  Duration? _lastStageTapTime;
  double _commentInputBarHeight = BarrageInputView.inputBarHeight;
  final GlobalKey<PusherAudienceManageViewState> _audienceManageKey = GlobalKey();
  final GlobalKey<PusherMusicViewState> _musicKey = GlobalKey();

  // 浮层显隐；关闭优先级见 [handleBackPressed]。
  bool _isAudienceListVisible = false;
  AudienceUser? _selectedAudience;
  bool _isSettingsVisible = false;
  bool _isCommentComposerVisible = false;
  bool _isMusicVisible = false;
  bool _isCoGuestSettingsVisible = false;
  bool _isLiveStatusVisible = false;
  bool _isEndConfirmationVisible = false;

  void showCoGuestToast(String message) => _toastController.show(message);
  void deactivateMusic() => _musicKey.currentState?.deactivateMusic();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isForeground = lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden &&
        lifecycle != AppLifecycleState.detached;
    _stageTapClock.start();
    _isPaused = widget.pauseState.value.$1;
    widget.pauseState.addListener(_onPauseChanged);
    widget.coGuestChanges.addListener(_onCoGuestChanged);
    widget.coGuestGeometryChanges?.addListener(_onNoticeChanged);
    widget.coGuestLayout.addListener(_onNoticeChanged);
    _coGuestUnread.value = widget.coGuestState.hasUnreadApplicant;
    _giftDisplayController = GiftDisplayController(liveID: widget.liveID);
    _giftDisplayController.setSuspended(_isPaused);
    _giftDisplayController.notice.addListener(_onNoticeChanged);
    _activateLikes();
    _hasAnnouncement = widget.hasConnected;
    _activateComments();
    _activateGiftComments();
    _audienceStore = PusherAudienceStore(liveID: widget.liveID);
    _audienceStore.addListener(_onAudienceStateChanged);
    _audienceStore.onAudienceEntered = _onAudienceEntered;
    _audienceStore.onActionCompleted = _onAudienceActionCompleted;
    _audienceStore.activate();
    _audienceStore.refresh();
    _onAudienceStateChanged();
    // 横幅出现时胶囊再上抬 32。
    _audienceEntranceController.addListener(_onAudienceWelcomeVisibilityChanged);
  }

  @override
  void didUpdateWidget(PusherLivingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pauseState != widget.pauseState) {
      oldWidget.pauseState.removeListener(_onPauseChanged);
      widget.pauseState.addListener(_onPauseChanged);
      _onPauseChanged();
    }
    if (oldWidget.coGuestChanges != widget.coGuestChanges) {
      oldWidget.coGuestChanges.removeListener(_onCoGuestChanged);
      widget.coGuestChanges.addListener(_onCoGuestChanged);
    }
    if (oldWidget.coGuestGeometryChanges != widget.coGuestGeometryChanges) {
      oldWidget.coGuestGeometryChanges?.removeListener(_onNoticeChanged);
      widget.coGuestGeometryChanges?.addListener(_onNoticeChanged);
    }
    if (oldWidget.coGuestLayout != widget.coGuestLayout) {
      oldWidget.coGuestLayout.removeListener(_onNoticeChanged);
      widget.coGuestLayout.addListener(_onNoticeChanged);
    }
    if (widget.hasConnected) showSystemAnnouncement();
    _onCoGuestChanged();
  }

  void _onCoGuestChanged() {
    _coGuestUnread.value = widget.coGuestState.hasUnreadApplicant;
    // Requests arriving while the open panel is visible are already seen.
    if (widget.coGuestState.hasUnreadApplicant && _isCoGuestSettingsVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isCoGuestSettingsVisible && widget.coGuestState.hasUnreadApplicant) {
          widget.coGuestActionHandler.markApplicantsSeen();
        }
      });
    }
  }

  void _onPauseChanged() {
    final paused = widget.pauseState.value.$1;
    if (_isPaused == paused) return;
    setState(() => _isPaused = paused);
    _giftDisplayController.setSuspended(paused);
    _giftBarrageStore.setEnabled(!paused);
    _musicKey.currentState?.setSuspended(paused || !_isForeground);
    if (paused) {
      _audienceEntranceController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDismissCoGuestActions?.call();
      });
    }
  }

  void _dismissDepartedAudience() {
    final AudienceUser? selectedAudience = _selectedAudience;
    if (selectedAudience != null &&
        !_audienceState.users.any(
          (AudienceUser user) => user.userID == selectedAudience.userID,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _selectedAudience?.userID == selectedAudience.userID) {
          final panel = _audienceManageKey.currentState;
          if (panel != null) {
            panel.dismiss();
          } else {
            setState(() => _selectedAudience = null);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.coGuestGeometryChanges?.removeListener(_onNoticeChanged);
    widget.coGuestLayout.removeListener(_onNoticeChanged);
    _stageTapClock.stop();
    widget.pauseState.removeListener(_onPauseChanged);
    widget.coGuestChanges.removeListener(_onCoGuestChanged);
    deactivateLikes();
    deactivateComments();
    _giftBarrageStore.dispose();
    _giftDisplayController.notice.removeListener(_onNoticeChanged);
    _giftDisplayController.dispose();
    _audienceStore.onAudienceEntered = null;
    _audienceStore.onActionCompleted = null;
    _audienceStore.removeListener(_onAudienceStateChanged);
    _audienceStore.dispose();
    _audienceEntranceController.removeListener(_onAudienceWelcomeVisibilityChanged);
    _audienceEntranceController.dispose();
    _likeAnimationController.dispose();
    _toastController.dispose();
    _likes.dispose();
    _audience.dispose();
    _comments.dispose();
    _coGuestUnread.dispose();
    _messageVisibleContentHeight.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isForeground) setState(() => _isForeground = true);
      _musicKey.currentState?.setSuspended(_isPaused);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_isForeground) setState(() => _isForeground = false);
      _musicKey.currentState?.setSuspended(true);
      _lastStageTapTime = null;
      _audienceEntranceController.reset();
      _likeAnimationController.removeAllAnimations();
    }
  }

  bool get _canHandleStageLike =>
      _isForeground &&
      !_isPaused &&
      !_isAudienceListVisible &&
      _selectedAudience == null &&
      !_isSettingsVisible &&
      !_isCommentComposerVisible &&
      !_isMusicVisible &&
      !_isCoGuestSettingsVisible &&
      widget.selectedCoGuestUserID.value == null &&
      !_isLiveStatusVisible &&
      !_isEndConfirmationVisible;

  /// 打开抽屉同时把申请标记为已读。
  void _showCoGuestSettings() {
    setState(() => _isCoGuestSettingsVisible = true);
    widget.coGuestActionHandler.markApplicantsSeen();
  }

  void _onAudienceEntered(AudienceWelcome entrance) {
    if (!mounted || !_isForeground || _isPaused) {
      return;
    }
    _audienceEntranceController.enqueue(entrance);
  }

  void _onAudienceActionCompleted(String userID, AudienceAction action, bool succeeded) {
    if (!mounted) return;
    _audienceManageKey.currentState?.completeAction(userID, action, succeeded);
    if (!succeeded) return;
    final String key;
    switch (action) {
      case AudienceAction.mute:
        key = 'tuilivekit.pusher.audience.muted_toast';
      case AudienceAction.unmute:
        key = 'tuilivekit.pusher.audience.unmuted_toast';
      case AudienceAction.remove:
        key = 'tuilivekit.pusher.audience.removed_toast';
      case AudienceAction.follow:
      case AudienceAction.unfollow:
        return;
    }
    String name = userID;
    for (final AudienceUser user in _audienceState.users) {
      if (user.userID == userID) {
        name = user.userName.isEmpty ? user.userID : user.userName;
        break;
      }
    }
    _toastController.show(LiveKitResources.localizedFormat(key, name));
  }

  void _onNoticeChanged() {
    if (mounted) setState(() {});
  }

  void _onAudienceWelcomeVisibilityChanged() {
    if (mounted) setState(() {});
  }

  Offset? _likeAnimationOrigin() {
    final RenderBox? moreBox = _moreActionKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? layerBox = _likeLayerKey.currentContext?.findRenderObject() as RenderBox?;
    if (moreBox == null || layerBox == null) {
      return null;
    }
    final Offset global = moreBox.localToGlobal(Offset(moreBox.size.width / 2, -10));
    return layerBox.globalToLocal(global);
  }

  void _onStageTap(TapUpDetails details) {
    if (!_canHandleStageLike) {
      _lastStageTapTime = null;
      return;
    }
    if (widget.onCoGuestStageTap?.call(details.globalPosition) == true) {
      _lastStageTapTime = null;
      return;
    }
    final Duration now = _stageTapClock.elapsed;
    final Duration? lastTapTime = _lastStageTapTime;
    _lastStageTapTime = now;
    final bool isContinuousTap = lastTapTime != null && now - lastTapTime <= _continuousTapInterval;
    if (!isContinuousTap) {
      return;
    }

    final RenderBox? layerBox = _likeLayerKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset? origin = _likeAnimationOrigin();
    if (layerBox == null || origin == null) {
      return;
    }
    _likeAnimationController.showLocalLike(
      point: layerBox.globalToLocal(details.globalPosition),
      auxiliaryOrigin: origin,
    );
    _registerLike();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;

    return LayoutBuilder(builder: (context, constraints) {
      final layout = _interactionLayout(constraints.biggest, padding);
      final boundary = _interactionTop(constraints.biggest);
      final giftDisplayView = GiftDisplayView(
          controller: _giftDisplayController,
          noticeBottom: constraints.maxHeight - layout.giftNoticeBottom,
          noticeTopBoundary: boundary);
      final frame = _commentFrame(padding, layout);
      return Stack(
        children: <Widget>[
          // 舞台连点手势层：与 iOS 一样挂在容器自身，上层按钮会先赢得手势。
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onStageTap,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 170,
            child: _LivingScrimView(direction: _LivingScrimDirection.top),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // 保持渐变顶部比视频底边高 74，随同一安全区移动。
            height: 74 + PusherVideoView.bottomInsetOf(context),
            child: const _LivingScrimView(direction: _LivingScrimDirection.bottom),
          ),
          Positioned(
            left: 12,
            right: 12,
            // Android 按 Ardot 77:405 的 46/844 保留顶部留白比例，
            // 系统保护区独立兜底；iOS 保持模版的 safeArea.top - 1。
            top: defaultTargetPlatform == TargetPlatform.android
                ? math.max(MediaQuery.viewPaddingOf(context).top, constraints.maxHeight * 46 / 844)
                : padding.top - 1,
            height: 67,
            child: ListenableBuilder(
                listenable: Listenable.merge([
                  widget.elapsedSeconds,
                  _likes,
                  _audience,
                  widget.deviceStatus,
                ]),
                builder: (context, _) => LiveHeaderView(
                      hostName: widget.hostName,
                      hostAvatarURL: widget.hostAvatarURL,
                      elapsedSeconds: widget.elapsedSeconds.value,
                      likeCount: _likes.value,
                      audience: _audienceState.users,
                      viewerCount: _audienceState.count,
                      networkQuality: widget.deviceStatus.value.networkQuality,
                      onAudience: _showAudienceList,
                      onClose: () => setState(() => _isEndConfirmationVisible = true),
                      onStatus: () => setState(() => _isLiveStatusVisible = true),
                    )),
          ),
          Positioned(
              left: 12,
              bottom: frame.bottom,
              width: _commentWidth(constraints.biggest, frame),
              height: frame.height,
              child: ValueListenableBuilder<List<LiveMessage>>(
                  valueListenable: _comments,
                  builder: (context, messages, _) => BarrageStreamView(
                      messages: messages,
                      maximumVisibleHeight: _isCommentComposerVisible ? null : layout.visibleCommentHeight,
                      onContentHeightChanged: (height) {
                        if (!mounted || (_messageVisibleContentHeight.value - height).abs() < .5) return;
                        _messageVisibleContentHeight.value = height;
                        setState(() {});
                      }))),
          Positioned(
              left: 0,
              right: 0,
              top: layout.welcomeTop,
              height: 28,
              child: ClipRect(
                  clipper: _WelcomeClipper(boundary == null ? 0 : math.max(0, boundary - layout.welcomeTop)),
                  child: AudienceWelcomeView(controller: _audienceEntranceController))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _toolbarHeight + padding.bottom,
            child: ListenableBuilder(
                listenable: Listenable.merge([
                  _coGuestUnread,
                  widget.coGuestLayout,
                ]),
                builder: (context, _) => LiveBottomToolbarView(
                      moreActionKey: _moreActionKey,
                      onPK: () => _toastController
                          .show(LiveKitResources.localizedString('tuilivekit.pusher.living.pk_developing')),
                      onFlipCamera: widget.onFlipCamera,
                      onShowBackgroundMusic: () => setState(() => _isMusicVisible = true),
                      onMore: _showSettings,
                      onCoGuest: _showCoGuestSettings,
                      hasCoGuestUnread: _coGuestUnread.value,
                      isCoGuestStageActive: _isCoGuestStageActive,
                    )),
          ),
          Positioned.fill(
            key: _likeLayerKey,
            child: LikeAnimationView(
              controller: _likeAnimationController,
              liveID: _isPaused || !_isForeground ? null : widget.liveID,
              auxiliaryOriginProvider: _likeAnimationOrigin,
            ),
          ),
          // 礼物浮层在点赞动画之上、各类抽屉之下。
          Positioned.fill(child: giftDisplayView),
          Positioned.fill(
            key: const ValueKey('livingSettings'),
            child: ValueListenableBuilder<PusherSettingsState>(
                valueListenable: widget.settings,
                builder: (context, settings, _) => PusherLivingSettingsView(
                      onShowBeauty: widget.onShowBeauty,
                      settings: settings,
                      settingsActionHandler: widget.settingsActionHandler,
                      isPresented: _isSettingsVisible,
                      onDismiss: () => setState(() => _isSettingsVisible = false),
                      onToggleMute: widget.onToggleMute,
                      onPause: widget.onPause,
                      onShowComment: _showComment,
                    )),
          ),
          Positioned.fill(
            key: const ValueKey('commentComposer'),
            child: BarrageInputView(
              isPresented: _isCommentComposerVisible,
              onDismiss: () => setState(() => _isCommentComposerVisible = false),
              onSend: _sendComment,
              onInputBarHeightChanged: (height) {
                if (mounted && height != _commentInputBarHeight) {
                  setState(() => _commentInputBarHeight = height);
                }
              },
            ),
          ),
          Positioned.fill(
            key: const ValueKey('music'),
            child: PusherMusicView(
              key: _musicKey,
              liveID: widget.liveID,
              isSuspended: _isPaused || !_isForeground,
              isPresented: _isMusicVisible,
              onDismiss: () => setState(() => _isMusicVisible = false),
            ),
          ),
          if (_isPaused)
            Positioned.fill(
              child: ValueListenableBuilder<(bool, int)>(
                  valueListenable: widget.pauseState,
                  builder: (context, pause, _) => PusherPauseOverlayView(
                        seconds: pause.$2,
                        onResume: widget.onResume,
                      )),
            ),
          if (_isAudienceListVisible)
            Positioned.fill(
              child: ValueListenableBuilder<AudienceState>(
                  valueListenable: _audience,
                  builder: (context, audience, _) => PusherAudienceListView(
                        audience: _audienceState.users,
                        onDismiss: () => setState(() => _isAudienceListVisible = false),
                        onSelectAudience: (AudienceUser user) {
                          setState(() => _selectedAudience = user);
                          _audienceStore.refreshFollowStatus(user.userID);
                        },
                      )),
            ),
          if (_selectedAudience case final AudienceUser selectedAudience)
            Positioned.fill(
              child: ValueListenableBuilder<AudienceState>(
                  valueListenable: _audience,
                  builder: (context, audience, _) => PusherAudienceManageView(
                        key: _audienceManageKey,
                        user: _audienceState.users.firstWhere(
                          (AudienceUser user) => user.userID == selectedAudience.userID,
                          orElse: () => selectedAudience,
                        ),
                        state: _audienceState,
                        onDismiss: () => setState(() => _selectedAudience = null),
                        onToggleFollow: (String userID) => _audienceStore.toggleFollow(userID),
                        onToggleMessagePermission: (String userID) => _audienceStore.toggleMessagePermission(userID),
                        onRemoveFromRoom: (String userID) => _audienceStore.removeFromRoom(userID),
                      )),
            ),
          if (_isEndConfirmationVisible)
            Positioned.fill(
              child: ValueListenableBuilder<AudienceState>(
                  valueListenable: _audience,
                  builder: (context, audience, _) => PusherEndConfirmationView(
                        viewerCount: _audienceState.count,
                        onDismiss: () => setState(() => _isEndConfirmationVisible = false),
                        onConfirmEnd: widget.onEnd,
                      )),
            ),
          if (_isCoGuestSettingsVisible)
            Positioned.fill(
              child: ListenableBuilder(
                  listenable: widget.coGuestChanges,
                  builder: (context, _) => PusherCoGuestSettingsView(
                        state: widget.coGuestState,
                        onDismiss: () => setState(() => _isCoGuestSettingsVisible = false),
                        actionHandler: widget.coGuestActionHandler,
                      )),
            ),
          if (_isLiveStatusVisible)
            Positioned.fill(
              child: ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.elapsedSeconds,
                    _likes,
                    _audience,
                    widget.settings,
                    widget.deviceStatus,
                  ]),
                  builder: (context, _) => PusherLiveStatusView(
                        onSetCaptureVolume: widget.settingsActionHandler.setCaptureVolume,
                        elapsedSeconds: widget.elapsedSeconds.value,
                        viewerCount: _audienceState.count,
                        likeCount: _likes.value,
                        liveID: widget.liveID,
                        settings: widget.settings.value,
                        deviceStatus: widget.deviceStatus.value,
                        onDismiss: () => setState(() => _isLiveStatusVisible = false),
                      )),
            ),
          // Keep the empty state positioned so it cannot size the stage.
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                widget.selectedCoGuestUserID,
                widget.coGuestChanges,
              ]),
              builder: (context, _) {
                final userID = widget.selectedCoGuestUserID.value;
                if (userID == null) return const SizedBox.shrink();
                return PusherCoGuestAudienceManageView(
                  userID: userID,
                  state: widget.coGuestState,
                  onDismiss: widget.onDismissCoGuestActions,
                  actionHandler: widget.coGuestActionHandler,
                );
              },
            ),
          ),
          Positioned.fill(child: LiveToastView(controller: _toastController)),
        ],
      );
    });
  }

  double? _interactionTop(Size size) {
    final template = widget.coGuestLayout.value.$1;
    if (template != CoGuestLayoutTemplate.gridLayout &&
        !(template == CoGuestLayoutTemplate.dynamicLayout && widget.coGuestLayout.value.$2 > 0)) {
      return null;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return size.height;
    final bounds = Offset.zero & size;
    final regions = (widget.coGuestGridRegions?.call() ?? <Rect>[])
        .map((r) => box.globalToLocal(r.topLeft) & r.size)
        .where((r) => !r.isEmpty && r.overlaps(bounds));
    return regions.isEmpty ? size.height : math.min(size.height, regions.map((r) => r.bottom).reduce(math.max) + 8);
  }

  LiveInteractionLayout _interactionLayout(Size size, EdgeInsets padding) {
    final count = _giftDisplayController.notice.activeEntries.length;
    return LiveInteractionLayout(
        topBoundary: _interactionTop(size),
        bottom: size.height - _toolbarHeight - padding.bottom - 14,
        contentHeight: _isCommentComposerVisible
            ? (_composerContentHeight ?? _messageVisibleContentHeight.value)
            : _messageVisibleContentHeight.value,
        isWelcomeVisible: _audienceEntranceController.active != null,
        giftNoticeHeight: count == 0 ? 0 : count * 44 + (count - 1) * 4,
        safeBottom: size.height - padding.bottom);
  }

  void _showComment() {
    if (_isCommentComposerVisible) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final layout = _interactionLayout(box.size, MediaQuery.paddingOf(context));
      _composerHeight = math.min(layout.commentHeight, layout.visibleCommentHeight ?? layout.commentHeight);
      _composerContentHeight = _messageVisibleContentHeight.value;
    }
    setState(() => _isCommentComposerVisible = true);
  }

  /// 评论区的底边与高度。
  /// 非输入态对应 iOS bottom = bottomToolbar.top - 14；
  /// 输入态对应 iOS bottom = commentComposer.inputBar.top - 6。
  ({double bottom, double height}) _commentFrame(EdgeInsets padding, LiveInteractionLayout layout) {
    if (!_isCommentComposerVisible) {
      return (bottom: _toolbarHeight + padding.bottom + 14, height: layout.commentHeight);
    }
    final keyboard = math.max(MediaQuery.viewInsetsOf(context).bottom, MediaQuery.viewPaddingOf(context).bottom);
    return (
      bottom: keyboard + BarrageInputView.keyboardGap + _commentInputBarHeight + 6,
      height: _composerHeight ?? layout.commentHeight,
    );
  }

  /// 默认宽度受连麦小窗挤压时，在小窗左侧留出 8 的间距。
  double _commentWidth(Size size, ({double bottom, double height}) frame) {
    final defaultWidth = math.min(size.width * BarrageStreamView.defaultWidthRatio, size.width - 24);
    final layout = widget.coGuestLayout.value.$1;
    if (layout != CoGuestLayoutTemplate.floatLayout && layout != CoGuestLayoutTemplate.columnLayout) {
      return defaultWidth;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return defaultWidth;
    final viewportBottom = size.height - frame.bottom;
    var width = defaultWidth;
    for (final region in widget.coGuestSmallWindowRegions?.call() ?? <Rect>[]) {
      final origin = box.globalToLocal(region.topLeft);
      if (origin.dy + region.height > viewportBottom - frame.height && origin.dy < viewportBottom) {
        width = math.min(width, origin.dx - 8 - 12);
      }
    }
    return math.max(17, width);
  }

  void _showSettings() {
    widget.onShowSettings?.call();
    setState(() => _isSettingsVisible = true);
  }

  void _showAudienceList() {
    _audienceStore.refresh();
    setState(() => _isAudienceListVisible = true);
  }
}

enum _LivingScrimDirection { top, bottom }

class _LivingScrimView extends StatelessWidget {
  const _LivingScrimView({required this.direction});

  final _LivingScrimDirection direction;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: direction == _LivingScrimDirection.top
                // UIColor.black.withAlphaComponent(0.5) → clear
                ? const <Color>[Color(0x80000000), Color(0x00000000)]
                // clear → UIColor.black.withAlphaComponent(0.58)
                : const <Color>[Color(0x00000000), Color(0x94000000)],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WelcomeClipper extends CustomClipper<Rect> {
  const _WelcomeClipper(this.top);
  final double top;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top.clamp(0, size.height), size.width, size.height);
  @override
  bool shouldReclip(_WelcomeClipper oldClipper) => oldClipper.top != top;
}
