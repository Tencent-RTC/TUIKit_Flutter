import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'constants.dart';

class LiveKitStyle {
  LiveKitStyle._();

  // === Brand & semantic colors (--c-*, per the design :root 2026-09 revision) ===
  static const Color brand = Color(0xFFFF3B6B); // --c-brand
  static const Color brand2 = Color(0xFFFF5580); // --c-brand2 (hover)
  static const Color danger = Color(0xFFFF5252); // --c-danger
  static const Color gold = Color(0xFFFFB020);
  static const Color info = Color(0xFF4C8DFF); // --c-info
  static const Color teal = Color(0xFF2BD9C7); // mobile-parity teal accent

  // === Sender name color pool (barrage / gift list) ===
  static const Color barrageSenderBlue = Color(0xFF4FC3F7); // lake blue
  static const Color barrageSenderGreen = Color(0xFF4DD0E1); // mint green
  static const Color barrageSenderPurple = Color(0xFFB39DDB); // light purple
  static const Color barrageSenderOrange = Color(0xFFFFCA28); // amber
  static const Color barrageSenderCoral = Color(0xFFFF8A80); // coral

  static const List<Color> _barrageSenderColorsList = [
    barrageSenderBlue,
    barrageSenderGreen,
    barrageSenderPurple,
    barrageSenderOrange,
    barrageSenderCoral,
  ];

  static Color barrageSenderColors(String userID) {
    if (userID.isEmpty) return brand;
    return _barrageSenderColorsList[userID.hashCode.abs() %
        _barrageSenderColorsList.length];
  }

  // === Text colors (design tailwind gray scale) ===
  static const Color textPrimary = Color(0xFFE5E7EB); // gray-200
  static const Color textSecondary = Color(0xFFD1D5DB); // gray-300
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400
  static const Color textHint = Color(0xFF6B7280); // gray-500
  static const Color textDisabled = Color(0xFF4B5563); // gray-600
  static const Color textEmphasis = Color(0xFFF3F4F6); // gray-100
  static const Color iconMuted = Color(0xFF9AA1AD); // summary cards
  static const Color textMuted = Color(0xFFB9BFCB);

  /// Design --text-3.
  static const Color text3 = Color(0xFF9AA2B0);

  static const Color titleStrong = Color(0xFFF4F6FA);

  /// Design --border-3.
  static const Color border3 = Color(0xFF545D70);

  /// Design --surface-2.
  static const Color surface2 = Color(0xFF262B35);

  /// Design --surface-3.
  static const Color surface3 = Color(0xFF2E3441);

  // === Source type identity ramp (--src-*) ===
  static const Color srcCamera = Color(0xFFF97287); // --src-cam
  static const Color srcScreen = Color(0xFFF96CAF); // --src-screen
  static const Color srcImage = Color(0xFFF169DD); // --src-image
  static const Color srcOnline = Color(0xFFD475FF); // --src-online
  static const Color srcFile = Color(0xFFAB8AFF); // --src-file

  /// Design: color-mix(in srgb, brand 62%, #FFFFFF); hover 55%.
  static const Color addSourceForeground = Color(0xFFFF85A3);
  static const Color addSourceForegroundHover = Color(0xFFFF93AE);

  static const Color addSourceBackground = Color(0xFF5F233B);
  static const Color addSourceBackgroundHover = Color(0xFF6D2540);
  static const Color addSourceBorder = Color(0xFFDA3660);
  static const Color addSourceBorderHover = brand;

  /// Design .empty-guide-card.
  static const Color srcGuideBg = Color(0xFF242935);

  /// Design .src-name.
  static const Color srcNameColor = Color(0xFFC6CCD7);

  // === Ambient hues ===
  static const Color amb1 = Color(0xFFFF3A7C);
  static const Color amb2 = Color(0xFF965CFF);
  static const Color amb3 = Color(0xFF608DFF);

  // === Typography ===
  static List<String> get cjkFontFamilyFallback => getTargetPlatformTextFont;

  // === Panel geometry ===
  static const double panelRadius = 8;

