import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../common/style/live_kit_style.dart';
import '../../../../common/widget/menu_panel.dart';
import '../../../../l10n/live_kit_localizations.dart';

Future<String?> showSceneRenameDialog(BuildContext context, String initialName) {
  return showMenuPanel<String>(
    context: context,
    estimatedSize: const Size(224, 148),
    padding: 12,
    captureFocus: false,
    builder: (close) => _SceneRenamePanel(initialName: initialName, onDone: (name) => close(name)),
  );
}

const int _maxNameLength = 20;

class _SceneRenamePanel extends StatefulWidget {
  const _SceneRenamePanel({required this.initialName, required this.onDone});

  final String initialName;

  final void Function(String? name) onDone;

  @override
  State<_SceneRenamePanel> createState() => _SceneRenamePanelState();
}

class _SceneRenamePanelState extends State<_SceneRenamePanel> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection.collapsed(offset: widget.initialName.length);

  final _focusNode = FocusNode();

  bool _limitHit = false;
  bool _canSave = false;

  void _onLengthExceeded() {
    if (!_limitHit) {
      setState(() => _limitHit = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _canSave = widget.initialName.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onTextChanged() {
    final canSave = _controller.text.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    widget.onDone(name);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(RemixIcons.edit_2_line, size: 12, color: LiveKitStyle.textMuted),
            const SizedBox(width: 6),
            Text(strings.sceneRenameTitle, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): _save,
            const SingleActivator(LogicalKeyboardKey.escape): () => widget.onDone(null),
          },
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            selectAllOnFocus: false,
            cursorColor: LiveKitStyle.brand2,
            inputFormatters: [_SceneNameLengthFormatter(_maxNameLength, _onLengthExceeded)],
            onChanged: (value) {
              if (_limitHit && value.length < _maxNameLength) {
                setState(() => _limitHit = false);
              }
            },
            style: const TextStyle(fontSize: 12, height: 16 / 12, color: LiveKitStyle.textMuted),
            decoration: InputDecoration(
              hintText: strings.sceneNameHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: LiveKitStyle.softPanelBase,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: LiveKitStyle.white8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: LiveKitStyle.brand),
              ),
            ),
          ),
        ),
        if (_limitHit) ...[
          const SizedBox(height: 6),
          Text(strings.sceneNameLimit, style: const TextStyle(fontSize: 12, color: LiveKitStyle.danger)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _PanelButton(label: strings.commonCancel, onTap: () => widget.onDone(null))),
            const SizedBox(width: 8),
            Expanded(child: _PanelButton(label: strings.commonSave, primary: true, enabled: _canSave, onTap: _save)),
          ],
        ),
      ],
    );
  }
}

class _SceneNameLengthFormatter extends TextInputFormatter {
  const _SceneNameLengthFormatter(this.maxLength, this.onExceeded);

  final int maxLength;
  final VoidCallback onExceeded;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > maxLength) {
      onExceeded();
      return oldValue;
    }
    return newValue;
  }
}

class _PanelButton extends StatefulWidget {
  const _PanelButton({required this.label, required this.onTap, this.primary = false, this.enabled = true});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  final bool enabled;

  @override
  State<_PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<_PanelButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final background =
        widget.primary
            ? (enabled ? LiveKitStyle.brand : LiveKitStyle.brand.withValues(alpha: 0.4))
            : (_hovering && enabled ? LiveKitStyle.white10 : LiveKitStyle.white5);
    final foreground =
        widget.primary ? (enabled ? Colors.white : Colors.white.withValues(alpha: 0.5)) : LiveKitStyle.textMuted;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.primary ? FontWeight.w500 : FontWeight.normal,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
