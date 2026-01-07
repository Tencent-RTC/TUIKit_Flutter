import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_list_helper.dart';

mixin MessageStatusMixin {
  /// Build status indicator (sendFail, violation, or sending) - to be shown outside bubble
  /// Returns null if no status to show
  Widget? buildOutsideBubbleStatusIndicator({
    required MessageInfo message,
    required SemanticColorScheme colorsTheme,
    VoidCallback? onResendTap,
  }) {
    switch (message.status) {
      case MessageStatus.sendFail:
      case MessageStatus.violation:
        return GestureDetector(
          onTap: onResendTap,
          child: Icon(
            Icons.error,
            size: 18,
            color: colorsTheme.textColorError,
          ),
        );
      case MessageStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.textColorSecondary),
          ),
        );
      default:
        return null;
    }
  }

  /// Check if message has error status (sendFail or violation)
  bool hasErrorStatus(MessageInfo message) {
    return message.status == MessageStatus.sendFail || message.status == MessageStatus.violation;
  }

  /// Check if message status should be shown outside bubble
  bool shouldShowStatusOutsideBubble(MessageInfo message) {
    return message.status == MessageStatus.sendFail ||
        message.status == MessageStatus.violation ||
        message.status == MessageStatus.sending;
  }

  Widget buildMessageStatusIndicator({
    required MessageInfo message,
    required bool isSelf,
    required SemanticColorScheme colorsTheme,
    bool isOverlay = false,
    VoidCallback? onResendTap,
    bool enableReadReceipt = false,
    bool isInMergedDetailView = false,
  }) {
    if (!isSelf) return const SizedBox.shrink();

    Color iconColor = isOverlay ? colorsTheme.textColorAntiPrimary : colorsTheme.buttonColorPrimaryDefault;

    switch (message.status) {
      case MessageStatus.sendSuccess:
        // In merged detail view, don't show any read status indicator
        if (isInMergedDetailView) {
          return const SizedBox.shrink();
        }
        if (MessageListHelper.shouldShowReadReceipt(
          message: message,
          enableReadReceipt: enableReadReceipt,
        )) {
          return buildReadReceiptIndicator(
            message: message,
            enableReadReceipt: enableReadReceipt,
            colorsTheme: colorsTheme,
            isOverlay: isOverlay,
          );
        }
        return SvgPicture.asset(
          'chat_assets/icon/message_read_status.svg',
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          package: 'tuikit_atomic_x',
          fit: BoxFit.contain,
        );
      case MessageStatus.sending:
      case MessageStatus.sendFail:
      case MessageStatus.violation:
        // These status icons are now shown outside the bubble in message_item.dart
        return const SizedBox.shrink();
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
    bool enableReadReceipt = false,
    bool isInMergedDetailView = false,
  }) {
    final widgets = <Widget>[];

    final statusWidget = buildMessageStatusIndicator(
      message: message,
      isSelf: isSelf,
      colorsTheme: colors,
      isOverlay: isOverlay,
      onResendTap: onResendTap,
      enableReadReceipt: enableReadReceipt,
      isInMergedDetailView: isInMergedDetailView,
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

  /// 构建已读回执指示器
  Widget buildReadReceiptIndicator({
    required MessageInfo message,
    required bool enableReadReceipt,
    required SemanticColorScheme colorsTheme,
    bool isOverlay = false,
  }) {
    if (!MessageListHelper.shouldShowReadReceipt(
      message: message,
      enableReadReceipt: enableReadReceipt,
    )) {
      return const SizedBox.shrink();
    }

    final iconName = MessageListHelper.getReceiptIconName(message);
    final isHighlight = iconName == 'read_receipt_check_all_highlight';

    // 高亮图标使用固定颜色，其他图标使用主题颜色
    if (isHighlight) {
      return SvgPicture.asset(
        'chat_assets/icon/$iconName.svg',
        width: 14,
        height: 14,
        package: 'tuikit_atomic_x',
        fit: BoxFit.contain,
      );
    }

    Color iconColor = colorsTheme.textColorAntiPrimary;

    return SvgPicture.asset(
      'chat_assets/icon/$iconName.svg',
      width: 14,
      height: 14,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      package: 'tuikit_atomic_x',
      fit: BoxFit.contain,
    );
  }
}
