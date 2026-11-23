import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';

enum CapabilityTab { source, beauty, more }

class CapabilityList extends StatelessWidget {
  const CapabilityList({super.key, required this.selected, required this.onChanged});

  final CapabilityTab selected;
  final ValueChanged<CapabilityTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: LiveKitStyle.white8))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _RailButton(
            icon: RemixIcons.layout_grid_line,
            tooltip: LiveKitLocalizations.of(context).tabSources,
            active: selected == CapabilityTab.source,
            onTap: () => onChanged(CapabilityTab.source),
          ),
          _RailButton(
            icon: RemixIcons.magic_line,
            tooltip: LiveKitLocalizations.of(context).tabBeauty,
            active: selected == CapabilityTab.beauty,
            onTap: () => onChanged(CapabilityTab.beauty),
          ),
          const SizedBox(height: 4),
          Container(width: 24, height: 1, color: LiveKitStyle.white6),
          const SizedBox(height: 4),
          _RailButton(
            icon: RemixIcons.more_fill,
            tooltip: LiveKitLocalizations.of(context).tabMore,
            active: selected == CapabilityTab.more,
            onTap: () => onChanged(CapabilityTab.more),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  const _RailButton({required this.icon, required this.tooltip, required this.active, required this.onTap});

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active ? LiveKitStyle.white10 : (_hovering ? LiveKitStyle.white5 : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: active ? Colors.white : (_hovering ? LiveKitStyle.textEmphasis : LiveKitStyle.textTertiary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
