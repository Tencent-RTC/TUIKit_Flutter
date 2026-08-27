import 'package:atomic_x_core/atomicxcore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_input/src/chat_special_text_span_builder.dart';
import 'package:tencent_chat_uikit/src/third_party/extended_text/extended_text.dart';
import '../../common/language/gen/chat_localizations.dart';

/// A preview bar displayed below the message input when quoting a message.
/// Shows sender name + content preview (text / thumbnail / icon) + close button.
class QuotePreviewBar extends StatelessWidget {
  final MessageInfo quotedMessage;
  final VoidCallback onClose;

  const QuotePreviewBar({
    super.key,
    required this.quotedMessage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);
    final senderName = ChatUtil.getMessageSenderName(quotedMessage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgColorDefault,
        border: Border(
          top: BorderSide(color: colors.strokeColorPrimary.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          // Content area - single line: "sender: content"
          Expanded(
            child: _buildSingleLineContent(colors, locale, senderName),
          ),
          // Thumbnail (for image/video)
          _buildThumbnail(colors),
          const SizedBox(width: 8),
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 18,
              color: colors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineContent(SemanticColorScheme colors, ChatLocalizations locale, String senderName) {
    final payload = quotedMessage.messagePayload;
    final textStyle = FontScheme.caption2Regular.copyWith(
      color: colors.textColorSecondary,
    );
    final prefix = senderName.isNotEmpty ? '$senderName：' : '';

    // Audio and file use Icon prefix
    if (payload is AudioMessagePayload) {
      final duration = payload.audioDuration;
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      final timeText = '${minutes > 0 ? "$minutes:" : ""}${seconds.toString().padLeft(2, '0')}"';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty) Text(prefix, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          Icon(Icons.volume_up, size: 14, color: colors.textColorSecondary),
          const SizedBox(width: 2),
          Flexible(child: Text(timeText, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      );
    }
    if (payload is FileMessagePayload) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty) Text(prefix, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          Icon(Icons.insert_drive_file, size: 14, color: colors.textColorSecondary),
          const SizedBox(width: 2),
          Flexible(child: Text(payload.fileName ?? locale.messageTypeFile, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      );
    }

    final contentText = _getContentSummary(locale);
    final displayText = '$prefix$contentText';
    // Use ExtendedText so [TUIEmoji_*] tokens in the quoted text render as
    // inline emoji images instead of literal text, matching the message
    // bubble's quote preview.
    return ExtendedText(
      displayText,
      specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
        colorScheme: colors,
        onTapUrl: (_) {},
      ),
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getContentSummary(ChatLocalizations locale) {
    final payload = quotedMessage.messagePayload;

    switch (payload) {
      case TextMessagePayload p:
        return p.text;
      case ImageMessagePayload _:
        return locale.messageTypeImage;
      case VideoMessagePayload _:
        return locale.messageTypeVideo;
      case AudioMessagePayload _:
        return '';
      case FileMessagePayload _:
        return '';
      case FaceMessagePayload _:
        return locale.messageTypeSticker;
      case CustomMessagePayload p:
        return p.description ?? locale.messageTypeCustom;
      case MergedMessagePayload p:
        return p.title.isNotEmpty ? p.title : locale.messageTypeMerged;
      default:
        return locale.messageTypeUnknown;
    }
  }

  Widget _buildThumbnail(SemanticColorScheme colors) {
    final payload = quotedMessage.messagePayload;

    String? imageUrl;
    bool isVideo = false;

    if (payload is ImageMessagePayload) {
      imageUrl = payload.thumbImageURL ?? payload.originalImageURL;
    } else if (payload is VideoMessagePayload) {
      imageUrl = payload.videoSnapshotURL;
      isVideo = true;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: colors.bgColorBubbleReciprocal,
                child: Icon(
                  isVideo ? Icons.videocam : Icons.image,
                  size: 16,
                  color: colors.textColorSecondary,
                ),
              ),
            ),
            if (isVideo)
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
