import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../common/style/live_kit_style.dart';
import '../../../../common/widget/hover_clickable.dart';
import '../../../../common/widget/overflow_tooltip_text.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';

IconData _sourceIcon(MediaSourceKind kind) {
  return switch (kind) {
    MediaSourceKind.camera => RemixIcons.webcam_line,
    MediaSourceKind.screen => RemixIcons.computer_line,
    MediaSourceKind.image => RemixIcons.image_line,
    MediaSourceKind.onlineVideo => RemixIcons.global_line,
    MediaSourceKind.videoFile => RemixIcons.file_video_line,
  };
}

class SourceItemView extends StatelessWidget {
  const SourceItemView({
    super.key,
    required this.source,
    required this.displayIndex,
    required this.selected,
    required this.onTap,
    required this.onToggleVisible,
    required this.onEdit,
    required this.onRemove,
  });

  final MediaSourceConfig source;

  final int displayIndex;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleVisible;

  final VoidCallback? onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final off = !source.visible;
    // Row dragging uses immediate mode (drag starts once the pointer moves
    // past the slop) instead of a long-press timer: with DelayedMultiDrag,
    // the timer winning the arena means a normal press-and-hold longer than
    // the delay fails to select; in immediate mode "press without moving
    // then release = select, press and move = drag".
    return ReorderableDragStartListener(
      index: displayIndex,
      child: HoverClickable(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? LiveKitStyle.white8 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            // Transparent outline placeholder to avoid content jumping when
            // the selection state toggles.
            border: Border.all(color: selected ? LiveKitStyle.brand2 : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(_sourceIcon(source.kind), size: 14, color: LiveKitStyle.text3),
              const SizedBox(width: 8),
              Expanded(
                child: OverflowTooltipText(
                  source.name,
                  style: TextStyle(fontSize: 12, color: off ? LiveKitStyle.textHint : LiveKitStyle.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              if (onEdit != null) ...[
                _ActionIcon(icon: RemixIcons.edit_2_line, size: 12, onTap: onEdit),
                const SizedBox(width: 8),
              ],
              _ActionIcon(icon: off ? RemixIcons.eye_off_line : RemixIcons.eye_line, size: 14, onTap: onToggleVisible),
              const SizedBox(width: 8),
              _ActionIcon(icon: RemixIcons.delete_bin_6_line, size: 12, onTap: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatefulWidget {
  const _ActionIcon({required this.icon, required this.size, this.onTap});

  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Icon(widget.icon, size: widget.size, color: _hovering ? LiveKitStyle.textEmphasis : LiveKitStyle.text3),
      ),
    );
  }
}
