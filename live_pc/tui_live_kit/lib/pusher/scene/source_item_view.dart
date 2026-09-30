import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../pusher_style.dart';
import 'scene_store.dart';

/// 画面源列表行：可见性开关 / 类型图标 / 名称 / 编辑 / 删除。
///
/// 整行短按点击选中（选中行高亮：浅色底 + 主题色描边，与预览画布
/// 的画面源选中态同源）；整行长按拖拽调整层级
/// （ReorderableDelayedDragStartListener，长按与点击天然不冲突）。
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

  /// 在展示列表（倒序）中的索引，用于拖拽排序监听。
  final int displayIndex;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleVisible;

  /// 编辑入口（当前仅已绑定引擎的摄像头画面源提供，其余为 null 不展示）。
  final VoidCallback? onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final off = !source.visible;
    // 整行拖拽用立即模式（移动超过 slop 即起拖），不用长按定时器：
    // DelayedMultiDrag 在定时器到点后会在竞技场胜出，按住超过延迟的
    // 普通点击就选中失败；立即模式下「按下不动抬起=选中、按下移动=拖拽」。
    return ReorderableDragStartListener(
      index: displayIndex,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PusherStyle.white8 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          // 透明描边占位，避免选中态切换时内容跳动。
          border: Border.all(
            color: selected ? PusherStyle.brand2 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(source.icon, size: 14, color: PusherStyle.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                source.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: off ? PusherStyle.textHint : PusherStyle.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (onEdit != null) ...[
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  RemixIcons.edit_2_line,
                  size: 12,
                  color: PusherStyle.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onToggleVisible,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                off ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                size: 14,
                color: PusherStyle.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                RemixIcons.delete_bin_6_line,
                size: 12,
                color: PusherStyle.textPrimary,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
