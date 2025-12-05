import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

mixin MessageStatusMixin {
  Widget buildMessageStatusIndicator({
    required MessageInfo message,
    required bool isSelf,
    required SemanticColorScheme colorsTheme,
    bool isOverlay = false,
    VoidCallback? onResendTap,
  }) {
    if (!isSelf) return const SizedBox.shrink();

    Color iconColor = isOverlay ? colorsTheme.textColorAntiPrimary : colorsTheme.buttonColorPrimaryDefault;

    switch (message.status) {
      case MessageStatus.sendSuccess:
        return SvgPicture.asset(
          'chat_assets/icon/message_read_status.svg',
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          package: 'tuikit_atomic_x',
          fit: BoxFit.contain,
        );
      case MessageStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation<Color>(
                isOverlay ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorSecondary),
          ),
        );
      case MessageStatus.sendFail:
        return GestureDetector(
          onTap: onResendTap,
          child: Icon(
            Icons.error_outline,
            size: 14,
            color: colorsTheme.textColorError,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildMessageTimeIndicator({
    required DateTime? dateTime,
    required SemanticColorScheme colorsTheme,
    bool isOverlay = false,
    bool isSelf = false,
  }) {
    if (dateTime == null) return const SizedBox.shrink();

    Color textColor = isOverlay
        ? colorsTheme.textColorAntiPrimary
        : (isSelf ? colorsTheme.textColorAntiSecondary : colorsTheme.textColorTertiary);

    return Text(
      _formatMessageTime(dateTime),
      style: TextStyle(
        fontSize: 12,
        color: textColor,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  List<Widget> buildStatusAndTimeWidgets({
    required MessageInfo message,
    required bool isSelf,
    required SemanticColorScheme colors,
    bool isOverlay = false,
    VoidCallback? onResendTap,
    bool isShowTimeInBubble = true,
  }) {
    final widgets = <Widget>[];

    final statusWidget = buildMessageStatusIndicator(
      message: message,
      isSelf: isSelf,
      colorsTheme: colors,
      isOverlay: isOverlay,
      onResendTap: onResendTap,
    );

    if (statusWidget is! SizedBox || statusWidget.child != null) {
      widgets.add(statusWidget);
      widgets.add(const SizedBox(width: 3));
    }

    if (isShowTimeInBubble) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch((message.timestamp ?? 0) * 1000);
      final timeWidget = buildMessageTimeIndicator(
        dateTime: dateTime,
        colorsTheme: colors,
        isOverlay: isOverlay,
        isSelf: isSelf,
      );

      if (timeWidget is! SizedBox || timeWidget.child != null) {
        widgets.add(timeWidget);
      }
    }

    return widgets;
  }

  String _formatMessageTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
