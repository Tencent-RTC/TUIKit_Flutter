import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';

BottomSheetHandler popupWidget(Widget widget,
    {Color? barrierColor,
    Color? backgroundColor = LiveColors.designStandardG2,
    BuildContext? context,
    RouteSettings? routeSettings,
    bool isDismissible = true,
    VoidCallback? onDismiss}) {
  return BaseBottomSheet.showModalSheet(
    barrierColor: barrierColor,
    backgroundColor: backgroundColor,
    isScrollControlled: true,
    isDismissible: isDismissible,
    onDismiss: onDismiss,
    context: context ?? Global.appContext(),
    routeSettings: routeSettings,
    builder: (context) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.radius),
          topRight: Radius.circular(20.radius),
        ),
        color: backgroundColor,
      ),
      child: widget,
    ),
  );
}
