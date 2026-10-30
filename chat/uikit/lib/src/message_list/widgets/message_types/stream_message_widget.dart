import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/stream/stream_markdown_view.dart';
import 'package:tencent_chat_uikit/src/message_list/stream/typewriter_controller.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_types/text_message_widget.dart' show BackgroundBuilder;
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// A stream message bubble, revealed one grapheme at a time.
///
/// Deliberately indistinguishable from [TextMessageWidget] at rest — same
/// bubble, padding, status row and timestamp. Only the reveal and the trailing
/// cursor set it apart.
class StreamMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final MessageListConfigProtocol config;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GlobalKey? bubbleKey;
  final BackgroundBuilder? backgroundBuilder;
  final bool isInMergedDetailView;

  /// Overrides the default reveal pacing for this bubble.
  final TypewriterPacing? pacing;

  const StreamMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onTap,
    this.onLongPress,
    this.bubbleKey,
    this.backgroundBuilder,
    this.isInMergedDetailView = false,
    this.pacing,
  });

  @override
  State<StreamMessageWidget> createState() => _StreamMessageWidgetState();
}

class _StreamMessageWidgetState extends State<StreamMessageWidget>
    with MessageStatusMixin, SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TypewriterController _typewriter;

  /// Created once and started/stopped as needed — `SingleTickerProviderStateMixin`
  /// throws if a second ticker is ever created from the same state.
  late final Ticker _ticker;

  /// `Ticker` reports time since its last `start()`, so this resets on resume.
  Duration _lastTick = Duration.zero;

  StreamMessagePayload? get _payload => widget.message.messagePayload as StreamMessagePayload?;

  /// Keeps a streaming bubble alive while it scrolls out of view. Sliver lists
  /// otherwise dispose it, and the rebuilt widget would restart the reveal from
  /// the first character. Released once the reveal is over.
  @override
  bool get wantKeepAlive => _typewriter.phase != TypewriterPhase.done;

  @override
  void initState() {
    // Ahead of the super call on purpose: AutomaticKeepAliveClientMixin reads
    // `wantKeepAlive` from its own initState, which needs the controller.
    _typewriter = TypewriterController(pacing: widget.pacing);
    super.initState();
    _ticker = createTicker(_onTick);
    _syncPayload();

    // A stream already ended when its bubble first builds is history. Replaying
    // it would set every stream message in the loaded page typing at once.
    if (_payload?.isStreamEnded ?? false) {
      _typewriter.snapToEnd();
    } else {
      _resumeTicker();
    }
  }

  @override
  void didUpdateWidget(StreamMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Each continuation chunk arrives here: the store swaps in a new
    // MessageInfo while the list key stays put, so the element is reused.
    _syncPayload();
    if (_typewriter.phase == TypewriterPhase.done) {
      _ticker.stop();
    } else {
      _resumeTicker();
    }
    updateKeepAlive();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _typewriter.dispose();
    super.dispose();
  }

  void _syncPayload() {
    final payload = _payload;
    _typewriter.sync(
      fullText: payload?.markdown ?? '',
      isStreamEnded: payload?.isStreamEnded ?? false,
    );
  }

  void _resumeTicker() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _typewriter.advance(elapsed - _lastTick);
    _lastTick = elapsed;
    if (_typewriter.phase == TypewriterPhase.done) {
      _ticker.stop();
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = BaseThemeProvider.colorsOf(context);

    final content = Container(
      key: widget.bubbleKey,
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: _buildContentWithStatusAndTime(colors),
    );

    final bubble = widget.backgroundBuilder?.call(content) ??
        Container(
          decoration: BoxDecoration(
            color: _getBubbleColor(colors),
            borderRadius: _getBubbleBorderRadius(),
          ),
          child: content,
        );

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: bubble,
    );
  }

  Widget _buildContentWithStatusAndTime(SemanticColorScheme colors) {
    final statusAndTimeWidgets = buildStatusAndTimeWidgets(
      message: widget.message,
      isSelf: widget.isSelf,
      colors: colors,
      isShowTimeInBubble: widget.config.isShowTimeInBubble,
      enableReadReceipt: widget.config.enableReadReceipt,
      isInMergedDetailView: widget.isInMergedDetailView,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          // Scoped to the text alone: rebuilding the bubble, its decoration and
          // the status row on every revealed grapheme is what makes a reveal
          // drop frames in a long conversation.
          child: ListenableBuilder(
            listenable: _typewriter,
            builder: (context, _) => _buildRevealedText(),
          ),
        ),
        if (statusAndTimeWidgets.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...statusAndTimeWidgets,
        ],
      ],
    );
  }

  Widget _buildRevealedText() {
    return StreamMarkdownView(
      revealed: _typewriter.visibleText,
      isRevealing: _typewriter.phase != TypewriterPhase.done,
      isSelf: widget.isSelf,
    );
  }

  Color _getBubbleColor(SemanticColorScheme colors) {
    return widget.isSelf ? colors.bgColorBubbleOwn : colors.bgColorBubbleReciprocal;
  }

  BorderRadius _getBubbleBorderRadius() => MessageUtil.bubbleBorderRadius(
        alignment: widget.config.alignment,
        isSelf: widget.isSelf,
        radius: widget.config.textBubbleCornerRadius,
      );
}
