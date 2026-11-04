import 'package:flutter/widgets.dart';

import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import '../../settings/pusher_settings_item_view.dart';
import 'pusher_audience_store.dart';

class PusherAudienceManageView extends StatefulWidget {
  const PusherAudienceManageView({
    super.key,
    required this.user,
    required this.state,
    required this.onDismiss,
    required this.onToggleFollow,
    required this.onToggleMessagePermission,
    required this.onRemoveFromRoom,
  });

  final AudienceUser user;
  final AudienceState state;
  final VoidCallback onDismiss;
  final void Function(String userID) onToggleFollow;
  final void Function(String userID) onToggleMessagePermission;
  final void Function(String userID) onRemoveFromRoom;

  static const double contentHeight = 191;

  @override
  State<PusherAudienceManageView> createState() => PusherAudienceManageViewState();
}

class PusherAudienceManageViewState extends State<PusherAudienceManageView> {
  final BottomSheetController _sheetController = BottomSheetController();

  void dismiss() => _sheetController.dismiss();

  void completeAction(String userID, AudienceAction action, bool succeeded) {
    if (userID != widget.user.userID || !succeeded) return;
    if (action == AudienceAction.mute || action == AudienceAction.unmute || action == AudienceAction.remove) {
      _sheetController.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final state = widget.state;
    final followStatus = state.followStatus(user.userID);
    final pendingAction = state.pendingActionByUserID[user.userID];
    final isPending = pendingAction != null;
    final isMuted = state.mutedUserIDs.contains(user.userID);
    final actions = [
      (
        title: followStatus == AudienceFollowStatus.following ? 'following' : 'follow',
        asset: followStatus == AudienceFollowStatus.following
            ? 'livekit_pusher_audience_followed'
            : 'livekit_pusher_audience_follow',
        size: const Size.square(22),
        enabled: !isPending && followStatus != AudienceFollowStatus.unknown,
        pending: pendingAction == AudienceAction.follow || pendingAction == AudienceAction.unfollow,
        perform: widget.onToggleFollow,
      ),
      (
        title: isMuted ? 'unmute' : 'mute',
        asset: 'livekit_pusher_audience_mute',
        size: const Size.square(22),
        enabled: !isPending,
        pending: pendingAction == AudienceAction.mute || pendingAction == AudienceAction.unmute,
        perform: widget.onToggleMessagePermission,
      ),
      (
        title: 'remove',
        asset: 'livekit_pusher_audience_remove',
        size: const Size.square(21),
        enabled: !isPending,
        pending: pendingAction == AudienceAction.remove,
        perform: widget.onRemoveFromRoom,
      ),
    ];
    return BottomSheetView(
      controller: _sheetController,
      sheetHeight: PusherAudienceManageView.contentHeight + MediaQuery.viewPaddingOf(context).bottom,
      sheetTitle: user.userName.isEmpty ? user.userID : user.userName,
      onDismiss: widget.onDismiss,
      child: Stack(children: [
        Positioned(
            left: 16,
            right: 16,
            top: 75,
            height: 84,
            child: Row(children: [
              for (final action in actions)
                Expanded(
                    child: Opacity(
                        opacity: action.pending ? 0.46 : 1,
                        child: PusherSettingsItemView(
                          title: LiveKitResources.localizedString('tuilivekit.pusher.audience.${action.title}'),
                          assetName: action.asset,
                          iconSize: action.size,
                          onPressed: action.enabled ? () => action.perform(user.userID) : null,
                        ))),
            ])),
      ]),
    );
  }
}
