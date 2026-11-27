library;

import 'dart:async';
import 'dart:math' as math;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../live_kit_resources.dart';
import 'gift_send_panel_view.dart';

class GiftSendComboButton extends StatefulWidget {
  const GiftSendComboButton({
    super.key,
    required this.controller,
    this.faceDiameter = 68,
  });

  final GiftSendComboButtonController controller;
  final double faceDiameter;

  @override
  State<GiftSendComboButton> createState() => _GiftSendComboButtonState();
}

class _GiftSendComboButtonState extends State<GiftSendComboButton> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _badgePopController;
  Timer? _expireTimer;
  Timer? _holdDelayTimer;
  Timer? _holdRepeatTimer;
  bool _pressing = false;
  Offset? _pressOrigin;
  int _count = 0;
  Gift? _gift;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: GiftSendComboButtonController.comboDuration,
    );
    _badgePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant GiftSendComboButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach(this);
      _cancelTimers();
      _progressController.stop();
      _gift = null;
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _cancelTimers();
    _progressController.dispose();
    _badgePopController.dispose();
    super.dispose();
  }

  void _begin(Gift gift) {
    _cancelTimers();
    setState(() {
      _gift = gift;
      _count = 0;
    });
    _performSingleShot();
  }

  void _end() {
    _cancelTimers();
    _progressController.stop();
    if (!mounted) return;
    setState(() {
      _gift = null;
    });
  }

  void _cancelTimers() {
    _expireTimer?.cancel();
    _expireTimer = null;
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = null;
    _pressing = false;
    _pressOrigin = null;
  }

  void _performSingleShot() {
    if (_gift == null) return;
    setState(() {
      _count += 1;
    });
    _badgePopController.forward(from: 0);
    _restartTimer();
    widget.controller._notifySendOnce();
  }

  void _restartTimer() {
    _progressController.stop();
    _progressController.value = 0;
    _progressController.forward();
    _expireTimer?.cancel();
    _expireTimer = Timer(GiftSendComboButtonController.comboDuration, () {
      _handleExpired();
    });
  }

  void _handleExpired() {
    _cancelTimers();
    widget.controller._notifyExpired();
  }

  void _handleTouchDown() {
    if (_gift == null) return;
    _pressing = true;
    _performSingleShot();
    _holdDelayTimer?.cancel();
    _holdDelayTimer = Timer(GiftSendComboButtonController.holdDelay, () {
      _startHoldRepeat();
    });
  }

  void _handleTouchUp() {
    _pressing = false;
    _pressOrigin = null;
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = null;
  }

  void _startHoldRepeat() {
    if (!_pressing || _gift == null) return;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = Timer.periodic(GiftSendComboButtonController.holdInterval, (Timer timer) {
      if (!_pressing || _gift == null) {
        timer.cancel();
        return;
      }
      _performSingleShot();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gift == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 4),
          SizedBox(
            width: widget.faceDiameter,
            height: widget.faceDiameter,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              // UIControl's touchDown is immediate. TapGestureRecognizer
              // delays onTapDown while competing with the gift grid's scroll.
              onPointerDown: (event) {
                _pressOrigin = event.position;
                _handleTouchDown();
              },
              onPointerMove: (event) {
                final origin = _pressOrigin;
                if (origin != null && (event.position - origin).distance > kTouchSlop) {
                  _handleTouchUp();
                }
              },
              onPointerUp: (_) => _handleTouchUp(),
              onPointerCancel: (_) => _handleTouchUp(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                onTapCancel: _handleTouchUp,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: _ComboFacePainter(
                        progress: 1 - _progressController.value,
                      ),
                      child: child,
                    );
                  },
                  child: Center(child: _buildFaceContent()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildFaceContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        _formattedHint(LiveKitResources.localizedString(
          'tuilivekit.player.gift.combo.hint',
        )),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _badgePopController,
      builder: (BuildContext context, Widget? child) {
        final double t = _badgePopController.value;
        final double scale = 1 + (1 - Curves.easeOutBack.transform(t)) * 0.35;
        return Transform.scale(scale: scale, child: child);
      },
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 30),
          height: (MediaQuery.textScalerOf(context).scale(12) * 1.2).clamp(20.0, double.infinity).toDouble(),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: GiftPanelStyle.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$_count',
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formattedHint(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.contains(' ')) return trimmed;
    final characters = trimmed.characters;
    if (characters.length != 4) return trimmed;
    return '${characters.take(2)}\n${characters.skip(2)}';
  }
}

