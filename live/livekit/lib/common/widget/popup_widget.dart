import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';

BottomSheetHandler popupWidget(Widget widget,
    {Color? barrierColor,
    Color? backgroundColor,
    required BuildContext context,
    RouteSettings? routeSettings,
    bool isDismissible = true,
    VoidCallback? onDismiss}) {
  final effectiveBackgroundColor = backgroundColor ?? BaseThemeProvider.of(context).colors.bgColorDialog;
  return BaseBottomSheet.showModalSheet(
    barrierColor: barrierColor,
    backgroundColor: effectiveBackgroundColor,
    isScrollControlled: true,
    isDismissible: isDismissible,
    onDismiss: onDismiss,
    context: context,
    routeSettings: routeSettings,
    builder: (context) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.radius),
          topRight: Radius.circular(20.radius),
        ),
        color: effectiveBackgroundColor,
      ),
      child: widget,
    ),
  );
}
