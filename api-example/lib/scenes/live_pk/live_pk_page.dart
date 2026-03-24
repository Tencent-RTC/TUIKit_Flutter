import 'dart:async';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/role.dart';
import 'package:atomic_x_core_example/components/setting_panel_controller.dart';
import 'package:atomic_x_core_example/components/device_setting_widget.dart';
import 'package:atomic_x_core_example/components/permission_helper.dart';
import 'package:atomic_x_core_example/components/barrage_widget.dart';
import 'package:atomic_x_core_example/components/gift_panel_widget.dart';
import 'package:atomic_x_core_example/components/gift_animation_widget.dart';
import 'package:atomic_x_core_example/components/like_button.dart' as app_like;
import 'package:atomic_x_core_example/components/co_host_user_list_widget.dart';

/// Business scenario: live PK battle page
///
/// On top of `Interactive`, this page adds cross-room host connection and PK battle features:
/// - Host connection (`CoHostStore`) - request / accept / reject / exit cross-room host connections
/// - PK battle (`BattleStore`) - request / accept / reject / exit PK battles, with real-time score display
///
/// Related APIs (basic live streaming + real-time interaction):
/// - `LiveListStore.shared.createLive(liveInfo)` - anchor creates a live stream
/// - `LiveListStore.shared.joinLive(liveID)` - audience joins a live stream
/// - `LiveListStore.shared.endLive()` - anchor ends the live stream
/// - `LiveListStore.shared.leaveLive()` - audience leaves the live stream
/// - `LiveListStore.shared.addLiveListListener(listener)` - live event listener
/// - `DeviceStore.shared` - camera / microphone management
/// - `BarrageStore.create(liveID)` - barrage management
/// - `GiftStore.create(liveID)` - gift management
/// - `LikeStore.create(liveID)` - like management
/// - `LiveCoreView(viewType:)` - video rendering widget
///
/// Related APIs (co-host + PK):
/// - `CoHostStore.create(liveID)` - cross-room host-connection management
/// - `CoHostStore.requestHostConnection(targetHostLiveID:layoutTemplate:timeout:)` - start a host connection
/// - `CoHostStore.acceptHostConnection(fromHostLiveID)` - accept a host connection
/// - `CoHostStore.rejectHostConnection(fromHostLiveID)` - reject a host connection
/// - `CoHostStore.exitHostConnection()` - exit the host connection
/// - `CoHostStore.addCoHostListener(listener)` - host-connection event listener
/// - `BattleStore.create(liveID)` - PK battle management
/// - `BattleStore.requestBattle(config:userIDList:timeout:)` - start a PK battle
/// - `BattleStore.acceptBattle(battleID)` - accept a PK battle
/// - `BattleStore.rejectBattle(battleID)` - reject a PK battle
/// - `BattleStore.exitBattle(battleID)` - exit a PK battle
/// - `BattleStore.addBattleListener(listener)` - PK event listener
///
/// Different operations are provided based on the role:
/// - Anchor: pushing + barrage + likes + gift animations + starting host connections + starting PK + displaying PK scores
/// - Audience: playback + barrage + gifts + likes + displaying PK status
class LivePKPage extends StatefulWidget {
  // MARK: - Properties

  final Role role;
  final String liveID;

  // MARK: - Init

  const LivePKPage({
    super.key,
    required this.role,
    required this.liveID,
  });

  @override
  State<LivePKPage> createState() => _LivePKPageState();
}

class _LivePKPageState extends State<LivePKPage> {
  // MARK: - Properties

  /// Whether the page is currently in the live state
  bool _isLiveActive = false;

  /// 主播co-guest state
  bool _isCoHostConnected = false;

  /// PK 进行中
  bool _isBattling = false;

  /// 当前 PK ID
  String? _currentBattleID;

  /// 当前连线主播的 liveID
  String? _connectedHostLiveID;

  late final LiveCoreController _liveCoreController;
  late final LiveListListener _liveListListener;

  /// CoHostStore 实例(直播创建/加入后初始化)
  CoHostStore? _coHostStore;

  /// BattleStore 实例(直播创建/加入后初始化)
  BattleStore? _battleStore;

  /// GiftStore 实例
  GiftStore? _giftStore;
  GiftListener? _giftListener;

  /// CoHost Listener(用于 dispose 时移除)
  CoHostListener? _coHostListener;

  /// Battle Listener(用于 dispose 时移除)
  BattleListener? _battleListener;

