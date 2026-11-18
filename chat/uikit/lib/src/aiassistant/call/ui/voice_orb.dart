import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../ai_call_state.dart';

/// The orb in the middle of the call page. Colors come from the app theme's
/// primary button color, with the neighboring hover / active shades for depth.
///
/// listening: glowing orb that breathes
/// speaking : soft-edged orb whose radius follows the smoothed playback level,
///            with a light breath in the gaps
/// thinking : slowly rotating sweep gradient
/// idle     : still frame of listening, same color and glow with the radius
///            pinned. A dark solid circle on entry would look like an unlit
///            empty orb.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.state,
    required this.level,
    required this.colorLight,
    required this.colorCore,
    required this.colorDark,
    this.auroraStyle = false,
    this.auroraOnDark = false,
  });

  final AICallState state;

  /// Playback / microphone level in 0..1. Read on every frame while speaking,
  /// not listened to: it changes every 20ms.
  final ValueListenable<double> level;

  final Color colorLight;
  final Color colorCore;
  final Color colorDark;

  /// Aurora look used by the experience demo's AI home and call page: colored
  /// glows drifting inside a softly deforming outline. Off keeps the original
  /// drawing; the theme colors are not used while it is on.
  final bool auroraStyle;

  /// Brighter, clearer glow for dark backgrounds.
  final bool auroraOnDark;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  /// Catches up with a sudden rise in about 40ms.
  static const double _levelAttack = 0.38;

  /// Falls back in about 150ms, so gaps between words do not jitter.
  static const double _levelRelease = 0.10;

  static const double _frameMs = 1000 / 60;

  late final Ticker _ticker = createTicker(_onTick);

  /// Breath / rotation progress, 0..1.
  double _phase = 0;

  /// The level actually drawn, following the target with fast attack and slow
  /// release so TTS chunks of 20~60ms do not make the orb step.
  double _displayedLevel = 0;

  Duration _lastElapsed = Duration.zero;

  /// Aurora motion runs on its own accumulated time, so speed changes only
  /// affect later increments and never make the picture jump.
  double _auroraTime = 0;
  double _smoothEnergy = 0.2;
  double _smoothBoost = 0;

  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.auroraStyle != widget.auroraStyle) {
      if (widget.state != AICallState.speaking) {
        _displayedLevel = 0;
      }
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _ticker.stop();
    _phase = 0;
    _lastElapsed = Duration.zero;
    if (widget.state != AICallState.idle || widget.auroraStyle) {
      _ticker.start();
    }
  }

  int get _periodMs {
    switch (widget.state) {
      case AICallState.listening:
        return 2600;
      case AICallState.thinking:
        return 1400;
      case AICallState.speaking:
      case AICallState.idle:
        return 2000;
    }
  }

  void _onTick(Duration elapsed) {
    final periodUs = _periodMs * 1000;
    final dtMs = (elapsed - _lastElapsed).inMicroseconds / 1000;
    _lastElapsed = elapsed;
    setState(() {
      _phase = (elapsed.inMicroseconds % periodUs) / periodUs;
      if (widget.state == AICallState.speaking) {
        _tickDisplayedLevel(dtMs);
      }
      if (widget.auroraStyle) {
        _tickAurora((dtMs / 1000).clamp(0.0, 0.05).toDouble());
      }
    });
  }

  /// State energy and the volume boost ease exponentially, so state switches
  /// and level jitter never change the orb abruptly.
  void _tickAurora(double dt) {
    final double targetEnergy;
    switch (widget.state) {
      case AICallState.idle:
        targetEnergy = 0.2;
        break;
      case AICallState.listening:
        targetEnergy = 0.4;
        break;
      case AICallState.thinking:
        targetEnergy = 0.7;
        break;
      case AICallState.speaking:
        targetEnergy = 0.55 + 0.35 * _displayedLevel;
        break;
    }
    _smoothEnergy += (targetEnergy - _smoothEnergy) * (1 - math.exp(-dt * 3));
    final targetBoost =
        widget.state == AICallState.speaking ? _displayedLevel : 0.0;
    _smoothBoost += (targetBoost - _smoothBoost) * (1 - math.exp(-dt * 10));
    _auroraTime += dt * (0.5 + 1.3 * _smoothEnergy);
  }

  /// The coefficients are per 60fps frame; they are scaled by the real frame
  /// time so high refresh rates do not speed up the envelope.
  void _tickDisplayedLevel(double dtMs) {
    final target = widget.level.value.clamp(0.0, 1.0).toDouble();
    final perFrame = target > _displayedLevel ? _levelAttack : _levelRelease;
    final alpha = 1 - math.pow(1 - perFrame, dtMs / _frameMs).toDouble();
    _displayedLevel += (target - _displayedLevel) * alpha;
    if ((_displayedLevel - target).abs() < 0.002) {
      _displayedLevel = target;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auroraStyle) {
      return CustomPaint(
        painter: _AuroraOrbPainter(
          time: _auroraTime,
          energy: _smoothEnergy,
          boost: _smoothBoost,
          onDark: widget.auroraOnDark,
        ),
      );
    }
    return CustomPaint(
      painter: _VoiceOrbPainter(
        state: widget.state,
        phase: _phase,
        level: _displayedLevel,
        colorLight: widget.colorLight,
        colorCore: widget.colorCore,
        colorDark: widget.colorDark,
      ),
    );
  }
}

