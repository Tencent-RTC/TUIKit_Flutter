import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/role.dart';
import 'package:atomic_x_core_example/components/setting_panel_controller.dart';
import 'package:atomic_x_core_example/components/device_setting_widget.dart';
import 'package:atomic_x_core_example/components/permission_helper.dart';

/// Business scenario: basic live streaming page
///
/// APIs involved:
/// - `LiveListStore.shared.createLive(_:completion:)` - anchor creates a live stream
/// - `LiveListStore.shared.joinLive(liveID:completion:)` - audience joins a live stream
/// - `LiveListStore.shared.endLive(completion:)` - anchor ends the live stream
/// - `LiveListStore.shared.leaveLive(completion:)` - audience leaves the live stream
/// - `LiveListStore.shared.liveListEventPublisher` - listens for live events (`LiveListEvent`)
/// - `DeviceStore.shared.openLocalCamera(isFront:completion:)` - opens the camera
/// - `DeviceStore.shared.openLocalMicrophone(completion:)` - opens the microphone
/// - `DeviceStore.shared.closeLocalCamera()` - closes the camera
/// - `DeviceStore.shared.closeLocalMicrophone()` - closes the microphone
/// - `LiveCoreView(viewType:)` - video rendering widget (`pushView` / `playView`)
///
/// Different operations are provided based on the role:
/// - Anchor: enter the page → open camera/microphone → tap "Start Live" → the navigation bar shows an "End Live" button while live
/// - Audience: enter the page → automatically join the room → return on join failure → show the playback view on success → leave through the navigation back button
class BasicStreamingPage extends StatefulWidget {
  // MARK: - Properties

  final Role role;
  final String liveID;

  // MARK: - Init

  const BasicStreamingPage({super.key, required this.role, required this.liveID});

  @override
  State<BasicStreamingPage> createState() => _BasicStreamingPageState();
}

class _BasicStreamingPageState extends State<BasicStreamingPage> {
  // MARK: - Properties

  /// Whether the page is currently in the live state
  bool _isLiveActive = false;

  late final LiveCoreController _liveCoreController;
  late final LiveListListener _liveListListener;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureForRole();
    });
  }

  @override
  void dispose() {
    LiveListStore.shared.removeLiveListListener(_liveListListener);
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
          leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: _handleBackPressed),
          actions: _buildNavigationBarActions(l10n),
        ),
        body: Stack(
          children: [
            // Full-screen video rendering area
            Positioned.fill(child: LiveCoreWidget(controller: _liveCoreController)),

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

      // Device settings button
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
    // Join the live room automatically after entering the page
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
      // If already live, end the live stream first and then go back
      _endLiveAndGoBack();
    } else {
      // If not live yet, close devices and go back
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

  /// Open the device settings panel
  void _settingsTapped() {
    final l10n = AppLocalizations.of(context)!;
    showSettingPanel(context: context, title: l10n.deviceSettingTitle, contentWidget: const DeviceSettingWidget());
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
      // Join failed, so go back to the previous page
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

  // MARK: - State Handling

  void _handleLiveEnded(String liveID, LiveEndedReason reason, String message) {
    // The live stream was ended by the anchor (audience side receives the notification)
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
    // The user was kicked out of the live room
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
