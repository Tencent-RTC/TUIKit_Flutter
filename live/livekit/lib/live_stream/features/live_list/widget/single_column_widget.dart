import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../common/index.dart';

class SingleColumnWidget extends StatelessWidget {
  final String roomName;
  final String ownerName;
  final String ownerAvatarUrl;

  const SingleColumnWidget({
    super.key,
    required this.roomName,
    required this.ownerName,
    required this.ownerAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 20.width,
            right: 20.width,
            bottom: 96.height,
            child: Text(
              roomName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: LiveColors.designStandardFlowkitWhite,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 22 / 20,
              ),
            ),
          ),
          Positioned(
            left: 20.width,
            right: 20.width,
            bottom: 43.height,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.radius),
                  child: SizedBox(
                    width: 24.radius,
                    height: 24.radius,
                    child: CachedNetworkImage(
                      imageUrl: ownerAvatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Image.asset(
                        LiveImages.defaultAvatar,
                        fit: BoxFit.cover,
                        package: Constants.pluginName,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.width),
                Expanded(
                  child: Text(
                    ownerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: LiveColors.designStandardFlowkitWhite.withAlpha(140),
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 234.height,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200.width,
                height: 40.height,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(20.height),
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.radius,
                      height: 16.radius,
                      child: const _LiveStatusAnimationWidget(),
                    ),
                    SizedBox(width: 8.width),
                    Text(
                      LiveKitLocalizations.of(Global.appContext())!.livelist_click_enter_room,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated audio bar indicator widget.
/// Draws 3 vertical bars that oscillate in height using a sine wave,
class _LiveStatusAnimationWidget extends StatefulWidget {
  const _LiveStatusAnimationWidget();

  @override
  State<_LiveStatusAnimationWidget> createState() => _LiveStatusAnimationWidgetState();
}

class _LiveStatusAnimationWidgetState extends State<_LiveStatusAnimationWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AudioBarPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _AudioBarPainter extends CustomPainter {
  final double progress;
  static const int barCount = 3;
  static const double barWidth = 2.0;
  static const double minBarHeight = 7.0;
  static const double barSpacing = 3.0;

  _AudioBarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final totalWidth = barWidth * barCount + barSpacing * (barCount - 1);
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final phase = i * 0.6;
      final adjustedProgress = (progress + phase) % 1.0;
      final barHeight = minBarHeight + sin(adjustedProgress * pi) * 15;

      final left = startX + i * (barWidth + barSpacing);
      final top = centerY - barHeight / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_AudioBarPainter oldDelegate) => oldDelegate.progress != progress;
}
