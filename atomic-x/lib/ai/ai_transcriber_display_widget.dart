import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import '../base_component/localizations/atomic_localizations.dart';

class AITranscriberDisplayWidget extends StatefulWidget {
  final bool showBilingual;
  final TranslationLanguage? displayTranslationLanguage;
  final VoidCallback? onArrowTap;
  final double maxHeightRatio;

  const AITranscriberDisplayWidget({
    super.key,
    this.showBilingual = true,
    this.displayTranslationLanguage,
    this.onArrowTap,
    this.maxHeightRatio = 0.15,
  });

  @override
  State<AITranscriberDisplayWidget> createState() => AITranscriberDisplayWidgetState();
}

class AITranscriberDisplayWidgetState extends State<AITranscriberDisplayWidget> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _isAtBottom = true;

  ValueListenable<List<TranscriberMessage>> get _messageListenable {
    return AITranscriberStore.shared.transcriberState.realtimeMessageList;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScrollChanged);
    _messageListenable.addListener(_onMessageListChanged);
    _lastMessageCount = _messageListenable.value.length;
    _scrollToBottom();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScrollChanged);
    _messageListenable.removeListener(_onMessageListChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scrollToBottom();
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = (maxScroll - currentScroll) < 50;
    
    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });
    }
  }

  void _onMessageListChanged() {
    final messages = _messageListenable.value;
    final hasNewMessage = messages.length != _lastMessageCount;
    _lastMessageCount = messages.length;
    
    if (_isAtBottom) {
      _scrollToBottom();
    } else if (hasNewMessage) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void scrollToBottom() {
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TranscriberMessage>>(
      valueListenable: _messageListenable,
      builder: (context, messages, child) {
        return _buildSubtitleContainer(context, messages);
      },
    );
  }

  Widget _buildSubtitleContainer(BuildContext context, List<TranscriberMessage> messages) {
    final effectiveMaxHeight = MediaQuery.of(context).size.height * widget.maxHeightRatio;

    return GestureDetector(
      onTap: widget.onArrowTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12).add(const EdgeInsets.only(right: 24)),
              child: messages.isEmpty
                  ? const SizedBox(height: 40)
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final previousSpeakerId = index > 0 ? messages[index - 1].speakerUserId : null;
                        return _buildSubtitleItem(context, messages[index], index, messages.length, previousSpeakerId);
                      },
                    ),
            ),
            if (widget.onArrowTap != null)
              const Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleItem(BuildContext context, TranscriberMessage message, int index, int totalCount, String? previousSpeakerId) {
    final isLastItem = index == totalCount - 1;
    final translationText = _getTranslationText(message);
    final isSelf = _isSelfMessage(message);
    final showSpeakerName = previousSpeakerId != message.speakerUserId;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLastItem ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSpeakerName) ...[
            _buildSpeakerName(context, message, isSelf),
            const SizedBox(height: 2),
          ],
          if (widget.showBilingual) ...[
            _buildSourceText(message),
            if (translationText.isNotEmpty) ...[
              const SizedBox(height: 2),
              _buildTranslationText(translationText),
            ],
          ] else ...[
            if (translationText.isNotEmpty)
              _buildTranslationText(translationText)
            else
              _buildSourceText(message),
          ],
        ],
      ),
    );
  }

  bool _isSelfMessage(TranscriberMessage message) {
    try {
      final selfUserId = CallStore.shared.state.selfInfo.value.id;
      return message.speakerUserId == selfUserId;
    } catch (e) {
      return false;
    }
  }

  String _getTranslationText(TranscriberMessage message) {
    if (message.translationTexts.isEmpty) {
      return '';
    }
    
    if (widget.displayTranslationLanguage != null) {
      return message.translationTexts[widget.displayTranslationLanguage] 
          ?? message.translationTexts.values.first;
    }
    
    return message.translationTexts.values.first;
  }

  Widget _buildSpeakerName(BuildContext context, TranscriberMessage message, bool isSelf) {
    final displayName = message.speakerUserName.isNotEmpty 
        ? message.speakerUserName 
        : message.speakerUserId;
    final locale = AtomicLocalizations.of(context);
    final nameText = isSelf ? '$displayName ${locale.aiSubtitleMe}:' : '$displayName:';
    
    return Text(
      nameText,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildSourceText(TranscriberMessage message) {
    return Text(
      message.sourceText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildTranslationText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }
}
