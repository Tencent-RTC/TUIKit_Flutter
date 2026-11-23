
import 'dart:ui' as ui;

import 'package:atomic_x_core/api/live/live_summary_store.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';
import '../../common/widget/panel_dialog.dart';

class LiveSummaryDialog extends StatelessWidget {
  const LiveSummaryDialog({
    super.key,
    required this.summary,
    required this.durationSec,
  });

  final LiveSummaryData? summary;

  final int durationSec;

  static String _fmtDuration(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LiveKitLocalizations.of(context);
    final data = summary;

    return Center(
      child: Container(
        width: 420,
        decoration: LiveKitStyle.dialogPanel(radius: 8),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelDialogHeader(
                icon: RemixIcons.bar_chart_2_line,
                title: l10n.liveSummaryTitle,
                iconSize: 16,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 12),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DurationRow(
                      label: l10n.liveSummaryDuration,
                      value: _fmtDuration(durationSec),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.gold,
                            label: l10n.liveSummaryGiftsSent,
                            value: '${data?.totalGiftsSent ?? 0}',
                            unit: l10n.liveSummaryUnitPiece,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.brand,
                            label: l10n.liveSummaryGiftIncome,
                            value: '${data?.totalGiftCoins ?? 0}',
                            unit: l10n.liveSummaryUnitCoin,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.teal,
                            label: l10n.liveSummaryGiftSenders,
                            value: '${data?.totalGiftUniqueSenders ?? 0}',
                            unit: l10n.liveSummaryUnitPerson,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.info,
                            label: l10n.liveSummaryViewers,
                            value: '${data?.totalViewers ?? 0}',
                            unit: l10n.liveSummaryUnitPerson,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.amb2,
                            label: l10n.liveSummaryMessages,
                            value: '${data?.totalMessageSent ?? 0}',
                            unit: l10n.liveSummaryUnitMessage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            accent: LiveKitStyle.danger,
                            label: l10n.liveSummaryLikes,
                            value: '${data?.totalLikesReceived ?? 0}',
                            unit: l10n.liveSummaryUnitTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _SummaryDoneButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: LiveKitStyle.glassPanelSoft(radius: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: LiveKitStyle.text3, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: LiveKitStyle.textEmphasis,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.accent,
    required this.label,
    required this.value,
    required this.unit,
  });

  final Color accent;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: LiveKitStyle.glassPanelSoft(radius: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: LiveKitStyle.text3, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: LiveKitStyle.textEmphasis,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [ui.FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(color: LiveKitStyle.text3, fontSize: 9),
              ),
            ],
          ),
        ],
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
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.9 : 1,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: LiveKitStyle.brand,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.liveSummaryDone,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
