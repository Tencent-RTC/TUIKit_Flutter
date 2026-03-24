import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Beauty settings panel widget
///
/// Related APIs:
/// - `BaseBeautyStore.shared` - Get the beauty management singleton
/// - `BaseBeautyStore.baseBeautyState` - Beauty state (`BaseBeautyState`)
/// - `BaseBeautyStore.setSmoothLevel(double)` - Set the smoothing level [0-9] (positional parameter)
/// - `BaseBeautyStore.setWhitenessLevel(double)` - Set the whitening level [0-9] (positional parameter)
/// - `BaseBeautyStore.setRuddyLevel(double)` - Set the ruddy level [0-9] (positional parameter)
/// - `BaseBeautyStore.reset()` - Reset all beauty parameters
///
/// Fields in `BaseBeautyState` (all are `ValueListenable`):
/// - `smoothLevel`: `ValueListenable` of `double`
/// - `whitenessLevel`: `ValueListenable` of `double`
/// - `ruddyLevel`: `ValueListenable` of `double`
///
/// Features:
/// - Three sliders that control smoothing, whitening, and ruddy separately
/// - Real-time preview of beauty effects
/// - One-tap reset for all beauty parameters
class BeautySettingWidget extends StatelessWidget {
  const BeautySettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = BaseBeautyStore.shared.baseBeautyState;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Smoothing slider
          ValueListenableBuilder<double>(
            valueListenable: state.smoothLevel,
            builder: (context, smoothValue, _) {
              return _BeautySliderRow(
                icon: Icons.face_retouching_natural,
                title: l10n.interactiveBeautySmooth,
                maxValue: 9,
                value: smoothValue,
                onValueChanged: (value) {
                  BaseBeautyStore.shared.setSmoothLevel(value);
                },
              );
            },
          ),
          _buildSeparator(context),
          // Whitening slider
          ValueListenableBuilder<double>(
            valueListenable: state.whitenessLevel,
            builder: (context, whitenessValue, _) {
              return _BeautySliderRow(
                icon: Icons.wb_sunny,
                title: l10n.interactiveBeautyWhiteness,
                maxValue: 9,
                value: whitenessValue,
                onValueChanged: (value) {
                  BaseBeautyStore.shared.setWhitenessLevel(value);
                },
              );
            },
          ),
          _buildSeparator(context),
          // Ruddy slider
          ValueListenableBuilder<double>(
            valueListenable: state.ruddyLevel,
            builder: (context, ruddyValue, _) {
              return _BeautySliderRow(
                icon: Icons.water_drop,
                title: l10n.interactiveBeautyRuddy,
                maxValue: 9,
                value: ruddyValue,
                onValueChanged: (value) {
                  BaseBeautyStore.shared.setRuddyLevel(value);
                },
              );
            },
          ),
          _buildSeparator(context),
          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton(
              onPressed: () {
                BaseBeautyStore.shared.reset();
              },
              child: Text(l10n.interactiveBeautyReset, style: const TextStyle(fontSize: 15, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Helpers

  Widget _buildSeparator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 56, right: 16),
      height: 0.5,
      color: Theme.of(context).dividerColor,
    );
  }
}

// MARK: - BeautySliderRow

/// Beauty slider row widget - icon and title on the left, slider and value on the right
class _BeautySliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double maxValue;
  final double value;
  final ValueChanged<double> onValueChanged;

  const _BeautySliderRow({
    required this.icon,
    required this.title,
    required this.maxValue,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              SizedBox(
                width: 30,
                child: Text(
                  '${value.round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.pink,
              thumbColor: Colors.pink,
              overlayColor: Colors.pink.withValues(alpha: 0.2),
            ),
            child: Slider(
              min: 0,
              max: maxValue,
              value: value,
              onChanged: (v) {
                onValueChanged(v.roundToDouble());
              },
            ),
          ),
        ],
      ),
    );
  }
}
