import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import 'scene_button.dart';
import 'scene_menu.dart';
import 'scene_store.dart';

/// 场景切换区：模式标签（横屏场景 / 竖屏场景）+ 场景按钮网格
/// （每行 3 个，最多 3 行，超出滚动）+ 末尾虚线「+」添加。
class SceneSwitchView extends StatelessWidget {
  const SceneSwitchView({super.key, required this.store});

  final SceneStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Padding(
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
              style: const TextStyle(
                fontSize: 12,
                color: PusherStyle.textPrimary,
              ),
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
                            child: SceneButton(
                              scene: scene,
                              active: scene.key == store.currentSceneKey,
                              // 当前模式只剩一个场景时不允许删除。
                              deleteEnabled: store.visibleScenes.length > 1,
                              onTap: () => store.setCurrentScene(scene.key),
                              onMenuAction: (action) => _handleSceneAction(
                                context,
                                scene.key,
                                action,
                              ),
                            ),
                          ),
                        _AddSceneButton(
                          width: buttonWidth,
                          onTap: () => _addScene(context),
                        ),
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

  Future<void> _handleSceneAction(
    BuildContext context,
    String key,
    String action,
  ) async {
    switch (action) {
      case 'rename':
        final scene = store.sceneOf(key);
        if (scene == null || !context.mounted) {
          return;
        }
        final name =
            await showSceneRenameDialog(context, sceneDisplayName(context, scene));
        if (name != null) {
          store.renameScene(key, name);
        }
      case 'duplicate':
        store.duplicateScene(key);
      case 'delete':
        store.deleteScene(key);
    }
  }

  Future<void> _addScene(BuildContext context) async {
    final result = await showAddSceneDialog(
      context,
      store.nextCustomSceneName(),
    );
    if (result != null) {
      store.addScene(result.name, result.icon);
    }
  }
}

/// 末尾「添加预设场景」按钮：虚线描边。
class _AddSceneButton extends StatelessWidget {
  const _AddSceneButton({required this.width, required this.onTap});

  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        foregroundPainter: _DashedRoundedRectPainter(
          radius: 6,
          color: PusherStyle.white20,
        ),
        child: Container(
          width: width,
          height: 30,
          alignment: Alignment.center,
          child: const Icon(
            RemixIcons.add_line,
            size: 14,
            color: PusherStyle.textHint,
          ),
        ),
      ),
    );
  }
}

/// 虚线圆角矩形描边。
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
