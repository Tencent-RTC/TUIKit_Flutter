import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_input/src/chat_special_text_span_builder.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_text_parser.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_status_mixin.dart';
import 'package:tuikit_atomic_x/third_party/extended_text/extended_text.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

typedef BackgroundBuilder = Widget Function(Widget child);

class TextMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String>? onLinkTapped;
  final GlobalKey? bubbleKey;
  final BackgroundBuilder? backgroundBuilder;
  final VoidCallback? onResendTap;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;
  // Translation related properties
  final bool isTranslating;
  /// Whether the translation bubble is hidden in this session (default: false, meaning shown if translatedText exists)
  final bool isTranslationHidden;
  /// Callback when translation bubble is long pressed, provides the GlobalKey for positioning popup menu
  final void Function(GlobalKey translationBubbleKey)? onTranslationBubbleLongPress;

  const TextMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onTap,
    this.onLongPress,
    this.onLinkTapped,
    this.bubbleKey,
    this.backgroundBuilder,
    this.onResendTap,
    this.isInMergedDetailView = false,
    this.isTranslating = false,
    this.isTranslationHidden = false,
    this.onTranslationBubbleLongPress,
  });

  @override
  State<TextMessageWidget> createState() => _TextMessageWidgetState();
}

class _TextMessageWidgetState extends State<TextMessageWidget> with MessageStatusMixin {
  final GlobalKey _translationBubbleKey = GlobalKey();
  
  // Local state for @ user names (loaded async)
  List<String>? _atUserNames;
  // Whether @ user names have been loaded (null means not loaded yet)
  bool _atUserNamesLoaded = false;
  // Whether we're currently loading @ user names
  bool _isLoadingAtUserNames = false;

