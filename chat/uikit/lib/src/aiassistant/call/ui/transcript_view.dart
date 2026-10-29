import 'package:flutter/material.dart';

import '../ai_call_state.dart';

/// Conversation list of the call page's subtitle mode.
///
/// The data does not come from a Store: the user side is the ASR result
/// joined by chunkIndex, the AI side the stream message markdown, both kept by
/// the call controller so subtitles and audio share one state.
class TranscriptView extends StatefulWidget {
  const TranscriptView({super.key, required this.entries});

  final List<TranscriptEntry> entries;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  static const Color _colorUser = Color(0xFF8A9099);
  static const Color _colorAssistant = Color(0xFFF2F4F6);
  static const Color _colorFailed = Color(0xFFFF5A5F);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant TranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries)) {
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          // User speech is dimmed gray, the AI answer bright white, failures red.
          final color = entry.isFailed
              ? _colorFailed
              : entry.isFromUser
                  ? _colorUser
                  : _colorAssistant;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(entry.text,
                style: TextStyle(fontSize: 16, height: 1.4, color: color)),
          );
        },
      ),
    );
  }
}