class _VoiceOrbPainter extends CustomPainter {
  _VoiceOrbPainter({
    required this.state,
    required this.phase,
    required this.level,
    required this.colorLight,
    required this.colorCore,
    required this.colorDark,
  });

  /// Share of the radius taken by the outward glow.
  static const double _glowRatio = 0.22;

  /// Midpoint of the listening breath; idle is pinned here so entering the
  /// page and starting to listen show the same orb.
  static const double _restScale = 0.85;

  final AICallState state;
  final double phase;
  final double level;
  final Color colorLight;
  final Color colorCore;
  final Color colorDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    if (maxRadius <= 0) return;
    // The glow spreads outward; the body leaves room for it or the glow is
    // clipped square by the bounds.
    final baseRadius = maxRadius * (1 - _glowRatio);
    switch (state) {
      case AICallState.listening:
        final breath = _restScale + 0.07 * math.sin(phase * 2 * math.pi);
        _drawGlowingOrb(canvas, center, maxRadius, baseRadius * breath);
        break;
      case AICallState.speaking:
        _drawSpeaking(canvas, center, baseRadius);
        break;
      case AICallState.thinking:
        _drawThinking(canvas, center, maxRadius, baseRadius);
        break;
      case AICallState.idle:
        _drawGlowingOrb(canvas, center, maxRadius, baseRadius * _restScale);
        break;
    }
  }

  /// Radius follows the smoothed level with a faint breath so it never fully
  /// stops between words. A transparent outer stop softens the edge instead
  /// of a blur.
  void _drawSpeaking(Canvas canvas, Offset center, double baseRadius) {
    final breath = math.sin(phase * 2 * math.pi);
    final radius = baseRadius * (0.84 + 0.14 * level + 0.025 * breath);
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [colorLight, colorCore, colorDark, colorDark.withAlpha(0)],
        const [0, 0.48, 0.78, 1],
      );
    canvas.drawCircle(center, radius, paint);
  }

  /// The gradient turns through its own matrix while the circle stays put.
  /// Rotating the canvas instead makes Impeller clip the blurred circle to a
  /// spinning wedge.
  void _drawThinking(
      Canvas canvas, Offset center, double maxRadius, double baseRadius) {
    final radius = baseRadius * 0.84;
    final rotation = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(phase * 2 * math.pi)
      ..translate(-center.dx, -center.dy);
    final paint = Paint()
      ..isAntiAlias = true
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, _blurSigma(maxRadius * 0.12))
      ..shader = ui.Gradient.sweep(
        center,
        [colorCore, colorDark, colorLight, colorCore],
        const [0, 0.34, 0.67, 1],
        TileMode.clamp,
        0,
        2 * math.pi,
        rotation.storage,
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawGlowingOrb(
      Canvas canvas, Offset center, double maxRadius, double radius) {
    final paint = Paint()
      ..isAntiAlias = true
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, _blurSigma(maxRadius * _glowRatio))
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [colorLight, colorCore, colorDark],
        const [0, 0.6, 1],
      );
    canvas.drawCircle(center, radius, paint);
  }

  /// Android's BlurMaskFilter takes a radius; Skia converts it to sigma this
  /// way.
  static double _blurSigma(double radius) => radius * 0.57735 + 0.5;

  @override
  bool shouldRepaint(covariant _VoiceOrbPainter oldDelegate) {
    return state != oldDelegate.state ||
        phase != oldDelegate.phase ||
        level != oldDelegate.level ||
        colorLight != oldDelegate.colorLight ||
        colorCore != oldDelegate.colorCore ||
        colorDark != oldDelegate.colorDark;
  }
}

/// Aurora orb: colored soft lights orbit slowly inside a rounded outline and
/// blend into each other, with a soft outer glow and a top-left highlight.
///
/// The outline only uses low-frequency deformation joined with quadratic
/// curves, so the edge stays round; the lights are painted with srcATop inside
/// a layer holding the anti-aliased outline, so the edge does not alias.
class _AuroraOrbPainter extends CustomPainter {
  _AuroraOrbPainter({
    required this.time,
    required this.energy,
    required this.boost,
    required this.onDark,
  });

  static const double _glowRatio = 0.22;

