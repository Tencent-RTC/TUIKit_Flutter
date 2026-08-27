import 'package:atomic_x_core/atomicxcore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_input/src/chat_special_text_span_builder.dart';
import 'package:tencent_chat_uikit/src/third_party/extended_text/extended_text.dart';
import '../../common/language/gen/chat_localizations.dart';

/// A quote message preview block shown under a message bubble.
/// Displays the quoted message's sender name + content summary/thumbnail.
/// Tapping triggers navigation to the quoted message.
class QuoteMessagePreview extends StatelessWidget {
  final MessageQuoteInfo quoteInfo;
  final VoidCallback? onTap;
  final double maxWidth;

  const QuoteMessagePreview({
    super.key,
    required this.quoteInfo,
    this.onTap,
    this.maxWidth = 200,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

    return GestureDetector(
      onTap: () => _handleTap(context, locale),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.bgColorBubbleReciprocal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildContent(colors, locale),
      ),
    );
  }

  Widget _buildContent(SemanticColorScheme colors, ChatLocalizations locale) {
    // Display priority — derived from (status, payload) only; no extra
    // "isNotFound" flag is needed because the engine repurposes
    // `status = deleted` to mean "original unreachable" when cloud
    // lookup also fails (see MessageListStoreImpl._fillQuoteInfoFromCloud).
    //
    //   1. `status == revoked`
    //        → "引用内容已撤回". `ChatUtil.getMessagePayload` returns
    //          null for revoked messages by global convention, so this
    //          must come BEFORE any payload-null check.
    //
    //   2. `status == deleted` AND `payload != null`
    //        → render the original payload preview (per product spec:
    //          "if the deleted original message is still loadable, show
    //          its content"). Tap-time navigation is still blocked and
    //          shows "无法定位到原消息" (see `_handleTap`).
    //
    //   3. `status == deleted` AND `payload == null`
    //        → "无法找到引用内容". This is the "unreachable" branch the
    //          engine routes to when both local DB and cloud history
    //          can't find the quoted message anymore.
    //
    //   4. `payload == null` AND status is neither revoked nor deleted
    //        → partial loading placeholder. Engine is still
    //          asynchronously filling quoteInfo.
    //
    //   5. Otherwise → render full original content normally.
    if (quoteInfo.status == MessageStatus.revoked) {
      return _buildStatusContent(colors, locale.quotedMessageRevoked);
    }
    if (quoteInfo.status == MessageStatus.deleted) {
      if (quoteInfo.messagePayload == null) {
        return _buildStatusContent(colors, locale.quotedMessageNotFound);
      }
      return _buildFullContent(colors, locale);
    }
    if (quoteInfo.messagePayload == null) {
      return _buildPartialContent(colors);
    }
    return _buildFullContent(colors, locale);
  }

  /// Tap handler: gate the upstream `onTap` (navigate-to-original) when
  /// the original message is no longer reachable, and surface a toast
  /// instead.
  ///
  /// Reachability rules:
  ///   - `revoked` → unreachable (server still has the message but it's
  ///     hidden from history navigation by product design)
  ///   - `deleted` → unreachable (either truly deleted by the user, or
  ///     repurposed by the engine to mean "cloud lookup gave up" —
  ///     either way it can't be located in the list)
  ///   - any other state (including partial-loading) → defer to caller
  void _handleTap(BuildContext context, ChatLocalizations locale) {
    final unreachable = quoteInfo.status == MessageStatus.revoked ||
        quoteInfo.status == MessageStatus.deleted;
    if (unreachable) {
      Toast.info(context, locale.quotedOriginalMessageUnreachable);
      return;
    }
    onTap?.call();
  }

