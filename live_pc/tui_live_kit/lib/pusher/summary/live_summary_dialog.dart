import 'dart:ui' as ui;

import 'package:atomic_x_core/api/live/live_summary_store.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';

class LiveSummaryDialog extends StatelessWidget {
  const LiveSummaryDialog({
    super.key,
    required this.summary,
    required this.durationSec,
  });
  
  final LiveSummaryData? summary;
  
  final int durationSec;

  /// 秒 → HH:MM:SS。
  static String _fmtDuration(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LiveKitLocalizations.of(context);
    final data = summary;

    final cells = <Widget>[
      _SummaryCell(
        icon: RemixIcons.time_line,
        iconColor: PusherStyle.iconMuted,
        value: _fmtDuration(durationSec),
        label: l10n.liveSummaryDuration,
      ),
      _SummaryCell(
        icon: RemixIcons.eye_line,
        iconColor: PusherStyle.textPrimary,
        value: '${data?.totalViewers ?? 0}',
        label: l10n.liveSummaryViewers,
      ),
      _SummaryCell(
        icon: RemixIcons.thumb_up_fill,
        iconColor: PusherStyle.brand2,
        value: '${data?.totalLikesReceived ?? 0}',
        label: l10n.liveSummaryLikes,
      ),
      _SummaryCell(
        icon: RemixIcons.gift_2_fill,
        iconColor: PusherStyle.gold,
        value: '${data?.totalGiftUniqueSenders ?? 0}',
        label: l10n.liveSummaryGiftSenders,
      ),
    ];

    return Center(
      child: Container(
        width: 420,
        decoration: PusherStyle.dialogPanel(radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          RemixIcons.bar_chart_2_line,
                          color: PusherStyle.iconMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.liveSummaryTitle,
                          style: const TextStyle(
                            color: PusherStyle.textEmphasis,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    _SummaryCloseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Text(
                  l10n.liveSummarySubtitle,
                  style: const TextStyle(
                    color: PusherStyle.textHint,
                    fontSize: 10,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 190 / 64,
                  children: cells,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _SummaryDoneButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PusherStyle.softPanel(radius: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: PusherStyle.textEmphasis,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: PusherStyle.textHint,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCloseButton extends StatefulWidget {
  const _SummaryCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SummaryCloseButton> createState() => _SummaryCloseButtonState();
}

class _SummaryCloseButtonState extends State<_SummaryCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _hovered ? PusherStyle.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            RemixIcons.close_line,
            size: 14,
            color: PusherStyle.textHint,
          ),
        ),
      ),
    );
  }
}

class _SummaryDoneButton extends StatefulWidget {
  const _SummaryDoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SummaryDoneButton> createState() => _SummaryDoneButtonState();
}

class _SummaryDoneButtonState extends State<_SummaryDoneButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = LiveKitLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? PusherStyle.whitePure : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            l10n.liveSummaryDone,
            style: const TextStyle(
              color: Color(0xFF1F2128),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
