import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';

/// 左侧面板的 Tab 项。
enum SceneTab { source, beauty, more }

/// 图标竖排 Tab 导航（面板内左侧窄条，44px 宽）。
///
/// 上方为常驻常用能力（画面源 / 美颜），分隔线下方为
/// 更多能力。样式对齐设计稿：选中项白 10% 底 + 白色图标；
/// 未选中项悬停提亮（图标变亮 + 白 5% 底）。
class SceneTabRail extends StatelessWidget {
  const SceneTabRail({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SceneTab selected;
  final ValueChanged<SceneTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: PusherStyle.white4)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _RailButton(
            icon: RemixIcons.layout_grid_line,
            tooltip: LiveKitLocalizations.of(context).tabSources,
            active: selected == SceneTab.source,
            onTap: () => onChanged(SceneTab.source),
          ),
          _RailButton(
            icon: RemixIcons.webcam_line,
            tooltip: LiveKitLocalizations.of(context).tabBeauty,
            active: selected == SceneTab.beauty,
            onTap: () => onChanged(SceneTab.beauty),
          ),
          const SizedBox(height: 4),
          Container(width: 24, height: 1, color: PusherStyle.white6),
          const SizedBox(height: 4),
          _RailButton(
            icon: RemixIcons.more_fill,
            tooltip: LiveKitLocalizations.of(context).tabMore,
            active: selected == SceneTab.more,
            onTap: () => onChanged(SceneTab.more),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

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
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? PusherStyle.white10
                    : (_hovering ? PusherStyle.white5 : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : (_hovering
                          ? PusherStyle.textEmphasis
                          : PusherStyle.textTertiary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
