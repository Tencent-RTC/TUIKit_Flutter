import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/svg.dart';

class SettingWidgets {
  /// Shared minimum height for the tappable/toggle setting rows so a Switch row
  /// (whose control reserves ~40px) lines up with a plain text/navigation row.
  static const double _rowMinHeight = 48;

  static Widget buildSettingRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorSecondary,
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

  /// [valueWidget] replaces the plain [value] text when a row needs a richer
  /// accessory, e.g. the theme-color swatch.
  static Widget buildNavigationRow({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? value,
    Widget? valueWidget,
    VoidCallback? onTap,
    bool useEditIcon = false,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final showTrailing = useEditIcon || onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: _rowMinHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FontScheme.caption1Regular.copyWith(
                      color: colorsTheme.textColorSecondary,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: FontScheme.caption2Regular.copyWith(
                        color: colorsTheme.textColorSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (valueWidget != null)
              valueWidget
            else if (value != null)
              Text(
                value,
                style: FontScheme.caption1Regular.copyWith(
                  color: colorsTheme.textColorPrimary,
                ),
              ),
            if (showTrailing) const SizedBox(width: 8),
            if (useEditIcon)
              SvgPicture.asset(
                'chat_assets/icon/name_edit.svg',
                package: 'tencent_chat_uikit',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
              )
            else if (onTap != null)
              SvgPicture.asset(
                'chat_assets/icon/chevron_right.svg',
                package: 'tencent_chat_uikit',
                width: 12,
                height: 24,
                colorFilter: ColorFilter.mode(colorsTheme.textColorTertiary, BlendMode.srcIn),
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
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: FontScheme.caption1Regular.copyWith(
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
                style: FontScheme.caption1Regular.copyWith(
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
                style: FontScheme.caption1Regular.copyWith(
                  color: titleColor ?? colorsTheme.textColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A full-width tappable row whose label is centered. Used for the bottom
  /// action stack on the setting pages (send message / clear history / delete
  /// etc). [color] picks the label tint — omit for a normal (blue) action,
  /// pass the error color for a destructive one.
  static Widget buildCenteredActionRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          title,
          style: FontScheme.caption1Regular.copyWith(
            color: color ?? colorsTheme.buttonColorPrimaryDefault,
          ),
        ),
      ),
    );
  }

  static Widget buildDangerousActionRow({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return buildCenteredActionRow(
      context: context,
      title: title,
      onTap: onTap,
      color: BaseThemeProvider.colorsOf(context).textColorError,
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
              style: FontScheme.caption1Regular.copyWith(
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
        content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
        type: ButtonType.noBorder,
        size: ButtonSize.l,
        onClick: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: FontScheme.caption1Medium.copyWith(
          color: colorsTheme.textColorPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  static Widget buildSettingGroup({
    required BuildContext context,
    required List<Widget> children,
    bool showDividers = true,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && showDividers) {
        rows.add(buildRowDivider(context));
      }
      rows.add(children[i]);
    }

    return Container(
      color: colorsTheme.bgColorOperate,
      child: Column(children: rows),
    );
  }

  /// A thin separator drawn between rows inside the same card. It is inset on
  /// the left so it lines up with the row content and runs to the right edge.
  static Widget buildRowDivider(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      height: 0.5,
      color: colorsTheme.strokeColorPrimary,
    );
  }
}
