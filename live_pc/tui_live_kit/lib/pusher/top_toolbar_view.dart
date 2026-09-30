import 'dart:ui' as ui;

import 'package:atomic_x_core/api/live/live_summary_store.dart';
import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../l10n/live_kit_localizations.dart';
import 'util/encoder_params_util.dart';
import 'pusher_style.dart';
class PusherTopToolbarView extends StatelessWidget {
  const PusherTopToolbarView({
    super.key,
    required this.isLiveStarted,
    required this.liveName,
    required this.avatarUrl,
    required this.hostName,
    required this.liveID,
    required this.onEditLiveInfo,
  });

  final ValueListenable<bool> isLiveStarted;

  /// 直播间名称（实时展示）。
  final ValueListenable<String> liveName;

  /// 主播头像地址（空则回退昵称首字）。
  final String avatarUrl;

  /// 主播昵称（头像回退时取首字）。
  final String hostName;

  /// 直播间 ID
  final String liveID;

  /// 打开「修改直播间信息」弹窗。
  final VoidCallback onEditLiveInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: PusherStyle.glassPanel(radius: 12),
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
          GestureDetector(
            onTap: onEditLiveInfo,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(
                  RemixIcons.edit_2_line,
                  size: 12,
                  color: PusherStyle.textHint,
                ),
              ),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: isLiveStarted,
            builder: (context, started, _) => started
                ? _LiveSummaryBar(liveID: liveID)
                : const _OrientationSwitch(enabled: true),
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
          colors: [PusherStyle.brand, PusherStyle.brand2],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: PusherStyle.whitePure,
        ),
      ),
    );
  }
}

class _LiveName extends StatefulWidget {
  const _LiveName({required this.name});

  final String name;

  @override
  State<_LiveName> createState() => _LiveNameState();
}

class _LiveNameState extends State<_LiveName> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  static const _style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: PusherStyle.textEmphasis,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.name, style: _style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final text = Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _style,
        );

        if (!painter.didExceedMaxLines) {
          return text;
        }
        return MouseRegion(
          onEnter: (_) => _tooltipKey.currentState?.ensureTooltipVisible(),
          onExit: (_) => Tooltip.dismissAllToolTips(),
          child: Tooltip(
            key: _tooltipKey,
            message: widget.name,
            triggerMode: TooltipTriggerMode.manual,
            showDuration: const Duration(seconds: 10),
            child: text,
          ),
        );
      },
    );
  }
}

/// 横竖屏模式切换：直接读写引擎 MediaMixingState.params。
/// [enabled] 为 false（开播中）时整体禁用并降透明度。
class _OrientationSwitch extends StatelessWidget {
  const _OrientationSwitch({this.enabled = true});

  final bool enabled;

  void _setOrientation(bool landscape) {
    EncoderParamsUtil.switchOrientation(landscape);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaMixingParams>(
      valueListenable: MediaMixingStore.shared.state.params,
      builder: (context, params, _) {
        final isLandscape = params.videoEncoderParams.resolutionMode ==
            VideoResolutionMode.landscape;
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: PusherStyle.softPanel(radius: 6),
            child: Row(
              children: [
                _ModeChip(
                  icon: RemixIcons.tv_2_line,
                  label: LiveKitLocalizations.of(context).orientationLandscape,
                  active: isLandscape,
                  enabled: enabled,
                  onTap: () => _setOrientation(true),
                ),
                _ModeChip(
                  icon: RemixIcons.smartphone_line,
                  label: LiveKitLocalizations.of(context).orientationPortrait,
                  active: !isLandscape,
                  enabled: enabled,
                  onTap: () => _setOrientation(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? PusherStyle.white15 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? Colors.white : PusherStyle.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : PusherStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSummaryBar extends StatelessWidget {
  const _LiveSummaryBar({required this.liveID});

  final String liveID;

  static String _abbreviateCount(int n) {
    if (n >= 10000) {
      final double w = n / 10000.0;
      final String s = w.toStringAsFixed(1);
      return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}w';
    }
    return '$n';
  }

  Widget _buildContent(BuildContext context, int likes, int giftSenders) {
    final l10n = LiveKitLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SummaryItem(
          icon: RemixIcons.thumb_up_fill,
          iconColor: PusherStyle.brand2,
          text: _abbreviateCount(likes),
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          icon: RemixIcons.gift_2_fill,
          iconColor: PusherStyle.gold,
          text: l10n.liveStatsGiftSenders(_abbreviateCount(giftSenders)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    LiveSummaryStore? store;
    if (liveID.isNotEmpty) {
      try {
        store = LiveSummaryStore.create(liveID);
      } catch (_) {
        store = null;
      }
    }

    if (store == null) {
      return _buildContent(context, 0, 0);
    }

    return ValueListenableBuilder<LiveSummaryData>(
      valueListenable: store.liveSummaryState.summaryData,
      builder: (context, data, _) => _buildContent(
        context,
        data.totalLikesReceived,
        data.totalGiftUniqueSenders,
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: PusherStyle.textPrimary,
            fontSize: 12,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
