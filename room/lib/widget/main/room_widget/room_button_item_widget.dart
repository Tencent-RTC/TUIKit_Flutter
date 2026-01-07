import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomButtonItemWidget extends StatelessWidget {
  final String iconPath;

  final String? selectedIconPath;

  final String text;

  final String? selectedText;

  final ValueNotifier<bool>? isSelected;

  final VoidCallback onPressed;

  final double width;

  final double height;

  final double opacity;

  const RoomButtonItemWidget({
    super.key,
    required this.iconPath,
    required this.text,
    required this.onPressed,
    this.selectedIconPath,
    this.selectedText,
    this.isSelected,
    this.width = 52,
    this.height = 52,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: RoomColors.lightGrey, borderRadius: BorderRadius.circular(10)),
          child: isSelected != null
              ? ValueListenableBuilder(
                  valueListenable: isSelected!,
                  builder: (context, selected, _) {
                    return _buildContent(selected);
                  },
                )
              : _buildContent(false),
        ),
      ),
    );
  }

  Widget _buildContent(bool selected) {
    final displayIconPath = selected && selectedIconPath != null ? selectedIconPath! : iconPath;
    final displayText = selected && selectedText != null ? selectedText! : text;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(displayIconPath, package: RoomConstants.pluginName, fit: BoxFit.contain),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 10, color: RoomColors.white, fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
