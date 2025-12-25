import 'dart:math';

import 'package:flutter/material.dart';

class SoundWaveAnimatedWidget extends StatefulWidget {
  final int waveSpeedInMillisecond;
  final Tween<double> waveRadiusTween;
  final Color waveColor;
  final double waveWidth;

  SoundWaveAnimatedWidget(
      {super.key,
      int? waveSpeedInMillisecond,
      Tween<double>? waveRadiusTween,
      Color? waveColor,
      double? waveWidth})
      : waveSpeedInMillisecond = waveSpeedInMillisecond ?? 500,
        waveRadiusTween = waveRadiusTween ?? Tween(begin: 25.0, end: 36.0),
        waveColor = waveColor ?? const Color(0x1AFFDADE),
        waveWidth = waveWidth ?? 4;

  @override
  State<SoundWaveAnimatedWidget> createState() =>
      _SoundWaveAnimatedWidgetState();
}

class _SoundWaveAnimatedWidgetState extends State<SoundWaveAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.waveSpeedInMillisecond),
        vsync: this)
      ..repeat();

    _radiusAnimation = widget.waveRadiusTween
        .chain(CurveTween(curve: Curves.easeInOut))
        .chain(CurveTween(curve: const Interval(0.0, 0.5)))
        .animate(_controller);
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
        builder: (context, child) {
          final width = widget.waveRadiusTween.end ?? 70;
          final height = width;
          return Center(
            child: CustomPaint(
                size: Size(width, height),
                painter: ArcPainter(
                    radius: _radiusAnimation.value,
                    color: widget.waveColor,
                    strokeWidth: widget.waveWidth)),
          );
        });
  }
}

class ArcPainter extends CustomPainter {
  final double radius;
  final Color color;
  final double strokeWidth;

  ArcPainter(
      {required this.radius, this.color = Colors.blue, this.strokeWidth = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
        0,
        2 * pi,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return true;
  }
}
