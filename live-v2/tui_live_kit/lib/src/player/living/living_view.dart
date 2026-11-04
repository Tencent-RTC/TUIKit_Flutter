import 'dart:math' as math;

import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/barrage/barrage_input_view.dart';
import '../../common/barrage/barrage_stream_view.dart';
import '../../common/barrage/barrage_ui_store.dart';
import '../../common/gift/send/gift_send_panel_view.dart';
import '../../common/gift/gift_barrage_store.dart';
import '../../common/gift/display/gift_display_view.dart';
import '../../common/gift/send/gift_send_combo_button.dart';
import '../../common/gift/send/gift_send_store.dart';
import '../../common/like/like_animation_view.dart';
import '../../common/live_kit_resources.dart';
import 'audience/audience_list_panel.dart';
import '../../common/audience/audience_welcome_view.dart';
import 'audience/audience_view.dart';
import 'coguest/co_guest_icon.dart';
import 'hostinfo/host_info_view.dart';

class LivingView extends StatefulWidget {
  const LivingView({
    super.key,
    required this.liveInfo,
    required this.safeAreaInsets,
    this.onClose,
    this.adminDeviceRequestsEnabled,
    this.onCoGuestUiStateChanged,
    this.onToast,
    this.videoGeometryChanges,
    this.videoSeatRegions,
  });

  final Listenable? videoGeometryChanges;
  final List<Rect> Function()? videoSeatRegions;
  final LiveInfo liveInfo;
  final ValueListenable<bool>? adminDeviceRequestsEnabled;
  final EdgeInsets safeAreaInsets;
  final VoidCallback? onClose;
  final ValueChanged<CoGuestStatus>? onCoGuestUiStateChanged;
  final ValueChanged<String>? onToast;

  @override
  State<LivingView> createState() => LivingViewState();
}

class LivingViewState extends State<LivingView> with SingleTickerProviderStateMixin {
  final GlobalKey<HostInfoViewState> hostInfoKey = GlobalKey();
  final GlobalKey<AudienceViewState> audienceKey = GlobalKey();
  final GlobalKey<AudienceListPanelState> audiencePanelKey = GlobalKey();
  final GlobalKey<CoGuestIconState> coGuestKey = GlobalKey();
  final GlobalKey<GiftSendPanelViewState> giftPanelKey = GlobalKey();
  final GlobalKey _giftDisplayKey = GlobalKey();
  final GlobalKey _likeLayerKey = GlobalKey();
  final GlobalKey _likeButtonKey = GlobalKey();

  late final AnimationController _cleanController;
  bool isCleanScreen = false;
  bool _cleanStateAtGestureStart = false;
  double _cleanValueAtGestureStart = 0;
  double _dragTravelDistance = 1;

  bool isCommentComposerVisible = false;
  double _commentInputBarHeight = BarrageInputView.inputBarHeight;
  double _messageVisibleContentHeight = 0;
  double? _composerHeight;
  double? _composerContentHeight;
  double? _giftPanelHeight;
  void _onInteractionChanged() {
    if (mounted) setState(() {});
  }

  final AudienceWelcomeController _audienceWelcomeController = AudienceWelcomeController();
  BarrageUIStore? commentStore;
  GiftDisplayController? giftDisplayController;
  GiftSendStore? giftSendStore;
  GiftBarrageStore? giftBarrageStore;
  List<GiftCategory> giftCategories = <GiftCategory>[];
  bool giftIsLoading = false;
  bool isGiftPanelPresented = false;

  Gift? floatingComboGift;
  final GiftSendComboButtonController floatingComboController = GiftSendComboButtonController();

  final LikeAnimationController likeAnimationController = LikeAnimationController();
  LikeStore? likeStore;
  final _likeSender = LikeSender();
  bool _isLikeActive = false;
  DateTime? _lastStageLikeTapAt;
  static const Duration _continuousTapInterval = Duration(milliseconds: 420);
  static const double _cleanFlipProgressThreshold = 0.22;
  static const double _cleanFlipVelocityThreshold = 450;

