import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rings spreading out from the center and fading, around the AI home's orb
/// and call button.
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    required this.color,
    required this.count,
    required this.period,
    required this.startFraction,
    this.maxAlpha = 0.6,
  });

  final Color color;
  final int count;
  final Duration period;

  /// Starting diameter as a share of the shorter side, usually the size of
  /// the element being circled.
  final double startFraction;
  final double maxAlpha;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PulseRingsPainter(
          progress: _controller,
          color: widget.color,
          count: widget.count,
          startFraction: widget.startFraction,
          maxAlpha: widget.maxAlpha,
        ),
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  _PulseRingsPainter({
    required this.progress,
    required this.color,
    required this.count,
    required this.startFraction,
    required this.maxAlpha,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final int count;
  final double startFraction;
  final double maxAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final half = math.min(size.width, size.height) / 2 - 1.5;
    if (half <= 0) return;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    for (var i = 0; i < count; i++) {
      final p = (progress.value + i / count) % 1;
      // Decelerating spread: fast out of the center, slower further out.
      final eased = 1 - (1 - p) * (1 - p);
      final radius = half * (startFraction + (1 - startFraction) * eased);
      // Fade in from zero before fading out, so no hard line hugs the edge.
      final fadeIn = math.min(p / 0.18, 1.0);
      final fadeOut = (1 - p) * (1 - p);
      paint
        ..strokeWidth = 2 - 1.2 * p
        ..color = color.withAlpha(
            (maxAlpha * fadeIn * fadeOut * 255).round().clamp(0, 255));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingsPainter oldDelegate) =>
      color != oldDelegate.color ||
      count != oldDelegate.count ||
      startFraction != oldDelegate.startFraction ||
      maxAlpha != oldDelegate.maxAlpha;
}