  Widget _buildPartialContent(SemanticColorScheme colors) {
    final senderName = _getSenderName();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (senderName.isNotEmpty)
          Text(
            '$senderName:',
            style: FontScheme.caption3Medium.copyWith(
              color: colors.textColorSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 2),
        Text(
          '...',
          style: FontScheme.caption3Regular.copyWith(
            color: colors.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusContent(SemanticColorScheme colors, String statusText) {
    return Text(
      statusText,
      style: FontScheme.caption3Regular.copyWith(
        color: colors.textColorSecondary,
      ),
    );
  }

  Widget _buildFullContent(SemanticColorScheme colors, ChatLocalizations locale) {
    final senderName = _getSenderName();
    final payload = quoteInfo.messagePayload!;
    final thumbnail = _getThumbnailUrl(payload);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderName.isNotEmpty)
                Text(
                  '$senderName:',
                  style: FontScheme.caption3Medium.copyWith(
                    color: colors.textColorSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // When a thumbnail is being rendered alongside (image /
              // video payloads), skip the redundant "[图片]" / "[视频]"
              // text label — the thumbnail itself IS the content
              // summary, and showing both is visual noise.
              if (thumbnail == null) ...[
                const SizedBox(height: 2),
                _buildContentWidget(payload, colors, locale),
              ],
            ],
          ),
        ),
        if (thumbnail != null) ...[
          const SizedBox(width: 8),
          _buildThumbnail(colors, thumbnail),
        ],
      ],
    );
  }

  Widget _buildContentWidget(MessagePayload payload, SemanticColorScheme colors, ChatLocalizations locale) {
    final textStyle = FontScheme.caption3Regular.copyWith(
      color: colors.textColorSecondary,
    );

    // Audio and file types use Icon prefix instead of emoji
    switch (payload) {
      case AudioMessagePayload p:
        final duration = p.audioDuration;
        final minutes = duration ~/ 60;
        final seconds = duration % 60;
        final timeText = '${minutes > 0 ? "$minutes:" : ""}${seconds.toString().padLeft(2, '0')}"';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up, size: 14, color: colors.textColorSecondary),
            const SizedBox(width: 2),
            Text(timeText, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      case FileMessagePayload p:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 14, color: colors.textColorSecondary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                p.fileName ?? locale.messageTypeFile,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        // Use ExtendedText so [TUIEmoji_*] tokens render as inline emoji
        // images instead of being shown literally. This matches the bubble
        // rendering and the merged-message preview.
        return ExtendedText(
          _getContentSummary(payload, locale),
          specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
            colorScheme: colors,
            onTapUrl: (_) {},
          ),
          style: textStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  String _getSenderName() {
    final sender = quoteInfo.sender;
    for (final candidate in [sender.friendRemark, sender.nameCard, sender.nickname]) {
      final name = candidate?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return sender.userID;
  }

  String _getContentSummary(MessagePayload payload, ChatLocalizations locale) {
    switch (payload) {
      case TextMessagePayload p:
        return p.text;
      case ImageMessagePayload _:
        return locale.messageTypeImage;
      case VideoMessagePayload _:
        return locale.messageTypeVideo;
      case AudioMessagePayload p:
        final duration = p.audioDuration;
        final minutes = duration ~/ 60;
        final seconds = duration % 60;
        return '${minutes > 0 ? "$minutes:" : ""}${seconds.toString().padLeft(2, '0')}"';
      case FileMessagePayload p:
        return p.fileName ?? locale.messageTypeFile;
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

  _ThumbnailInfo? _getThumbnailUrl(MessagePayload payload) {
    if (payload is ImageMessagePayload) {
      final url = payload.thumbImageURL ?? payload.originalImageURL;
      if (url != null && url.isNotEmpty) {
        return _ThumbnailInfo(url: url, isVideo: false);
      }
    } else if (payload is VideoMessagePayload) {
      final url = payload.videoSnapshotURL;
      if (url != null && url.isNotEmpty) {
        return _ThumbnailInfo(url: url, isVideo: true);
      }
    }
    return null;
  }

  Widget _buildThumbnail(SemanticColorScheme colors, _ThumbnailInfo info) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: info.url,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: colors.bgColorBubbleReciprocal,
                child: Icon(
                  info.isVideo ? Icons.videocam : Icons.image,
                  size: 18,
                  color: colors.textColorSecondary,
                ),
              ),
            ),
            if (info.isVideo)
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 18,
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

class _ThumbnailInfo {
  final String url;
  final bool isVideo;

  const _ThumbnailInfo({required this.url, required this.isVideo});
}
