import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

/// Centered dialog that picks the app primary color through HSV sliders,
/// mirroring the native Android `PrimaryColorPickerDialog`.
///
/// Theme color is an app-level concern (the native side keeps this dialog in the
/// demo app too), so it deliberately lives here rather than in the chat UIKit.
///
/// There is deliberately no preset swatch grid: the native implementation lets
/// the user land on any hue/saturation/brightness and only offers a reset back
/// to [defaultPrimaryColor].
class ThemeColorPicker extends StatefulWidget {
  const ThemeColorPicker._({required this.initialColor});

  /// Same default as the native demos and `AppBuilderConfig.primaryColor`.
  static const String defaultPrimaryColor = '#1C66E5';

  final Color initialColor;

  /// Shows the picker and resolves to the chosen hex string, or `null` when the
  /// user dismissed it.
  static Future<String?> show(BuildContext context, {String? selectedHex}) {
    return showDialog<String>(
      context: context,
      builder: (_) => ThemeColorPicker._(
        initialColor: parseHex(selectedHex) ?? parseHex(defaultPrimaryColor)!,
      ),
    );
  }

  /// Parses `#RRGGBB` (with or without the leading `#`). Returns `null` when the
  /// input isn't a valid 6-digit hex color.
  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(normalized)) return null;
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static String toHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }

  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  Color get _color => _hsv.toColor();

  /// The full spectrum, independent of the current selection.
  List<Color> get _hueGradient =>
      [for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor()];

  /// These two track the live selection, so dragging any slider restains the
  /// other tracks — the same feedback the native dialog gives.
  List<Color> get _saturationGradient => [
        HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
        HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
      ];

  List<Color> get _brightnessGradient => [
        Colors.black,
        HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
      ];

  void _reset() {
    setState(() {
      _hsv = HSVColor.fromColor(ThemeColorPicker.parseHex(ThemeColorPicker.defaultPrimaryColor)!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);

    return Dialog(
      backgroundColor: colors.bgColorDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              locale.selectThemeColor,
              textAlign: TextAlign.center,
              style: FontScheme.body4Bold.copyWith(color: colors.textColorPrimary),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.strokeColorPrimary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${locale.colorHex}: ${ThemeColorPicker.toHex(_color)}',
              textAlign: TextAlign.center,
              style: FontScheme.caption2Regular.copyWith(color: colors.textColorSecondary),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: locale.colorHue,
              value: _hsv.hue / 360,
              gradientColors: _hueGradient,
              colors: colors,
              onChanged: (value) => setState(() => _hsv = _hsv.withHue(value * 360)),
            ),
            _buildSlider(
              label: locale.colorSaturation,
              value: _hsv.saturation,
              gradientColors: _saturationGradient,
              colors: colors,
              onChanged: (value) => setState(() => _hsv = _hsv.withSaturation(value)),
            ),
            _buildSlider(
              label: locale.colorBrightness,
              value: _hsv.value,
              gradientColors: _brightnessGradient,
              colors: colors,
              onChanged: (value) => setState(() => _hsv = _hsv.withValue(value)),
              isLast: true,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    locale.reset,
                    style: FontScheme.caption1Regular.copyWith(color: colors.textColorSecondary),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    locale.cancel,
                    style: FontScheme.caption1Regular.copyWith(color: colors.textColorSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(ThemeColorPicker.toHex(_color)),
                  child: Text(
                    locale.confirm,
                    style: FontScheme.caption1Medium.copyWith(color: colors.textColorLink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required List<Color> gradientColors,
    required SemanticColorScheme colors,
    required ValueChanged<double> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FontScheme.caption3Regular.copyWith(color: colors.textColorSecondary),
          ),
          const SizedBox(height: 4),
          _GradientSliderBar(
            value: value.clamp(0.0, 1.0),
            gradientColors: gradientColors,
            thumbColor: _color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Slider whose track paints an arbitrary gradient and whose thumb is filled
/// with the live selection, matching the native `GradientSliderBar`.
///
/// Material's [Slider] can't express this: it only paints flat active/inactive
/// track colors.
class _GradientSliderBar extends StatelessWidget {
  const _GradientSliderBar({
    required this.value,
    required this.gradientColors,
    required this.thumbColor,
    required this.onChanged,
  });

  /// Normalized position in `0..1`.
  final double value;
  final List<Color> gradientColors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  static const double _trackHeight = 24;

  /// Room above and below the track for the thumb's drop shadow.
  static const double _shadowPadding = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // The thumb centre can only travel between the track's rounded caps, so
        // map taps onto that inset range instead of the full width.
        void report(double dx) {
          const radius = _trackHeight / 2;
          final maxCentre = math.max(radius, width - radius);
          final usableWidth = math.max(1.0, width - radius * 2);
          onChanged(((dx.clamp(radius, maxCentre) - radius) / usableWidth).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => report(details.localPosition.dx),
          onHorizontalDragStart: (details) => report(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => report(details.localPosition.dx),
          child: SizedBox(
            width: width,
            height: _trackHeight + _shadowPadding * 2,
            child: CustomPaint(
              painter: _GradientSliderPainter(
                value: value,
                gradientColors: gradientColors,
                thumbColor: thumbColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientSliderPainter extends CustomPainter {
  _GradientSliderPainter({
    required this.value,
    required this.gradientColors,
    required this.thumbColor,
  });

  final double value;
  final List<Color> gradientColors;
  final Color thumbColor;

  static const Color _shadowColor = Color(0x29000000);

  /// White ring thickness around the thumb's colored core.
  static const double _thumbBezel = 3;

  @override
  void paint(Canvas canvas, Size size) {
    const trackTop = _GradientSliderBar._shadowPadding;
    final trackBottom = size.height - _GradientSliderBar._shadowPadding;
    if (trackBottom <= trackTop || size.width <= 0) return;

    final trackRadius = (trackBottom - trackTop) / 2;
    final track = Rect.fromLTRB(0, trackTop, size.width, trackBottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, Radius.circular(trackRadius)),
      Paint()..shader = LinearGradient(colors: gradientColors).createShader(track),
    );

    final usableWidth = math.max(0.0, size.width - trackRadius * 2);
    final centre = Offset(trackRadius + value * usableWidth, (trackTop + trackBottom) / 2);

    canvas.drawCircle(centre.translate(0, 1), trackRadius, Paint()..color = _shadowColor);
    canvas.drawCircle(centre, trackRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      centre,
      math.max(0.0, trackRadius - _thumbBezel),
      Paint()..color = thumbColor,
    );
    canvas.drawCircle(
      centre,
      trackRadius - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _shadowColor,
    );
  }

  @override
  bool shouldRepaint(_GradientSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.thumbColor != thumbColor ||
        !_sameColors(oldDelegate.gradientColors, gradientColors);
  }

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
