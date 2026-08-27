import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_input/src/chat_special_text_span_builder.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/asr_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_text_parser.dart';
import 'package:tencent_chat_uikit/src/third_party/extended_text/extended_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/language/gen/chat_localizations.dart';

/// Builds the optional "attachment" widget that hangs below the main
/// message bubble — the ASR (voice → text) bubble for audio messages and
/// the translation bubble for text messages.
///
/// **Why this exists as a separate widget instead of being baked into
/// `SoundMessageWidget` / `TextMessageWidget`:**
/// the read-receipt label and the status / failure icon are placed in
/// the same `Row(crossAxisAlignment: end)` as the main bubble inside
/// `MessageItem`. If the ASR / translation bubble lives *inside* the
/// main bubble widget (returned as a `Column` of [main, attachment]),
/// the row's `end` alignment snaps the receipt to the bottom of the
/// whole column — i.e. the bottom of the attachment — which makes the
/// receipt drift downwards as soon as voice-to-text or translation
/// expands. Pulling the attachment out so `MessageItem` can render it
/// in the column *below* the main row keeps the receipt anchored to
/// the main bubble.
class MessageAttachmentBuilder {
  MessageAttachmentBuilder._();

  /// Returns the attachment widget for [message], or `null` when none
  /// applies (e.g. non-audio / non-text payloads, ASR not requested,
  /// translation hidden, etc.).
  ///
  /// `isInMergedDetailView` suppresses attachments inside merged
  /// forwards: those bubbles never have ASR / translation state in the
  /// first place, and the merged view doesn't have managers attached.
  static Widget? buildIfAny({
    required MessageInfo message,
    required bool isSelf,
    required double maxWidth,
    required MessageListConfigProtocol config,
    bool isInMergedDetailView = false,
    AsrDisplayManager? asrDisplayManager,
    void Function(MessageInfo message, GlobalKey asrBubbleKey)?
        onAsrBubbleLongPress,
    TranslationDisplayManager? translationDisplayManager,
    void Function(MessageInfo message, GlobalKey translationBubbleKey)?
        onTranslationBubbleLongPress,
  }) {
    if (isInMergedDetailView) return null;
    final messageID = message.msgID;
    if (messageID.isEmpty) return null;

    if (message.messageType == MessageType.audio) {
      final hasAsr =
          (message.messagePayload as AudioMessagePayload?)?.asrText?.isNotEmpty ==
              true;
      final isConverting = asrDisplayManager?.isConverting(messageID) ?? false;
      final isAsrHidden = asrDisplayManager?.isHidden(messageID) ?? false;
      final shouldShow = isConverting || (hasAsr && !isAsrHidden);
      if (!shouldShow) return null;
      return AsrAttachmentBubble(
        key: ValueKey('asr-attachment-$messageID'),
        message: message,
        isSelf: isSelf,
        maxWidth: maxWidth,
        isConverting: isConverting,
        onLongPress: onAsrBubbleLongPress,
      );
    }

    if (message.messageType == MessageType.text) {
      if (!config.isSupportTranslate) return null;
      final translatedTextMap =
          (message.messagePayload as TextMessagePayload?)?.translatedText;
      final hasTranslation =
          translatedTextMap != null && translatedTextMap.isNotEmpty;
      final isTranslating =
          translationDisplayManager?.isTranslating(messageID) ?? false;
      final isTranslationHidden =
          translationDisplayManager?.isHidden(messageID) ?? true;
      final shouldShow =
          !isTranslationHidden && (isTranslating || hasTranslation);
      if (!shouldShow) return null;
      return TranslationAttachmentBubble(
        key: ValueKey('translation-attachment-$messageID'),
        message: message,
        isSelf: isSelf,
        maxWidth: maxWidth,
        isTranslating: isTranslating,
        onLongPress: onTranslationBubbleLongPress,
      );
    }

    return null;
  }
}

/// ASR (voice → text) bubble shown directly underneath the audio bubble.
class AsrAttachmentBubble extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final bool isConverting;
  final void Function(MessageInfo message, GlobalKey asrBubbleKey)? onLongPress;

  const AsrAttachmentBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.isConverting,
    this.onLongPress,
  });

  @override
  State<AsrAttachmentBubble> createState() => _AsrAttachmentBubbleState();
}

