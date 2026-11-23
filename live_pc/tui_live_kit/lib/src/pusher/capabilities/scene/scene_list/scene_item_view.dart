import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../common/style/live_kit_style.dart';
import '../../../../common/widget/hover_clickable.dart';
import '../../../../common/widget/overflow_tooltip_text.dart';
import 'scene_menu.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import '../scene_localization.dart';

class SceneItemView extends StatefulWidget {
  const SceneItemView({
    super.key,
    required this.scene,
    required this.active,
    required this.onTap,
    required this.onMenuAction,
    this.deleteEnabled = true,
  });

  final SceneConfig scene;
  final bool active;
  final VoidCallback onTap;

  final void Function(String action, BuildContext anchorContext) onMenuAction;

  final bool deleteEnabled;

  @override
  State<SceneItemView> createState() => _SceneItemViewState();
}

class _SceneItemViewState extends State<SceneItemView> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    widget.active
                        ? const Color(0x33FF5580) // brand2 / 20%
                        : LiveKitStyle.white5,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      widget.active
                          ? const Color(0xE6FF5580) // brand2 / 90%
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(right: _hovering ? 22 : 0),
                      child: OverflowTooltipText(
                        sceneDisplayName(context, widget.scene),
                        style: TextStyle(fontSize: 12, color: widget.active ? Colors.white : LiveKitStyle.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 4,
              child: Center(
                child: Builder(
                  builder:
                      (iconContext) => HoverClickable(
                        onTap: () async {
                          final action = await showSceneActionsMenu(iconContext, canDelete: widget.deleteEnabled);
                          if (!mounted) {
                            return;
                          }
                          if (action != null && iconContext.mounted) {
                            widget.onMenuAction(action, iconContext);
                          }
                        },
                        child: IgnorePointer(
                          ignoring: !_hovering,
                          child: AnimatedOpacity(
                            opacity: _hovering ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: AnimatedScale(
                              scale: _hovering ? 1 : 0.9,
                              duration: const Duration(milliseconds: 150),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 3, 0, 3),
                                child: const _SceneMoreChip(),
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneMoreChip extends StatefulWidget {
  const _SceneMoreChip();

  @override
  State<_SceneMoreChip> createState() => _SceneMoreChipState();
}

class _SceneMoreChipState extends State<_SceneMoreChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: const Color(0xFF4A2438), borderRadius: BorderRadius.circular(6)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                LiveKitStyle.brand.withValues(alpha: _hovering ? 0.78 : 0.65),
                LiveKitStyle.brand.withValues(alpha: _hovering ? 0.58 : 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.14), Colors.transparent],
                stops: const [0, 0.55],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: AnimatedRotation(
              turns: _hovering ? 0.25 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(RemixIcons.settings_3_line, size: 15, color: Color(0xFFE9EDF4)),
            ),
          ),
        ),
      ),
    );
  }
}
