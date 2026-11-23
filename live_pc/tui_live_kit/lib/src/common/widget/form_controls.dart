import 'package:flutter/material.dart';

import '../style/live_kit_style.dart';
import 'hover_clickable.dart';

class FormButton extends StatefulWidget {
  const FormButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  State<FormButton> createState() => _FormButtonState();
}

class _FormButtonState extends State<FormButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient:
                widget.primary && enabled
                    ? LinearGradient(
                      colors:
                          _hovering
                              ? const [LiveKitStyle.brand2, LiveKitStyle.brand]
                              : const [LiveKitStyle.brand, LiveKitStyle.brand2],
                    )
                    : null,
            color:
                widget.primary
                    ? (enabled ? null : LiveKitStyle.white8)
                    : (_hovering ? LiveKitStyle.white10 : LiveKitStyle.white6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.primary ? FontWeight.w500 : FontWeight.normal,
              color: widget.primary ? (enabled ? Colors.white : LiveKitStyle.textHint) : LiveKitStyle.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textTertiary));
  }
}

class FormHintText extends StatelessWidget {
  const FormHintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textTertiary));
  }
}

class FormToggleSwitch extends StatelessWidget {
  const FormToggleSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return HoverClickable(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? LiveKitStyle.brand : LiveKitStyle.white15,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 120),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  const FormTextField({super.key, required this.controller, this.hint, this.keyboardType});

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: LiveKitStyle.softPanel(),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: LiveKitStyle.textPrimary),
        cursorColor: LiveKitStyle.brand2,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: LiveKitStyle.textTertiary),
        ),
      ),
    );
  }
}
