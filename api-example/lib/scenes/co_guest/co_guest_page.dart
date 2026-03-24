import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/role.dart';
import 'package:atomic_x_core_example/components/setting_panel_controller.dart';
import 'package:atomic_x_core_example/components/device_setting_widget.dart';
import 'package:atomic_x_core_example/components/permission_helper.dart';

/// Business scenario: audience co-guest page (Stage 3: CoGuest)
///
/// On top of the basic live-streaming flow, this page adds audience co-guest features:
/// - Audience list (`LiveAudienceStore`)
/// - Audience co-guest (`CoGuestStore`) - apply for co-guest, accept invitations, and join/leave the seat
/// - Seat management (`LiveSeatStore`) - manage the camera and microphone for co-guest users
///
/// Related APIs (basic live streaming):
/// - `LiveListStore.shared.createLive(LiveInfo)` -> `Future<CompletionHandler>` - anchor creates a live stream
/// - `LiveListStore.shared.joinLive(liveID)` -> `Future<CompletionHandler>` - audience joins a live stream
/// - `LiveListStore.shared.endLive()` -> `Future<CompletionHandler>` - anchor ends the live stream
/// - `LiveListStore.shared.leaveLive()` -> `Future<CompletionHandler>` - audience leaves the live stream
/// - `LiveListStore.shared.addLiveListListener(LiveListListener)` - live event listener
/// - `DeviceStore.shared.openLocalCamera(isFront)` -> `Future<CompletionHandler>` - open the camera
/// - `DeviceStore.shared.openLocalMicrophone()` -> `Future<CompletionHandler>` - open the microphone
/// - `DeviceStore.shared.closeLocalCamera()` - close the camera
/// - `DeviceStore.shared.closeLocalMicrophone()` - close the microphone
/// - `LiveCoreWidget(controller:, videoWidgetBuilder:)` - video rendering widget
///
/// Related APIs (audience co-guest):
/// - `LiveAudienceStore.create(liveID)` - fetch the audience list (positional parameter)
/// - `LiveAudienceStore.fetchAudienceList()` -> `Future<CompletionHandler>` - refresh the audience list
/// - `LiveAudienceStore.liveAudienceState` - audience state (`audienceList`, `audienceCount`)
/// - `LiveAudienceStore.addLiveAudienceListener(LiveAudienceListener)` - audience join/leave events
/// - `CoGuestStore.create(liveID)` - audience co-guest management (positional parameter)
/// - `CoGuestStore.applyForSeat({seatIndex:, timeout:, extraInfo:})` -> `Future<CompletionHandler>`
/// - `CoGuestStore.cancelApplication()` -> `Future<CompletionHandler>`
/// - `CoGuestStore.acceptApplication(userID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `CoGuestStore.rejectApplication(userID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `CoGuestStore.inviteToSeat({inviteeID:, seatIndex:, timeout:, extraInfo:})` -> `Future<CompletionHandler>`
/// - `CoGuestStore.acceptInvitation(inviterID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `CoGuestStore.rejectInvitation(inviterID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `CoGuestStore.disconnect()` -> `Future<CompletionHandler>`
/// - `CoGuestStore.coGuestState` - co-guest state (`connected`, `applicants`, `invitees`)
/// - `CoGuestStore.addGuestListener(GuestListener)` - audience-side events
/// - `CoGuestStore.addHostListener(HostListener)` - anchor-side events
/// - `LiveSeatStore.create(liveID)` - seat management (positional parameter)
/// - `LiveSeatStore.openRemoteCamera({userID:, policy:})` -> `Future<CompletionHandler>`
/// - `LiveSeatStore.closeRemoteCamera(userID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `LiveSeatStore.openRemoteMicrophone({userID:, policy:})` -> `Future<CompletionHandler>`
/// - `LiveSeatStore.closeRemoteMicrophone(userID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `LiveSeatStore.kickUserOutOfSeat(userID)` -> `Future<CompletionHandler>` (positional parameter)
/// - `LiveSeatStore.liveSeatState` - seat state (`seatList`)
/// - `LiveSeatStore.addLiveSeatEventListener(LiveSeatListener)` - seat events
/// - `LiveCoreWidget(videoWidgetBuilder: VideoWidgetBuilder)` - custom video area builder
///
/// Different operations are provided based on the role:
/// - Anchor: pushing + viewing the audience list + inviting co-guests + handling co-guest applications + managing co-guest user devices
/// - Audience: playback + viewing the audience list + applying for co-guest + responding to invitations + managing their own devices after joining the seat
class CoGuestPage extends StatefulWidget {
  // MARK: - Properties

  final Role role;
  final String liveID;

