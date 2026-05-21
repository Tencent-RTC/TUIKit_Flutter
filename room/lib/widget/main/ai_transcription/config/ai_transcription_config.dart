import 'dart:ui';

import 'package:flutter/material.dart';

/// Transcription data for a single subtitle/minutes segment.
class AITranscriptionData {
  final String segmentId;
  final String speakerUserId;
  final String speakerUserName;
  final String sourceText;
  final String translationText;
  final int timestamp;
  final bool isCompleted;

  AITranscriptionData({
    this.segmentId = '',
    this.speakerUserId = '',
    this.speakerUserName = '',
    this.sourceText = '',
    this.translationText = '',
    this.timestamp = 0,
    this.isCompleted = false,
  });

  AITranscriptionData copyWith({
    String? segmentId,
    String? speakerUserId,
    String? speakerUserName,
    String? sourceText,
    String? translationText,
    int? timestamp,
    bool? isCompleted,
  }) {
    return AITranscriptionData(
      segmentId: segmentId ?? this.segmentId,
      speakerUserId: speakerUserId ?? this.speakerUserId,
      speakerUserName: speakerUserName ?? this.speakerUserName,
      sourceText: sourceText ?? this.sourceText,
      translationText: translationText ?? this.translationText,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITranscriptionData &&
          runtimeType == other.runtimeType &&
          segmentId == other.segmentId &&
          speakerUserId == other.speakerUserId &&
          speakerUserName == other.speakerUserName &&
          sourceText == other.sourceText &&
          translationText == other.translationText &&
          timestamp == other.timestamp &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        segmentId,
        speakerUserId,
        speakerUserName,
        sourceText,
        translationText,
        timestamp,
        isCompleted,
      );
}

/// Display mode for subtitle and minutes views.
enum DisplayMode {
  sourceOnly,
  translationOnly,

  /// Dual-language: source on top, translation below.
  dual,

  /// Dual-language reversed: translation on top, source below (subtitle only).
  dualReversed,
}

/// Text appearance configuration shared by subtitle and minutes views.
class AITextStyle {
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final Color shadowColor;
  final Offset shadowOffset;
  final double shadowRadius;

  const AITextStyle({
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.shadowColor = const Color(0x99000000),
    this.shadowOffset = const Offset(0, 1),
    this.shadowRadius = 2,
  });

  TextStyle toTextStyle() {
    return TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: [
        Shadow(
          color: shadowColor,
          offset: shadowOffset,
          blurRadius: shadowRadius,
        ),
      ],
    );
  }

  TextStyle toTextStyleWithoutShadow() {
    return TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}

/// Speaker label appearance configuration.
class SpeakerStyle {
  final Color nameColor;
  final double nameFontSize;
  final FontWeight nameFontWeight;
  final Color timestampColor;
  final double timestampFontSize;
  final FontWeight timestampFontWeight;
  final double nameTimestampSpacing;
  final double bottomSpacing;

  const SpeakerStyle({
    this.nameColor = const Color(0xB3FFFFFF),
    this.nameFontSize = 16.0,
    this.nameFontWeight = FontWeight.normal,
    this.timestampColor = const Color(0xFF4D99FF),
    this.timestampFontSize = 14,
    this.timestampFontWeight = FontWeight.normal,
    this.nameTimestampSpacing = 8,
    this.bottomSpacing = 2,
  });
}

/// Avatar appearance configuration (used by subtitle view).
class AvatarStyle {
  final double size;
  final double spacing;
  final String? placeholderAsset;
  final double topOffset;

  const AvatarStyle({
    this.size = 32,
    this.spacing = 8,
    this.placeholderAsset,
    this.topOffset = 0,
  });
}

/// Data change events published by the repository.
sealed class AISubtitleDataEvent {
  const AISubtitleDataEvent();
}

class AISubtitleDataAdded extends AISubtitleDataEvent {
  final AITranscriptionData data;
  const AISubtitleDataAdded(this.data);
}

class AISubtitleDataUpdated extends AISubtitleDataEvent {
  final AITranscriptionData data;
  const AISubtitleDataUpdated(this.data);
}

class AISubtitleDataCompleted extends AISubtitleDataEvent {
  final AITranscriptionData data;
  const AISubtitleDataCompleted(this.data);
}

class AISubtitleDataClearedAll extends AISubtitleDataEvent {
  const AISubtitleDataClearedAll();
}