  @override
  void initState() {
    super.initState();
    _cleanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    floatingComboController.onSendOnce = _handleFloatingComboSend;
    floatingComboController.onExpired = _handleFloatingComboExpired;
    _audienceWelcomeController.addListener(_onAudienceWelcomeVisibilityChanged);
    widget.videoGeometryChanges?.addListener(_onInteractionChanged);
    ensureCommentInfrastructure();
    ensureGiftInfrastructure();
    ensureLikeInfrastructure();
    WidgetsBinding.instance.addPostFrameCallback((_) => bindChildren());
  }

  void _handleCommentsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleCommentSendError(String message) {
    widget.onToast?.call(message);
  }

  void _onAudienceWelcomeVisibilityChanged() {
    _onInteractionChanged();
  }

  void _handleAudienceEntered(AudienceWelcome welcome) {
    if (!mounted || isCleanScreen) return;
    _audienceWelcomeController.enqueue(welcome);
  }

  @override
  void didUpdateWidget(covariant LivingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoGeometryChanges != widget.videoGeometryChanges) {
      oldWidget.videoGeometryChanges?.removeListener(_onInteractionChanged);
      widget.videoGeometryChanges?.addListener(_onInteractionChanged);
    }
    if (oldWidget.liveInfo.liveID != widget.liveInfo.liveID) {
      _composerHeight = null;
      _composerContentHeight = null;
      _messageVisibleContentHeight = 0;
      _giftPanelHeight = null;
      isCommentComposerVisible = false;
      _audienceWelcomeController.reset();
      commentStore?.deactivate();
      commentStore = null;
      giftDisplayController?.notice.removeListener(_onInteractionChanged);
      giftDisplayController?.dispose();
      giftDisplayController = null;
      giftSendStore?.dispose();
      giftSendStore = null;
      giftBarrageStore?.dispose();
      giftBarrageStore = null;
      giftCategories = <GiftCategory>[];
      giftIsLoading = false;
      _endFloatingCombo();
      _detachLikeStore();
      likeAnimationController.removeAllAnimations();
      _lastStageLikeTapAt = null;
      ensureCommentInfrastructure();
      ensureGiftInfrastructure();
      ensureLikeInfrastructure();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => bindChildren());
  }

  @override
  void dispose() {
    widget.videoGeometryChanges?.removeListener(_onInteractionChanged);
    giftDisplayController?.notice.removeListener(_onInteractionChanged);
    _cleanController.dispose();
    commentStore?.deactivate();
    commentStore = null;
    giftDisplayController?.dispose();
    giftDisplayController = null;
    giftSendStore?.dispose();
    giftSendStore = null;
    giftBarrageStore?.dispose();
    giftBarrageStore = null;
    floatingComboController.onSendOnce = null;
    floatingComboController.onExpired = null;
    floatingComboController.dispose();
    _detachLikeStore();
    likeAnimationController.dispose();
    _audienceWelcomeController
      ..removeListener(_onAudienceWelcomeVisibilityChanged)
      ..dispose();
    super.dispose();
  }

  void ensureCommentInfrastructure() {
    final String liveID = widget.liveInfo.liveID;
    if (liveID.isEmpty) return;
    if (commentStore != null) return;
    final BarrageUIStore store = BarrageUIStore();
    store.onStateChanged = _handleCommentsChanged;
    store.onSendError = _handleCommentSendError;
    store.activate(
      liveID: liveID,
      hostUserID: widget.liveInfo.liveOwner.userID,
    );
    commentStore = store;
  }

  void ensureGiftInfrastructure() {
    final String liveID = widget.liveInfo.liveID;
    if (liveID.isEmpty) return;
    if (giftDisplayController == null) {
      final GiftDisplayController controller = GiftDisplayController(liveID: liveID);
      giftDisplayController = controller;
      controller.notice.addListener(_onInteractionChanged);
    }
    if (giftSendStore == null) {
      final GiftSendStore store = GiftSendStore();
      store.onStateChanged = _handleGiftStateChanged;
      store.activate(liveID);
      giftSendStore = store;
    }
    giftBarrageStore ??= GiftBarrageStore(liveID: liveID)
      ..onGiftBarrageSettled = _handleGiftBarrageSettled
      ..activate();
    _updateGiftPresentationState();
  }

  void ensureLikeInfrastructure() {
    final String liveID = widget.liveInfo.liveID;
    if (liveID.isEmpty) return;
    likeStore ??= LikeStore.create(liveID);
    if (_isLikeActive) return;
    _isLikeActive = true;
    final store = likeStore!;
    _likeSender.activate((count) => store.sendLike(count).ignore());
  }

  /// 对应 iOS `LiveUIStore`：等待期间连续点赞复用同一个 6 秒合并发送计时器。
  void _registerLike() {
    if (!_isLikeActive) return;
    _likeSender.sendLike();
  }

  void _detachLikeStore() {
    _likeSender.deactivate();
    _isLikeActive = false;
    likeStore = null;
  }

  void _handleGiftStateChanged(GiftSendState state) {
    if (!mounted) return;
    setState(() {
      giftCategories = state.categories;
      giftIsLoading = state.isLoading;
    });
  }

  void _handleGiftBarrageSettled(LiveGiftBarrage giftComment) {
    commentStore?.appendGiftComment(giftComment);
  }

  List<LiveMessage> get mergedComments {
    return [
      if (commentStore != null)
        LiveMessage(
            id: 'player-system-${widget.liveInfo.liveID}',
            userName: '',
            content: LiveKitResources.localizedString('tuilivekit.player.system_announcement'),
            level: 0,
            isSystemAnnouncement: true),
      ...?commentStore?.comments
    ];
  }

  void openCommentComposer() {
    if (commentStore?.isSelfMessageBanned() ?? false) {
      widget.onToast?.call(LiveKitResources.localizedString(
        'tuilivekit.player.audience.message_disabled',
      ));
      return;
    }
    if (isCommentComposerVisible) return;
    dismissPanels();
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final layout = _interactionLayout(box.size);
      _composerHeight = math.min(layout.commentHeight, layout.visibleCommentHeight ?? layout.commentHeight);
      _composerContentHeight = _messageVisibleContentHeight;
    }
    setState(() => isCommentComposerVisible = true);
  }

  void closeCommentComposer() {
    if (!isCommentComposerVisible) return;
    setState(() {
      isCommentComposerVisible = false;
      _composerHeight = null;
      _composerContentHeight = null;
    });
  }

  void handleSendComment(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    commentStore?.sendComment(trimmed);
  }

  /// 对应 iOS `LivingView.invalidateCoGuestCameraRequests`：返回是否有正在进行的开启请求。
  bool invalidateCoGuestCameraRequests({required bool allowRestore}) {
    return coGuestKey.currentState?.invalidateCameraRequests(allowRestore: allowRestore) ?? false;
  }

  void bindChildren() {
    if (!mounted) return;
    hostInfoKey.currentState?.bind(widget.liveInfo, likeStore: likeStore);
    audienceKey.currentState?.bind(widget.liveInfo);
    audiencePanelKey.currentState?.attachStore(widget.liveInfo.liveID);
  }

  void dismissPanels() {
    audiencePanelKey.currentState?.dismiss();
    giftPanelKey.currentState?.dismiss();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _cleanController.stop();
    _cleanStateAtGestureStart = isCleanScreen;
    _cleanValueAtGestureStart = _cleanController.value;
    _dragTravelDistance = MediaQuery.sizeOf(context).width;
    if (_dragTravelDistance <= 0) _dragTravelDistance = 1;
    _lastStageLikeTapAt = null;
    dismissPanels();
    closeCommentComposer();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta ?? 0;
    final double next = (_cleanController.value + delta / _dragTravelDistance).clamp(0.0, 1.0);
    _cleanController.value = next;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final double delta = _cleanController.value - _cleanValueAtGestureStart;
    final double progress = delta.abs();
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldFlip;
    if (_cleanStateAtGestureStart) {
      shouldFlip = delta < 0 && (progress >= _cleanFlipProgressThreshold || velocity <= -_cleanFlipVelocityThreshold);
    } else {
      shouldFlip = delta > 0 && (progress >= _cleanFlipProgressThreshold || velocity >= _cleanFlipVelocityThreshold);
    }
    _setCleanScreen(
      shouldFlip ? !_cleanStateAtGestureStart : _cleanStateAtGestureStart,
      animated: true,
    );
  }

  void _setCleanScreen(
    bool clean, {
    bool animated = true,
  }) {
    isCleanScreen = clean;
    _updateGiftPresentationState();
    if (clean) {
      dismissPanels();
      closeCommentComposer();
    }
    final double target = clean ? 1.0 : 0.0;
    if (!animated) {
      _cleanController.value = target;
      return;
    }
    _cleanController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _updateGiftPresentationState() {
    final bool isEnabled = !isCleanScreen;
    giftBarrageStore?.setEnabled(isEnabled);
    giftDisplayController?.setSuspended(!isEnabled);
  }

  void _openGiftPanel() {
    audiencePanelKey.currentState?.dismiss();
    closeCommentComposer();
    giftPanelKey.currentState?.present();
  }

  void _handleGiftPresentationChanged(bool isPresented, double heightAboveSafeArea) {
    if (!mounted) return;
    setState(() {
      isGiftPanelPresented = isPresented;
      _giftPanelHeight = isPresented ? heightAboveSafeArea : null;
    });
  }

  void _handleSendGift(Gift gift, int count) {
    final int normalizedCount = count < 1 ? 1 : count;
    final UserProfile? profile = LoginStore.shared.loginState.loginUserInfo;
    final GiftDisplayItem? localGift = profile == null
        ? null
        : GiftDisplayItem(
            giftID: gift.giftID,
            name: gift.name,
            iconURL: gift.iconURL,
            resourceURL: gift.resourceURL,
            coins: gift.coins < 0 ? 0 : gift.coins,
            count: normalizedCount,
            senderID: profile.userID,
            senderName: profile.nickname ?? '',
            senderAvatarURL: profile.avatarURL ?? '',
          );
    final GiftDisplayController? display = giftDisplayController;
    final int? reservationID = localGift == null ? null : display?.reserveLocalGift(localGift);
    giftSendStore?.sendGift(
      id: gift.giftID,
      count: normalizedCount,
      completion: (bool isSuccess) {
        if (reservationID == null) return;
        if (isSuccess) {
          display?.confirmLocalGift(reservationID);
        } else {
          display?.cancelLocalGift(reservationID);
        }
      },
    );
  }

  void _handleAdvancedComboStart(Gift gift) {
    _endFloatingCombo();
    setState(() {
      floatingComboGift = gift;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      floatingComboController.begin(gift);
    });
  }

  void _handleFloatingComboSend() {
    final Gift? gift = floatingComboGift;
    if (gift == null) return;
    _handleSendGift(gift, 1);
  }

  void _handleFloatingComboExpired() {
    _endFloatingCombo();
  }

  void _endFloatingCombo() {
    floatingComboController.end();
    if (floatingComboGift != null) {
      setState(() {
        floatingComboGift = null;
      });
    }
  }

  Offset? _likeButtonCenterInLikeLayer() {
    final RenderBox? layerBox = _likeLayerKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? buttonBox = _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (layerBox == null || buttonBox == null) return null;
    final Offset global = buttonBox.localToGlobal(
      Offset(buttonBox.size.width / 2, buttonBox.size.height / 2),
    );
    return layerBox.globalToLocal(global);
  }

  void _handleLikeButtonTap() {
    final Offset? origin = _likeButtonCenterInLikeLayer();
    if (origin != null) {
      likeAnimationController.showButtonLike(origin: origin);
    }
    _registerLike();
  }

  void _handleStageTap(TapUpDetails details) {
    if (isCleanScreen || _cleanController.value > 0) {
      _lastStageLikeTapAt = null;
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? last = _lastStageLikeTapAt;
    _lastStageLikeTapAt = now;
    if (last == null || now.difference(last) > _continuousTapInterval) return;
    final RenderBox? layerBox = _likeLayerKey.currentContext?.findRenderObject() as RenderBox?;
    if (layerBox == null) return;
    final Offset local = layerBox.globalToLocal(details.globalPosition);
    final double width = layerBox.size.width;
    final double height = layerBox.size.height;
    final double maxX = width - 28;
    final double maxY = height - 24;
    final Offset point = Offset(
      local.dx.clamp(28.0, maxX < 28 ? 28.0 : maxX).toDouble(),
      (local.dy - 8).clamp(62.0, maxY < 62 ? 62.0 : maxY).toDouble(),
    );
    final Offset? origin = _likeButtonCenterInLikeLayer();
    if (origin == null) return;
    likeAnimationController.showStageLike(
      point: point,
      auxiliaryOrigin: origin,
    );
    _registerLike();
  }

  double _normalCommentBottom(Size size) {
    final normal = widget.safeAreaInsets.bottom +
        PlayerLayout.bottomBarBottomInset +
        PlayerLayout.bottomBarHeight +
        PlayerLayout.messageBottomSpacing;
    return _giftPanelHeight == null ? normal : math.max(normal, widget.safeAreaInsets.bottom + _giftPanelHeight! + 4);
  }

  double? _interactionTop(Size size) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final regions = (widget.videoSeatRegions?.call() ?? <Rect>[])
        .map((r) => box.globalToLocal(r.topLeft) & r.size)
        .where((r) => !r.isEmpty && r.overlaps(Offset.zero & size));
    if (regions.isEmpty) return null;
    final top = math.min(size.height, math.max(0.0, regions.map((r) => r.bottom).reduce(math.max) + 8));
    final normalBottom = size.height -
        widget.safeAreaInsets.bottom -
        PlayerLayout.bottomBarBottomInset -
        PlayerLayout.bottomBarHeight -
        PlayerLayout.messageBottomSpacing;
    return normalBottom - top >= 184 ? top : null;
  }

  LiveInteractionLayout _interactionLayout(Size size) {
    final count = giftDisplayController?.notice.activeEntries.length ?? 0;
    return LiveInteractionLayout(
        topBoundary: _interactionTop(size),
        bottom: size.height - _normalCommentBottom(size),
        contentHeight: isCommentComposerVisible
            ? (_composerContentHeight ?? _messageVisibleContentHeight)
            : _messageVisibleContentHeight,
        isWelcomeVisible: _audienceWelcomeController.active != null,
        giftNoticeHeight: count == 0 ? 0 : count * 44 + (count - 1) * 4,
        safeBottom: size.height - widget.safeAreaInsets.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final double top = math.max(MediaQuery.paddingOf(context).top, widget.safeAreaInsets.top) + 10;
    final double bottomInset = widget.safeAreaInsets.bottom;
    final double messageBottom = bottomInset +
        PlayerLayout.bottomBarBottomInset +
        PlayerLayout.bottomBarHeight +
        PlayerLayout.messageBottomSpacing;
    final double composerBottom = isCommentComposerVisible
        ? math.max(MediaQuery.viewInsetsOf(context).bottom, MediaQuery.viewPaddingOf(context).bottom) +
            BarrageInputView.keyboardGap +
            _commentInputBarHeight +
            6
        : messageBottom;
    return LayoutBuilder(builder: (context, constraints) {
      final layout = _interactionLayout(constraints.biggest);
      final boundary = _interactionTop(constraints.biggest);
      final normalBottom = _normalCommentBottom(constraints.biggest);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onTapUp: _handleStageTap,
        child: AnimatedBuilder(
          animation: _cleanController,
          builder: (BuildContext context, Widget? _) {
            final double progress = _cleanController.value.clamp(0.0, 1.0);
            final double screenWidth = MediaQuery.sizeOf(context).width;
            final double translation = screenWidth * progress;
            final double contentOpacity = (1 - progress).clamp(0.0, 1.0);
            final bool ignoreContent = progress >= 0.999;
            final GiftDisplayView? giftDisplayView = giftDisplayController == null
                ? null
                : GiftDisplayView(
                    key: _giftDisplayKey,
                    controller: giftDisplayController!,
                    noticeBottom: constraints.maxHeight - layout.giftNoticeBottom,
                    noticeTopBoundary: boundary);
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Transform.translate(
                  offset: Offset(translation, 0),
                  child: Opacity(
                    opacity: contentOpacity,
                    child: IgnorePointer(
                      ignoring: ignoreContent,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Positioned(
                            left: 20,
                            top: top,
                            height: 36,
                            child: HostInfoView(key: hostInfoKey),
                          ),
                          Positioned(
                            right: 42,
                            top: top + 5,
                            child: AudienceView(
                              key: audienceKey,
                              onToast: widget.onToast,
                              onAudience: () {
                                giftPanelKey.currentState?.dismiss();
                                audiencePanelKey.currentState?.show();
                              },
                              onAudienceEntered: _handleAudienceEntered,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: layout.welcomeTop,
                            height: 28,
                            child: ClipRect(
                                clipper: _PlayerWelcomeClipper(
                                    boundary == null ? 0 : math.max(0, boundary - layout.welcomeTop)),
                                child: AudienceWelcomeView(controller: _audienceWelcomeController)),
                          ),
                          Positioned(
                            left: 12,
                            bottom: isCommentComposerVisible ? composerBottom : normalBottom,
                            width: MediaQuery.sizeOf(context).width * BarrageStreamView.defaultWidthRatio,
                            height: isCommentComposerVisible
                                ? (_composerHeight ?? layout.commentHeight)
                                : layout.commentHeight,
                            child: BarrageStreamView(
                              messages: mergedComments,
                              maximumVisibleHeight: isCommentComposerVisible ? null : layout.visibleCommentHeight,
                              onContentHeightChanged: (double height) {
                                if (_messageVisibleContentHeight != height) {
                                  setState(() {
                                    _messageVisibleContentHeight = height;
                                  });
                                }
                              },
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: bottomInset + PlayerLayout.bottomBarBottomInset,
                            height: PlayerLayout.bottomBarHeight,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _BottomCommentEntry(onTap: openCommentComposer),
                                ),
                                const SizedBox(width: PlayerLayout.bottomBarSpacing),
                                SizedBox(
                                  width: PlayerLayout.bottomBarControlSize,
                                  height: PlayerLayout.bottomBarControlSize,
                                  child: CoGuestIcon(
                                    key: coGuestKey,
                                    liveInfo: widget.liveInfo,
                                    onUiStateChanged: widget.onCoGuestUiStateChanged,
                                    onToast: widget.onToast,
                                  ),
                                ),
                                const SizedBox(width: PlayerLayout.bottomBarSpacing),
                                _BottomActionButton(
                                  onTap: _openGiftPanel,
                                  icon: Image(
                                    image: LiveKitResources.image('livekit_player_gift'),
                                    width: PlayerLayout.bottomBarControlSize,
                                    height: PlayerLayout.bottomBarControlSize,
                                  ),
                                ),
                                const SizedBox(width: PlayerLayout.bottomBarSpacing),
                                _BottomActionButton(
                                  key: _likeButtonKey,
                                  onTap: _handleLikeButtonTap,
                                  icon: Image(
                                    image: LiveKitResources.image('livekit_player_like'),
                                    width: PlayerLayout.bottomBarControlSize,
                                    height: PlayerLayout.bottomBarControlSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            key: _likeLayerKey,
                            child: LikeAnimationView(
                              controller: likeAnimationController,
                              liveID: widget.liveInfo.liveID,
                              auxiliaryOriginProvider: _likeButtonCenterInLikeLayer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (progress > 0)
                  Positioned(
                    right: 18,
                    bottom: bottomInset + 10,
                    child: Opacity(
                      opacity: progress,
                      child: _RestoreControlsButton(
                        onTap: () => _setCleanScreen(false),
                      ),
                    ),
                  ),
                AudienceListPanel(key: audiencePanelKey),
                if (giftDisplayView != null && !isGiftPanelPresented) Positioned.fill(child: giftDisplayView),
                if (floatingComboGift != null)
                  Positioned(
                    key: const ValueKey('floatingGiftCombo'),
                    right: 16,
                    bottom: bottomInset + PlayerLayout.bottomBarBottomInset + PlayerLayout.bottomBarHeight + 30,
                    width: 72,
                    child: GiftSendComboButton(controller: floatingComboController),
                  ),
                GiftSendPanelView(
                  key: giftPanelKey,
                  categories: giftCategories,
                  isLoading: giftIsLoading,
                  onSendGift: _handleSendGift,
                  onAdvancedComboStart: _handleAdvancedComboStart,
                  onPresentationChanged: _handleGiftPresentationChanged,
                ),
                Positioned.fill(
                  child: BarrageInputView(
                    isPresented: isCommentComposerVisible,
                    onDismiss: closeCommentComposer,
                    onInputBarHeightChanged: (height) {
                      if (mounted && height != _commentInputBarHeight) {
                        setState(() => _commentInputBarHeight = height);
                      }
                    },
                    onSend: (String text) {
                      handleSendComment(text);
                      closeCommentComposer();
                    },
                  ),
                ),
                if (giftDisplayView != null && isGiftPanelPresented) Positioned.fill(child: giftDisplayView),
              ],
            );
          },
        ),
      );
    });
  }
}

class _BottomCommentEntry extends StatefulWidget {
  const _BottomCommentEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BottomCommentEntry> createState() => _BottomCommentEntryState();
}

class _BottomCommentEntryState extends State<_BottomCommentEntry> {
  bool pressed = false;

  void setPressed(bool value) {
    if (pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? 0.99 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: PlayerLayout.bottomBarHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: PlayerLayout.background,
            borderRadius: BorderRadius.circular(PlayerLayout.bottomBarHeight / 2),
            border: Border.all(color: PlayerLayout.border),
          ),
          child: Text(
            LiveKitResources.localizedString(
              'tuilivekit.player.comment_placeholder',
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: _PlayerOverlayStyle.commentForeground,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatefulWidget {
  const _BottomActionButton({super.key, required this.onTap, required this.icon});

  final VoidCallback onTap;
  final Widget icon;

  @override
  State<_BottomActionButton> createState() => _BottomActionButtonState();
}

class _BottomActionButtonState extends State<_BottomActionButton> {
  bool pressed = false;

  void setPressed(bool value) {
    if (pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: PlayerLayout.bottomBarControlSize,
          height: PlayerLayout.bottomBarControlSize,
          child: widget.icon,
        ),
      ),
    );
  }
}

class _RestoreControlsButton extends StatefulWidget {
  const _RestoreControlsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RestoreControlsButton> createState() => _RestoreControlsButtonState();
}

class _RestoreControlsButtonState extends State<_RestoreControlsButton> {
  bool pressed = false;

  void setPressed(bool value) {
    if (pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LiveKitResources.localizedString(
        'tuilivekit.player.restore_controls_accessibility',
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setPressed(true),
        onTapUp: (_) => setPressed(false),
        onTapCancel: () => setPressed(false),
        child: AnimatedScale(
          scale: pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: Image(
            image: LiveKitResources.image('livekit_ic_controls_restore'),
            width: 56,
            height: 56,
          ),
        ),
      ),
    );
  }
}

/// 房内浮层布局与控件配方，对应 iOS `Player/Living/LivingView.swift` 的 Constants。
abstract final class PlayerLayout {
  static const double bottomBarBottomInset = 3;
  static const double bottomBarHeight = 39;
  static const double bottomBarControlSize = 39;
  static const double bottomBarSpacing = 8.5;
  static const double messageBottomSpacing = 14;
  static const double messageNormalHeight = 184;

  /// UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.18)
  static const background = Color(0x2E0A0A0F);

  /// 白色 6% 描边。
  static const border = Color(0x0FFFFFFF);
}

abstract final class _PlayerOverlayStyle {
  static const commentForeground = Color(0x80FFFFFF);
}

class _PlayerWelcomeClipper extends CustomClipper<Rect> {
  const _PlayerWelcomeClipper(this.top);
  final double top;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top.clamp(0, size.height), size.width, size.height);
  @override
  bool shouldReclip(_PlayerWelcomeClipper oldClipper) => oldClipper.top != top;
}
