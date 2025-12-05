import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/svg.dart';

class SettingWidgets {
  static Widget buildSettingRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              return colorsTheme.textColorButton;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return colorsTheme.switchColorOn;
              }
              return colorsTheme.switchColorOff;
            }),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
              return colorsTheme.clearColor;
            }),
          ),
        ],
      ),
    );
  }

  static Widget buildNavigationRow({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? value,
    VoidCallback? onTap,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorsTheme.textColorSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: colorsTheme.textColorPrimary,
                ),
              ),
            if (onTap != null) const SizedBox(width: 8),
            if (onTap != null)
              SvgPicture.asset(
                'chat_assets/icon/chevron_right.svg',
                package: 'tuikit_atomic_x',
                width: 12,
                height: 24,
                colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildInfoRow({
    required BuildContext context,
    required String title,
    required String value,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: colorsTheme.textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorsTheme.buttonColorPrimaryDefault,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorsTheme.buttonColorPrimaryDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSimpleActionRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: titleColor ?? colorsTheme.textColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildDangerousActionRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorsTheme.textColorError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildDivider(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      height: 1,
      color: colorsTheme.listColorDefault,
    );
  }

  static Widget buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colorsTheme.bgColorTopBar,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorsTheme.bgColorOperate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colorsTheme.buttonColorPrimaryDefault,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    VoidCallback? onBackPressed,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return AppBar(
      backgroundColor: colorsTheme.bgColorOperate,
      scrolledUnderElevation: 0,
      leading: IconButton.buttonContent(
        content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
        type: ButtonType.noBorder,
        size: ButtonSize.l,
        onClick: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorsTheme.textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: colorsTheme.strokeColorPrimary,
        ),
      ),
    );
  }

  static Widget buildSettingGroup({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colorsTheme.bgColorTopBar,
      ),
      child: Column(children: children),
    );
  }
}
