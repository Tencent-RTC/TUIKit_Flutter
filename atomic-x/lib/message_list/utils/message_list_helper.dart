import 'package:atomic_x_core/atomicxcore.dart';

class MessageListHelper {
  static bool shouldShowReadReceipt({
    required MessageInfo message,
    required bool enableReadReceipt,
    bool isInMergedDetailView = false,
  }) {
    if (isInMergedDetailView) {
      return false;
    }

    if (!enableReadReceipt) {
      return false;
    }

    if (!message.isSelf) {
      return false;
    }

    if (!message.needReadReceipt) {
      return false;
    }

    if (message.status != MessageStatus.sendSuccess) {
      return false;
    }

    if (message.messageType == MessageType.system) {
      return false;
    }

    return true;
  }

  /// c2c:
  /// - read: read_receipt_check (Single gray hook)
  /// - unread: read_receipt_check_all_highlight (Two blue hooks)
  /// group:
  /// - all read (readCount = 0): read_receipt_check (Single gray hook)
  /// - Partially read (0 < readCount < totalCount): read_receipt_check_all (Two gray hooks)
  /// - all read (readCount = totalCount): read_receipt_check_all_highlight (Two blue hooks)
  static String getReceiptIconName(MessageInfo message) {
    if (message.groupID == null || message.groupID!.isEmpty) {
      if (message.receipt?.isPeerRead == true) {
        return 'read_receipt_check_all_highlight';
      } else {
        return 'read_receipt_check';
      }
    }
    
    final readCount = message.receipt?.readCount ?? 0;
    final unreadCount = message.receipt?.unreadCount ?? 0;
    final totalCount = readCount + unreadCount;

    if (readCount == 0) {
      return 'read_receipt_check';
    } else if (readCount == totalCount && totalCount > 0) {
      return 'read_receipt_check_all_highlight';
    } else {
      return 'read_receipt_check_all';
    }
  }
}
