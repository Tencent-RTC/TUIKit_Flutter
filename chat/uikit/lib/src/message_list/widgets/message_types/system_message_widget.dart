import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class SystemMessageWidget extends StatelessWidget {
  final MessageInfo? message;
  final String? customContent;

  const SystemMessageWidget({
    super.key,
    this.message,
    this.customContent,
  }) : assert(message != null || customContent != null, 
              'Either message or customContent must be provided');

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    
    String systemContent;
    if (customContent != null) {
      systemContent = customContent!;
    } else if (message != null && message!.status == MessageStatus.revoked) {
      systemContent = MessageUtil.getRevokeDisplayString(message!, context);
    } else {
      systemContent = MessageUtil.getSystemInfoDisplayString(
        (message?.messagePayload as TipsMessagePayload?)?.groupTips ?? [], 
        context
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.0),
      child: Center(
        child: Text(
          systemContent,
          textAlign: TextAlign.center,
          style: FontScheme.caption3Regular.copyWith(
            color: colorsTheme.textColorTertiary,
          ),
        ),
      ),
    );
  }
}