import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import 'scene_store.dart';

/// 添加预设场景时可选的图标（对齐设计稿 SCENE_ICONS）。
const List<IconData> kSceneIcons = [
  RemixIcons.gamepad_line,
  RemixIcons.movie_2_line,
  RemixIcons.mic_line,
  RemixIcons.chat_smile_2_line,
  RemixIcons.tv_2_line,
  RemixIcons.music_2_line,
  RemixIcons.basketball_line,
  RemixIcons.star_line,
  RemixIcons.bookmark_line,
  RemixIcons.live_line,
  RemixIcons.heart_3_line,
  RemixIcons.cup_line,
];

/// 在锚点（场景按钮右上角 ⚙）右侧弹出场景操作菜单。
///
/// [canDelete] 为 false 时（当前模式只剩一个场景）删除项禁用置灰。
///
/// 返回动作名：rename / duplicate / delete；取消返回 null。
Future<String?> showSceneActionsMenu(BuildContext context, {bool canDelete = true}) {
  final anchor = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final topRight = anchor.localToGlobal(
    anchor.size.topRight(Offset.zero),
    ancestor: overlay,
  );
  final overlaySize = overlay.size;
  return showMenu<String>(
    context: context,
    color: PusherStyle.menuBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: PusherStyle.white8),
    ),
    position: RelativeRect.fromLTRB(
      topRight.dx + 4,
      topRight.dy,
      overlaySize.width - topRight.dx - 4,
      overlaySize.height - topRight.dy - 120,
    ),
    items: [
      _menuItem(
        'rename',
        RemixIcons.edit_2_line,
        LiveKitLocalizations.of(context).sceneMenuRename,
      ),
      _menuItem(
        'duplicate',
        RemixIcons.file_copy_line,
        LiveKitLocalizations.of(context).sceneMenuDuplicate,
      ),
      _menuItem(
        'delete',
        RemixIcons.delete_bin_6_line,
        LiveKitLocalizations.of(context).sceneMenuDelete,
        isDanger: true,
        enabled: canDelete,
      ),
    ],
  );
}

/// 「添加画面源」弹窗：居中类型卡片选择（玻璃面板 + 背景模糊遮罩，
/// 对齐设计稿 sourceModalMask）。
///
/// 返回所选类型；点击关闭按钮 / 遮罩 / 按 ESC 返回 null。
Future<MediaSourceKind?> showSourceAddDialog(BuildContext context) {
  return showGeneralDialog<MediaSourceKind>(
    context: context,
    barrierDismissible: true,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    // 遮罩由弹窗内容自绘（含背景模糊），不用默认纯色遮罩。
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _SourceAddDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

typedef _SourceCardData = ({
  MediaSourceKind kind,
  IconData icon,
  String name,
  String desc,
});

class _SourceAddDialog extends StatelessWidget {
  const _SourceAddDialog();

  static List<_SourceCardData> _cards(LiveKitLocalizations strings) => [
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

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    final cards = _cards(strings);
    return Stack(
      children: [
        // 遮罩：背景模糊 + 半透明黑，点击关闭。
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 560,
            decoration: PusherStyle.dialogPanel(),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            RemixIcons.add_box_line,
                            size: 14,
                            color: PusherStyle.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            strings.sourceAddTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: PusherStyle.textEmphasis,
                            ),
                          ),
                        ],
                      ),
                      _DialogCloseButton(onTap: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Container(height: 1, color: PusherStyle.white6),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final card in cards)
                        _SourceTypeCard(
                          card: card,
                          onTap: () => Navigator.pop(context, card.kind),
                        ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 弹窗右上角关闭按钮（悬停高亮）。
class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? PusherStyle.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            RemixIcons.close_line,
            size: 14,
            color: _hovering
                ? PusherStyle.textSecondary
                : PusherStyle.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// 画面源类型卡片（悬停高亮，点击选择）。
class _SourceTypeCard extends StatefulWidget {
  const _SourceTypeCard({required this.card, required this.onTap});

  final _SourceCardData card;
  final VoidCallback onTap;

  @override
  State<_SourceTypeCard> createState() => _SourceTypeCardState();
}

class _SourceTypeCardState extends State<_SourceTypeCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: _hovering ? PusherStyle.white10 : const Color(0x0EFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PusherStyle.white8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(card.icon, size: 24, color: PusherStyle.textPrimary),
              const SizedBox(height: 8),
              Text(
                card.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: PusherStyle.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: PusherStyle.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 通用错误提示对话框（引擎操作失败等）。
Future<void> showSceneErrorDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final strings = LiveKitLocalizations.of(context);
      return AlertDialog(
        title: Text(strings.errorDialogTitle, style: const TextStyle(fontSize: 14)),
        content: Text(message, style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.commonConfirm),
          ),
        ],
      );
    },
  );
}

/// 重命名场景对话框。
Future<String?> showSceneRenameDialog(
  BuildContext context,
  String initialName,
) {
  final controller = TextEditingController(text: initialName);
  return showDialog<String>(
    context: context,
    builder: (context) {
      final strings = LiveKitLocalizations.of(context);
      return AlertDialog(
        title: Text(strings.sceneRenameTitle, style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.sceneNameHint,
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.commonSave),
          ),
        ],
      );
    },
  );
}

/// 添加预设场景对话框：名称（预填建议名）+ 图标选择。
Future<({String name, IconData icon})?> showAddSceneDialog(
  BuildContext context,
  String suggestedName,
) {
  final controller = TextEditingController(text: suggestedName);
  final selected = ValueNotifier<IconData>(kSceneIcons.first);
  return showDialog<({String name, IconData icon})>(
    context: context,
    builder: (context) {
      final strings = LiveKitLocalizations.of(context);
      return AlertDialog(
      title: Text(strings.sceneAddTitle, style: const TextStyle(fontSize: 14)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.sceneNameHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.sceneIconPick,
              style: const TextStyle(fontSize: 12, color: PusherStyle.textHint),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<IconData>(
              valueListenable: selected,
              builder: (context, icon, _) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in kSceneIcons)
                    GestureDetector(
                      onTap: () => selected.value = candidate,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: candidate == icon
                              ? PusherStyle.white15
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: candidate == icon
                                ? PusherStyle.brand2
                                : PusherStyle.white10,
                            width: candidate == icon ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          candidate,
                          size: 14,
                          color: candidate == icon
                              ? Colors.white
                              : PusherStyle.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.commonCancel),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.pop(context, (name: name, icon: selected.value));
          },
          child: Text(strings.commonAdd),
        ),
      ],
    );
    },
  );
}

PopupMenuItem<String> _menuItem(
  String value,
  IconData icon,
  String label, {
  bool isDanger = false,
  bool enabled = true,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 36,
    enabled: enabled,
    child: Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: enabled ? PusherStyle.textTertiary : PusherStyle.textDisabled,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: !enabled
                ? PusherStyle.textDisabled
                : (isDanger ? PusherStyle.danger : PusherStyle.textPrimary),
          ),
        ),
      ],
    ),
  );
}
