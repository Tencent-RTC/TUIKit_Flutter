import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/role.dart';
import 'package:atomic_x_core_example/components/setting_panel_controller.dart';
import 'package:atomic_x_core_example/components/device_setting_widget.dart';
import 'package:atomic_x_core_example/components/permission_helper.dart';
import 'package:atomic_x_core_example/components/beauty_setting_widget.dart';
import 'package:atomic_x_core_example/components/audio_effect_setting_widget.dart';
import 'package:atomic_x_core_example/components/barrage_widget.dart';
import 'package:atomic_x_core_example/components/gift_panel_widget.dart';
import 'package:atomic_x_core_example/components/gift_animation_widget.dart';
import 'package:atomic_x_core_example/components/like_button.dart' as app_like;

/// Business scenario: real-time interaction page
///
/// On top of the basic live-streaming flow (`BasicStreaming`), this page adds real-time interaction features:
/// - Barrage chat (`BarrageStore`)
/// - Gift system (`GiftStore`)
/// - Likes (`LikeStore`)
/// - Beauty effects (`BaseBeautyStore`) — anchor only
/// - Audio effect settings (`AudioEffectStore`) — anchor only
///
/// Related APIs (basic live streaming):
/// - `LiveListStore.shared.createLive(_:completion:)` - anchor creates a live stream
/// - `LiveListStore.shared.joinLive(liveID:completion:)` - audience joins a live stream
/// - `LiveListStore.shared.endLive(completion:)` - anchor ends the live stream
/// - `LiveListStore.shared.leaveLive(completion:)` - audience leaves the live stream
/// - `LiveListStore.shared.liveListEventPublisher` - live event listener
/// - `DeviceStore.shared.openLocalCamera(isFront:completion:)` - open the camera
/// - `DeviceStore.shared.openLocalMicrophone(completion:)` - open the microphone
/// - `DeviceStore.shared.closeLocalCamera()` - close the camera
/// - `DeviceStore.shared.closeLocalMicrophone()` - close the microphone
/// - `LiveCoreView(viewType:)` - video rendering widget
///
/// Related APIs (real-time interaction):
/// - `BarrageStore.create(liveID:)` - barrage management
/// - `GiftStore.create(liveID:)` - gift management
/// - `GiftStore.giftEventPublisher` - gift event listener (for playing animations)
/// - `LikeStore.create(liveID:)` - like management
/// - `BaseBeautyStore.shared` - beauty management (singleton)
/// - `AudioEffectStore.shared` - audio effect management (singleton)
///
/// Different operations are provided based on the role:
/// - Anchor: pushing + barrage + likes + beauty + audio effects + device management + gift animation display
/// - Audience: playback + barrage + gifts + likes + gift animation display
class InteractivePage extends StatefulWidget {
  // MARK: - Properties

  final Role role;
  final String liveID;

  // MARK: - Init

  const InteractivePage({super.key, required this.role, required this.liveID});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  // MARK: - Properties

  /// Whether the page is currently in the live state
  bool _isLiveActive = false;

  late final LiveCoreController _liveCoreController;
  late final LiveListListener _liveListListener;
  late final GiftStore _giftStore;
  late final GiftListener _giftListener;

  // Used to keep track of the `GlobalKey` for `GiftAnimationWidget`
  final GlobalKey<GiftAnimationWidgetState> _giftAnimationKey = GlobalKey<GiftAnimationWidgetState>();

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
    _liveListListener = LiveListListener(onLiveEnded: _handleLiveEnded, onKickedOutOfLive: _handleKickedOutOfLive);
    LiveListStore.shared.addLiveListListener(_liveListListener);

