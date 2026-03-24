import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Audio effect settings panel widget
///
/// Related APIs:
/// - `AudioEffectStore.shared` - Get the audio effect management singleton
/// - `AudioEffectStore.audioEffectState` - Audio effect state (`AudioEffectState`)
/// - `AudioEffectStore.setAudioChangerType(AudioChangerType)` - Set the voice changer effect
/// - `AudioEffectStore.setAudioReverbType(AudioReverbType)` - Set the reverb effect
/// - `AudioEffectStore.setVoiceEarMonitorEnable(bool)` - Toggle ear monitoring
/// - `AudioEffectStore.setVoiceEarMonitorVolume(int)` - Set the ear-monitor volume
/// - `AudioEffectStore.reset()` - Reset all audio effect settings
///
/// Fields in `AudioEffectState` (all are `ValueListenable`):
/// - `audioChangerType`: `ValueListenable` of `AudioChangerType`
/// - `audioReverbType`: `ValueListenable` of `AudioReverbType`
/// - `isEarMonitorOpened`: `ValueListenable` of `bool`
/// - `earMonitorVolume`: `ValueListenable` of `int`
///
/// Features:
/// - Voice changer effect selection (horizontally scrollable tags)
/// - Reverb effect selection (horizontally scrollable tags)
/// - Ear-monitor toggle and volume adjustment
/// - One-tap reset
class AudioEffectSettingWidget extends StatelessWidget {
  const AudioEffectSettingWidget({super.key});

  /// Voice changer option list
  static const List<AudioChangerType> _changerTypes = [
    AudioChangerType.none,
    AudioChangerType.child,
    AudioChangerType.littleGirl,
    AudioChangerType.man,
    AudioChangerType.ethereal,
  ];

  /// Reverb option list
  static const List<AudioReverbType> _reverbTypes = [
    AudioReverbType.none,
    AudioReverbType.ktv,
    AudioReverbType.smallRoom,
    AudioReverbType.auditorium,
    AudioReverbType.metallic,
  ];

  List<String> _changerNames(AppLocalizations l10n) {
    return [
      l10n.interactiveAudioEffectChangerNone,
      l10n.interactiveAudioEffectChangerChild,
      l10n.interactiveAudioEffectChangerLittleGirl,
      l10n.interactiveAudioEffectChangerMan,
      l10n.interactiveAudioEffectChangerEthereal,
    ];
  }

  List<String> _reverbNames(AppLocalizations l10n) {
    return [
      l10n.interactiveAudioEffectReverbNone,
      l10n.interactiveAudioEffectReverbKtv,
      l10n.interactiveAudioEffectReverbSmallRoom,
      l10n.interactiveAudioEffectReverbAuditorium,
      l10n.interactiveAudioEffectReverbMetallic,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AudioEffectStore.shared.audioEffectState;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Voice changer selection
          ValueListenableBuilder<AudioChangerType>(
            valueListenable: state.audioChangerType,
            builder: (context, currentChanger, _) {
              final selectedIndex = _changerTypes.indexOf(currentChanger);
              return _TagSelectionSection(
                title: l10n.interactiveAudioEffectChangerTitle,
                tags: _changerNames(l10n),
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onSelect: (index) {
                  AudioEffectStore.shared.setAudioChangerType(_changerTypes[index]);
                },
              );
            },
          ),
          _buildSeparator(context, fullWidth: true),
          // Reverb effect selection
          ValueListenableBuilder<AudioReverbType>(
            valueListenable: state.audioReverbType,
            builder: (context, currentReverb, _) {
              final selectedIndex = _reverbTypes.indexOf(currentReverb);
              return _TagSelectionSection(
                title: l10n.interactiveAudioEffectReverbTitle,
                tags: _reverbNames(l10n),
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onSelect: (index) {
                  AudioEffectStore.shared.setAudioReverbType(_reverbTypes[index]);
                },
              );
            },
          ),
          _buildSeparator(context, fullWidth: true),
          // Ear-monitor toggle
          ValueListenableBuilder<bool>(
            valueListenable: state.isEarMonitorOpened,
            builder: (context, earMonitorOn, _) {
              return SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.headphones, size: 24),
                      const SizedBox(width: 16),
                      Text(l10n.interactiveAudioEffectEarMonitor, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: earMonitorOn,
                        onChanged: (isOn) {
                          AudioEffectStore.shared.setVoiceEarMonitorEnable(isOn);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildSeparator(context, fullWidth: true),
          // Ear-monitor volume
          ValueListenableBuilder<int>(
            valueListenable: state.earMonitorVolume,
            builder: (context, volume, _) {
              return _AudioSliderRow(
                icon: Icons.volume_up,
                title: l10n.interactiveAudioEffectEarMonitorVolume,
                minValue: 0,
                maxValue: 100,
                value: volume.toDouble(),
                onValueChanged: (value) {
                  AudioEffectStore.shared.setVoiceEarMonitorVolume(value.round());
                },
              );
            },
          ),
          _buildSeparator(context, fullWidth: true),
          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton(
              onPressed: () {
                AudioEffectStore.shared.reset();
              },
              child: Text(l10n.interactiveAudioEffectReset, style: const TextStyle(fontSize: 15, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Helpers

  Widget _buildSeparator(BuildContext context, {bool fullWidth = false}) {
    return Container(
      margin: EdgeInsets.only(left: fullWidth ? 16 : 56, right: 16),
      height: 0.5,
      color: Theme.of(context).dividerColor,
    );
  }
}

// MARK: - TagSelectionSection

/// Tag selection section widget - title plus a horizontally scrollable tag button group
class _TagSelectionSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TagSelectionSection({
    required this.title,
    required this.tags,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSelected ? Colors.blue : Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      tags[index],
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - AudioSliderRow

/// Audio slider row widget - icon and title on the left, slider and value below
class _AudioSliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double minValue;
  final double maxValue;
  final double value;
  final ValueChanged<double> onValueChanged;

  const _AudioSliderRow({
    required this.icon,
    required this.title,
    required this.minValue,
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
                width: 36,
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
          Slider(
            min: minValue,
            max: maxValue,
            value: value,
            onChanged: (v) {
              onValueChanged(v.roundToDouble());
            },
          ),
        ],
      ),
    );
  }
}
