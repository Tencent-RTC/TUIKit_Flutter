import 'package:flutter/widgets.dart';

class BottomSheetBackgroundView extends StatelessWidget {
  const BottomSheetBackgroundView({super.key, required this.child});

  final Widget child;

  static const double _cornerRadius = 26;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double horizontalScale = width / 390;

        return CustomPaint(
          painter: BottomSheetTheme.isEnabled(context)
              ? const _SheetShadowPainter()
              : null,
          child: DecoratedBox(
            decoration: BottomSheetTheme.isEnabled(context)
                ? const BoxDecoration()
                : const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xB3000000),
                          offset: Offset(0, -24),
                          blurRadius: 80),
                      BoxShadow(
                          color: Color(0x4D4A9EFF),
                          offset: Offset(0, -6),
                          blurRadius: 32),
                    ],
                  ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_cornerRadius),
                  ),
                  child: Stack(
                    children: <Widget>[
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                _SheetBackgroundStyle.top,
                                _SheetBackgroundStyle.bottom,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0x0DFFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: <double>[0, 0.2],
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0x09FFFFFF),
                                Color(0x04FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _glow(
                        context,
                        left: 39 * horizontalScale,
                        top: height - 40,
                        size: Size(312 * horizontalScale, 80),
                        color: const Color(0x384A9EFF),
                      ),
                      _glow(
                        context,
                        left: -148.8 * horizontalScale,
                        top: -180 + 0.08 * height,
                        size: Size(360 * horizontalScale, 360),
                        color: const Color(0x514A9EFF),
                      ),
                      _glow(
                        context,
                        left: 218.8 * horizontalScale,
                        top: -140 + 0.01 * height,
                        size: Size(280 * horizontalScale, 280),
                        color: const Color(0x4A7DE8FF),
                      ),
                      _glow(
                        context,
                        left: 135 * horizontalScale,
                        top: -60 + 0.43 * height,
                        size: Size(120 * horizontalScale, 120),
                        color: const Color(0x590052D9),
                      ),
                      _glow(
                        context,
                        left: -45.4 * horizontalScale,
                        top: -100 + 0.99 * height,
                        size: Size(200 * horizontalScale, 200),
                        color: const Color(0x3B7DE8FF),
                      ),
                      _glow(
                        context,
                        left: 262.2 * horizontalScale,
                        top: -120 + 0.99 * height,
                        size: Size(240 * horizontalScale, 240),
                        color: const Color(0x434A9EFF),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 1 / MediaQuery.of(context).devicePixelRatio,
                        child: const ColoredBox(
                          color: Color(0x24FFFFFF),
                          child: SizedBox.expand(),
                        ),
                      ),
                      Positioned(
                        left: (width - 36) / 2,
                        top: 10,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _SheetBackgroundStyle.handle,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                          child: SizedBox(width: 36, height: 4),
                        ),
                      ),
                      Positioned.fill(child: child),
                    ],
                  ),
                ),
                Positioned(
                  left: width * 0.15,
                  top: 0,
                  width: width * 0.7,
                  height: 2,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0x004A9EFF),
                          Color(0xE64A9EFF),
                          Color(0xE67DE8FF),
                          Color(0x007DE8FF),
                        ],
                        stops: <double>[0, 0.3, 0.7, 1],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: Color(0xB34A9EFF), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glow(
    BuildContext context, {
    required double left,
    required double top,
    required Size size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
          child: BottomSheetTheme.isEnabled(context)
              ? CustomPaint(painter: _SheetGlowPainter(color))
              : DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                          colors: [color, color.withAlpha(0)])))),
    );
  }
}

class _SheetShadowPainter extends CustomPainter {
  const _SheetShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    // UIKit's explicit shadowPath is inset from the filled layer. Flutter's
    // BoxShadow follows the decoration's outer contour, so paint each path
    // separately without clipping the blur to the sheet.
    for (final (
          double inset,
          double radius,
          double blur,
          double dy,
          Color color
        ) in [
      (24.0, 2.0, 80.0, -24.0, const Color(0xB3000000)),
      (12.0, 14.0, 32.0, -6.0, const Color(0x4D4A9EFF)),
    ]) {
      final Rect rect = bounds.deflate(inset);
      if (rect.isEmpty) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.shift(Offset(0, dy)), Radius.circular(radius)),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, Shadow.convertRadiusToSigma(blur)),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(bounds,
          topLeft: const Radius.circular(26),
          topRight: const Radius.circular(26)),
      Paint()..color = _SheetBackgroundStyle.bottom,
    );
  }

  @override
  bool shouldRepaint(_SheetShadowPainter oldDelegate) => false;
}

class _SheetGlowPainter extends CustomPainter {
  const _SheetGlowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // CAGradientLayer defines each ellipse diameter as twice the corresponding
    // endPoint - startPoint component. (0.5, 0.5) -> (1, 1) therefore has
    // radius 0.5 on both unit-square axes, not the distance to the corner.
    // Scale both axes to preserve elliptical glows on non-square layers.
    canvas.save();
    canvas.scale(size.width, size.height);
    const Rect unit = Rect.fromLTWH(0, 0, 1, 1);
    canvas.drawRect(
        unit,
        Paint()
          ..shader = RadialGradient(
            radius: 0.5,
            colors: [color, color.withAlpha(0)],
          ).createShader(unit));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheetGlowPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Scoped rollout keeps existing Player panels unchanged while Pusher adopts
/// the current shared sheet geometry. The scope owns no state or SDK calls.
class BottomSheetTheme extends InheritedWidget {
  const BottomSheetTheme({super.key, required super.child});

  static bool isEnabled(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BottomSheetTheme>() != null;

  @override
  bool updateShouldNotify(BottomSheetTheme oldWidget) => false;
}

abstract final class _SheetBackgroundStyle {
  static const top = Color(0xFF181620);
  static const bottom = Color(0xFF0A090E);
  static const handle = Color(0x33FFFFFF);
}
