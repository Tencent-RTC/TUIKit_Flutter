import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'package:tuikit_atomic_x/message_list/utils/calling_message_data_provider.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_status_mixin.dart';
import 'system_message_widget.dart';

typedef BackgroundBuilder = Widget Function(Widget child);

class CallMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;
  final VoidCallback? onStartVoiceCall;
  final VoidCallback? onStartVideoCall;
  final GlobalKey? bubbleKey;
  final BackgroundBuilder? backgroundBuilder;
  final String alignment;
  final VoidCallback? onResendTap;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;

  const CallMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onTap,
    this.onLongPress,
    this.messageListStore,
    this.onStartVoiceCall,
    this.onStartVideoCall,
    this.bubbleKey,
    this.backgroundBuilder,
    this.alignment = AppBuilder.MESSAGE_ALIGNMENT_TWO_SIDED,
    this.onResendTap,
    this.isInMergedDetailView = false,
  });

  @override
  State<CallMessageWidget> createState() => _CallMessageWidgetState();
}

class _CallMessageWidgetState extends State<CallMessageWidget> with MessageStatusMixin {
  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final atomicLocale = AtomicLocalizations.of(context);
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
        maxWidth: widget.maxWidth * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _buildCallContentWithStatusAndTime(colors, atomicLocale, provider),
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
        if (provider.streamMediaType == CallStreamMediaType.audio) {
          widget.onStartVoiceCall?.call();
        } else {
          widget.onStartVideoCall?.call();
        }
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: bubble,
    );
  }

  Widget _buildCallContentWithStatusAndTime(
    SemanticColorScheme colors,
    AtomicLocalizations atomicLocale,
    CallingMessageDataProvider provider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: _buildCallContent(colors, atomicLocale, provider),
        ),
        ...[
          const SizedBox(width: 8),
          ...buildStatusAndTimeWidgets(
            message: widget.message,
            isSelf: widget.isSelf,
            colors: colors,
            onResendTap: widget.onResendTap,
            isShowTimeInBubble: widget.config.isShowTimeInBubble,
            isInMergedDetailView: widget.isInMergedDetailView,
          ),
        ],
      ],
    );
  }

  Widget _buildCallContent(
    SemanticColorScheme colors,
    AtomicLocalizations atomicLocale,
    CallingMessageDataProvider provider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCallIcon(colors, provider),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            provider.content,
            style: TextStyle(
              color: widget.isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallIcon(SemanticColorScheme colors, CallingMessageDataProvider provider) {
    IconData iconData;

    if (provider.streamMediaType == CallStreamMediaType.audio) {
      iconData = Icons.phone;
    } else {
      iconData = Icons.videocam;
    }

    return Icon(
      iconData,
      size: 16,
      color: widget.isSelf ? colors.textColorAntiPrimary : colors.textColorSecondary,
    );
  }

  Color _getBubbleColor(SemanticColorScheme colors) {
    if (widget.isSelf) {
      return colors.bgColorBubbleOwn;
    } else {
      return colors.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    switch (widget.alignment) {
      case 'left':
        return const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(18),
        );
      case 'right':
        return const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(0),
        );
      case 'two-sided':
      default:
        if (widget.isSelf) {
          return const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(0),
          );
        } else {
          return const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(18),
          );
        }
    }
  }
}