  // MARK: - Init

  const CoGuestPage({super.key, required this.role, required this.liveID});

  @override
  State<CoGuestPage> createState() => _CoGuestPageState();
}

class _CoGuestPageState extends State<CoGuestPage> {
  // MARK: - Properties

  /// Whether the page is currently in the live state
  bool _isLiveActive = false;

  /// Whether the audience user is already on the seat (co-guesting)
  bool _isOnSeat = false;

  /// Whether the audience user is currently applying for co-guest
  bool _isApplying = false;

  late final LiveCoreController _liveCoreController;
  late final LiveListListener _liveListListener;

  // MARK: - Stores

  late final LiveAudienceStore _liveAudienceStore;
  late final CoGuestStore _coGuestStore;
  late final LiveSeatStore _liveSeatStore;

  // MARK: - Listener callbacks (used for `addListener` / `removeListener`)

  late final HostListener _hostListener;
  late final GuestListener _guestListener;
  late final LiveSeatListener _liveSeatListener;

  /// `State` `ValueListenable` listener callbacks
  late final VoidCallback _onAudienceCountChanged;
  late final VoidCallback _onCoGuestConnectedChanged;
  late final VoidCallback _onSeatListChanged;

  /// Whether state listeners have been registered (only after entering the live session)
  bool _bindingsSetup = false;

  /// Keep references to `CoGuestOverlayView` states (key: `userID`) to update audio/video status display
  final Map<String, _CoGuestOverlayState> _overlayStates = {};

  /// Online audience count
  int _audienceCount = 0;

  // MARK: - Lifecycle

