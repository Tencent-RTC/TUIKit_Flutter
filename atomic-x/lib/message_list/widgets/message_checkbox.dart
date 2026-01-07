import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// Checkbox component for message multi-select mode
class MessageCheckbox extends StatelessWidget {
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  const MessageCheckbox({
    super.key,
    required this.isSelected,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? colors.buttonColorPrimaryDefault : Colors.transparent,
            border: Border.all(
              color: isEnabled
                  ? (isSelected ? colors.buttonColorPrimaryDefault : colors.strokeColorPrimary)
                  : colors.textColorDisable,
              width: 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
