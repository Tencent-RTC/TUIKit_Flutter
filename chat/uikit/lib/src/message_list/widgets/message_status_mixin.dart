import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import '../../common/language/gen/chat_localizations.dart';

mixin MessageStatusMixin {
  /// Check whether a read-receipt indicator should be displayed for [message].
  static bool shouldShowReadReceipt({
    required MessageInfo message,
    required bool enableReadReceipt,
    bool isInMergedDetailView = false,
  }) {
    if (isInMergedDetailView) return false;
    if (!enableReadReceipt) return false;
    if (!message.isSentBySelf) return false;
    if (!message.needReadReceipt) return false;
    if (message.status != MessageStatus.sendSuccess) return false;
    if (message.messageType == MessageType.tips) return false;
    return true;
  }

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

    switch (message.status) {
      case MessageStatus.sendSuccess:
        // Read receipt is now shown outside the bubble as a text label.
        // No in-bubble icon needed for sendSuccess anymore.
        return const SizedBox.shrink();
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
      style: FontScheme.caption3Regular.copyWith(
        color: textColor,
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

  /// Build read receipt text label to be shown **outside** the bubble (on the left side).
  ///
  /// Rules:
  /// - Only for self-sent, successfully delivered messages with enableReadReceipt = true.
  /// - C2C: peer read → gray "已读", unread → primary color "未读".
  /// - Group: all read → gray "全部已读", partially read → primary color "N人已读",
  ///   no one read → primary color "未读".
  /// - Returns null when nothing should be shown.
  Widget? buildOutsideReadReceiptLabel({
    required MessageInfo message,
    required SemanticColorScheme colorsTheme,
    required ChatLocalizations locale,
    required bool enableReadReceipt,
    bool isInMergedDetailView = false,
    VoidCallback? onTap,
  }) {
    if (!shouldShowReadReceipt(
      message: message,
      enableReadReceipt: enableReadReceipt,
      isInMergedDetailView: isInMergedDetailView,
    )) {
      return null;
    }

    final isGroup = message.conversationType == ConversationType.group;

    String text;
    if (!isGroup) {
      // C2C conversation: "已读" / "未读"
      text = message.readReceiptInfo?.isPeerRead == true ? locale.groupReadBy : locale.groupDeliveredTo;
    } else {
      // Group conversation: "全部已读" / "N人已读" / "未读"
      final readCount = message.readReceiptInfo?.readCount ?? 0;
      final unreadCount = message.readReceiptInfo?.unreadCount ?? 0;
      final totalCount = readCount + unreadCount;

      if (totalCount > 0 && readCount == totalCount) {
        text = locale.readReceiptAllRead;
      } else if (readCount > 0) {
        text = locale.readReceiptNPersonRead(readCount);
      } else {
        text = locale.groupDeliveredTo;
      }
    }

    final textWidget = Text(
      text,
      style: FontScheme.caption3Regular.copyWith(
        color: colorsTheme.textColorTertiary,
      ),
    );

    // Group messages: tappable to show read receipt detail
    if (isGroup && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