  @override
  void initState() {
    super.initState();

    // Create the video rendering controller - anchor uses `pushView`, audience uses `playView`
    _liveCoreController = LiveCoreController.create(
      widget.role == Role.anchor ? CoreViewType.pushView : CoreViewType.playView,
    );
    _liveCoreController.setLiveID(widget.liveID);

    // Initialize stores (positional parameters)
    _liveAudienceStore = LiveAudienceStore.create(widget.liveID);
    _coGuestStore = CoGuestStore.create(widget.liveID);
    _liveSeatStore = LiveSeatStore.create(widget.liveID);

    // Listen for live events (live ended, kicked out, and so on)
    _liveListListener = LiveListListener(onLiveEnded: _handleLiveEnded, onKickedOutOfLive: _handleKickedOutOfLive);
    LiveListStore.shared.addLiveListListener(_liveListListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureForRole();
    });
  }

  @override
  void dispose() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    _removeCoGuestBindings();
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
              Positioned.fill(
                child: LiveCoreWidget(
                  controller: _liveCoreController,
                  videoWidgetBuilder: VideoWidgetBuilder(coGuestWidgetBuilder: _buildCoGuestWidget),
                ),
              ),

              // Interactive widgets (shown only while live)
              if (_isLiveActive) ...[
                // Online audience count badge - right below the navigation bar
                if (_audienceCount > 0)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: _audienceCountTapped,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            l10n.coGuestAudienceCount(_audienceCount),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom co-guest button
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: GestureDetector(
                    onTap: _coGuestButtonTapped,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _coGuestButtonColor, borderRadius: BorderRadius.circular(20)),
                      child: Icon(_coGuestButtonIcon, size: 15, color: Colors.white),
                    ),
                  ),
                ),
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

  // MARK: - Co-guest button appearance

  Color get _coGuestButtonColor {
    if (widget.role == Role.anchor) {
      return Colors.green.withValues(alpha: 0.8);
    }
    // Audience side: changes based on the current state
    if (_isOnSeat) {
      return Colors.red.withValues(alpha: 0.8);
    } else if (_isApplying) {
      return Colors.orange.withValues(alpha: 0.8);
    }
    return Colors.green.withValues(alpha: 0.8);
  }

  IconData get _coGuestButtonIcon {
    if (widget.role == Role.anchor) {
      return Icons.people;
    }
    if (_isOnSeat) {
      return Icons.phone_disabled;
    } else if (_isApplying) {
      return Icons.access_time_filled;
    }
    return Icons.people;
  }

  // MARK: - Navigation Bar

  List<Widget> _buildNavigationBarActions(AppLocalizations l10n) {
    final actions = <Widget>[];

    if (widget.role == Role.anchor) {
      // While live: show the end-live button
      if (_isLiveActive) {
        actions.add(IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: _endLiveButtonTapped));
      }

      // Device settings button
      actions.add(IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _settingsTapped));
    }

    return actions;
  }

  // MARK: - VideoWidgetBuilder

  /// `CoGuestWidgetBuilder`: create the foreground/background overlay view for co-guest users
  Widget _buildCoGuestWidget(BuildContext context, SeatInfo seatInfo, ViewLayer viewLayer) {
    switch (viewLayer) {
      case ViewLayer.foreground:
        // Foreground layer: avatar (shown when the camera is off) + microphone status icon + nickname label
        return _CoGuestOverlayView(
          seatInfo: seatInfo,
          onTap: (info) => _handleCoGuestViewTapped(seatInfo: info),
          onStateCreated: (state) {
            _overlayStates[seatInfo.userInfo.userID] = state;
          },
        );

      case ViewLayer.background:
        return Container();
    }
  }

  /// Handle taps on the co-guest video area
  void _handleCoGuestViewTapped({required SeatInfo seatInfo}) {
    // Defensive check: if `userID` is empty (empty seat), ignore the tap
    final tappedUserID = seatInfo.userInfo.userID;
    if (tappedUserID.isEmpty) {
      debugPrint('[CoGuest] Tapped on empty seat, ignoring.');
      return;
    }

    // Defensive check: if the current user is not logged in (`loginUserInfo` is null), the role cannot be determined
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (currentUserID == null || currentUserID.isEmpty) {
      debugPrint('[CoGuest] Cannot handle tap: loginUserInfo is null or userID is empty.');
      return;
    }

    if (widget.role == Role.anchor) {
      // Anchor taps a co-guest user -> show device management (excluding self)
      if (tappedUserID != currentUserID) {
        _showSeatUserDeviceAlert(seatInfo: seatInfo);
      }
    } else {
      // Audience taps their own video area -> manage their own devices
      if (tappedUserID == currentUserID) {
        _showSelfDeviceAlert();
      }
    }
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

  // MARK: - Interactive widget setup

  /// Set up co-guest-related state subscriptions (called after entering the live session)
  void _setupCoGuestBindings() {
    if (_bindingsSetup) return;
    _bindingsSetup = true;

    // 订阅audience list变化 → 更新在线人数标签(ValueListenable)
    _onAudienceCountChanged = () {
      if (!mounted) return;
      setState(() {
        _audienceCount = _liveAudienceStore.liveAudienceState.audienceCount.value;
      });
    };
    _liveAudienceStore.liveAudienceState.audienceCount.addListener(_onAudienceCountChanged);

    // 订阅co-guest state变化 → 更新Host connection button状态(ValueListenable)
    _onCoGuestConnectedChanged = () {
      if (!mounted) return;
      _handleCoGuestStateUpdate();
    };
    _coGuestStore.coGuestState.connected.addListener(_onCoGuestConnectedChanged);

    // 订阅seat state变化 → 更新连线用户的音视频状态显示(ValueListenable)
    _onSeatListChanged = () {
      if (!mounted) return;
      _handleSeatStateUpdate();
    };
    _liveSeatStore.liveSeatState.seatList.addListener(_onSeatListChanged);

    if (widget.role == Role.anchor) {
      // Anchor side: listen for audience co-guest applications (`Listener` callback mode)
      _hostListener = HostListener(
        onGuestApplicationReceived: (guestUser) {
          if (!mounted) return;
          _showApplicationAlert(guestUser);
        },
        onHostInvitationResponded: (isAccept, guestUser) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          final name = guestUser.userName.isEmpty ? guestUser.userID : guestUser.userName;
          if (isAccept) {
            _showToast(l10n.coGuestEventInviteAccepted(name));
          } else {
            _showToast(l10n.coGuestEventInviteRejected(name));
          }
        },
        onGuestApplicationCancelled: (guestUser) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          final name = guestUser.userName.isEmpty ? guestUser.userID : guestUser.userName;
          _showToast(l10n.coGuestEventApplicationCancelled(name));
        },
      );
      _coGuestStore.addHostListener(_hostListener);
    } else {
      // Audience side: listen for the anchor's co-guest invitations and application responses (`Listener` callback mode)
      _guestListener = GuestListener(
        onHostInvitationReceived: (hostUser) {
          if (!mounted) return;
          _showInvitationAlert(hostUser);
        },
        onGuestApplicationResponded: (isAccept, hostUser) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          if (isAccept) {
            setState(() {
              _isApplying = false;
            });
          } else {
            setState(() {
              _isApplying = false;
            });
            final name = hostUser.userName.isEmpty ? hostUser.userID : hostUser.userName;
            _showToast(l10n.coGuestEventApplicationRejected(name));
          }
        },
        onGuestApplicationNoResponse: (reason) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _isApplying = false;
          });
          _showToast(l10n.coGuestEventApplicationTimeout);
        },
        onKickedOffSeat: (seatIndex, hostUser) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _isOnSeat = false;
            _isApplying = false;
          });
          DeviceStore.shared.closeLocalCamera();
          DeviceStore.shared.closeLocalMicrophone();
          _showToast(l10n.coGuestEventKickedOff);
        },
        onHostInvitationCancelled: (hostUser) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          _showToast(l10n.coGuestEventInvitationCancelled);
        },
      );
      _coGuestStore.addGuestListener(_guestListener);

      // 观众端: 监听主播对本地设备的操作(打开/close the camera、麦克风)
      _liveSeatListener = LiveSeatListener(
        onLocalCameraClosedByAdmin: () {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          _showToast(l10n.coGuestDeviceCameraClosed);
        },
        onLocalCameraOpenedByAdmin: (policy) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          _showDeviceRequestAlert(
            title: l10n.coGuestDeviceCameraRequestTitle,
            message: l10n.coGuestDeviceCameraRequestMessage,
            onAccept: () {
              PermissionHelper.requestCameraPermission(
                context,
                onGranted: () {
                  DeviceStore.shared.openLocalCamera(true);
                },
              );
            },
          );
        },
        onLocalMicrophoneClosedByAdmin: () {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          _showToast(l10n.coGuestDeviceMicClosed);
        },
        onLocalMicrophoneOpenedByAdmin: (policy) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          _showDeviceRequestAlert(
            title: l10n.coGuestDeviceMicRequestTitle,
            message: l10n.coGuestDeviceMicRequestMessage,
            onAccept: () {
              PermissionHelper.requestMicrophonePermission(
                context,
                onGranted: () {
                  _liveSeatStore.unmuteMicrophone();
                  DeviceStore.shared.openLocalMicrophone();
                },
              );
            },
          );
        },
      );
      _liveSeatStore.addLiveSeatEventListener(_liveSeatListener);
    }

    // 获取初始audience list
    _liveAudienceStore.fetchAudienceList();
  }

  /// Remove co-guest-related state subscriptions
  void _removeCoGuestBindings() {
    if (!_bindingsSetup) return;
    _bindingsSetup = false;

    _liveAudienceStore.liveAudienceState.audienceCount.removeListener(_onAudienceCountChanged);
    _coGuestStore.coGuestState.connected.removeListener(_onCoGuestConnectedChanged);
    _liveSeatStore.liveSeatState.seatList.removeListener(_onSeatListChanged);

    if (widget.role == Role.anchor) {
      _coGuestStore.removeHostListener(_hostListener);
    } else {
      _coGuestStore.removeGuestListener(_guestListener);
      _liveSeatStore.removeLiveSeatEventListener(_liveSeatListener);
    }
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
  Future<void> _audienceBackTapped() async {
    if (_isOnSeat) {
      // Leave the seat first, then exit
      final result = await _coGuestStore.disconnect();
      if (!mounted) return;
      if (result.isSuccess) {
        _isOnSeat = false;
        _leaveLiveAndGoBack();
      } else {
        _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
      }
    } else if (_isLiveActive) {
      if (_isApplying) {
        _coGuestStore.cancelApplication();
      }
      _leaveLiveAndGoBack();
    } else {
      Navigator.pop(context);
    }
  }

  /// Device settings panel entry
  void _settingsTapped() {
    final l10n = AppLocalizations.of(context)!;

    showSettingPanel(context: context, title: l10n.deviceSettingTitle, contentWidget: const DeviceSettingWidget());
  }

  /// Handle taps on the audience count badge
  void _audienceCountTapped() {
    _showAudienceListPanel();
  }

  /// Bottom co-guest button点击
  void _coGuestButtonTapped() {
    if (widget.role == Role.anchor) {
      // 主播: 打开audience list, 从列表中选择观众发起连线
      _showAudienceListPanel();
    } else {
      // Audience: directly apply for / cancel co-guest
      if (_isOnSeat) {
        // Already on the seat -> leave the seat
        _disconnectCoGuest();
      } else if (_isApplying) {
        // Application in progress -> cancel the application
        _cancelCoGuestApplication();
      } else {
        // Not connected -> apply for co-guest
        _applyForCoGuest();
      }
    }
  }

  // MARK: - audience list面板

  void _showAudienceListPanel() {
    final l10n = AppLocalizations.of(context)!;

    showSettingPanel(
      context: context,
      title: l10n.coGuestAudienceListTitle,
      contentWidget: _AudienceListPanelView(
        role: widget.role,
        audienceStore: _liveAudienceStore,
        coGuestStore: _coGuestStore,
        onInvite: (userID) {
          _inviteAudienceToSeat(userID: userID);
        },
      ),
      height: 400,
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
      _liveCoreController.setLiveID(result.liveInfo.liveID);
      _setupCoGuestBindings();
      _showToast(l10n.basicStreamingStatusCreated(result.liveInfo.liveID));
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
      setState(() {
        _isLiveActive = true;
      });
      _liveCoreController.setLiveID(result.liveInfo.liveID);
      _setupCoGuestBindings();
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

  // MARK: - Audience co-guest actions

  /// Audience: apply for co-guest (join the seat)
  Future<void> _applyForCoGuest() async {
    setState(() {
      _isApplying = true;
    });
    _showToast(AppLocalizations.of(context)!.coGuestStatusApplying);

    final result = await _coGuestStore.applyForSeat(seatIndex: -1, timeout: 30);

    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _isApplying = false;
      });
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  /// Audience: cancel the co-guest application
  Future<void> _cancelCoGuestApplication() async {
    final result = await _coGuestStore.cancelApplication();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _isApplying = false;
      });
      _showToast(AppLocalizations.of(context)!.coGuestStatusCancelled);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  /// Audience / anchor: disconnect the co-guest session
  Future<void> _disconnectCoGuest() async {
    final result = await _coGuestStore.disconnect();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _isOnSeat = false;
        _isApplying = false;
      });
      if (widget.role == Role.audience) {
        DeviceStore.shared.closeLocalCamera();
        DeviceStore.shared.closeLocalMicrophone();
      }
      _showToast(AppLocalizations.of(context)!.coGuestStatusDisconnected);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  /// Anchor: invite an audience user to the seat
  Future<void> _inviteAudienceToSeat({required String userID}) async {
    final result = await _coGuestStore.inviteToSeat(inviteeID: userID, seatIndex: -1, timeout: 30);
    if (!mounted) return;
    if (result.isSuccess) {
      _showToast(AppLocalizations.of(context)!.coGuestStatusInvited);
    } else {
      _showToast(AppLocalizations.of(context)!.basicStreamingStatusFailed(result.errorMessage ?? ''));
    }
  }

  // MARK: - Anchor side: manage co-guest user devices

  /// When the anchor taps a co-guest user video area, show the device-management sheet
  void _showSeatUserDeviceAlert({required SeatInfo seatInfo}) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = seatInfo.userInfo;
    if (userInfo.userID.isEmpty) {
      debugPrint('[CoGuest] _showSeatUserDeviceAlert: userID is empty, aborting.');
      return;
    }

    final userName = userInfo.userName.isEmpty ? userInfo.userID : userInfo.userName;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.coGuestManageTitle(userName),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),

              // Camera management
              if (userInfo.cameraStatus == DeviceStatus.on)
                ListTile(
                  title: Text(l10n.coGuestManageCloseCamera),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _liveSeatStore.closeRemoteCamera(userInfo.userID);
                  },
                )
              else
                ListTile(
                  title: Text(l10n.coGuestManageOpenCamera),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _liveSeatStore.openRemoteCamera(userID: userInfo.userID, policy: DeviceControlPolicy.unlockOnly);
                  },
                ),

              // Microphone management
              if (userInfo.microphoneStatus == DeviceStatus.on)
                ListTile(
                  title: Text(l10n.coGuestManageCloseMic),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _liveSeatStore.closeRemoteMicrophone(userInfo.userID);
                  },
                )
              else
                ListTile(
                  title: Text(l10n.coGuestManageOpenMic),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _liveSeatStore.openRemoteMicrophone(
                      userID: userInfo.userID,
                      policy: DeviceControlPolicy.unlockOnly,
                    );
                  },
                ),

              // Kick off the seat
              ListTile(
                title: Text(l10n.coGuestManageKickOff, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _liveSeatStore.kickUserOutOfSeat(userInfo.userID);
                },
              ),

              // Cancel
              ListTile(
                title: Text(l10n.commonCancel, textAlign: TextAlign.center),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  /// When the audience taps their own video area, show the local device-management sheet
  void _showSelfDeviceAlert() {
    final l10n = AppLocalizations.of(context)!;
    final deviceState = DeviceStore.shared.state;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.coGuestSelfManageTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),

              // Camera management
              if (deviceState.cameraStatus.value == DeviceStatus.on)
                ListTile(
                  title: Text(l10n.coGuestSelfManageCloseCamera),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    DeviceStore.shared.closeLocalCamera();
                  },
                )
              else
                ListTile(
                  title: Text(l10n.coGuestSelfManageOpenCamera),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    PermissionHelper.requestCameraPermission(
                      context,
                      onGranted: () {
                        DeviceStore.shared.openLocalCamera(true);
                      },
                    );
                  },
                ),

              // Microphone management
              if (deviceState.microphoneStatus.value == DeviceStatus.on)
                ListTile(
                  title: Text(l10n.coGuestSelfManageCloseMic),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    DeviceStore.shared.closeLocalMicrophone();
                  },
                )
              else
                ListTile(
                  title: Text(l10n.coGuestSelfManageOpenMic),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    PermissionHelper.requestMicrophonePermission(
                      context,
                      onGranted: () {
                        DeviceStore.shared.openLocalMicrophone();
                      },
                    );
                  },
                ),

              // 断开连线
              ListTile(
                title: Text(l10n.coGuestSelfManageDisconnect, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _disconnectCoGuest();
                },
              ),

              // Cancel
              ListTile(
                title: Text(l10n.commonCancel, textAlign: TextAlign.center),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  // MARK: - CoGuest state handling

  void _handleCoGuestStateUpdate() {
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (currentUserID == null || currentUserID.isEmpty) {
      debugPrint('[CoGuest] _handleCoGuestStateUpdate: loginUserInfo is null or userID is empty, skipping.');
      return;
    }

    // Check whether the current user is on the seat
    final wasOnSeat = _isOnSeat;
    final connectedUsers = _coGuestStore.coGuestState.connected.value;
    final isNowOnSeat = connectedUsers.any((u) => u.userID == currentUserID);

    if (isNowOnSeat && !wasOnSeat && widget.role == Role.audience) {
      // 观众刚上麦成功, 请求权限后open the camera和麦克风
      _isApplying = false;
      PermissionHelper.requestCameraAndMicrophonePermissions(
        context,
        onGranted: () {
          DeviceStore.shared.openLocalCamera(true);
          DeviceStore.shared.openLocalMicrophone();
        },
      );
    } else if (!isNowOnSeat && wasOnSeat && widget.role == Role.audience) {
      // 观众被Kick off the seat
      DeviceStore.shared.closeLocalCamera();
      DeviceStore.shared.closeLocalMicrophone();
    }

    setState(() {
      _isOnSeat = isNowOnSeat;
    });
  }

  // MARK: - seat state变化处理

  /// seat state更新 → 通知 CoGuestOverlayView 刷新音视频状态显示
  void _handleSeatStateUpdate() {
    // Collect the user IDs currently on the seats
    final activeUserIDs = <String>{};
    final seatList = _liveSeatStore.liveSeatState.seatList.value;

    for (final seatInfo in seatList) {
      if (seatInfo.userInfo.userID.isEmpty) continue;
      activeUserIDs.add(seatInfo.userInfo.userID);

      // Update the corresponding `CoGuestOverlayView` audio/video status
      _overlayStates[seatInfo.userInfo.userID]?.updateAVStatus(seatInfo);
    }

    // Clean up `overlayView` references for users who have left the seat
    _overlayStates.removeWhere((key, _) => !activeUserIDs.contains(key));
  }

  /// Show the device-request confirmation dialog (when the audience receives the anchor's request to open a device)
  void _showDeviceRequestAlert({required String title, required String message, required VoidCallback onAccept}) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonCancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onAccept();
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  /// Show a confirmation dialog when the anchor receives a co-guest application
  void _showApplicationAlert(LiveUserInfo guestUser) {
    final l10n = AppLocalizations.of(context)!;
    final name = guestUser.userName.isEmpty ? guestUser.userID : guestUser.userName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.coGuestApplicationTitle),
          content: Text(l10n.coGuestApplicationMessage(name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coGuestStore.rejectApplication(guestUser.userID);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.coGuestApplicationReject),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coGuestStore.acceptApplication(guestUser.userID);
              },
              child: Text(l10n.coGuestApplicationAccept),
            ),
          ],
        );
      },
    );
  }

  /// Show a confirmation dialog when the audience receives a co-guest invitation from the anchor
  void _showInvitationAlert(LiveUserInfo hostUser) {
    final l10n = AppLocalizations.of(context)!;
    final name = hostUser.userName.isEmpty ? hostUser.userID : hostUser.userName;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.coGuestInvitationTitle),
          content: Text(l10n.coGuestInvitationMessage(name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coGuestStore.rejectInvitation(hostUser.userID);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.coGuestInvitationReject),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _coGuestStore.acceptInvitation(hostUser.userID);
              },
              child: Text(l10n.coGuestInvitationAccept),
            ),
          ],
        );
      },
    );
  }

  // MARK: - State Handling

  void _handleLiveEnded(String liveID, LiveEndedReason reason, String message) {
    if (liveID == widget.liveID && widget.role == Role.audience) {
      if (!mounted) return;
      setState(() {
        _isLiveActive = false;
        _isOnSeat = false;
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
        _isOnSeat = false;
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

    // Disconnect the co-guest session first
    if (_isOnSeat) {
      _coGuestStore.disconnect();
    }

    switch (widget.role) {
      case Role.anchor:
        DeviceStore.shared.closeLocalCamera();
        DeviceStore.shared.closeLocalMicrophone();
        LiveListStore.shared.endLive();
        break;

      case Role.audience:
        if (_isOnSeat) {
          DeviceStore.shared.closeLocalCamera();
          DeviceStore.shared.closeLocalMicrophone();
        }
        LiveListStore.shared.leaveLive();
        break;
    }

    _isLiveActive = false;
    _isOnSeat = false;
    _overlayStates.clear();
  }

  // MARK: - Toast Helper

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// MARK: - AudienceListPanelView

/// audience list面板 - 展示在线观众, 主播端附带Host connection button
class _AudienceListPanelView extends StatefulWidget {
  final Role role;
  final LiveAudienceStore audienceStore;
  final CoGuestStore coGuestStore;
  final void Function(String userID)? onInvite;

  const _AudienceListPanelView({
    required this.role,
    required this.audienceStore,
    required this.coGuestStore,
    this.onInvite,
  });

  @override
  State<_AudienceListPanelView> createState() => _AudienceListPanelViewState();
}

class _AudienceListPanelViewState extends State<_AudienceListPanelView> {
  List<LiveUserInfo> _audienceList = [];
  Set<String> _connectedUserIDs = {};
  Set<String> _invitedUserIDs = {};

  late final VoidCallback _onAudienceListChanged;
  late final VoidCallback _onConnectedChanged;
  late final VoidCallback _onInviteesChanged;

  @override
  void initState() {
    super.initState();
    _setupBindings();
  }

  @override
  void dispose() {
    widget.audienceStore.liveAudienceState.audienceList.removeListener(_onAudienceListChanged);
    widget.coGuestStore.coGuestState.connected.removeListener(_onConnectedChanged);
    widget.coGuestStore.coGuestState.invitees.removeListener(_onInviteesChanged);
    super.dispose();
  }

  void _setupBindings() {
    // 订阅audience list变化(ValueListenable)
    _onAudienceListChanged = () {
      if (!mounted) return;
      setState(() {
        _audienceList = widget.audienceStore.liveAudienceState.audienceList.value;
      });
    };
    widget.audienceStore.liveAudienceState.audienceList.addListener(_onAudienceListChanged);

    // 订阅co-guest state变化(用于更新Host connection button状态)
    _onConnectedChanged = () {
      if (!mounted) return;
      setState(() {
        _connectedUserIDs = Set.from(widget.coGuestStore.coGuestState.connected.value.map((u) => u.userID));
      });
    };
    widget.coGuestStore.coGuestState.connected.addListener(_onConnectedChanged);

    _onInviteesChanged = () {
      if (!mounted) return;
      setState(() {
        _invitedUserIDs = Set.from(widget.coGuestStore.coGuestState.invitees.value.map((u) => u.userID));
      });
    };
    widget.coGuestStore.coGuestState.invitees.addListener(_onInviteesChanged);

    // Read the initial snapshot from `ValueNotifier` (`addListener` only listens for later changes and will not emit the current value)
    _audienceList = widget.audienceStore.liveAudienceState.audienceList.value;
    _connectedUserIDs = Set.from(widget.coGuestStore.coGuestState.connected.value.map((u) => u.userID));
    _invitedUserIDs = Set.from(widget.coGuestStore.coGuestState.invitees.value.map((u) => u.userID));

    // 刷新一次audience list
    widget.audienceStore.fetchAudienceList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_audienceList.isEmpty) {
      return Center(
        child: Text(l10n.coGuestAudienceListEmpty, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
      );
    }

    return ListView.builder(
      itemCount: _audienceList.length,
      itemExtent: 56,
      itemBuilder: (context, index) {
        final user = _audienceList[index];
        final isConnected = _connectedUserIDs.contains(user.userID);
        final isInvited = _invitedUserIDs.contains(user.userID);

        return _AudienceCell(
          user: user,
          showInviteButton: widget.role == Role.anchor,
          isConnected: isConnected,
          isInvited: isInvited,
          onInvite: (userID) {
            widget.onInvite?.call(userID);
          },
        );
      },
    );
  }
}

// MARK: - AudienceCell

/// Audience list cell - avatar + username + invite button (anchor side only)
class _AudienceCell extends StatelessWidget {
  final LiveUserInfo user;
  final bool showInviteButton;
  final bool isConnected;
  final bool isInvited;
  final void Function(String userID)? onInvite;

  const _AudienceCell({
    required this.user,
    required this.showInviteButton,
    required this.isConnected,
    required this.isInvited,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.hardEdge,
            child:
                user.avatarURL.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: user.avatarURL,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Center(
                            child: Text(
                              user.userID.isNotEmpty ? user.userID[0].toUpperCase() : '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      errorWidget:
                          (_, __, ___) => Center(
                            child: Text(
                              user.userID.isNotEmpty ? user.userID[0].toUpperCase() : '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                    )
                    : Center(
                      child: Text(
                        user.userID.isNotEmpty ? user.userID[0].toUpperCase() : '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
          ),

          const SizedBox(width: 12),

          // Username
          Expanded(
            child: Text(
              user.userName.isEmpty ? user.userID : user.userName,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Invite button (anchor side only)
          if (showInviteButton) _buildInviteButton(l10n),
        ],
      ),
    );
  }

  Widget _buildInviteButton(AppLocalizations l10n) {
    String title;
    Color backgroundColor;
    Color textColor;
    bool enabled;

    if (isConnected) {
      title = l10n.coGuestAudienceListConnected;
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey;
      enabled = false;
    } else if (isInvited) {
      title = l10n.coGuestAudienceListInviting;
      backgroundColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange;
      enabled = false;
    } else {
      title = l10n.coGuestAudienceListInvite;
      backgroundColor = Colors.blue.withValues(alpha: 0.15);
      textColor = Colors.blue;
      enabled = true;
    }

    return GestureDetector(
      onTap: enabled ? () => onInvite?.call(user.userID) : null,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
        ),
      ),
    );
  }
}

// MARK: - CoGuestOverlayView

/// 连线用户视频覆盖层 — Avatar(摄像头关闭时显示)+ 麦克风状态图标 + Bottom nickname label
class _CoGuestOverlayView extends StatefulWidget {
  final SeatInfo seatInfo;
  final void Function(SeatInfo)? onTap;
  final void Function(_CoGuestOverlayState)? onStateCreated;

  const _CoGuestOverlayView({required this.seatInfo, this.onTap, this.onStateCreated});

  @override
  State<_CoGuestOverlayView> createState() => _CoGuestOverlayState();
}

class _CoGuestOverlayState extends State<_CoGuestOverlayView> {
  late SeatInfo _seatInfo;

  @override
  void initState() {
    super.initState();
    _seatInfo = widget.seatInfo;
    widget.onStateCreated?.call(this);
  }

  @override
  void didUpdateWidget(covariant _CoGuestOverlayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `LiveCoreWidget` may pass in a new `seatInfo` when rebuilt; keep the data in sync
    if (widget.seatInfo.userInfo.userID != oldWidget.seatInfo.userInfo.userID) {
      _seatInfo = widget.seatInfo;
    }
  }

  /// Update the audio/video status display
  void updateAVStatus(SeatInfo updatedSeatInfo) {
    if (!mounted) return;
    setState(() {
      _seatInfo = updatedSeatInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = _seatInfo.userInfo;
    // If the current user information is unavailable (not logged in and similar cases), always show the nickname label (do not hide the local user name)
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    final showNameLabel = currentUserID == null || currentUserID.isEmpty || userInfo.userID != currentUserID;
    final isCameraOff = userInfo.cameraStatus != DeviceStatus.on;
    final isMicOff = userInfo.microphoneStatus != DeviceStatus.on;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap?.call(_seatInfo),
      child: Stack(
        children: [
          // Avatar容器(摄像头关闭时显示)
          if (isCameraOff)
            Positioned.fill(
              child: Container(
                color: Colors.grey[800],
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(30)),
                    clipBehavior: Clip.hardEdge,
                    child:
                        userInfo.avatarURL.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: userInfo.avatarURL,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => Center(
                                    child: Text(
                                      userInfo.userID.isNotEmpty ? userInfo.userID[0].toUpperCase() : '',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => Center(
                                    child: Text(
                                      userInfo.userID.isNotEmpty ? userInfo.userID[0].toUpperCase() : '',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            )
                            : Center(
                              child: Text(
                                userInfo.userID.isNotEmpty ? userInfo.userID[0].toUpperCase() : '',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                  ),
                ),
              ),
            ),

          // Microphone status icon (top-right corner)
          Positioned(
            top: 4,
            right: 4,
            child: Icon(isMicOff ? Icons.mic_off : Icons.mic, size: 18, color: isMicOff ? Colors.red : Colors.white),
          ),

          // Bottom nickname label
          if (showNameLabel)
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    userInfo.userName.isEmpty ? userInfo.userID : userInfo.userName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
