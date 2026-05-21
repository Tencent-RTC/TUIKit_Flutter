import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomAIRecordFloatingWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const RoomAIRecordFloatingWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}

extension _RoomAIRecordFloatingWidgetPrivate on RoomAIRecordFloatingWidget {
  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72.radius,
        height: 72.radius,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RoomColors.aiRecordBg,
          borderRadius: BorderRadius.circular(10.radius),
          border: Border.all(
            color: RoomColors.aiRecordBorder,
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              RoomImages.aiRecord,
              package: RoomConstants.pluginName,
              width: 32.radius,
              height: 32.radius,
            ),
            SizedBox(height: 2.radius),
            _buildDescRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDescRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          RoomLocalizations.of(context)!.roomkit_transcription_recording,
          style: TextStyle(
            color: RoomColors.aiRecordText,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        Image.asset(
          RoomImages.aiRecordRightArrow,
          package: RoomConstants.pluginName,
          width: 12.radius,
          height: 12.radius,
        ),
      ],
    );
  }
}
