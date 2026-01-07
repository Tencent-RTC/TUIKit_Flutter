import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

void popupWidget(
  Widget widget, {
  Color? barrierColor,
  Color? backgroundColor = RoomColors.mainBlack,
  BuildContext? context,
  bool isDismissible = true,
  VoidCallback? onDismiss,
}) {
  showModalBottomSheet(
    barrierColor: barrierColor,
    backgroundColor: backgroundColor,
    isScrollControlled: true,
    isDismissible: isDismissible,
    context: context ?? Global.appContext(),
    builder: (context) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.radius), topRight: Radius.circular(20.radius)),
        color: backgroundColor,
      ),
      child: widget,
    ),
  ).then((value) => onDismiss?.call());
}
