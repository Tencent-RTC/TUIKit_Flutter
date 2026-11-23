import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';
import 'live_stats_bar.dart';
import '../../common/widget/hover_clickable.dart';
import '../basic_control/stream_orientation_switch.dart';
import '../../common/widget/overflow_tooltip_text.dart';
import '../../common/widget/toast.dart';

class PusherLiveInfoBar extends StatelessWidget {
  const PusherLiveInfoBar({
    super.key,
    required this.isLiveStarted,
    required this.liveName,
    required this.avatarUrl,
    required this.hostName,
    required this.liveID,
    required this.liveStartTime,
    required this.onEditLiveInfo,
  });

  final ValueListenable<bool> isLiveStarted;

  final ValueListenable<DateTime?> liveStartTime;

  final ValueListenable<String> liveName;

  final String avatarUrl;

  final String hostName;

  final String liveID;

  final VoidCallback onEditLiveInfo;

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return PusherAmbientPanel(
      radius: 8,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gradient: LiveKitStyle.ambientFlatGradient,
      child: Row(
        children: [
          _HostAvatar(avatarUrl: avatarUrl, hostName: hostName),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 146),
            child: ValueListenableBuilder<String>(
              valueListenable: liveName,
              builder: (context, name, _) => _LiveName(name: name),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<bool>(
            valueListenable: isLiveStarted,
            builder: (context, started, _) => started
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _ToolbarIconButton(
                      icon: RemixIcons.share_forward_line,
                      tooltip: strings.liveShareTooltip,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: liveID));
                        showToast(context, strings.liveShareCopied);
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _ToolbarIconButton(
            icon: RemixIcons.edit_2_line,
            tooltip: strings.liveInfoEditTitle,
            onTap: onEditLiveInfo,
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: isLiveStarted,
            builder:
                (context, started, _) =>
                    started
                        ? LiveStatsBar(
                          liveID: liveID,
                          liveStartTime: liveStartTime,
                        )
                        : const StreamOrientationSwitch(enabled: true),
          ),
        ],
      ),
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({required this.avatarUrl, required this.hostName});

  final String avatarUrl;
  final String hostName;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = hostName.isNotEmpty ? hostName.characters.first : '?';
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [LiveKitStyle.brand, LiveKitStyle.brand2],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LiveKitStyle.whitePure,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatefulWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: HoverClickable(
        onHover: (hovering) => setState(() => _hovering = hovering),
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? LiveKitStyle.white10 : LiveKitStyle.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 12,
            color: _hovering ? LiveKitStyle.titleStrong : LiveKitStyle.text3,
          ),
        ),
      ),
    );
  }
}

class _LiveName extends StatelessWidget {
  const _LiveName({required this.name});

  final String name;

  static const _style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: LiveKitStyle.textEmphasis,
    height: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return OverflowTooltipText(name, style: _style);
  }
}
