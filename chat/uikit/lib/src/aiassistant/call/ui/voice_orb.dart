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
  });

  final AICallState state;

  /// Playback / microphone level in 0..1. Read on every frame while speaking,
  /// not listened to: it changes every 20ms.
  final ValueListenable<double> level;

  final Color colorLight;
  final Color colorCore;
  final Color colorDark;

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

  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
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
    if (widget.state != AICallState.idle) {
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
    });
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
