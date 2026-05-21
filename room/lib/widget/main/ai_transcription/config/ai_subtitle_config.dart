import 'package:flutter/material.dart';

import 'ai_transcription_config.dart';

/// Configuration for the real-time subtitle overlay view.
class AISubtitleConfig {
  DisplayMode displayMode;
  final AITextStyle sourceStyle;
  final AITextStyle translationStyle;
  final SpeakerStyle speakerStyle;
  final bool showSpeaker;
  final AvatarStyle avatarStyle;
  final bool showAvatar;
  final Color backgroundColor;
  final double backgroundCornerRadius;
  final EdgeInsets contentInsets;
  final double lineSpacing;

  /// Auto-fade duration in seconds. 0 disables auto-fade.
  final double fadeOutDuration;

  /// Display hold time in seconds before fade-out begins.
  final double displayDuration;

  /// Per-character streaming animation interval in seconds.
  final double streamAnimationDuration;

  /// Maximum width ratio relative to the parent view.
  final double maxWidthRatio;

  /// Maximum number of visible speaker subtitle cells.
  final int maxVisibleSpeakers;

  /// Spacing between speaker subtitle items.
  final double speakerItemSpacing;

  AISubtitleConfig({
    this.displayMode = DisplayMode.dual,
    this.sourceStyle = const AITextStyle(
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    this.translationStyle = const AITextStyle(
      textColor: Color(0xB3FFFFFF),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    this.speakerStyle = const SpeakerStyle(),
    this.showSpeaker = true,
    this.avatarStyle = const AvatarStyle(),
    this.showAvatar = false,
    this.backgroundColor = const Color(0x80000000),
    this.backgroundCornerRadius = 8,
    this.contentInsets = const EdgeInsets.fromLTRB(12, 8, 12, 8),
    this.lineSpacing = 4,
    this.fadeOutDuration = 0.5,
    this.displayDuration = 5.0,
    this.streamAnimationDuration = 0.03,
    this.maxWidthRatio = 0.9,
    this.maxVisibleSpeakers = 2,
    this.speakerItemSpacing = 8,
  });

  static AISubtitleConfig get defaultConfig => AISubtitleConfig();
}
