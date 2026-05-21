import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../config/ai_transcription_config.dart';
import '../config/ai_subtitle_config.dart';
import '../repository/ai_transcriber_repository.dart';
import 'ai_subtitle_item_widget.dart';

/// Multi-speaker subtitle overlay widget.
/// Displays up to `maxVisibleSpeakers` subtitle items with auto-fade support.
class AISubtitleWidget extends StatefulWidget {
  final AITranscriberRepository repository;
  final AISubtitleConfig? config;
  final VoidCallback? onTap;

  const AISubtitleWidget({
    super.key,
    required this.repository,
    this.config,
    this.onTap,
  });

  @override
  State<AISubtitleWidget> createState() => _AISubtitleWidgetState();
}

class _AISubtitleWidgetState extends State<AISubtitleWidget> {
  late AISubtitleConfig _config;
  final List<String> _activeSegmentKeys = [];
  final Map<String, Timer> _fadeOutTimers = {};
  StreamSubscription<AISubtitleDataEvent>? _eventSubscription;
  VoidCallback? _repositoryListener;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? AISubtitleConfig.defaultConfig;
    _config.displayMode = _resolveDisplayMode();
    _bindRepository();
  }

  @override
  void didUpdateWidget(covariant AISubtitleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != null) {
      _config = widget.config!;
    }
    if (oldWidget.repository != widget.repository) {
      _unbindRepository();
      _bindRepository();
    }
  }

  @override
  void dispose() {
    _unbindRepository();
    for (final timer in _fadeOutTimers.values) {
      timer.cancel();
    }
    _fadeOutTimers.clear();
    super.dispose();
  }

  void _bindRepository() {
    _eventSubscription = widget.repository.subtitleEventStream.listen(_handleEvent);
    _repositoryListener = () {
      setState(() {
        _config.displayMode = _resolveDisplayMode();
      });
    };
    widget.repository.addListener(_repositoryListener!);
  }

  DisplayMode _resolveDisplayMode() {
    if (widget.repository.selectedTranslationLanguage == null) {
      return DisplayMode.sourceOnly;
    }
    return widget.repository.isBilingualEnabled ? DisplayMode.dual : DisplayMode.translationOnly;
  }

  void _unbindRepository() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    if (_repositoryListener != null) {
      widget.repository.removeListener(_repositoryListener!);
      _repositoryListener = null;
    }
  }

  void _handleEvent(AISubtitleDataEvent event) {
    switch (event) {
      case AISubtitleDataAdded(data: final data):
        _handleAdded(data);
      case AISubtitleDataUpdated(data: final data):
        _handleUpdated(data);
      case AISubtitleDataCompleted(data: final data):
        if (_config.displayDuration > 0) {
          _scheduleFadeOut(data.segmentId);
        }
        setState(() {});
      case AISubtitleDataClearedAll():
        _clearAll();
    }
  }

  void _handleAdded(AITranscriptionData data) {
    _cancelFadeOutTimer(data.segmentId);
    _activeSegmentKeys.add(data.segmentId);
    _trimExcessSegments();
    if (_config.displayDuration > 0) {
      _scheduleFadeOut(data.segmentId);
    }
    setState(() {});
  }

  void _handleUpdated(AITranscriptionData data) {
    _cancelFadeOutTimer(data.segmentId);
    if (!_activeSegmentKeys.contains(data.segmentId)) {
      _activeSegmentKeys.add(data.segmentId);
      _trimExcessSegments();
    } else {
      _moveToLatest(data.segmentId);
    }
    if (_config.displayDuration > 0) {
      _scheduleFadeOut(data.segmentId);
    }
    setState(() {});
  }

  void _moveToLatest(String segmentId) {
    _activeSegmentKeys.remove(segmentId);
    _activeSegmentKeys.add(segmentId);
  }

  void _trimExcessSegments() {
    final max = _config.maxVisibleSpeakers;
    while (_activeSegmentKeys.length > max) {
      final removed = _activeSegmentKeys.removeAt(0);
      _cancelFadeOutTimer(removed);
    }
  }

  List<String> _visibleSegmentKeys() {
    final max = _config.maxVisibleSpeakers;
    if (max <= 0 || _activeSegmentKeys.length <= max) {
      return List.from(_activeSegmentKeys);
    }
    return _activeSegmentKeys.sublist(_activeSegmentKeys.length - max);
  }

  int _maxLinesForCurrentLayout() {
    return _visibleSegmentKeys().length <= 1 ? 2 : 1;
  }

  void _removeSubtitle(String segmentId) {
    _cancelFadeOutTimer(segmentId);
    setState(() {
      _activeSegmentKeys.remove(segmentId);
    });
  }

  void _clearAll() {
    for (final timer in _fadeOutTimers.values) {
      timer.cancel();
    }
    _fadeOutTimers.clear();
    setState(() {
      _activeSegmentKeys.clear();
    });
  }

  void _scheduleFadeOut(String segmentId) {
    _cancelFadeOutTimer(segmentId);
    final duration = Duration(milliseconds: (_config.displayDuration * 1000).round());
    _fadeOutTimers[segmentId] = Timer(duration, () {
      _fadeOutTimers.remove(segmentId);
      _removeSubtitle(segmentId);
    });
  }

  void _cancelFadeOutTimer(String segmentId) {
    _fadeOutTimers[segmentId]?.cancel();
    _fadeOutTimers.remove(segmentId);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSegmentKeys();
    final maxLines = _maxLinesForCurrentLayout();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _config.backgroundColor,
          borderRadius: BorderRadius.circular(_config.backgroundCornerRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: visible.isEmpty
                  ? SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          RoomLocalizations.of(context)!.roomkit_transcription_ai_subtitle_placeholder,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < visible.length; i++) ...[
                          if (i > 0) SizedBox(height: _config.speakerItemSpacing),
                          _buildItemWidget(visible[i], maxLines),
                        ],
                      ],
                    ),
            ),
            if (visible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Image.asset(
                  RoomImages.aiRightArrow,
                  package: RoomConstants.pluginName,
                  width: 8,
                  height: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(String segmentId, int maxLines) {
    final data = widget.repository.getData(segmentId);
    if (data == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: AISubtitleItemWidget(
        data: data,
        config: _config,
        maxLines: maxLines,
      ),
    );
  }
}
