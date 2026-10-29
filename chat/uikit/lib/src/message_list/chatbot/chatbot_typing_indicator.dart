import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// 机器人回复前的占位气泡：对端头像 + 一个跳动三点的接收方气泡。
/// 尺寸与动画参数对齐 Android 的 StreamingTextContentView 等待态。
class ChatbotTypingIndicator extends StatefulWidget {
  const ChatbotTypingIndicator({
    super.key,
    required this.config,
    this.avatarURL,
    this.name,
  });

  final MessageListConfigProtocol config;
  final String? avatarURL;
  final String? name;

  @override
  State<ChatbotTypingIndicator> createState() => _ChatbotTypingIndicatorState();
}

class _ChatbotTypingIndicatorState extends State<ChatbotTypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final config = widget.config;
    final bubble = Container(
      key: const Key('chatbot_typing_indicator'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgColorBubbleReciprocal,
        borderRadius: MessageUtil.bubbleBorderRadius(
          alignment: config.alignment,
          isSelf: false,
          radius: config.textBubbleCornerRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: SizedBox(
          width: 24,
          height: 20,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _TypingDotsPainter(
                progress: _controller.value,
                color: colors.textColorSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    final alignEnd = config.alignment == 'right';
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (config.isShowLeftAvatar && !alignEnd) ...[
          Avatar(content: AvatarImageContent(url: widget.avatarURL, name: widget.name)),
          SizedBox(width: config.avatarSpacing),
        ],
        bubble,
      ],
    );
  }
}

class _TypingDotsPainter extends CustomPainter {
  _TypingDotsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const double _radius = 2;
  static const double _gap = 7;
  static const int _minAlpha = 64;
  static const int _maxAlpha = 255;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final centerY = size.height / 2;
    final startX = size.width / 2 - _gap;
    for (var i = 0; i < 3; i++) {
      final phase = (progress - i / 3) * 2 * math.pi;
      final t = (math.sin(phase) + 1) / 2;
      final alpha = (_minAlpha + (_maxAlpha - _minAlpha) * t).round();
      paint.color = color.withAlpha((color.a * alpha).round().clamp(0, 255));
      canvas.drawCircle(Offset(startX + i * _gap, centerY), _radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TypingDotsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
