/// 主播点击已连麦观众席位后展示的设备与下麦管理面板。
library;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../../../../common/live_kit_resources.dart';
import '../../../../common/theme/bottom_sheet_view.dart';
import '../../../../common/theme/live_text.dart';
import '../../../../common/theme/live_theme.dart';
import '../pusher_coguest_store.dart';

class PusherCoGuestAudienceManageView extends StatefulWidget {
  const PusherCoGuestAudienceManageView({
    super.key,
    required this.userID,
    required this.state,
    this.onDismiss,
    required this.actionHandler,
  });

  final String userID;
  final PusherCoGuestState state;
  final VoidCallback? onDismiss;
  final PusherCoGuestActionHandling actionHandler;

  @override
  State<PusherCoGuestAudienceManageView> createState() => _PusherCoGuestAudienceManageViewState();
}

class _PusherCoGuestAudienceManageViewState extends State<PusherCoGuestAudienceManageView> {
  static const double _minimumSheetHeight = 162;
  static const double _contentHeight = 148;

  final BottomSheetController _sheetController = BottomSheetController();
  bool _isAwaitingActionCompletion = false;
  bool _didObservePendingAction = false;
  int _actionID = 0;
  bool _isDismissing = false;

  @override
  void didUpdateWidget(PusherCoGuestAudienceManageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final PusherCoGuestUser? user = _selectedUser;
    if (user == null) {
      _dismiss();
      return;
    }
    final bool isPending = widget.state.pendingUserIDs.contains(widget.userID);
    if (_isAwaitingActionCompletion) {
      _didObservePendingAction = _didObservePendingAction || isPending;
      if (_didObservePendingAction && !isPending) {
        _dismiss();
      }
    }
  }

  PusherCoGuestUser? get _selectedUser {
    for (final PusherCoGuestUser user in widget.state.connected) {
      if (user.userID == widget.userID) {
        return user;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final PusherCoGuestUser? user = _selectedUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final double sheetHeight = (_contentHeight + bottomInset).clamp(_minimumSheetHeight, double.infinity);
    final bool isPending = widget.state.pendingUserIDs.contains(widget.userID);

    return BottomSheetView(
      controller: _sheetController,
      sheetHeight: sheetHeight,
      onDismiss: () => widget.onDismiss?.call(),
      onWillDismiss: () {
        _isDismissing = true;
        _actionID++;
        _isAwaitingActionCompletion = false;
        _didObservePendingAction = false;
      },
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 20,
            right: 20,
            top: 27,
            height: 22,
            child: LiveText(
              LiveTextRole.dialogTitle,
              text: LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.manage_user', user.userName),
              alignment: TextAlign.center,
              lineHeight: 22,
            ),
          ),
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                  child: SizedBox(
                width: 200,
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                        child: _AudienceAction(
                      title: (user.allowOpenMicrophone && user.microphoneStatus == DeviceStatus.on)
                          ? LiveKitResources.localizedString('tuilivekit.pusher.coguest.mute_user')
                          : LiveKitResources.localizedString('tuilivekit.pusher.coguest.unmute_user'),
                      assetName: (user.allowOpenMicrophone && user.microphoneStatus == DeviceStatus.on)
                          ? 'livekit_coguest_action_mic'
                          : 'livekit_coguest_action_mic_off',
                      titleColor: _PusherCoGuestManageStyle.deviceForeground,
                      isPending: isPending,
                      onTap: () => _perform(widget.actionHandler.toggleRemoteMicrophone),
                    )),
                    const SizedBox(width: 40),
                    Expanded(
                        child: _AudienceAction(
                      title: LiveKitResources.localizedString('tuilivekit.pusher.coguest.disconnect_user'),
                      assetName: 'livekit_coguest_action_disconnect',
                      titleColor: _PusherCoGuestManageStyle.disconnectForeground,
                      isPending: isPending,
                      onTap: () => _perform(widget.actionHandler.disconnect),
                    )),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _perform(Future<void> Function(String) action) async {
    if (_isDismissing || _isAwaitingActionCompletion || widget.state.pendingUserIDs.contains(widget.userID)) {
      return;
    }
    _isAwaitingActionCompletion = true;
    _didObservePendingAction = false;
    final int actionID = ++_actionID;
    final operation = action(widget.userID);
    _didObservePendingAction = _didObservePendingAction || widget.state.pendingUserIDs.contains(widget.userID);
    await operation;
    if (mounted && actionID == _actionID) {
      if (_didObservePendingAction) {
        await _dismiss();
      } else {
        _isAwaitingActionCompletion = false;
      }
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sheetController.dismiss();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

class _AudienceAction extends StatelessWidget {
  const _AudienceAction({
    required this.title,
    required this.assetName,
    required this.titleColor,
    required this.isPending,
    required this.onTap,
  });

  final String title;
  final String assetName;
  final Color titleColor;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: isPending ? 0.46 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isPending ? null : onTap,
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Column(
            children: <Widget>[
              Image(
                width: 44,
                height: 44,
                image: LiveKitResources.image(assetName),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 16,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: LiveTheme.textStyle(LiveTextRole.control, lineHeight: 16).copyWith(color: titleColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _PusherCoGuestManageStyle {
  static const deviceForeground = Color(0xBFFFFFFF);
  static const disconnectForeground = Color(0xFFFF9095);
}
