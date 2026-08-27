import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'package:tencent_chat_uikit/src/message_list/utils/calling_message_data_provider.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';
import 'system_message_widget.dart';

typedef BackgroundBuilder = Widget Function(Widget child);

class CallMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final MessageListStore? messageListStore;
  final GlobalKey? bubbleKey;
  final BackgroundBuilder? backgroundBuilder;
  final String alignment;
  final VoidCallback? onResendTap;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;
  final void Function(String userID, bool isVideoCall)? onCallMessageClick;

  const CallMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.messageListStore,
    this.bubbleKey,
    this.backgroundBuilder,
    this.alignment = AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED,
    this.onResendTap,
    this.isInMergedDetailView = false,
    this.onCallMessageClick,
  });

  @override
  State<CallMessageWidget> createState() => _CallMessageWidgetState();
}

class _CallMessageWidgetState extends State<CallMessageWidget> with MessageStatusMixin {
  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    CallingMessageDataProvider provider = CallingMessageDataProvider(widget.message, context);
    if (!provider.isCallingSignal) {
      return Container();
    }

    if (provider.content.isEmpty) {
      return Container();
    }

    if (provider.participantType == CallParticipantType.group) {
      return SystemMessageWidget(
        customContent: provider.content,
      );
    }

    final content = Container(
      key: widget.bubbleKey,
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _buildCallContentWithStatusAndTime(colors, provider),
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
      onTap: () {
        final isVideoCall = provider.streamMediaType == CallStreamMediaType.video;
        
        // Get the userID of the other party from the message
        final userID = widget.message.isSentBySelf
            ? widget.message.rawMessage?.userID ?? ''
            : widget.message.rawMessage?.sender ?? '';
        
        if (widget.onCallMessageClick != null && userID.isNotEmpty) {
          widget.onCallMessageClick!(userID, isVideoCall);
        }
      },
      child: bubble,
    );
  }

  Widget _buildCallContentWithStatusAndTime(
    SemanticColorScheme colors,
    CallingMessageDataProvider provider,
  ) {
    final statusAndTimeWidgets = buildStatusAndTimeWidgets(
      message: widget.message,
      isSelf: widget.isSelf,
      colors: colors,
      onResendTap: widget.onResendTap,
      isShowTimeInBubble: widget.config.isShowTimeInBubble,
      isInMergedDetailView: widget.isInMergedDetailView,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: _buildCallContent(colors, provider),
        ),
        if (statusAndTimeWidgets.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...statusAndTimeWidgets,
        ],
      ],
    );
  }

  Widget _buildCallContent(
    SemanticColorScheme colors,
    CallingMessageDataProvider provider,
  ) {
    final icon = _buildCallIcon(colors, provider);
    final text = Flexible(
      child: Text(
        provider.content,
        style: FontScheme.caption2Medium.copyWith(
          color: widget.isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary,
          height: 1.4,
        ),
      ),
    );

    // Received: [icon] text. Sent: text [icon] — the icon sits on the sender's
    // side (right), matching the design.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.isSelf
          ? [text, const SizedBox(width: 8), icon]
          : [icon, const SizedBox(width: 8), text],
    );
  }

  Widget _buildCallIcon(SemanticColorScheme colors, CallingMessageDataProvider provider) {
    final bool isAudio = provider.streamMediaType == CallStreamMediaType.audio;
    final String asset = isAudio
        ? 'chat_assets/icon/voice_call.png'
        : (widget.isSelf ? 'chat_assets/icon/video_call_self.png' : 'chat_assets/icon/video_call.png');

    return Image.asset(
      asset,
      package: 'tencent_chat_uikit',
      height: 18,
    );
  }

  Color _getBubbleColor(SemanticColorScheme colors) {
    if (widget.isSelf) {
      return colors.bgColorBubbleOwn;
    } else {
      return colors.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() => MessageUtil.bubbleBorderRadius(
        alignment: widget.alignment,
        isSelf: widget.isSelf,
        radius: widget.config.textBubbleCornerRadius,
      );
}
