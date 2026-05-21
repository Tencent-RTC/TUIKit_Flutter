import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../config/ai_transcription_config.dart';
import '../config/ai_minutes_config.dart';
import '../repository/ai_transcriber_repository.dart';

/// Scrollable list widget displaying all AI transcription minutes entries.
class AIMinutesWidget extends StatefulWidget {
  final AITranscriberRepository repository;
  final AIMinutesConfig? config;
  final VoidCallback? onBackTap;

  const AIMinutesWidget({
    super.key,
    required this.repository,
    this.config,
    this.onBackTap,
  });

  @override
  State<AIMinutesWidget> createState() => _AIMinutesWidgetState();
}

class _AIMinutesWidgetState extends State<AIMinutesWidget> {
  late AIMinutesConfig _config;
  final List<String> _segmentIds = [];
  final Map<String, int> _segmentIndexMap = {};
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<AISubtitleDataEvent>? _eventSubscription;
  VoidCallback? _repositoryListener;

  bool _isUserDragging = false;
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? AIMinutesConfig.defaultConfig;
    _config.displayMode = _resolveDisplayMode();
    _scrollController.addListener(_onScroll);
    _bindRepository();
    _syncFromRepository();
  }

  @override
  void didUpdateWidget(covariant AIMinutesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != null) {
      _config = widget.config!;
    }
    if (oldWidget.repository != widget.repository) {
      _unbindRepository();
      _bindRepository();
      _syncFromRepository();
    }
  }

  @override
  void dispose() {
    _unbindRepository();
    _scrollController.dispose();
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

  void _syncFromRepository() {
    final repo = widget.repository;
    _segmentIds.clear();
    _segmentIndexMap.clear();
    _segmentIds.addAll(repo.orderedSegmentIds);
    for (int i = 0; i < _segmentIds.length; i++) {
      _segmentIndexMap[_segmentIds[i]] = i;
    }
    setState(() {});
    if (_segmentIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    }
  }

  void _handleEvent(AISubtitleDataEvent event) {
    switch (event) {
      case AISubtitleDataAdded(data: final data):
        setState(() {
          final index = _segmentIds.length;
          _segmentIds.add(data.segmentId);
          _segmentIndexMap[data.segmentId] = index;
        });
        if (_isNearBottom && !_isUserDragging) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(animated: true);
          });
        }
      case AISubtitleDataUpdated():
      case AISubtitleDataCompleted():
        setState(() {});
        if (_isNearBottom && !_isUserDragging) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(animated: false);
          });
        }
      case AISubtitleDataClearedAll():
        setState(() {
          _segmentIds.clear();
          _segmentIndexMap.clear();
        });
    }
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    _isNearBottom = distanceFromBottom <= 40;
  }

  /// Determines whether the cell at the given index should display speaker name and timestamp.
  /// Returns false when the previous cell belongs to the same speaker and the time gap is ≤ 60 seconds.
  bool _shouldShowSpeakerInfo(int index, AITranscriptionData currentData) {
    if (index <= 0) return true;
    final previousSegmentId = _segmentIds[index - 1];
    final previousData = widget.repository.getData(previousSegmentId);
    if (previousData == null) return true;

    final isSameSpeaker = previousData.speakerUserId == currentData.speakerUserId;
    final timeDiffMs = (currentData.timestamp - previousData.timestamp).abs();
    final isWithin60Seconds = timeDiffMs <= 60000;

    return !(isSameSpeaker && isWithin60Seconds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _config.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onBackTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Image.asset(
                RoomImages.backArrow,
                package: RoomConstants.pluginName,
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              RoomLocalizations.of(context)!.roomkit_transcription_ai_minutes_title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: RoomColors.g2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification && notification.dragDetails != null) {
          _isUserDragging = true;
        } else if (notification is ScrollEndNotification) {
          _isUserDragging = false;
          _onScroll();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: _config.listContentInsets,
        itemCount: _segmentIds.length,
        itemBuilder: (context, index) {
          final segmentId = _segmentIds[index];
          final data = widget.repository.getData(segmentId);
          if (data == null) return const SizedBox.shrink();
          final showSpeakerInfo = _shouldShowSpeakerInfo(index, data);
          return _AIMinutesCellWidget(data: data, config: _config, showSpeakerInfo: showSpeakerInfo);
        },
      ),
    );
  }
}

/// Single minutes cell widget.
class _AIMinutesCellWidget extends StatelessWidget {
  final AITranscriptionData data;
  final AIMinutesConfig config;
  final bool showSpeakerInfo;

  const _AIMinutesCellWidget({
    required this.data,
    required this.config,
    this.showSpeakerInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: config.itemContentInsets.left,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSpeakerInfo && config.showSpeaker && data.speakerUserName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSpeakerRow(),
            SizedBox(height: config.speakerStyle.bottomSpacing),
          ] else ...[
            const SizedBox(height: 10),
          ],
          Container(
            width: double.infinity,
            padding: config.itemContentInsets,
            decoration: BoxDecoration(
              color: config.itemBackgroundColor,
              borderRadius: BorderRadius.circular(config.itemCornerRadius),
            ),
            child: _buildTextContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerRow() {
    return Row(
      children: [
        Text(
          data.speakerUserName,
          style: TextStyle(
            color: config.speakerStyle.nameColor,
            fontSize: config.speakerStyle.nameFontSize,
            fontWeight: config.speakerStyle.nameFontWeight,
          ),
        ),
        if (showSpeakerInfo && config.showTimestamp && data.timestamp > 0) ...[
          SizedBox(width: config.speakerStyle.nameTimestampSpacing),
          Text(
            config.formatTimestamp(data.timestamp),
            style: TextStyle(
              color: config.speakerStyle.timestampColor,
              fontSize: config.speakerStyle.timestampFontSize,
              fontWeight: config.speakerStyle.timestampFontWeight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextContent() {
    final widgets = <Widget>[];

    final showSource = config.displayMode != DisplayMode.translationOnly && data.sourceText.isNotEmpty;
    final showTranslation = config.displayMode != DisplayMode.sourceOnly && data.translationText.isNotEmpty;

    if (showSource) {
      widgets.add(Text(
        data.sourceText,
        style: config.sourceStyle.toTextStyleWithoutShadow(),
      ));
    }

    if (showSource && showTranslation) {
      widgets.add(SizedBox(height: config.lineSpacing));
    }

    if (showTranslation) {
      widgets.add(Text(
        data.translationText,
        style: config.translationStyle.toTextStyleWithoutShadow(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
