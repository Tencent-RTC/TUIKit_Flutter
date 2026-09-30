import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';

enum RoomVisibility { public, privacy }

typedef RoomEditResult = ({String name, RoomVisibility visibility});

Future<RoomEditResult?> showRoomEditDialog(
  BuildContext context, {
  required String initialName,
  RoomVisibility initialVisibility = RoomVisibility.public,
}) {
  final strings = LiveKitLocalizations.of(context);
  return showGeneralDialog<RoomEditResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: strings.commonClose,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => _RoomEditDialog(
      initialName: initialName,
      initialVisibility: initialVisibility,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _RoomEditDialog extends StatefulWidget {
  const _RoomEditDialog({
    required this.initialName,
    required this.initialVisibility,
  });

  final String initialName;
  final RoomVisibility initialVisibility;

  @override
  State<_RoomEditDialog> createState() => _RoomEditDialogState();
}

class _RoomEditDialogState extends State<_RoomEditDialog> {
  late final TextEditingController _nameController;
  late RoomVisibility _visibility;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _visibility = widget.initialVisibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
            width: 384,
            decoration: PusherStyle.dialogPanel(),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildNameField(),
                    const SizedBox(height: 12),
                    _buildVisibilityField(),
                    const SizedBox(height: 12),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final strings = LiveKitLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              RemixIcons.edit_2_line,
              size: 14,
              color: PusherStyle.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              strings.liveInfoEditTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PusherStyle.textEmphasis,
              ),
            ),
          ],
        ),
        _CloseButton(onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildNameField() {
    final strings = LiveKitLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.liveInfoNameLabel,
          style: const TextStyle(fontSize: 10, color: PusherStyle.textHint),
        ),
        const SizedBox(height: 4),
        // 输入框（设计稿聚焦态：白 5% 底 + 品牌描边）。
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: PusherStyle.white5,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: PusherStyle.brand2),
          ),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 12,
              color: PusherStyle.textPrimary,
            ),
            cursorColor: PusherStyle.brand2,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityField() {
    final strings = LiveKitLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.liveInfoVisibilityLabel,
          style: const TextStyle(fontSize: 10, color: PusherStyle.textHint),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _VisibilityOption(
              icon: RemixIcons.earth_line,
              label: strings.liveInfoVisibilityPublic,
              selected: _visibility == RoomVisibility.public,
              onTap: () => setState(() => _visibility = RoomVisibility.public),
            ),
            const SizedBox(width: 6),
            _VisibilityOption(
              icon: RemixIcons.lock_line,
              label: strings.liveInfoVisibilityPrivate,
              selected: _visibility == RoomVisibility.privacy,
              onTap: () =>
                  setState(() => _visibility = RoomVisibility.privacy),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final strings = LiveKitLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _save,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            strings.liveInfoSave,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      (name: _nameController.text.trim(), visibility: _visibility),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        selected ? PusherStyle.brand2 : PusherStyle.textTertiary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 27,
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: selected
                ? PusherStyle.brand2.withValues(alpha: 0.12)
                : PusherStyle.white4,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? PusherStyle.brand2.withValues(alpha: 0.4)
                  : PusherStyle.white8,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 12, color: accent),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
            size: 16,
            color: _hovering
                ? PusherStyle.textSecondary
                : PusherStyle.textTertiary,
          ),
        ),
      ),
    );
  }
}