  /// CoHost state listener 回调(观众端 + 主播端复用)
  VoidCallback? _coHostStateListener;

  /// Battle state listener 回调(观众端 + 主播端复用)
  VoidCallback? _battleStateListener;

  /// 用于追踪 GlobalKey 以便 GiftAnimationWidget 使用
  final GlobalKey<GiftAnimationWidgetState> _giftAnimationKey = GlobalKey<GiftAnimationWidgetState>();

  // MARK: - PK Score数据

  /// 当前 PK 参战用户Score数据: (userID, userName, score, isMe)
  List<_BattleScoreEntry> _battleScoreEntries = [];

  /// PK countdown Timer
  Timer? _pkTimer;

  /// PK ended时间(秒级时间戳)
  int _pkEndTime = 0;

  /// PK 状态文本
  String _pkStatusText = '';

  /// PK 状态文本颜色
  Color _pkStatusColor = Colors.yellow;

  /// Whether the PK score panel is visible
  bool _pkScoreVisible = false;

  // MARK: - Lifecycle

  @override
  void initState() {
    super.initState();

    // Create the video rendering controller - anchor uses `pushView`, audience uses `playView`
    _liveCoreController = LiveCoreController.create(
      widget.role == Role.anchor ? CoreViewType.pushView : CoreViewType.playView,
    );
    _liveCoreController.setLiveID(widget.liveID);

    // Listen for live events (live ended, kicked out, and so on)
    _liveListListener = LiveListListener(
      onLiveEnded: _handleLiveEnded,
      onKickedOutOfLive: _handleKickedOutOfLive,
    );
    LiveListStore.shared.addLiveListListener(_liveListListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureForRole();
    });
  }

  @override
  void dispose() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    if (_giftListener != null) {
      _giftStore?.removeGiftListener(_giftListener!);
    }
    if (_coHostListener != null) {
      _coHostStore?.removeCoHostListener(_coHostListener!);
    }
    if (_battleListener != null) {
      _battleStore?.removeBattleListener(_battleListener!);
    }
    // 移除 state listeners
    if (_coHostStateListener != null) {
      _coHostStore?.coHostState.coHostStatus.removeListener(_coHostStateListener!);
    }
    if (_battleStateListener != null) {
      _battleStore?.battleState.currentBattleInfo.removeListener(_battleStateListener!);
      _battleStore?.battleState.battleUsers.removeListener(_battleStateListener!);
      _battleStore?.battleState.battleScore.removeListener(_battleStateListener!);
    }
    _stopPKTimer();
    // Make sure live resources are cleaned up when leaving the page
    _cleanupLiveSession();
    super.dispose();
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBackPressed();
      },
      child: GestureDetector(
        // Tap the blank area to dismiss the keyboard
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: AppBar(
            // Transparent navigation bar
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            // Use the room ID as the navigation bar title
            title: Text(
              widget.liveID,
              style: const TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _handleBackPressed,
            ),
            actions: _buildNavigationBarActions(l10n),
          ),
          body: Stack(
            children: [
              // 全屏视频渲染区域
              Positioned.fill(
                child: LiveCoreWidget(controller: _liveCoreController),
              ),

              // co-guest state指示标签(顶部导航栏下方)
              if (_isLiveActive && _connectionStatusVisible)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 24,
                      constraints: const BoxConstraints(minWidth: 120),
                      decoration: BoxDecoration(
                        color: _connectionStatusBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          _connectionStatusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Interactive widgets (shown only while live)
              if (_isLiveActive) ...[
                // 弹幕组件 - 左下区域
                Positioned(
                  left: 0,
                  right: MediaQuery.of(context).size.width * 0.4,
                  bottom: MediaQuery.of(context).padding.bottom + 18,
                  height: 280,
                  child: BarrageWidget(liveID: widget.liveID),
                ),

                // 点赞按钮 - 右下角
                Positioned(
                  right: 10,
                  bottom: MediaQuery.of(context).padding.bottom + 18,
                  child: app_like.LikeButton(liveID: widget.liveID),
                ),

                // 观众显示礼物入口按钮
                if (widget.role == Role.audience)
                  Positioned(
                    right: 60,
                    bottom: MediaQuery.of(context).padding.bottom + 22,
                    child: GestureDetector(
                      onTap: _showGiftPanel,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          size: 15,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ),

                // 主播端: Host connection and PK action buttons
                if (widget.role == Role.anchor) ...[
                  // PK button (horizontally aligned with the like button)
                  Positioned(
                    right: 105,
                    bottom: MediaQuery.of(context).padding.bottom + 22,
                    child: GestureDetector(
                      onTap: _isCoHostConnected ? _battleButtonTapped : null,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isBattling
                              ? Colors.grey
                              : (_isCoHostConnected ? Colors.red : Colors.red.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'PK',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isCoHostConnected
                                  ? (_isBattling ? Colors.white.withValues(alpha: 0.6) : Colors.white)
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Host connection button
                  Positioned(
                    right: 60,
                    bottom: MediaQuery.of(context).padding.bottom + 22,
                    child: GestureDetector(
                      onTap: _coHostButtonTapped,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isCoHostConnected ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isCoHostConnected ? Icons.link : Icons.link,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

                // 礼物动画组件 - 全屏覆盖(主播和观众共用)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GiftAnimationWidget(key: _giftAnimationKey),
                  ),
                ),
              ],

              // PK score display area
              if (_pkScoreVisible)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                  left: 16,
                  right: 16,
                  child: _buildPKScoreView(),
                ),

              // "Start Live" button (anchor only, centered)
              if (widget.role == Role.anchor && !_isLiveActive)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _createLive,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        child: Text(l10n.basicStreamingStartLive),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - PK score panel UI

  Widget _buildPKScoreView() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 160),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PK status label
            Text(
              _pkStatusText.isNotEmpty ? _pkStatusText : l10n.livePKStatusBattling,
              style: TextStyle(
                color: _pkStatusColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Multi-user score display (horizontal layout)
            if (_battleScoreEntries.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildScoreWidgets(),
              ),

            // Countdown label
            if (_pkTimerText != null) ...[
              const SizedBox(height: 2),
              Text(
                _pkTimerText!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the score widget list from the participating users
  List<Widget> _buildScoreWidgets() {
    final l10n = AppLocalizations.of(context)!;
    final userColors = [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange];
    final widgets = <Widget>[];

    for (int i = 0; i < _battleScoreEntries.length; i++) {
      final entry = _battleScoreEntries[i];
      final color = userColors[i % userColors.length];

      // Add a separator before every user except the first
      if (i > 0) {
        widgets.add(
          SizedBox(
            width: 12,
            child: Center(
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      }

      widgets.add(
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username
              Text(
                entry.isMe ? l10n.livePKBattleMe : entry.userName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              // Score
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: entry.scoreColor ?? color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  /// PK countdown text
  String? get _pkTimerText {
    if (_pkEndTime <= 0 || !_isBattling) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now >= _pkEndTime) return '00:00';
    final remaining = _pkEndTime - now;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // MARK: - co-guest state指示

  bool get _connectionStatusVisible {
    return _isBattling || _isCoHostConnected;
  }

  String get _connectionStatusText {
    final l10n = AppLocalizations.of(context)!;
    if (_isBattling) {
      return l10n.livePKStatusBattling;
    } else if (_isCoHostConnected) {
      return l10n.livePKStatusCoHostConnected;
    }
    return '';
  }

  Color get _connectionStatusBackgroundColor {
    if (_isBattling) {
      return Colors.red.withValues(alpha: 0.7);
    } else if (_isCoHostConnected) {
      return Colors.green.withValues(alpha: 0.7);
    }
    return Colors.transparent;
  }

  // MARK: - Navigation Bar

  List<Widget> _buildNavigationBarActions(AppLocalizations l10n) {
    final actions = <Widget>[];

    if (widget.role == Role.anchor) {
      // While live: show the end-live button
      if (_isLiveActive) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: _endLiveButtonTapped,
          ),
        );
      }

      // Device settings button
      actions.add(
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _settingsTapped,
        ),
      );
    }

    return actions;
  }

  // MARK: - Role Configuration

  /// Configure different interaction logic based on the role
  void _configureForRole() {
    switch (widget.role) {
      case Role.anchor:
        _configureForAnchor();
        break;
      case Role.audience:
        _configureForAudience();
        break;
    }
  }

  // MARK: - Anchor Setup

  void _configureForAnchor() {
    // Request camera and microphone permissions, then open the devices
    PermissionHelper.requestCameraAndMicrophonePermissions(
      context,
      onGranted: () {
        DeviceStore.shared.openLocalCamera(true);
        DeviceStore.shared.openLocalMicrophone();
      },
    );
  }

  // MARK: - Audience Setup

  void _configureForAudience() {
    // Join the room automatically after entering the page
    _joinLive();
  }

  // MARK: - Actions

  /// Handle the back button action
  void _handleBackPressed() {
    if (widget.role == Role.anchor) {
      _anchorBackTapped();
    } else {
      _audienceBackTapped();
    }
  }

  /// Handle the anchor back button tap
  void _anchorBackTapped() {
    if (_isLiveActive) {
      _endLiveAndGoBack();
    } else {
      DeviceStore.shared.closeLocalCamera();
      DeviceStore.shared.closeLocalMicrophone();
      Navigator.pop(context);
    }
  }

  /// Handle the audience back button tap
  void _audienceBackTapped() {
    if (_isLiveActive) {
      _leaveLiveAndGoBack();
    } else {
      Navigator.pop(context);
    }
  }

  /// Device settings panel entry
  void _settingsTapped() {
    final l10n = AppLocalizations.of(context)!;

    showSettingPanel(
      context: context,
      title: l10n.deviceSettingTitle,
      contentWidget: const DeviceSettingWidget(),
    );
  }

  /// 展示礼物面板(半屏浮层)
  void _showGiftPanel() {
    if (_giftStore == null) return;
    final l10n = AppLocalizations.of(context)!;

    showSettingPanel(
      context: context,
      title: l10n.interactiveGiftTitle,
      contentWidget: GiftPanelWidget(
        liveID: widget.liveID,
        onSendGiftResult: (result) {
          if (result != null && result.errorMessage != null) {
            _showToast(l10n.basicStreamingStatusFailed(result.errorMessage!));
          }
        },
      ),
      height: 400,
      backgroundColor: const Color.fromRGBO(28, 28, 36, 1.0),
    );
  }

  // MARK: - Anchor: Create Live

  Future<void> _createLive() async {
    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.basicStreamingStatusCreating);

    final result = await LiveListStore.shared.createLive(
      LiveInfo(liveID: widget.liveID, liveName: widget.liveID, seatTemplate: const VideoDynamicGrid9Seats()),
    );

    if (!mounted) return;
    if (result.isSuccess) {
      final createdLiveID = result.liveInfo.liveID;

      // Initialize the co-host and PK stores (positional parameters)
      _coHostStore = CoHostStore.create(createdLiveID);
      _battleStore = BattleStore.create(createdLiveID);
      _giftStore = GiftStore.create(createdLiveID);

      // Set up the gift event listener
      _giftListener = GiftListener(
        onReceiveGift: (liveID, gift, count, sender) {
          _giftAnimationKey.currentState?.playGiftAnimation(gift: gift, count: count, sender: sender);
        },
      );
      _giftStore!.addGiftListener(_giftListener!);

      setState(() {
        _isLiveActive = true;
      });

      _liveCoreController.setLiveID(createdLiveID);

      // Register the host-connection and PK listeners
      _setupCoHostBindings();
      _setupBattleBindings();

      _showToast(l10n.basicStreamingStatusCreated(createdLiveID));
    } else {
      _showToast(l10n.basicStreamingStatusFailed(result.errorMessage ?? ''));

      DeviceStore.shared.closeLocalCamera();
      DeviceStore.shared.closeLocalMicrophone();
    }
  }

  // MARK: - Audience: Join Live

  Future<void> _joinLive() async {
    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.basicStreamingStatusJoining);

    final result = await LiveListStore.shared.joinLive(widget.liveID);

    if (!mounted) return;
    if (result.isSuccess) {
      final joinedLiveID = result.liveInfo.liveID;

      // 初始化 Store(观众端也需要监听 PK 状态)(位置参数)
      _coHostStore = CoHostStore.create(joinedLiveID);
      _battleStore = BattleStore.create(joinedLiveID);
      _giftStore = GiftStore.create(joinedLiveID);

      // Set up the gift event listener
      _giftListener = GiftListener(
        onReceiveGift: (liveID, gift, count, sender) {
          _giftAnimationKey.currentState?.playGiftAnimation(gift: gift, count: count, sender: sender);
        },
      );
      _giftStore!.addGiftListener(_giftListener!);

      setState(() {
        _isLiveActive = true;
      });

      _liveCoreController.setLiveID(joinedLiveID);

      // Register the host-connection and PK listeners
      _setupCoHostBindings();
      _setupBattleBindings();

      _showToast(l10n.basicStreamingStatusJoined(joinedLiveID));
    } else {
      _showToast(l10n.basicStreamingStatusFailed(result.errorMessage ?? ''));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // MARK: - Anchor: End Live and Go Back

  Future<void> _endLiveAndGoBack() async {
    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.basicStreamingStatusEnding);

    // Exit PK and host connection first
    if (_isBattling && _currentBattleID != null) {
      _battleStore?.exitBattle(_currentBattleID!);
    }
    if (_isCoHostConnected) {
      _coHostStore?.exitHostConnection();
    }

    final result = await LiveListStore.shared.endLive();

    if (!mounted) return;
    if (result.isSuccess) {
      DeviceStore.shared.closeLocalCamera();
      DeviceStore.shared.closeLocalMicrophone();
      setState(() {
        _isLiveActive = false;
      });
      _stopPKTimer();
      Navigator.pop(context);
    } else {
      _showToast(l10n.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  // MARK: - Audience: Leave Live and Go Back

  Future<void> _leaveLiveAndGoBack() async {
    final result = await LiveListStore.shared.leaveLive();

    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _isLiveActive = false;
      });
      _stopPKTimer();
      Navigator.pop(context);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  // MARK: - Host connection actions

  /// Host connection button点击: 根据当前状态切换操作
  void _coHostButtonTapped() {
    if (_isCoHostConnected) {
      // Already connected: confirm again before disconnecting
      _confirmExitCoHost();
    } else {
      // Not connected: show the list of hosts available for connection
      _showHostSelectionPanel();
    }
  }

  /// Show the host list and choose the host to connect to
  void _showHostSelectionPanel() {
    CoHostUserListWidget.show(
      context,
      currentLiveID: widget.liveID,
      onSelectHost: (liveInfo) {
        _requestCoHostConnection(targetLiveID: liveInfo.liveID);
      },
      onEmptyList: () {
        _showToast(AppLocalizations.of(context)!.livePKCoHostEmptyList);
      },
      onLoadError: (error) {
        _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(error.errorMessage ?? ''));
      },
    );
  }

  /// Start a cross-room host-connection request
  void _requestCoHostConnection({required String targetLiveID}) {
    final l10n = AppLocalizations.of(context)!;
    _showToast(l10n.livePKCoHostConnecting);

    _coHostStore?.requestHostConnection(
      targetHostLiveID: targetLiveID,
      layoutTemplate: CoHostLayoutTemplate.hostDynamicGrid,
      timeout: 30,
      extraInfo: '',
    );
  }

  /// Confirm disconnecting the host connection
  void _confirmExitCoHost() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.livePKCoHostDisconnect),
          content: Text(l10n.livePKCoHostConfirmDisconnect),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _exitCoHost();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  /// Exit the host connection
  void _exitCoHost() async {
    final result = await _coHostStore?.exitHostConnection();

    if (!mounted) return;
    if (result != null && result.isSuccess) {
      setState(() {
        _isCoHostConnected = false;
        _connectedHostLiveID = null;
      });
      _showToast(AppLocalizations.of(context)!.livePKCoHostDisconnected);

      // If PK is in progress, end PK at the same time
      if (_isBattling && _currentBattleID != null) {
        final exitResult = await _battleStore?.exitBattle(_currentBattleID!);
        if (!mounted) return;
        if (exitResult != null && exitResult.isSuccess) {
          _handleBattleEnded();
        }
      }
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result?.errorMessage ?? ''));
    }
  }

  // MARK: - PK battle actions

  /// Handle taps on the PK button
  void _battleButtonTapped() {
    if (_isBattling) {
      // PK is in progress, confirm before ending it
      _confirmEndBattle();
    } else {
      // Not currently in PK, start a PK battle
      _startBattle();
    }
  }

  /// Start PK
  void _startBattle() {
    if (!_isCoHostConnected) return;

    // Get the `userID` list of connected hosts (excluding self)
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    final connectedUsers = _coHostStore?.coHostState.connected.value ?? [];
    final userIDList = connectedUsers
        .map((u) => u.userID)
        .where((id) => id != currentUserID)
        .toList();

    if (userIDList.isEmpty) {
      _showToast(AppLocalizations.of(context)!.livePKCoHostEmptyList);
      return;
    }

    _showToast(AppLocalizations.of(context)!.livePKBattleRequesting);

    final config = BattleConfig(duration: 30, needResponse: true, extensionInfo: '');
    _battleStore?.requestBattle(
      config: config,
      userIDList: userIDList,
      timeout: 10,
    );
  }

  /// Confirm ending PK
  void _confirmEndBattle() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.livePKBattleEnd),
          content: Text(l10n.livePKBattleConfirmEnd),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _exitBattle();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  /// Exit PK
  void _exitBattle() async {
    if (_currentBattleID == null) return;
    final result = await _battleStore?.exitBattle(_currentBattleID!);

    if (!mounted) return;
    if (result != null && result.isSuccess) {
      _handleBattleEnded();
      _showToast(AppLocalizations.of(context)!.livePKBattleEnded);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result?.errorMessage ?? ''));
    }
  }

  // MARK: - CoHost event bindings (anchor side)

  void _setupCoHostBindings() {
    _coHostListener = CoHostListener(
      onCoHostRequestReceived: (inviter, extensionInfo) {
        if (!mounted && widget.role == Role.audience) return;
        _showCoHostRequestAlert(inviter);
      },
      onCoHostRequestAccepted: (invitee) {
        if (!mounted) return;
        setState(() {
          _isCoHostConnected = true;
          _connectedHostLiveID = invitee.liveID;
        });
        if (widget.role == Role.audience) return;
        final name = invitee.userName.isEmpty ? invitee.userID : invitee.userName;
        _showToast(AppLocalizations.of(context)!.livePKCoHostRequestAccepted(name));
      },
      onCoHostRequestRejected: (invitee) {
        if (!mounted && widget.role == Role.audience) return;
        final name = invitee.userName.isEmpty ? invitee.userID : invitee.userName;
        _showToast(AppLocalizations.of(context)!.livePKCoHostRequestRejected(name));
      },
      onCoHostRequestTimeout: (inviter, invitee) {
        if (!mounted && widget.role == Role.audience) return;
        _showToast(AppLocalizations.of(context)!.livePKCoHostRequestTimeout);
      },
      onCoHostRequestCancelled: (inviter, invitee) {
        if (!mounted && widget.role == Role.audience) return;
        _showToast(AppLocalizations.of(context)!.livePKCoHostRequestCancelled);
      },
      onCoHostUserJoined: (userInfo) {
        if (!mounted) return;
        setState(() {
          _isCoHostConnected = true;
          _connectedHostLiveID = userInfo.liveID;
        });
        if (widget.role == Role.audience) return;
        _showToast(AppLocalizations.of(context)!.livePKCoHostConnected);
      },
      onCoHostUserLeft: (userInfo) {
        if (!mounted) return;
        if (widget.role == Role.anchor) {
          final name = userInfo.userName.isEmpty ? userInfo.userID : userInfo.userName;
          _showToast(AppLocalizations.of(context)!.livePKCoHostUserLeft(name));
        }
        // When the host connection ends, automatically end PK if it is in progress
        if (_isBattling) {
          _handleBattleEnded();
        }
        setState(() {
          _isCoHostConnected = false;
        });
      },
    );
    _coHostStore?.addCoHostListener(_coHostListener!);

    // 订阅 PK 状态变化(Score更新)
    _setupBattleStateObserver();
  }

  /// Show the incoming host-connection request dialog
  void _showCoHostRequestAlert(SeatUserInfo inviter) {
    final l10n = AppLocalizations.of(context)!;
    final name = inviter.userName.isEmpty ? inviter.userID : inviter.userName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.livePKCoHostConnect),
          content: Text(l10n.livePKCoHostRequestReceived(name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coHostStore?.rejectHostConnection(inviter.liveID);
              },
              child: Text(l10n.coGuestApplicationReject),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coHostStore?.acceptHostConnection(inviter.liveID);
              },
              child: Text(l10n.coGuestApplicationAccept),
            ),
          ],
        );
      },
    );
  }

  // MARK: - Battle event bindings (anchor side)

  void _setupBattleBindings() {
    _battleListener = BattleListener(
      onBattleStarted: (battleInfo, inviter, invitees) {
        if (!mounted) return;
        final battleUsers = [inviter, ...invitees];
        _handleBattleStarted(battleInfo: battleInfo, battleUsers: battleUsers);
      },
      onBattleEnded: (battleInfo, reason) {
        if (!mounted) return;
        _handleBattleEnded();
        _showToast(AppLocalizations.of(context)!.livePKBattleEnded);
      },
      onBattleRequestReceived: (battleID, inviter, invitee) {
        if (!mounted && widget.role == Role.audience) return;
        _showBattleRequestAlert(battleID: battleID, inviter: inviter);
      },
      onUserJoinBattle: (battleID, battleUser) {
        // A user joined the PK battle
      },
    );
    _battleStore?.addBattleListener(_battleListener!);

    // 订阅 PK 状态变化(Score更新)
    _setupBattleStateObserver();
  }

  /// Show the incoming PK request dialog
  void _showBattleRequestAlert({required String battleID, required SeatUserInfo inviter}) {
    final l10n = AppLocalizations.of(context)!;
    final name = inviter.userName.isEmpty ? inviter.userID : inviter.userName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.livePKBattleTitle),
          content: Text(l10n.livePKBattleRequestReceived(name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _battleStore?.rejectBattle(battleID);
              },
              child: Text(l10n.coGuestApplicationReject),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _battleStore?.acceptBattle(battleID);
              },
              child: Text(l10n.coGuestApplicationAccept),
            ),
          ],
        );
      },
    );
  }

  // MARK: - Audience-side state observers

  /// 观众端监听co-guest state变化(使用 addListener 替代 subscribe().listen())
  void _setupCoHostStateObserver() {
    _coHostStateListener = () {
      if (!mounted) return;
      final wasConnected = _isCoHostConnected;
      final isNowConnected = _coHostStore?.coHostState.coHostStatus.value == CoHostStatus.connected;
      if (wasConnected != isNowConnected) {
        setState(() {
          _isCoHostConnected = isNowConnected;
        });
      }
    };
    _coHostStore?.coHostState.coHostStatus.addListener(_coHostStateListener!);
  }

  /// 观众端 / 主播端 监听 PK 状态变化(Score更新)
  void _setupBattleStateObserver() {
    _battleStateListener = () {
      if (!mounted) return;
      final battleState = _battleStore?.battleState;
      if (battleState == null) return;

      final currentBattleInfo = battleState.currentBattleInfo.value;
      final battleUsers = battleState.battleUsers.value;

      if (currentBattleInfo != null) {
        if (!_isBattling) {
          _handleBattleStarted(battleInfo: currentBattleInfo, battleUsers: battleUsers);
        } else if (battleUsers.length != _battleScoreEntries.length) {
          // 参战人数变化(有人加入/退出), 重建Score面板
          _rebuildScoreEntries(battleUsers);
        }
        // 更新Score
        _updateBattleScores(battleState);
      } else if (_isBattling) {
        _handleBattleEnded();
      }
    };
    _battleStore?.battleState.currentBattleInfo.addListener(_battleStateListener!);
    _battleStore?.battleState.battleUsers.addListener(_battleStateListener!);
    _battleStore?.battleState.battleScore.addListener(_battleStateListener!);
  }

  // MARK: - PK state handling

  /// PK started
  void _handleBattleStarted({required BattleInfo battleInfo, required List<SeatUserInfo> battleUsers}) {
    // Calculate the PK end time: prefer `endTime`, otherwise compute it from `startTime + duration`
    if (battleInfo.endTime > 0) {
      _pkEndTime = battleInfo.endTime.toInt();
    } else if (battleInfo.startTime > 0 && battleInfo.config.duration > 0) {
      _pkEndTime = battleInfo.startTime.toInt() + battleInfo.config.duration.toInt();
    } else if (battleInfo.config.duration > 0) {
      _pkEndTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + battleInfo.config.duration.toInt();
    } else {
      _pkEndTime = 0;
    }

    // 动态构建多人Score面板
    _rebuildScoreEntries(battleUsers);

    setState(() {
      _isBattling = true;
      _currentBattleID = battleInfo.battleID;
      _pkScoreVisible = true;
      _pkStatusText = AppLocalizations.of(context)!.livePKStatusBattling;
      _pkStatusColor = Colors.yellow;
    });

    // Start the countdown
    _startPKTimer();

    _showToast(AppLocalizations.of(context)!.livePKBattleStarted);
  }

  /// PK ended
  void _handleBattleEnded() {
    // Prevent duplicate triggers
    if (!_isBattling) return;

    _stopPKTimer();

    // 显示结果后隐藏Score面板
    _showBattleResult();

    setState(() {
      _isBattling = false;
      _currentBattleID = null;
    });
  }

  /// 根据参战用户列表重建Score数据
  void _rebuildScoreEntries(List<SeatUserInfo> battleUsers) {
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';

    _battleScoreEntries = battleUsers.map((user) {
      return _BattleScoreEntry(
        userID: user.userID,
        userName: user.userName,
        score: 0,
        isMe: user.userID == currentUserID,
      );
    }).toList();
  }

  /// 更新 PK Score(支持多人)
  void _updateBattleScores(BattleState state) {
    final scoreMap = state.battleScore.value;
    bool changed = false;
    for (int i = 0; i < _battleScoreEntries.length; i++) {
      final score = scoreMap[_battleScoreEntries[i].userID] ?? 0;
      if (_battleScoreEntries[i].score != score) {
        _battleScoreEntries[i].score = score;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  /// Show the PK result (supports multiple participants)
  void _showBattleResult() {
    final l10n = AppLocalizations.of(context)!;

    // 找到自己的Score和最高分
    final myScore = _battleScoreEntries.firstWhere((e) => e.isMe, orElse: () => _BattleScoreEntry(userID: '', userName: '', score: 0, isMe: true)).score;
    final maxScore = _battleScoreEntries.map((e) => e.score).fold(0, (a, b) => a > b ? a : b);
    final maxCount = _battleScoreEntries.where((e) => e.score == maxScore).length;

    if (maxCount == _battleScoreEntries.length) {
      // 所有人Score相同 → 平局
      _pkStatusText = l10n.livePKBattleDraw;
      _pkStatusColor = Colors.white;
    } else if (myScore == maxScore) {
      // The local score is the highest -> win
      _pkStatusText = l10n.livePKBattleWin;
      _pkStatusColor = Colors.yellow;
    } else {
      // The local score is not the highest -> lose
      _pkStatusText = l10n.livePKBattleLose;
      _pkStatusColor = Colors.grey;
    }

    // 高亮获胜者的Score标签
    for (int i = 0; i < _battleScoreEntries.length; i++) {
      if (_battleScoreEntries[i].score == maxScore && maxCount < _battleScoreEntries.length) {
        _battleScoreEntries[i].scoreColor = Colors.yellow;
      }
    }

    // 确保Score面板可见, 展示结果
    setState(() {
      _pkScoreVisible = true;
    });

    // Hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _isBattling) return;
      setState(() {
        _pkScoreVisible = false;
        _pkStatusText = '';
        _pkStatusColor = Colors.yellow;
        // 重置Score颜色
        for (final entry in _battleScoreEntries) {
          entry.scoreColor = null;
        }
      });
    });
  }

  // MARK: - PK countdown

  void _startPKTimer() {
    _stopPKTimer();
    setState(() {}); // 触发 _pkTimerText 更新
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (_pkEndTime > 0 && now >= _pkEndTime) {
        _stopPKTimer();
      }
      setState(() {}); // 触发 _pkTimerText 更新
    });
  }

  void _stopPKTimer() {
    _pkTimer?.cancel();
    _pkTimer = null;
  }

  // MARK: - State Handling

  void _handleLiveEnded(String liveID, LiveEndedReason reason, String message) {
    if (liveID == widget.liveID && widget.role == Role.audience) {
      if (!mounted) return;
      setState(() {
        _isLiveActive = false;
      });
      _stopPKTimer();
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusEnded);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _handleKickedOutOfLive(String liveID, LiveKickedOutReason reason, String message) {
    if (liveID == widget.liveID) {
      if (!mounted) return;
      setState(() {
        _isLiveActive = false;
      });
      _stopPKTimer();
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusEnded);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // MARK: - UI Helpers

  /// Handle the end-live button tap and show the confirmation dialog
  void _endLiveButtonTapped() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.basicStreamingEndLiveConfirmTitle),
          content: Text(l10n.basicStreamingEndLiveConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _endLiveAndGoBack();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  // MARK: - Cleanup

  /// Clean up live resources when leaving the page
  void _cleanupLiveSession() {
    if (!_isLiveActive) return;

    _stopPKTimer();

    switch (widget.role) {
      case Role.anchor:
        // Exit PK 和连线
        if (_isBattling && _currentBattleID != null) {
          _battleStore?.exitBattle(_currentBattleID!);
        }
        if (_isCoHostConnected) {
          _coHostStore?.exitHostConnection();
        }

        DeviceStore.shared.closeLocalCamera();
        DeviceStore.shared.closeLocalMicrophone();
        LiveListStore.shared.endLive();
        break;

      case Role.audience:
        LiveListStore.shared.leaveLive();
        break;
    }

    _isLiveActive = false;
  }

  // MARK: - Toast Helper

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// MARK: - BattleScoreEntry

/// PK Score数据模型
class _BattleScoreEntry {
  final String userID;
  final String userName;
  int score;
  final bool isMe;
  Color? scoreColor;

  _BattleScoreEntry({
    required this.userID,
    required this.userName,
    required this.score,
    required this.isMe,
    this.scoreColor,
  });
}