    // Create gift management so the anchor side can also listen for gift events
    _giftStore = GiftStore.create(widget.liveID);
    _giftListener = GiftListener(
      onReceiveGift: (liveID, gift, count, sender) {
        // Play the gift animation (full-screen SVGA or barrage slide animation)
        _giftAnimationKey.currentState?.playGiftAnimation(gift: gift, count: count, sender: sender);
      },
    );
    _giftStore.addGiftListener(_giftListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureForRole();
    });
  }

  @override
  void dispose() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _giftStore.removeGiftListener(_giftListener);
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
            title: Text(widget.liveID, style: const TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _handleBackPressed,
            ),
            actions: _buildNavigationBarActions(l10n),
          ),
          body: Stack(
            children: [
              // Full-screen video rendering area
              Positioned.fill(child: LiveCoreWidget(controller: _liveCoreController)),

              // Interactive widgets (shown only while live)
              if (_isLiveActive) ...[
                // Barrage widget - lower-left area
                Positioned(
                  left: 0,
                  right: MediaQuery.of(context).size.width * 0.3,
                  bottom: MediaQuery.of(context).padding.bottom + 18,
                  height: 280,
                  child: BarrageWidget(liveID: widget.liveID),
                ),

                // Like button - lower-right corner
                Positioned(
                  right: 10,
                  bottom: MediaQuery.of(context).padding.bottom + 18,
                  child: app_like.LikeButton(liveID: widget.liveID),
                ),

                // Audience-side gift entry button
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
                        child: const Icon(Icons.card_giftcard, size: 15, color: Colors.pink),
                      ),
                    ),
                  ),

                // Gift animation widget - shared full-screen overlay for anchor and audience
                Positioned.fill(child: IgnorePointer(child: GiftAnimationWidget(key: _giftAnimationKey))),
              ],

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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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

  // MARK: - Navigation Bar

  List<Widget> _buildNavigationBarActions(AppLocalizations l10n) {
    final actions = <Widget>[];

    if (widget.role == Role.anchor) {
      // While live: show the end-live button
      if (_isLiveActive) {
        actions.add(IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: _endLiveButtonTapped));
      }

      // Device settings button (combined device / beauty / audio tabs)
      actions.add(IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _settingsTapped));
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

  /// Settings panel entry (combines device management, beauty, and audio effects)
  void _settingsTapped() {
    final l10n = AppLocalizations.of(context)!;

    // The anchor settings panel switches tabs between device management / beauty / audio effects
    showSettingPanel(
      context: context,
      title: l10n.interactiveSettingsTitle,
      contentWidget: TabbedSettingView(
        tabs: [
          TabbedSettingTab(title: l10n.deviceSettingTitle, child: const DeviceSettingWidget()),
          TabbedSettingTab(title: l10n.interactiveBeautyTitle, child: const BeautySettingWidget()),
          TabbedSettingTab(title: l10n.interactiveAudioEffectTitle, child: const AudioEffectSettingWidget()),
        ],
      ),
      height: 525,
    );
  }

  /// Show the gift panel as a half-screen bottom sheet
  void _showGiftPanel() {
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
      height: 395,
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
      setState(() {
        _isLiveActive = true;
      });

      // Set the `LiveID` on `LiveCoreWidget` and start rendering the outgoing stream view
      _liveCoreController.setLiveID(result.liveInfo.liveID);

      _showToast(l10n.basicStreamingStatusCreated(result.liveInfo.liveID));
    } else {
      _showToast(l10n.basicStreamingStatusFailed(result.errorMessage ?? ''));

      // Creation failed, so close any devices that were already opened
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
      setState(() {
        _isLiveActive = true;
      });
      _liveCoreController.setLiveID(result.liveInfo.liveID);
      _showToast(l10n.basicStreamingStatusJoined(result.liveInfo.liveID));
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

    final result = await LiveListStore.shared.endLive();

    if (!mounted) return;
    if (result.isSuccess) {
      DeviceStore.shared.closeLocalCamera();
      DeviceStore.shared.closeLocalMicrophone();
      BaseBeautyStore.shared.reset();
      AudioEffectStore.shared.reset();
      setState(() {
        _isLiveActive = false;
      });
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
      Navigator.pop(context);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  // MARK: - State Handling

  void _handleLiveEnded(String liveID, LiveEndedReason reason, String message) {
    if (liveID == widget.liveID && widget.role == Role.audience) {
      if (!mounted) return;
      setState(() {
        _isLiveActive = false;
      });
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
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

    switch (widget.role) {
      case Role.anchor:
        DeviceStore.shared.closeLocalCamera();
        DeviceStore.shared.closeLocalMicrophone();
        BaseBeautyStore.shared.reset();
        AudioEffectStore.shared.reset();
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

// MARK: - TabbedSettingView

/// Tabbed container component
///
/// Used to display multiple settings panels as tabs inside `SettingPanelController`:
/// - Device management (`DeviceSettingWidget`)
/// - Beauty settings (`BeautySettingWidget`)
/// - Audio effect settings (`AudioEffectSettingWidget`)
class TabbedSettingTab {
  final String title;
  final Widget child;

  const TabbedSettingTab({required this.title, required this.child});
}

class TabbedSettingView extends StatefulWidget {
  final List<TabbedSettingTab> tabs;

  const TabbedSettingView({super.key, required this.tabs});

  @override
  State<TabbedSettingView> createState() => _TabbedSettingViewState();
}

class _TabbedSettingViewState extends State<TabbedSettingView> {
  // MARK: - Properties

  int _selectedTabIndex = 0;

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SegmentedControl
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: List.generate(
                widget.tabs.length,
                (index) => ButtonSegment<int>(value: index, label: Text(widget.tabs[index].title)),
              ),
              selected: {_selectedTabIndex},
              onSelectionChanged: (Set<int> selected) {
                setState(() {
                  _selectedTabIndex = selected.first;
                });
              },
              showSelectedIcon: false,
            ),
          ),
        ),

        // Content area - use `IndexedStack` to keep all tab states
        Expanded(child: IndexedStack(index: _selectedTabIndex, children: widget.tabs.map((tab) => tab.child).toList())),
      ],
    );
  }
}
