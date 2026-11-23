import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../common/widget/menu_panel.dart';
import '../../../../l10n/live_kit_localizations.dart';
import '../../../../common/style/live_kit_style.dart';

Future<String?> showSceneActionsMenu(BuildContext context, {bool canDelete = true}) {
  final strings = LiveKitLocalizations.of(context);
  return showMenuPanel<String>(
    context: context,
    estimatedSize: const Size(112, 92),
    padding: 4,
    builder:
        (close) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SceneActionItem(
              icon: RemixIcons.edit_2_line,
              label: strings.sceneMenuRename,
              onTap: () => close('rename'),
            ),
            _SceneActionItem(
              icon: RemixIcons.file_copy_line,
              label: strings.sceneMenuDuplicate,
              onTap: () => close('duplicate'),
            ),
            _SceneActionItem(
              icon: RemixIcons.delete_bin_6_line,
              label: strings.sceneMenuDelete,
              isDanger: true,
              enabled: canDelete,
              onTap: () => close('delete'),
            ),
          ],
        ),
  );
}

class _SceneActionItem extends StatefulWidget {
  const _SceneActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;
  final bool enabled;

  @override
  State<_SceneActionItem> createState() => _SceneActionItemState();
}

class _SceneActionItemState extends State<_SceneActionItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color =
        !widget.enabled ? LiveKitStyle.textDisabled : (widget.isDanger ? LiveKitStyle.danger : LiveKitStyle.textMuted);
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _hovering && widget.enabled ? LiveKitStyle.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 12, color: color),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
