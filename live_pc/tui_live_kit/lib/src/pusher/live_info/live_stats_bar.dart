import 'dart:async';
import 'dart:ui' as ui;

import 'package:atomic_x_core/api/live/live_summary_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';

class LiveStatsBar extends StatelessWidget {
  const LiveStatsBar({
    super.key,
    required this.liveID,
    required this.liveStartTime,
  });

  final String liveID;
  final ValueListenable<DateTime?> liveStartTime;

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
        ValueListenableBuilder<DateTime?>(
          valueListenable: liveStartTime,
          builder: (context, startTime, _) => _LiveDurationItem(startTime: startTime),
        ),
        const SizedBox(width: 12),
        Container(width: 1, height: 12, color: LiveKitStyle.white15),
        const SizedBox(width: 12),
        _StatsItem(
          icon: RemixIcons.thumb_up_fill,
          iconColor: LiveKitStyle.brand2,
          text: _abbreviateCount(likes),
        ),
        const SizedBox(width: 12),
        _StatsItem(
          icon: RemixIcons.gift_2_fill,
          iconColor: LiveKitStyle.gold,
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
      builder:
          (context, data, _) => _buildContent(
            context,
            data.totalLikesReceived,
            data.totalGiftUniqueSenders,
          ),
    );
  }
}

class _LiveDurationItem extends StatefulWidget {
  const _LiveDurationItem({required this.startTime});

  final DateTime? startTime;

  @override
  State<_LiveDurationItem> createState() => _LiveDurationItemState();
}

class _LiveDurationItemState extends State<_LiveDurationItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _LiveDurationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) _syncTimer();
  }

  void _syncTimer() {
    if (widget.startTime == null) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startTime;
    final text =
        start == null
            ? '00:00:00'
            : _formatDuration(DateTime.now().difference(start));
    return _StatsItem(
      icon: RemixIcons.alarm_fill,
      iconColor: LiveKitStyle.barrageSenderGreen,
      text: text,
    );
  }
}

class _StatsItem extends StatelessWidget {
  const _StatsItem({
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
            color: LiveKitStyle.textPrimary,
            fontSize: 12,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
