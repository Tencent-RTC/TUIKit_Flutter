import 'live_theme.dart';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class LiveSlider extends StatelessWidget {
  const LiveSlider({
    super.key,
    required this.value,
    this.min = 0,
    required this.max,
    this.step = 1,
    this.onChanged,
    this.semanticLabel,
  })  : assert(max > min),
        assert(step > 0);

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double>? onChanged;
  final String? semanticLabel;

  double _snap(double raw) =>
      (((raw - min) / step).round() * step + min).clamp(min, max).toDouble();

  @override
  Widget build(BuildContext context) {
    final double current = value.clamp(min, max).toDouble();
    final bool reversed = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final double travel = math.max(0, width - 18);
      void update(double x) {
        if (travel == 0) return;
        double fraction = ((x - 9) / travel).clamp(0, 1);
        if (reversed) fraction = 1 - fraction;
        onChanged?.call(_snap(min + fraction * (max - min)));
      }

      void adjust(double delta) => onChanged?.call(_snap(current + delta));
      return Semantics(
        label: semanticLabel,
        value: '${_snap(current)}',
        slider: true,
        enabled: onChanged != null,
        increasedValue: '${_snap(current + step)}',
        decreasedValue: '${_snap(current - step)}',
        onIncrease: onChanged == null ? null : () => adjust(step),
        onDecrease: onChanged == null ? null : () => adjust(-step),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onTapDown: onChanged == null
              ? null
              : (details) => update(details.localPosition.dx),
          onHorizontalDragStart: onChanged == null
              ? null
              : (details) => update(details.localPosition.dx),
          onHorizontalDragUpdate: onChanged == null
              ? null
              : (details) => update(details.localPosition.dx),
          child: SizedBox(
            height: 44,
            width: width,
            child: CustomPaint(
                painter: _LiveSliderPainter(
              fraction: (current - min) / (max - min),
              reversed: reversed,
            )),
          ),
        ),
      );
    });
  }
}

class _LiveSliderPainter extends CustomPainter {
  const _LiveSliderPainter({required this.fraction, required this.reversed});
  final double fraction;
  final bool reversed;
  static const Color blue = LiveTheme.brandBlue;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 18 || size.height <= 0) return;
    final double centerY = size.height / 2;
    final double travel = size.width - 18;
    final double x = 9 + travel * (reversed ? 1 - fraction : fraction);
    final Rect track = Rect.fromLTWH(9, centerY - 1, travel, 2);
    canvas.drawRRect(RRect.fromRectAndRadius(track, const Radius.circular(1)),
        Paint()..color = _SliderStyle.inactiveTrack);
    final Rect active = Rect.fromLTRB(reversed ? x : 9, centerY - 1,
        reversed ? size.width - 9 : x, centerY + 1);
    canvas.drawRRect(RRect.fromRectAndRadius(active, const Radius.circular(1)),
        Paint()..color = blue);
    final Offset center = Offset(x, centerY);
    canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = _SliderStyle.thumbShadow
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, Shadow.convertRadiusToSigma(3)));
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_LiveSliderPainter oldDelegate) =>
      fraction != oldDelegate.fraction || reversed != oldDelegate.reversed;
}

abstract final class _SliderStyle {
  static const inactiveTrack = Color(0x1FFFFFFF);
  static const thumbShadow = Color(0x40000000);
}
