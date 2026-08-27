import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_input/src/chat_special_text_span_builder.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/merged_message_detail_page.dart';
import 'package:tencent_chat_uikit/src/third_party/extended_text/extended_text.dart';
import '../../../common/language/gen/chat_localizations.dart';

/// Merged message display widget
class MergedMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final MessageListConfigProtocol config;
  final VoidCallback? onLongPress;
  final GlobalKey? bubbleKey;
  final MessageListStore messageListStore;
  final bool isInMergedDetailView;

  /// Optional override for bubble background color — used by the
  /// "highlight after navigate" animation in `MessageBubble`. Matches
  /// the same hook on [SoundMessageWidget] / [FileMessageWidget].
  final Color? bubbleColor;

  const MergedMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onLongPress,
    this.bubbleKey,
    required this.messageListStore,
    this.isInMergedDetailView = false,
    this.bubbleColor,
  });

  @override
  State<MergedMessageWidget> createState() => _MergedMessageWidgetState();
}

/// A merged forward is rendered as a card rather than a chat bubble: fixed
/// width, symmetric corners and a hairline border on both sides of the
/// conversation, so it reads as an attached transcript instead of speech.
const double _cardWidth = 214;
const double _cardCornerRadius = 12;
const int _maxAbstractCount = 4;

class _MergedMessageWidgetState extends State<MergedMessageWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final mergedInfo = (widget.message.messagePayload as MergedMessagePayload?);
    final abstracts = (mergedInfo?.abstractList ?? const <String>[]).take(_maxAbstractCount).toList();

    return GestureDetector(
      onTap: () => _openMergedMessagePayloadDetail(context),
      onLongPress: widget.onLongPress,
      child: Container(
        key: widget.bubbleKey,
        width: _cardWidth,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: widget.bubbleColor ?? colors.bgColorOperate,
          borderRadius: BorderRadius.circular(_cardCornerRadius),
          border: Border.all(color: colors.strokeColorPrimary, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mergedInfo?.title ?? _chatHistoryText(context),
              style: FontScheme.caption1Regular.copyWith(
                color: colors.textColorPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            for (var index = 0; index < abstracts.length; index++)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 6 : 2),
                // ExtendedText so [TUIEmoji_*] tokens in the preview render as
                // inline emoji images rather than raw tokens.
                child: ExtendedText(
                  abstracts[index],
                  specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
                    colorScheme: colors,
                    onTapUrl: (_) {},
                  ),
                  style: FontScheme.caption3Regular.copyWith(
                    color: colors.textColorTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 6),
              child: Container(
                width: double.infinity,
                height: 0.5,
                color: colors.strokeColorPrimary,
              ),
            ),
            Text(
              _chatHistoryText(context),
              style: FontScheme.caption4Regular.copyWith(
                color: colors.textColorTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMergedMessagePayloadDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MergedMessageDetailPage(
          message: widget.message,
          messageListStore: widget.messageListStore,
        ),
      ),
    );
  }

  String _chatHistoryText(BuildContext context) {
    return ChatLocalizations.of(context).chatHistory;
  }
}
