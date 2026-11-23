import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../l10n/live_kit_localizations.dart';
import '../../../../common/style/live_kit_style.dart';
import '../../../../common/widget/hover_clickable.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';

typedef SourceTypeCardData = ({MediaSourceKind kind, IconData icon, String name, String desc});

List<SourceTypeCardData> sourceTypeCards(LiveKitLocalizations strings) => [
  (
    kind: MediaSourceKind.camera,
    icon: RemixIcons.webcam_line,
    name: strings.sourceTypeCamera,
    desc: strings.sourceTypeCameraDesc,
  ),
  (
    kind: MediaSourceKind.screen,
    icon: RemixIcons.computer_line,
    name: strings.sourceTypeScreen,
    desc: strings.sourceTypeScreenDesc,
  ),
  (
    kind: MediaSourceKind.image,
    icon: RemixIcons.image_line,
    name: strings.sourceTypeImage,
    desc: strings.sourceTypeImageDesc,
  ),
  (
    kind: MediaSourceKind.onlineVideo,
    icon: RemixIcons.global_line,
    name: strings.sourceTypeOnlineVideo,
    desc: strings.sourceTypeOnlineVideoDesc,
  ),
  (
    kind: MediaSourceKind.videoFile,
    icon: RemixIcons.file_video_line,
    name: strings.sourceTypeVideoFile,
    desc: strings.sourceTypeVideoFileDesc,
  ),
];

Color sourceTypeAccent(MediaSourceKind kind) => switch (kind) {
  MediaSourceKind.camera => LiveKitStyle.srcCamera,
  MediaSourceKind.screen => LiveKitStyle.srcScreen,
  MediaSourceKind.image => LiveKitStyle.srcImage,
  MediaSourceKind.onlineVideo => LiveKitStyle.srcOnline,
  MediaSourceKind.videoFile => LiveKitStyle.srcFile,
};

enum SourceTypeCardVariant { dialog, guide }

class SourceTypeCardGrid extends StatelessWidget {
  const SourceTypeCardGrid({
    super.key,
    required this.cards,
    required this.onTap,
    this.variant = SourceTypeCardVariant.dialog,
    this.portrait = false,
    this.cardWrapper,
  });

  final List<SourceTypeCardData> cards;

  final void Function(SourceTypeCardData data) onTap;
  final SourceTypeCardVariant variant;

  final bool portrait;

  final Widget Function(int index, Widget card)? cardWrapper;

  @override
  Widget build(BuildContext context) {
    final guide = variant == SourceTypeCardVariant.guide;
    final compact = guide && portrait;
    final perRow = guide && !portrait ? 5 : 3;
    final spacing = compact ? 10.0 : 12.0;
    final maxCardWidth = guide ? (compact ? 130.0 : 188.0) : 150.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Floor to whole pixels: a fractional division result can round up
        // in binary floating point, making perRow*cardWidth + spacings exceed
        // the constraint by ~1e-13 and trip RenderFlex's overflow warning;
        // integer widths also keep 1px borders pixel-sharp.
        final cardWidth = math.min(
          maxCardWidth,
          ((constraints.maxWidth - spacing * (perRow - 1)) / perRow).floorToDouble(),
        );
        final rows = <Widget>[];
        for (var start = 0; start < cards.length; start += perRow) {
          final end = math.min(start + perRow, cards.length);
          rows.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start; i < end; i++) ...[
                  if (i > start) SizedBox(width: spacing),
                  Flexible(child: _buildCard(i, cardWidth, compact)),
                ],
              ],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var r = 0; r < rows.length; r++) ...[if (r > 0) SizedBox(height: spacing), rows[r]],
          ],
        );
      },
    );
  }

  Widget _buildCard(int index, double width, bool compact) {
    final data = cards[index];
    final card = _SourceTypeCard(
      key: ValueKey(data.kind),
      data: data,
      variant: variant,
      compact: compact,
      width: width,
      onTap: () => onTap(data),
    );
    return cardWrapper?.call(index, card) ?? card;
  }
}

