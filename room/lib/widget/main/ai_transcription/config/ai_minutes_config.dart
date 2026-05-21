import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'ai_transcription_config.dart';

/// Configuration for the AI minutes list view.
class AIMinutesConfig {
  DisplayMode displayMode;
  final AITextStyle sourceStyle;
  final AITextStyle translationStyle;
  final SpeakerStyle speakerStyle;
  final bool showSpeaker;
  final bool showTimestamp;
  final Color backgroundColor;
  final Color itemBackgroundColor;
  final double itemCornerRadius;
  final EdgeInsets itemContentInsets;
  final double itemSpacing;
  final double lineSpacing;
  final EdgeInsets listContentInsets;

  /// Custom timestamp formatter. Receives millisecond timestamp, returns formatted string.
  final String Function(int)? timestampFormatter;

  AIMinutesConfig({
    this.displayMode = DisplayMode.dual,
    this.sourceStyle = const AITextStyle(
      textColor: Color(0xFF22262E),
      fontSize: 15,
      fontWeight: FontWeight.normal,
      shadowColor: Colors.transparent,
    ),
    this.translationStyle = const AITextStyle(
      textColor: Color(0x9922262E),
      fontSize: 12,
      fontWeight: FontWeight.normal,
      shadowColor: Colors.transparent,
    ),
    this.speakerStyle = const SpeakerStyle(
      nameColor: Color(0xFF22262E),
      nameFontSize: 14,
      nameFontWeight: FontWeight.w500,
      timestampColor: Color(0xFF8F8F94),
      timestampFontSize: 13,
      timestampFontWeight: FontWeight.normal,
      nameTimestampSpacing: 6,
      bottomSpacing: 8,
    ),
    this.showSpeaker = true,
    this.showTimestamp = true,
    this.backgroundColor = Colors.white,
    this.itemBackgroundColor = const Color(0xFFF2F5FA),
    this.itemCornerRadius = 10,
    this.itemContentInsets = const EdgeInsets.all(12),
    this.itemSpacing = 0,
    this.lineSpacing = 12,
    this.listContentInsets = const EdgeInsets.fromLTRB(0, 0, 0, 12),
    this.timestampFormatter,
  });

  static AIMinutesConfig get defaultConfig => AIMinutesConfig();

  String formatTimestamp(int timestamp) {
    if (timestampFormatter != null) {
      return timestampFormatter!(timestamp);
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MM-dd HH:mm').format(date);
  }
}