class GiftSendComboButtonController extends ChangeNotifier {
  static const Duration comboDuration = Duration(milliseconds: 2000);
  static const Duration holdDelay = Duration(milliseconds: 300);
  static const Duration holdInterval = Duration(milliseconds: 300);

  _GiftSendComboButtonState? _state;

  VoidCallback? onSendOnce;
  VoidCallback? onExpired;

  Gift? get gift => _state?._gift;
  bool get isRunning => _state?._gift != null;
  bool get isAttached => _state != null;

  void begin(Gift gift) {
    _state?._begin(gift);
  }

  void end() {
    _state?._end();
  }

  void _attach(_GiftSendComboButtonState state) {
    _state = state;
  }

  void _detach(_GiftSendComboButtonState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  void _notifySendOnce() {
    onSendOnce?.call();
  }

  void _notifyExpired() {
    onExpired?.call();
  }
}

class _ComboFacePainter extends CustomPainter {
  const _ComboFacePainter({required this.progress});

  final double progress;

  static const Color _brandBlue = GiftPanelStyle.blue;
  static const Color _brandBlueDark = GiftPanelStyle.deepBlue;
  static const Color _faceFill = Color(0xE605060C);
  static const double _faceToCoreRatio = 46.0 / 52.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = math.min(size.width, size.height) / 2 - 2;
    final double coreRadius = outerRadius - 6;
    final Paint fill = Paint()
      ..color = _faceFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, fill);

    _paintProgress(canvas, center, outerRadius);

    final double faceSide = coreRadius * 2 * _faceToCoreRatio;
    final Rect faceRect = Rect.fromCenter(
      center: center,
      width: faceSide,
      height: faceSide,
    );
    final Paint facePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[_brandBlue, _brandBlue, _brandBlueDark],
        stops: <double>[0, 0.55, 1],
      ).createShader(faceRect);
    canvas.drawCircle(center, faceSide / 2, facePaint);

    final Paint highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.7),
        // CAGradientLayer's normalized start/end differ by .55 on each
        // axis. Flutter's radius is the circle radius, not its diameter.
        radius: 0.55,
        colors: <Color>[
          Colors.white.withOpacity(0.28),
          Colors.white.withOpacity(0),
        ],
        stops: const <double>[0, 1],
      ).createShader(faceRect);
    canvas.drawCircle(center, faceSide / 2, highlightPaint);
  }

  void _paintProgress(Canvas canvas, Offset center, double outerRadius) {
    final double progressRadius = outerRadius - 3;
    final double circumference = 2 * math.pi * progressRadius;
    final double dashLength = circumference * 8.0 / 360.0;
    final double gapLength = circumference * 4.0 / 360.0;
    final double perDash = dashLength + gapLength;
    final int dashCount = circumference ~/ perDash;

    final Rect arcRect = Rect.fromCircle(center: center, radius: progressRadius);
    final double clamped = progress.clamp(0.0, 1.0).toDouble();
    final double activeSweep = 2 * math.pi * clamped;
    if (activeSweep <= 0) return;

    final Paint glowPaint = Paint()
      ..color = _brandBlue.withOpacity(0.72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(5));
    final Paint progressPaint = Paint()
      ..color = _brandBlue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    const double startAngle = -math.pi / 2;
    final double endAngle = startAngle - activeSweep;
    final double dashRad = dashLength / progressRadius;
    final double stepRad = perDash / progressRadius;
    for (final Paint paint in <Paint>[glowPaint, progressPaint]) {
      for (int i = 0; i < dashCount + 1; i++) {
        final double dashStart = startAngle - i * stepRad;
        final double dashEnd = math.max(dashStart - dashRad, endAngle);
        if (dashEnd >= dashStart) break;
        canvas.drawArc(arcRect, dashStart, dashEnd - dashStart, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ComboFacePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
