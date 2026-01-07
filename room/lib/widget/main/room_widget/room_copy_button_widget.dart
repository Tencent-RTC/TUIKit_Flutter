import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomCopyButtonWidget extends StatelessWidget {
  final String infoText;
  final String successToast;

  const RoomCopyButtonWidget({super.key, required this.infoText, required this.successToast});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleCopy(context),
      child: Container(
        width: 62.width,
        height: 25.height,
        decoration: BoxDecoration(color: RoomColors.g4, borderRadius: BorderRadius.circular(5.radius)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              RoomImages.roomCopy,
              package: RoomConstants.pluginName,
              width: 16.width,
              height: 16.height,
              color: RoomColors.white,
            ),
            SizedBox(width: 2),
            Text(
              RoomLocalizations.of(context)!.roomkit_copy,
              style: TextStyle(fontSize: 12.width, color: RoomColors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCopy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: infoText));
    Toast.info(context, successToast, useRootOverlay: true);
  }
}
