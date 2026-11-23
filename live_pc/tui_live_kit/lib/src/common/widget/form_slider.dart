import 'package:flutter/material.dart';

import '../../l10n/live_kit_localizations.dart';
import '../style/live_kit_style.dart';
import 'form_controls.dart';

class LabeledSliderGroup extends StatelessWidget {
  const LabeledSliderGroup({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.display,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FormFieldLabel(label),
            Text(display, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        GradientSlider(
          fraction: (value / max).clamp(0.0, 1.0),
          tickCount: divisions,
          onChanged: (fraction) {
            final raw = fraction * max;
            onChanged(divisions != null ? raw.roundToDouble() : raw);
          },
        ),
      ],
    );
  }
}

class VolumeSliderGroup extends StatelessWidget {
  const VolumeSliderGroup({super.key, required this.volume, required this.onChanged});

  final int volume;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledSliderGroup(
      label: LiveKitLocalizations.of(context).playbackVolume,
      value: volume.toDouble(),
      max: 100,
      display: '$volume',
      onChanged: (value) => onChanged(value.round()),
    );
  }
}

class GradientSlider extends StatelessWidget {
  const GradientSlider({super.key, required this.fraction, required this.onChanged, this.tickCount});

  final double fraction;
  final ValueChanged<double> onChanged;

  final int? tickCount;

  static const double _trackHeight = 6;
  static const double _thumbSize = 14;
  static const double _tickSize = 4;

  void _update(double dx, double width) {
    if (width <= 0) {
      return;
    }
    onChanged((dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbCenter = (fraction * width).clamp(
          _thumbSize / 2,
          (width - _thumbSize / 2).clamp(_thumbSize / 2, double.infinity),
        );
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _update(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) => _update(details.localPosition.dx, width),
            child: SizedBox(
              height: 20,
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  height: _thumbSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Unswept track (fills the whole row; must be explicitly
                      // full-width under Center's loose constraints).
                      Positioned.fill(
                        top: (_thumbSize - _trackHeight) / 2,
                        bottom: (_thumbSize - _trackHeight) / 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF414959),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: (_thumbSize - _trackHeight) / 2,
                        bottom: (_thumbSize - _trackHeight) / 2,
                        width: thumbCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: LiveKitStyle.danger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      if (tickCount != null && tickCount! > 0)
                        for (var i = 0; i <= tickCount!; i++)
                          Positioned(
                            left: ((i / tickCount!) * width - _tickSize / 2).clamp(
                              0.0,
                              (width - _tickSize).clamp(0.0, double.infinity),
                            ),
                            top: (_thumbSize - _tickSize) / 2,
                            width: _tickSize,
                            height: _tickSize,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(color: LiveKitStyle.whitePure, shape: BoxShape.circle),
                            ),
                          ),
                      Positioned(
                        left: thumbCenter - _thumbSize / 2,
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            color: LiveKitStyle.titleStrong,
                            shape: BoxShape.circle,
                            border: Border.all(color: LiveKitStyle.danger, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
