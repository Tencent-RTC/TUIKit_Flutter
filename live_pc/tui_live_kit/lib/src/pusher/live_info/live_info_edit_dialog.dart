import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import '../../common/widget/hover_clickable.dart';
import '../../l10n/live_kit_localizations.dart';
import '../../common/style/live_kit_style.dart';
import '../../common/widget/panel_dialog.dart';

const int _kLiveNameMaxBytes = 100;

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
    barrierColor: LiveKitStyle.transparent,
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

  int get _currentBytes => utf8.encode(_nameController.text).length;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _nameController.addListener(_onNameChanged);
    _visibility = widget.initialVisibility;
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelDialog(
      width: 384,
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
    );
  }

  Widget _buildHeader() {
    final strings = LiveKitLocalizations.of(context);
    return PanelDialogHeader(
      icon: RemixIcons.edit_2_line,
      title: strings.liveInfoEditTitle,
      padded: false,
      closeSize: 16,
    );
  }

  Widget _buildNameField() {
    final strings = LiveKitLocalizations.of(context);
    final bytes = _currentBytes;
    final isNearLimit = bytes >= (_kLiveNameMaxBytes * 0.8).round();
    final isAtLimit = bytes >= _kLiveNameMaxBytes;
    final counterColor = isAtLimit
        ? LiveKitStyle.danger
        : isNearLimit
            ? LiveKitStyle.gold
            : LiveKitStyle.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.liveInfoNameLabel,
              style: const TextStyle(fontSize: 10, color: LiveKitStyle.textHint),
            ),
            Text(
              '$bytes / $_kLiveNameMaxBytes',
              style: TextStyle(fontSize: 10, color: counterColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: LiveKitStyle.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LiveKitStyle.white8),
            ),
            child: TextField(
              controller: _nameController,
              inputFormatters: const [
                _Utf8ByteLimitFormatter(_kLiveNameMaxBytes),
              ],
              style: const TextStyle(
                fontSize: 12,
                color: LiveKitStyle.textPrimary,
              ),
              cursorColor: LiveKitStyle.brand2,
              decoration: const InputDecoration.collapsed(
                hintText: '',
              ),
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
          style: const TextStyle(fontSize: 10, color: LiveKitStyle.textHint),
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
    return _SaveButton(onTap: _save);
  }

  void _save() {
    final trimmed = _nameController.text.trim();
    final name = trimmed.isEmpty ? widget.initialName : trimmed;
    Navigator.pop(context, (name: name, visibility: _visibility));
  }
}

/// Owns its hover state so hovering does not rebuild the whole dialog.
class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HoverClickable(
        onTap: widget.onTap,
        onHover: (hovering) => setState(() => _hovering = hovering),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovering ? LiveKitStyle.brand2 : LiveKitStyle.brand,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            LiveKitLocalizations.of(context).liveInfoSave,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: LiveKitStyle.whitePure,
            ),
          ),
        ),
      ),
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
        selected ? LiveKitStyle.brand2 : LiveKitStyle.textTertiary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 27,
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: selected
                ? LiveKitStyle.brand2.withValues(alpha: 0.12)
                : LiveKitStyle.white4,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? LiveKitStyle.brand2.withValues(alpha: 0.4)
                  : LiveKitStyle.white8,
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

class _Utf8ByteLimitFormatter extends TextInputFormatter {
  const _Utf8ByteLimitFormatter(this.maxBytes);

  final int maxBytes;

  int _bytes(String s) => utf8.encode(s).length;

  String _limitedPrefix(String value, int budget) {
    var remaining = budget < 0 ? 0 : budget;
    final buffer = StringBuffer();
    for (final char in value.characters) {
      final len = _bytes(char);
      if (len > remaining) break;
      buffer.write(char);
      remaining -= len;
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing != TextRange.empty) return newValue;
    if (_bytes(newValue.text) <= maxBytes) return newValue;

    final oldChars = oldValue.text.characters.toList();
    final newChars = newValue.text.characters.toList();

    var pre = 0;
    while (pre < oldChars.length &&
        pre < newChars.length &&
        oldChars[pre] == newChars[pre]) {
      pre++;
    }
    var suf = 0;
    while (suf < oldChars.length - pre &&
        suf < newChars.length - pre &&
        oldChars[oldChars.length - 1 - suf] ==
            newChars[newChars.length - 1 - suf]) {
      suf++;
    }

    final prefix = oldChars.take(pre).join();
    final suffix = suf > 0
        ? oldChars.skip(oldChars.length - suf).join()
        : '';
    final insertion =
        newChars.skip(pre).take(newChars.length - pre - suf).join();

    final available = maxBytes - _bytes(prefix) - _bytes(suffix);
    final accepted = _limitedPrefix(insertion, available);
    final result = prefix + accepted + suffix;
    final safeResult = _limitedPrefix(result, maxBytes);

    return TextEditingValue(
      text: safeResult,
      selection: TextSelection.collapsed(
        offset: (prefix + accepted).length.clamp(0, safeResult.length),
      ),
    );
  }
}