class _AsrAttachmentBubbleState extends State<AsrAttachmentBubble> {
  final GlobalKey _asrBubbleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    return GestureDetector(
      onLongPress: widget.isConverting
          ? null
          : () {
              widget.onLongPress?.call(widget.message, _asrBubbleKey);
            },
      child: Container(
        key: _asrBubbleKey,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: widget.maxWidth * 0.7),
        decoration: BoxDecoration(
          color: _bubbleColor(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.isConverting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isSelf
                        ? colors.textColorAntiPrimary
                        : colors.textColorPrimary,
                  ),
                ),
              )
            : Text(
                (widget.message.messagePayload as AudioMessagePayload?)
                        ?.asrText ??
                    '',
                style: FontScheme.caption2Regular.copyWith(
                  color: widget.isSelf
                      ? colors.textColorAntiPrimary
                      : colors.textColorPrimary,
                ),
              ),
      ),
    );
  }

  Color _bubbleColor(SemanticColorScheme colors) =>
      widget.isSelf ? colors.bgColorBubbleOwn : colors.bgColorBubbleReciprocal;
}

/// Translation bubble shown directly underneath the text bubble.
///
/// Owns the asynchronous load of `@user` display names so the parent
/// text widget no longer has to. Until the names are loaded the bubble
/// renders nothing rather than a half-resolved string (the legacy
/// in-bubble translation had the same gate on `_atUserNamesLoaded`).
class TranslationAttachmentBubble extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final bool isTranslating;
  final void Function(MessageInfo message, GlobalKey translationBubbleKey)?
      onLongPress;

  const TranslationAttachmentBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.isTranslating,
    this.onLongPress,
  });

  @override
  State<TranslationAttachmentBubble> createState() =>
      _TranslationAttachmentBubbleState();
}

class _TranslationAttachmentBubbleState
    extends State<TranslationAttachmentBubble> {
  final GlobalKey _translationBubbleKey = GlobalKey();

  List<String>? _atUserNames;
  bool _atUserNamesLoaded = false;
  bool _isLoadingAtUserNames = false;

  bool get _hasAtUsers => widget.message.atUserList.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAtUserNamesIfNeeded();
  }

  @override
  void didUpdateWidget(TranslationAttachmentBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.msgID != widget.message.msgID) {
      _atUserNames = null;
      _atUserNamesLoaded = false;
      _isLoadingAtUserNames = false;
      _loadAtUserNamesIfNeeded();
    } else if (!_atUserNamesLoaded && !_isLoadingAtUserNames) {
      _loadAtUserNamesIfNeeded();
    }
  }

  void _loadAtUserNamesIfNeeded() {
    final translatedTextMap =
        (widget.message.messagePayload as TextMessagePayload?)?.translatedText;
    final hasTranslation =
        translatedTextMap != null && translatedTextMap.isNotEmpty;
    if (!hasTranslation || _atUserNamesLoaded || _isLoadingAtUserNames) return;

    if (!_hasAtUsers) {
      _atUserNamesLoaded = true;
      return;
    }

    _isLoadingAtUserNames = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final localizations = ChatLocalizations.of(context);
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
    final localizations = ChatLocalizations.of(context);
    final translatedTextMap =
        (widget.message.messagePayload as TextMessagePayload?)?.translatedText;

    Widget bubbleContent;
    if (widget.isTranslating) {
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(colors.textColorSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            localizations.translating,
            style: FontScheme.caption2Regular.copyWith(
              color: colors.textColorSecondary,
            ),
          ),
        ],
      );
    } else if (!_atUserNamesLoaded) {
      // Same gating as the legacy in-bubble translation: until names are
      // resolved, render nothing rather than a half-resolved string.
      return const SizedBox.shrink();
    } else {
      final originalText =
          (widget.message.messagePayload as TextMessagePayload?)?.text ?? '';
      final translatedDisplayText =
          TranslationTextParser.buildTranslatedDisplayText(
        originalText,
        translatedTextMap ?? {},
        _atUserNames,
      );
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExtendedText(
            translatedDisplayText,
            specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
              colorScheme: colors,
              onTapUrl: _launchUrl,
              showAtBackground: true,
            ),
            style: FontScheme.caption2Regular.copyWith(
              color: widget.isSelf
                  ? colors.textColorAntiPrimary
                  : colors.textColorPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
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
                style: FontScheme.caption4Regular.copyWith(
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
        widget.onLongPress?.call(widget.message, _translationBubbleKey);
      },
      child: Container(
        key: _translationBubbleKey,
        margin: const EdgeInsets.only(top: 4),
        constraints: BoxConstraints(maxWidth: widget.maxWidth * 0.9),
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('cannot open url: $url');
    }
  }
}