class _SourceTypeCard extends StatefulWidget {
  const _SourceTypeCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.variant,
    required this.compact,
    required this.width,
  });

  final SourceTypeCardData data;
  final VoidCallback onTap;
  final SourceTypeCardVariant variant;
  final bool compact;
  final double width;

  @override
  State<_SourceTypeCard> createState() => _SourceTypeCardState();
}

class _SourceTypeCardState extends State<_SourceTypeCard> {
  static const _duration = Duration(milliseconds: 180);

  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final accent = sourceTypeAccent(data.kind);
    final guide = widget.variant == SourceTypeCardVariant.guide;
    final compact = widget.compact;

    final padding =
        compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 11)
            : guide
            ? const EdgeInsets.fromLTRB(12, 13, 12, 12)
            : const EdgeInsets.all(14);
    final gap =
        compact
            ? 5.0
            : guide
            ? 7.0
            : 6.0;
    final background =
        guide
            ? LiveKitStyle.srcGuideBg
            : _hovering
            ? LiveKitStyle.surface3
            : LiveKitStyle.surface2;
    final borderColor = accent.withValues(
      alpha:
          _hovering
              ? 0.62
              : guide
              ? 0.24
              : 0.28,
    );
    final shadows =
        _hovering
            ? guide
                ? [
                  BoxShadow(color: accent.withValues(alpha: 0.16), spreadRadius: 1),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.95),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                    spreadRadius: -14,
                  ),
                ]
                : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.9),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -12,
                  ),
                ]
            : guide
            ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.9),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -14,
              ),
            ]
            : const <BoxShadow>[];
    final lift =
        _pressed
            ? -1.0
            : _hovering
            ? (guide ? -3.0 : -2.0)
            : 0.0;

    return HoverClickable(
      onTap: widget.onTap,
      onHover:
          (hovering) => setState(() {
            _hovering = hovering;
            if (!hovering) {
              _pressed = false;
            }
          }),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOut,
        width: widget.width,
        transform: Matrix4.translationValues(0, lift, 0)..scale(_pressed ? 0.985 : 1.0),
        transformAlignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(guide ? 10 : 8),
          border: Border.all(color: borderColor),
          boxShadow: shadows,
        ),
        child: Stack(
          children: [
            if (guide)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovering ? 1 : 0.44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.24),
                          radius: 1.3,
                          stops: const [0, 0.54, 1],
                          colors: [
                            accent.withValues(alpha: 0.46),
                            accent.withValues(alpha: 0.12),
                            accent.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _SourceTypeBadge(icon: data.icon, accent: accent, hovering: _hovering, compact: compact),
                  ),
                  SizedBox(height: gap),
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: compact ? 12 : 13, color: LiveKitStyle.srcNameColor),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: compact ? 26 : 28,
                    child: Text(
                      data.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: compact ? 9 : 10, height: 1.4, color: LiveKitStyle.text3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTypeBadge extends StatelessWidget {
  const _SourceTypeBadge({required this.icon, required this.accent, required this.hovering, required this.compact});

  final IconData icon;
  final Color accent;
  final bool hovering;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      transform: Matrix4.translationValues(0, hovering ? -1 : 0, 0)..scale(hovering ? 1.04 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.34, -0.94),
          end: const Alignment(0.34, 0.94),
          colors:
              hovering
                  ? [accent.withValues(alpha: 0.46), accent.withValues(alpha: 0.22)]
                  : [accent.withValues(alpha: 0.30), accent.withValues(alpha: 0.13)],
        ),
        borderRadius: BorderRadius.circular(compact ? 9 : 10),
        border: Border.all(color: accent.withValues(alpha: hovering ? 0.58 : 0.36)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: hovering ? 1.0 : 0.9),
            blurRadius: hovering ? 16 : 10,
            offset: Offset(0, hovering ? 6 : 3),
            spreadRadius: hovering ? -7 : -6,
          ),
        ],
      ),
      child: Icon(icon, size: compact ? 17 : 19, color: Color.lerp(accent, Colors.white, 0.4)),
    );
  }
}
