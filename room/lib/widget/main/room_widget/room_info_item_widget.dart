import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomInfoItemWidget extends StatelessWidget {
  final String prefixText;
  final String infoText;
  final TextStyle? prefixTextStyle;
  final TextStyle? infoTextStyle;
  final Widget? child;

  const RoomInfoItemWidget({
    super.key,
    required this.prefixText,
    required this.infoText,
    this.prefixTextStyle,
    this.infoTextStyle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 73,
          child: Text(
            prefixText,
            style: prefixTextStyle ?? TextStyle(fontSize: 14.width, color: RoomColors.g5),
          ),
        ),
        SizedBox(width: 20.width),
        Expanded(
          child: Text(
            infoText,
            style: infoTextStyle ?? TextStyle(fontSize: 14.width, color: RoomColors.g7),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (child != null) ...[SizedBox(width: 4.width), child!],
      ],
    );
  }
}
