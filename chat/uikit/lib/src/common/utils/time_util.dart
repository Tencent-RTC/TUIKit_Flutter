import 'package:flutter/widgets.dart';
import '../language/gen/chat_localizations.dart';

/// Controls whether a formatted timestamp keeps the concrete "HH:mm" suffix.
///
/// The conversation list only needs the coarse bucket (yesterday / weekday /
/// date), while the message list timeline always needs the exact clock time
/// appended to it.
enum TimeFormatStyle {
  /// Conversation list: only "yesterday" keeps "HH:mm"; weekday and date do not.
  conversationList,

  /// Message list: every bucket ends with "HH:mm".
  messageList,
}

class TimeUtil {
  /// Formats [timestamp] (in seconds) into a display string.
  ///
  /// Buckets, in order: today -> "HH:mm"; yesterday -> "Yesterday HH:mm";
  /// same week -> weekday; same year -> month/day; otherwise year/month/day.
  /// [style] decides whether the weekday/date buckets keep the "HH:mm" suffix.
  static String convertToFormatTime(
    int timestamp,
    BuildContext context, {
    TimeFormatStyle style = TimeFormatStyle.conversationList,
  }) {
    if (timestamp <= 0) {
      return '';
    }

    if (!context.mounted) {
      return '';
    }

    final ChatLocalizations localizations = ChatLocalizations.of(context);
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final DateTime now = DateTime.now();

    final String timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime messageDay = DateTime(date.year, date.month, date.day);
    final int daysDiff = today.difference(messageDay).inDays;

    if (daysDiff == 0) {
      return timeStr;
    }

    // "Yesterday" always keeps the concrete time in both styles.
    if (daysDiff == 1) {
      return "${localizations.yesterday} $timeStr";
    }

    // Monday-based week start, used to decide whether the date is in this week.
    final DateTime nowWeekStart = today.subtract(Duration(days: (now.weekday + 6) % 7));
    final DateTime dateWeekStart = messageDay.subtract(Duration(days: (date.weekday + 6) % 7));

    if (nowWeekStart == dateWeekStart) {
      final weekdays = [
        localizations.weekdaySunday,
        localizations.weekdayMonday,
        localizations.weekdayTuesday,
        localizations.weekdayWednesday,
        localizations.weekdayThursday,
        localizations.weekdayFriday,
        localizations.weekdaySaturday,
      ];
      return _withTime(weekdays[date.weekday % 7], timeStr, style);
    }

    if (now.year == date.year) {
      return _withTime(
        localizations.dateMonthDayFormat(date.month, date.day),
        timeStr,
        style,
      );
    }

    return _withTime(
      localizations.dateYearMonthDayFormat(date.year, date.month, date.day),
      timeStr,
      style,
    );
  }

  static String _withTime(String datePart, String timeStr, TimeFormatStyle style) {
    return style == TimeFormatStyle.messageList ? "$datePart $timeStr" : datePart;
  }
}
