import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../pusher_style.dart';
import 'scene_menu.dart';
import 'scene_store.dart';

/// 单个预设场景按钮：点击切换场景；悬停出现 ⚙，点击弹出场景操作菜单
/// （重命名 / 复制 / 删除）。
class SceneButton extends StatefulWidget {
  const SceneButton({
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

  /// 菜单动作回调：rename / duplicate / delete。
  final void Function(String action) onMenuAction;

  /// 是否允许删除（当前模式只剩这一个场景时为 false，菜单删除项禁用）。
  final bool deleteEnabled;

  @override
  State<SceneButton> createState() => _SceneButtonState();
}

class _SceneButtonState extends State<SceneButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
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
                color: widget.active
                    ? const Color(0x33EB5A8F) // brand2 / 20%
                    : PusherStyle.white5,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.scene.icon,
                    size: 12,
                    color: widget.active
                        ? Colors.white
                        : PusherStyle.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      sceneDisplayName(context, widget.scene),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.active
                            ? Colors.white
                            : PusherStyle.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hovering)
              Positioned(
                top: 0,
                right: 0,
                child: Builder(
                  builder: (iconContext) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final action = await showSceneActionsMenu(
                        iconContext,
                        canDelete: widget.deleteEnabled,
                      );
                      if (!mounted) {
                        return;
                      }
                      if (action != null) {
                        widget.onMenuAction(action);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        RemixIcons.settings_3_line,
                        size: 10,
                        color: PusherStyle.textTertiary,
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
