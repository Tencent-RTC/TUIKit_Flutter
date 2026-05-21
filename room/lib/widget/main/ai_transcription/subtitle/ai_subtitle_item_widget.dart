import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../config/ai_transcription_config.dart';
import '../config/ai_subtitle_config.dart';
import 'ai_subtitle_line_widget.dart';

/// Single-speaker subtitle item widget with avatar, speaker label, and dual-line subtitles.
class AISubtitleItemWidget extends StatefulWidget {
  final AITranscriptionData data;
  final AISubtitleConfig config;
  final int maxLines;

  const AISubtitleItemWidget({
    super.key,
    required this.data,
    required this.config,
    this.maxLines = 2,
  });

  @override
  State<AISubtitleItemWidget> createState() => _AISubtitleItemWidgetState();
}

class _AISubtitleItemWidgetState extends State<AISubtitleItemWidget> {
  final GlobalKey<AISubtitleLineWidgetState> _sourceLineKey = GlobalKey();
  final GlobalKey<AISubtitleLineWidgetState> _translationLineKey = GlobalKey();

  AISubtitleConfig get config => widget.config;
  AITranscriptionData get data => widget.data;

  /// Track displayMode separately so that didUpdateWidget can detect changes
  /// even when oldWidget.config and widget.config are the same object reference.
  late DisplayMode _previousDisplayMode;

  @override
  void initState() {
    super.initState();
    _previousDisplayMode = widget.config.displayMode;
  }

  @override
  void didUpdateWidget(covariant AISubtitleItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final displayModeChanged = _previousDisplayMode != widget.config.displayMode;
    _previousDisplayMode = widget.config.displayMode;
    if (oldWidget.data != widget.data || displayModeChanged) {
      _updateTexts();
    }
  }

  void _updateTexts() {
    if (config.displayMode != DisplayMode.translationOnly) {
      _sourceLineKey.currentState?.updateText(data.sourceText, animated: false);
    }
    if (config.displayMode != DisplayMode.sourceOnly) {
      _translationLineKey.currentState?.updateText(data.translationText, animated: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: config.contentInsets,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showAvatar) ...[
            ClipOval(
              child: Container(
                width: config.avatarStyle.size,
                height: config.avatarStyle.size,
                color: RoomColors.buttonGrey,
                child: config.avatarStyle.placeholderAsset != null
                    ? Image.asset(config.avatarStyle.placeholderAsset!)
                    : Icon(Icons.person, color: RoomColors.white, size: 20),
              ),
            ),
            SizedBox(width: config.avatarStyle.spacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config.showSpeaker && data.speakerUserName.isNotEmpty) ...[
                  Text(
                    data.speakerUserName,
                    style: TextStyle(
                      color: config.speakerStyle.nameColor,
                      fontSize: config.speakerStyle.nameFontSize,
                      fontWeight: config.speakerStyle.nameFontWeight,
                    ),
                  ),
                  SizedBox(height: config.speakerStyle.bottomSpacing),
                ],
                ..._buildTextLines(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTextLines() {
    final widgets = <Widget>[];
    switch (config.displayMode) {
      case DisplayMode.sourceOnly:
        widgets.add(AISubtitleLineWidget(
          key: _sourceLineKey,
          textStyle: config.sourceStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.sourceText,
        ));
      case DisplayMode.translationOnly:
        widgets.add(AISubtitleLineWidget(
          key: _translationLineKey,
          textStyle: config.translationStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.translationText,
        ));
      case DisplayMode.dual:
        widgets.add(AISubtitleLineWidget(
          key: _sourceLineKey,
          textStyle: config.sourceStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.sourceText,
        ));
        widgets.add(SizedBox(height: config.lineSpacing));
        widgets.add(AISubtitleLineWidget(
          key: _translationLineKey,
          textStyle: config.translationStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.translationText,
        ));
      case DisplayMode.dualReversed:
        widgets.add(AISubtitleLineWidget(
          key: _translationLineKey,
          textStyle: config.translationStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.translationText,
        ));
        widgets.add(SizedBox(height: config.lineSpacing));
        widgets.add(AISubtitleLineWidget(
          key: _sourceLineKey,
          textStyle: config.sourceStyle,
          streamAnimationDuration: config.streamAnimationDuration,
          maxLines: widget.maxLines,
          initialText: data.sourceText,
        ));
    }
    return widgets;
  }
}
