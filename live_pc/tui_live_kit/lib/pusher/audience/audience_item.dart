import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';

class AudienceItem extends StatelessWidget {
  final LiveUserInfo userInfo;
  final bool isAudienceMuted;
  final VoidCallback onDisableSendMessage;
  final VoidCallback onKickUserOutOfRoom;

  const AudienceItem({
    super.key,
    required this.userInfo,
    required this.isAudienceMuted,
    required this.onDisableSendMessage,
    required this.onKickUserOutOfRoom,
  });

  String get _displayName =>
      userInfo.userName.isNotEmpty ? userInfo.userName : userInfo.userID;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAudienceMuted ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: PusherStyle.white5,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PusherStyle.white8),
        ),
        child: Row(
          children: [
            _AudienceAvatar(
              audienceAvatarUrl: userInfo.avatarURL,
              audienceName: _displayName,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PusherStyle.textPrimary,
                      ),
                    ),
                  ),
                  if (isAudienceMuted) ...[
                    const SizedBox(width: 4),
                    const _MutedBadge(),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LevelBadge(level: userInfo.level),
            const SizedBox(width: 4),
            _AudienceActionButton(
              isAudienceMuted: isAudienceMuted,
              onDisableSendMessage: onDisableSendMessage,
              onKickUserOutOfRoom: onKickUserOutOfRoom,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceAvatar extends StatelessWidget {
  final String audienceAvatarUrl;
  final String audienceName;

  const _AudienceAvatar({
    required this.audienceAvatarUrl,
    required this.audienceName,
  });

  @override
  Widget build(BuildContext context) {
    if (audienceAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          audienceAvatarUrl,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackAvatar(),
        ),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final initial = audienceName.isNotEmpty ? audienceName.characters.first : '?';
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [PusherStyle.brand, PusherStyle.brand2],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: PusherStyle.whitePure,
        ),
      ),
    );
  }
}

class _MutedBadge extends StatelessWidget {
  const _MutedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: PusherStyle.brand2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        LiveKitLocalizations.of(context).audienceMutedTag,
        style: const TextStyle(fontSize: 9, color: PusherStyle.brand2),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: PusherStyle.brand2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'Lv.$level',
        style: const TextStyle(fontSize: 9, color: PusherStyle.brand2),
      ),
    );
  }
}

class _AudienceActionButton extends StatefulWidget {
  final bool isAudienceMuted;
  final VoidCallback onDisableSendMessage;
  final VoidCallback onKickUserOutOfRoom;

  const _AudienceActionButton({
    required this.isAudienceMuted,
    required this.onDisableSendMessage,
    required this.onKickUserOutOfRoom,
  });

  @override
  State<_AudienceActionButton> createState() => _AudienceActionButtonState();
}

class _AudienceActionButtonState extends State<_AudienceActionButton> {
  bool _hovering = false;

  Future<void> _showActionMenu() async {
    final anchor = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final bottomLeft = anchor.localToGlobal(
      anchor.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final overlaySize = overlay.size;
    final loc = LiveKitLocalizations.of(context);

    final action = await showMenu<String>(
      context: context,
      color: PusherStyle.menuBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: PusherStyle.white10),
      ),
      position: RelativeRect.fromLTRB(
        bottomLeft.dx,
        bottomLeft.dy + 4,
        overlaySize.width - bottomLeft.dx,
        overlaySize.height - bottomLeft.dy,
      ),
      items: [
        _buildActionMenuItem(
          'mute',
          RemixIcons.forbid_line,
          widget.isAudienceMuted ? loc.audienceUnmute : loc.audienceMute,
        ),
        _buildActionMenuItem(
          'kick',
          RemixIcons.logout_box_line,
          loc.audienceKick,
          isDanger: true,
        ),
      ],
    );

    if (action == 'mute') {
      widget.onDisableSendMessage();
    } else if (action == 'kick') {
      widget.onKickUserOutOfRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _showActionMenu,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? PusherStyle.white10 : PusherStyle.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            RemixIcons.more_line,
            size: 12,
            color: _hovering
                ? PusherStyle.textSecondary
                : PusherStyle.textTertiary,
          ),
        ),
      ),
    );
  }
}

PopupMenuItem<String> _buildActionMenuItem(
  String value,
  IconData icon,
  String label, {
  bool isDanger = false,
}) {
  final color = isDanger ? PusherStyle.danger : PusherStyle.textPrimary;
  return PopupMenuItem<String>(
    value: value,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    ),
  );
}