  /// Check if message has @ users that need to be resolved
  bool get _hasAtUsers => widget.message.atUserList.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAtUserNamesIfNeeded();
  }

  @override
  void didUpdateWidget(TextMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If message changed, reset and reload
    if (oldWidget.message.msgID != widget.message.msgID) {
      _atUserNames = null;
      _atUserNamesLoaded = false;
      _isLoadingAtUserNames = false;
      _loadAtUserNamesIfNeeded();
    }
    // If translation appeared (or isTranslating changed to false), load if not loaded yet
    // This handles the case when translation completes and we need to load @ user names
    else if (!_atUserNamesLoaded && !_isLoadingAtUserNames) {
      final newHasTranslation = widget.message.messageBody?.translatedText?.isNotEmpty == true;
      if (newHasTranslation) {
        _loadAtUserNamesIfNeeded();
      }
    }
  }

  /// Load @ user names if needed (when showing translation and message has @ users)
  void _loadAtUserNamesIfNeeded() {
    // Check if we need to show translation
    final translatedTextMap = widget.message.messageBody?.translatedText;
    final hasTranslation = translatedTextMap != null && translatedTextMap.isNotEmpty;
    
    // If no translation or already loaded, skip
    if (!hasTranslation || _atUserNamesLoaded || _isLoadingAtUserNames) {
      return;
    }
    
    // If message has no @ users, mark as loaded immediately (no need to fetch)
    if (!_hasAtUsers) {
      _atUserNamesLoaded = true;
      return;
    }
    
    // Need to load @ user names
    _isLoadingAtUserNames = true;
    
    // Use post-frame callback to get localization context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final localizations = AtomicLocalizations.of(context);
      final atUserNames = await TranslationTextParser.getAtUserNames(
        widget.message,
        allMembersText: localizations.messageInputAllMembers,
      );
      
      if (mounted) {
        setState(() {
          _atUserNames = atUserNames;
          _atUserNamesLoaded = true;
          _isLoadingAtUserNames = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    final content = Container(
      key: widget.bubbleKey,
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _buildTextWithStatusAndTime(colors),
    );

    final bubble = widget.backgroundBuilder?.call(content) ??
        Container(
          decoration: BoxDecoration(
            color: _getBubbleColor(colors),
            borderRadius: _getBubbleBorderRadius(),
          ),
          child: content,
        );

    final mainBubble = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: bubble,
    );

    // Check if we need to show translation bubble
    final translatedTextMap = widget.message.messageBody?.translatedText;
    final hasTranslation = translatedTextMap != null && translatedTextMap.isNotEmpty;
    
    // Show translation bubble only when:
    // 1. isTranslating (loading state) OR
    // 2. Has translation AND not hidden AND @ user names loaded
    final shouldShowTranslation = !widget.isTranslationHidden &&
        (widget.isTranslating || (hasTranslation && _atUserNamesLoaded));

    if (!shouldShowTranslation) {
      return mainBubble;
    }

    // Build translation bubble below main bubble
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        mainBubble,
        const SizedBox(height: 4),
        _buildTranslationBubble(colors, translatedTextMap),
      ],
    );
  }

  Widget _buildTranslationBubble(SemanticColorScheme colors, Map<String, String>? translatedTextMap) {
    final localizations = AtomicLocalizations.of(context);

    Widget bubbleContent;
    if (widget.isTranslating) {
      // Show loading state
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.textColorSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            localizations.translating,
            style: TextStyle(
              color: colors.textColorSecondary,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      // Use loaded @ user names
      final originalText = widget.message.messageBody?.text ?? '';
      final translatedDisplayText = TranslationTextParser.buildTranslatedDisplayText(
        originalText,
        translatedTextMap ?? {},
        _atUserNames,
      );
      
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Translated text content
          ExtendedText(
            _getContentSpan(translatedDisplayText, colors),
            onSpecialTextTap: (dynamic parameter) {
              if (parameter.toString().startsWith('\$')) {
                widget.onLinkTapped?.call((parameter.toString()).replaceAll('\$', ''));
              }
            },
            specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
              colorScheme: colors,
              onTapUrl: widget.onLinkTapped ?? (_) {},
              showAtBackground: true,
            ),
            style: TextStyle(
              color: widget.isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          // Bottom tips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 10,
                color: widget.isSelf 
                    ? colors.textColorAntiPrimary.withValues(alpha: 0.6) 
                    : colors.textColorSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                localizations.translateDefaultTips,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isSelf 
                      ? colors.textColorAntiPrimary.withValues(alpha: 0.6) 
                      : colors.textColorSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onLongPress: () {
        widget.onTranslationBubbleLongPress?.call(_translationBubbleKey);
      },
      child: Container(
        key: _translationBubbleKey,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth * 0.9,
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        decoration: BoxDecoration(
          color: colors.bgColorBubbleReciprocal.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.strokeColorPrimary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: bubbleContent,
      ),
    );
  }

  Widget _buildTextWithStatusAndTime(SemanticColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: _buildTextContent(colors),
        ),
        ...[
          const SizedBox(width: 8),
          ...buildStatusAndTimeWidgets(
            message: widget.message,
            isSelf: widget.isSelf,
            colors: colors,
            onResendTap: widget.onResendTap,
            isShowTimeInBubble: widget.config.isShowTimeInBubble,
            enableReadReceipt: widget.config.enableReadReceipt,
            isInMergedDetailView: widget.isInMergedDetailView,
          ),
        ],
      ],
    );
  }

  Widget _buildTextContent(SemanticColorScheme colorsTheme) {
    final text = widget.message.messageBody?.text ?? '';

    return ExtendedText(
      _getContentSpan(text, colorsTheme),
      onSpecialTextTap: (dynamic parameter) {
        if (parameter.toString().startsWith('\$')) {
          widget.onLinkTapped?.call((parameter.toString()).replaceAll('\$', ''));
        }
      },
      specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
        colorScheme: colorsTheme,
        onTapUrl: widget.onLinkTapped ?? (_) {},
        showAtBackground: true,
      ),
      style: TextStyle(
        color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  String _getContentSpan(String text, SemanticColorScheme colors) {
    String contentData = "";
    Iterable<RegExpMatch> matches = ChatUtils.urlReg.allMatches(text);

    int index = 0;
    for (RegExpMatch match in matches) {
      String c = text.substring(match.start, match.end);
      if (match.start == index) {
        index = match.end;
      }
      if (index < match.start) {
        String a = text.substring(index, match.start);
        index = match.end;
        contentData += a;
      }

      if (ChatUtils.urlReg.hasMatch(c)) {
        contentData += '${HttpText.flag}$c${HttpText.flag}';
      } else {
        contentData += c;
      }
    }

    if (index < text.length) {
      String a = text.substring(index, text.length);
      contentData += a;
    }

    return contentData.isNotEmpty ? contentData : text;
  }

  Color _getBubbleColor(SemanticColorScheme colorsTheme) {
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    switch (widget.config.alignment) {
      case 'left':
        return BorderRadius.only(
          topLeft: Radius.circular(widget.config.textBubbleCornerRadius),
          topRight: Radius.circular(widget.config.textBubbleCornerRadius),
          bottomLeft: const Radius.circular(0),
          bottomRight: Radius.circular(widget.config.textBubbleCornerRadius),
        );
      case 'right':
        return BorderRadius.only(
          topLeft: Radius.circular(widget.config.textBubbleCornerRadius),
          topRight: Radius.circular(widget.config.textBubbleCornerRadius),
          bottomLeft: Radius.circular(widget.config.textBubbleCornerRadius),
          bottomRight: const Radius.circular(0),
        );
      case 'two-sided':
      default:
        if (widget.isSelf) {
          return BorderRadius.only(
            topLeft: Radius.circular(widget.config.textBubbleCornerRadius),
            topRight: Radius.circular(widget.config.textBubbleCornerRadius),
            bottomLeft: Radius.circular(widget.config.textBubbleCornerRadius),
            bottomRight: const Radius.circular(0),
          );
        } else {
          return BorderRadius.only(
            topLeft: Radius.circular(widget.config.textBubbleCornerRadius),
            topRight: Radius.circular(widget.config.textBubbleCornerRadius),
            bottomLeft: const Radius.circular(0),
            bottomRight: Radius.circular(widget.config.textBubbleCornerRadius),
          );
        }
    }
  }
}