  // === Translucent whites (design white/N%) ===
  static const Color white4 = Color(0x0AFFFFFF);
  static const Color white5 = Color(0x0DFFFFFF);
  static const Color white6 = Color(0x0FFFFFFF);
  static const Color white8 = Color(0x14FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white15 = Color(0x26FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color whitePure = Color(0xFFFFFFFF);

  // === Window backgrounds (--bg-*) ===
  static const Color bgBase1 = Color(0xFF060408); // --bg-base1
  static const Color bgBase2 = Color(0xFF201628); // --bg-base2
  static const Color bgBase3 = Color(0xFF3B2440); // --bg-base3
  static const Color bgGlow1 = Color(
    0x7AFF4691,
  ); // --bg-glow1 rgba(255,70,145,0.48)
  static const Color bgGlow2 = Color(
    0x4D14EBC8,
  ); // --bg-glow2 rgba(20,235,200,0.3)
  static const Color bgGlow3 = Color(
    0x38608DFF,
  ); // --bg-glow3 rgba(96,141,255,0.22)
  static const Color bgVignette = Color(
    0x73040509,
  ); // --bg-vignette rgba(4,5,9,0.45)
  static const Color shadowBlack = Color(0x42000000);
  static const Color transparent = Color(0x00000000);
  static const Color menuBg = Color(0xD9211E2E); // menu bg #211E2E 85%

  // === Shadow colors ===
  static const Color shadowBlack50 = Color(0x80000000);

  static const Color shadowBlack34 = Color(0x57000000);

  static BoxDecoration glassPanel({double radius = panelRadius}) =>
      BoxDecoration(
        color: const Color(0x66232130),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000), // black 35%
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      );

  static const Color panelAmbient = Color(0xB81F1A26);

  /// Design .panel-ambient overlay.
  static const Gradient ambientPanelGradient = LinearGradient(
    // CSS 165deg: mostly top-to-bottom, slightly right — not a diagonal.
    begin: Alignment(-0.26, -0.97),
    end: Alignment(0.26, 0.97),
    stops: [0, 0.3, 0.62, 0.82, 1],
    colors: [
      Color(0x33FF3A7C), // amb-1 20%
      Color(0x2BFF3A7C), // amb-1 17%
      Color(0x21965CFF), // amb-2 13%
      Color(0x1C965CFF), // amb-2 11%
      Color(0x17608DFF), // amb-3 9%
    ],
  );

  /// Design .panel-ambient-flat: toolbars are too short to unfold a full vertical ramp.
  static const Gradient ambientFlatGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x17FF3B6B), // brand 9%
      Color(0x08FF3B6B), // brand 3%
    ],
  );

  static const Color softPanelBase = Color(0x0EFFFFFF);

  static BoxDecoration softPanel({double radius = 8}) => BoxDecoration(
    color: softPanelBase,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: white8),
  );

  static BoxDecoration glassPanelSoft({double radius = 8}) => BoxDecoration(
    color: const Color(0xFF262B35),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFF414959)),
  );

  /// Fully opaque: a translucent dialog would show the main window through it.
  static BoxDecoration dialogPanel({double radius = 8}) => BoxDecoration(
    color: const Color(0xFF232130),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: white10),
    boxShadow: const [
      BoxShadow(
        color: shadowBlack50, // no material Colors import in this file
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  /// Pre-mixed opaque solids: the design's menu background has no translucency.
  static BoxDecoration menuSurface({double radius = 10}) => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, 0.55, 1],
      colors: [
        Color(0xFF4A1528), // #361121 + brand 10%
        Color(0xFF3E1324), // #361121 + brand 4%
        Color(0xFF3C1223), // #361121 + brand 3%
      ],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: white12),
    boxShadow: [
      BoxShadow(color: shadowBlack50, blurRadius: 30, offset: Offset(0, 12)),
      BoxShadow(color: shadowBlack34, blurRadius: 8, offset: Offset(0, 2)),
    ],
  );
}

/// saturate(160%) has no BackdropFilter equivalent; approximated by the blur alone.
class PusherBackdrop extends StatelessWidget {
  const PusherBackdrop({super.key, required this.radius, required this.child});

  /// Panel corner radius; must match the wrapped panel's border radius.
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: child,
      ),
    );
  }
}

/// The shadow is painted outside the backdrop clip (a same-radius ClipRRect would swallow it);
/// the border uses foregroundDecoration so the gradient does not tint it.
class PusherAmbientPanel extends StatelessWidget {
  const PusherAmbientPanel({
    super.key,
    required this.radius,
    required this.child,
    this.gradient,
    this.width,
    this.height,
    this.padding,
  });

  final double radius;

  final Gradient? gradient;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000), // black 35%
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: PusherBackdrop(
        radius: radius,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: LiveKitStyle.panelAmbient,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: LiveKitStyle.white8),
            borderRadius: borderRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
            child:
                padding == null
                    ? child
                    : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

/// localMatrix stretches the gradient into device space: [yScale] must be ry / rx of the CSS
/// ellipse, and the gradient radius is rx as a fraction of the box's shortest side.
class EllipticalGradientTransform extends GradientTransform {
  const EllipticalGradientTransform({
    required this.center,
    required this.yScale,
  });

  final Alignment center;

  /// Vertical squash factor (ry / rx of the CSS ellipse).
  final double yScale;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final Offset c = center.withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(1.0, yScale, 1.0, 1.0)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}