  /// The glow shader radius as a share of the drawable radius, leaving room
  /// for up to 1.2x scaling.
  static const double _glowBase = 0.82;
  static const int _points = 48;
  static const Color _base = Color(0xFF5B3CFF);
  static const Color _glow = Color(0xFF7B5CFF);
  static const Color _glowOuter = Color(0xFF2EC5FF);
  static const Color _glowDark = Color(0xFF9B87FF);
  static const Color _glowOuterDark = Color(0xFF5AD8FF);
  static const List<Color> _blobColors = [
    Color(0xFF2EC5FF),
    Color(0xFF6AF2C6),
    Color(0xFFFF6FD8),
    Color(0xFFB36BFF),
  ];
  static const List<double> _blobSpeed = [0.9, -0.7, 0.6, -1.1];
  static const List<double> _blobPhase = [0, 1.6, 3.2, 4.7];

  final double time;
  final double energy;
  final double boost;
  final bool onDark;

  static Color _alpha(Color color, double alpha) =>
      color.withAlpha((alpha.clamp(0.0, 1.0) * 255).round());

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    if (maxRadius <= 0) return;
    final baseRadius = maxRadius * (1 - _glowRatio);
    final t = time;
    final r = baseRadius * (0.86 + 0.018 * math.sin(t * 1.6) + 0.1 * boost);
    final scale = r / baseRadius;

    // Outer glow. Ends in the same color fully transparent rather than
    // transparent black, which would look muddy on a dark background.
    final glowScale = 1 + 0.03 * (math.sin(t * 1.2) + 1) + 0.12 * boost;
    final glowAlpha = onDark ? 0.8 + 0.2 * energy : 0.55 + 0.35 * energy;
    final inner = onDark ? _glowDark : _glow;
    final outer = onDark ? _glowOuterDark : _glowOuter;
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(
          center,
          maxRadius * _glowBase * glowScale,
          [
            _alpha(inner, 0.9 * glowAlpha),
            _alpha(inner, 0.8 * glowAlpha),
            _alpha(inner, 0.6 * glowAlpha),
            _alpha(outer, 0.32 * glowAlpha),
            _alpha(outer, 0.12 * glowAlpha),
            _alpha(outer, 0),
          ],
          const [0, 0.6, 0.78, 0.87, 0.94, 1],
        ),
    );

    final amp = r * (0.01 + 0.03 * energy);
    final xs = List<double>.filled(_points, 0);
    final ys = List<double>.filled(_points, 0);
    for (var k = 0; k < _points; k++) {
      final theta = k * 2 * math.pi / _points;
      final d = 0.6 * math.sin(2 * theta + t * 1.3) +
          0.4 * math.sin(3 * theta - t * 0.9);
      final rr = r + amp * d;
      xs[k] = center.dx + rr * math.cos(theta);
      ys[k] = center.dy + rr * math.sin(theta);
    }
    final path = Path()
      ..moveTo((xs[_points - 1] + xs[0]) / 2, (ys[_points - 1] + ys[0]) / 2);
    for (var k = 0; k < _points; k++) {
      final n = (k + 1) % _points;
      path.quadraticBezierTo(
          xs[k], ys[k], (xs[k] + xs[n]) / 2, (ys[k] + ys[n]) / 2);
    }
    path.close();

    final bound = Rect.fromCircle(center: center, radius: r * 1.15);
    canvas.saveLayer(bound, Paint());
    canvas.drawPath(
        path,
        Paint()
          ..isAntiAlias = true
          ..color = _base);
    for (var i = 0; i < _blobColors.length; i++) {
      final angle = t * _blobSpeed[i] + _blobPhase[i];
      final orbit = r * (0.42 + 0.08 * math.sin(t * 0.7 + i));
      final blobCenter = Offset(center.dx + math.cos(angle) * orbit,
          center.dy + math.sin(angle) * orbit * 0.9);
      final color = _blobColors[i];
      _fillAtop(canvas, bound, blobCenter, baseRadius * 0.95 * scale,
          [color, _alpha(color, 0.55), _alpha(color, 0)], const [0, 0.45, 1]);
    }
    _fillAtop(
        canvas,
        bound,
        Offset(center.dx - r * 0.3, center.dy - r * 0.38),
        baseRadius * 0.75 * scale,
        const [Color(0xB3FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
        const [0, 0.45, 1]);
    _fillAtop(
        canvas,
        bound,
        Offset(center.dx + r * 0.38, center.dy + r * 0.5),
        baseRadius * 0.9 * scale,
        const [Color(0x55100A40), Color(0x00100A40)],
        const [0, 1]);
    canvas.restore();
  }

  void _fillAtop(Canvas canvas, Rect bound, Offset center, double radius,
      List<Color> colors, List<double> stops) {
    canvas.drawRect(
      bound,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = ui.Gradient.radial(center, radius, colors, stops),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraOrbPainter oldDelegate) {
    return time != oldDelegate.time ||
        energy != oldDelegate.energy ||
        boost != oldDelegate.boost ||
        onDark != oldDelegate.onDark;
  }
}
