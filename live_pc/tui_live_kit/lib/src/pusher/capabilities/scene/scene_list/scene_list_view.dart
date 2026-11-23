import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../l10n/live_kit_localizations.dart';
import '../../../../common/style/live_kit_style.dart';
import '../../../../common/widget/hover_clickable.dart';
import 'scene_item_view.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'scene_rename_panel.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';
import '../scene_localization.dart';

class SceneListView extends StatelessWidget {
  const SceneListView({super.key, required this.store, required this.controller});

  final SceneStoreView store;

  final SceneController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder:
          (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.isLandscape
                        ? LiveKitLocalizations.of(context).sceneGroupLandscape
                        : LiveKitLocalizations.of(context).sceneGroupPortrait,
                    style: const TextStyle(fontSize: 12, color: LiveKitStyle.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonWidth = (constraints.maxWidth - 12) / 3;
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 114),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final scene in store.visibleScenes)
                                SizedBox(
                                  width: buttonWidth,
                                  child: SceneItemView(
                                    scene: scene,
                                    active: scene.key == store.currentSceneKey,
                                    deleteEnabled: store.visibleScenes.length > 1,
                                    onTap: () => controller.switchScene(scene.key),
                                    onMenuAction:
                                        (action, anchorContext) =>
                                            _handleSceneAction(context, scene.key, action, anchorContext),
                                  ),
                                ),
                              _AddSceneButton(width: buttonWidth, onTap: _addScene),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _handleSceneAction(BuildContext context, String key, String action, BuildContext anchorContext) async {
    switch (action) {
      case 'rename':
        final scene = store.sceneOf(key);
        if (scene == null || !anchorContext.mounted) {
          return;
        }
        final name = await showSceneRenameDialog(anchorContext, sceneDisplayName(context, scene));
        if (name != null) {
          controller.renameScene(key, name);
        }
      case 'duplicate':
        controller.duplicateScene(key);
      case 'delete':
        controller.deleteScene(key);
    }
  }

  void _addScene() {
    controller.addScene(store.nextCustomSceneName());
  }
}

class _AddSceneButton extends StatelessWidget {
  const _AddSceneButton({required this.width, required this.onTap});

  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverClickable(
      onTap: onTap,
      child: CustomPaint(
        foregroundPainter: _DashedRoundedRectPainter(radius: 6, color: LiveKitStyle.white20),
        child: Container(
          width: width,
          height: 30,
          alignment: Alignment.center,
          child: const Icon(RemixIcons.add_line, size: 14, color: LiveKitStyle.textHint),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 3;
        canvas.drawPath(
          metric.extractPath(distance, next + 2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
