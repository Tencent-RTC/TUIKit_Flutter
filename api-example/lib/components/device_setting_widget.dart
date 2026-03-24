import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/permission_helper.dart';

/// Device management panel content - reusable component
///
/// Related APIs:
/// - DeviceStore.shared.openLocalCamera(isFront) - Open the camera (positional parameter)
/// - DeviceStore.shared.closeLocalCamera() - Close the camera
/// - DeviceStore.shared.openLocalMicrophone() - Open the microphone (no parameters)
/// - DeviceStore.shared.closeLocalMicrophone() - Close the microphone
/// - DeviceStore.shared.switchCamera(isFront) - Switch between front and rear cameras (positional parameter)
/// - DeviceStore.shared.switchMirror(mirrorType) - Set the mirror mode (positional parameter)
/// - DeviceStore.shared.updateVideoQuality(quality) - Set the video quality (positional parameter)
/// - DeviceStore.shared.state - Device state (`DeviceState`, where all fields are `ValueListenable`)
///
/// Pure UI component that only depends on the public `DeviceStore` API and is not coupled to a specific business scenario.
/// Reusable across all four stages (`BasicStreaming` / `Interactive` / `MultiConnect` / `LivePK`).
class DeviceSettingWidget extends StatelessWidget {
  const DeviceSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deviceState = DeviceStore.shared.state;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Camera toggle
          ValueListenableBuilder<DeviceStatus>(
            valueListenable: deviceState.cameraStatus,
            builder: (context, cameraStatus, _) {
              final cameraOn = cameraStatus == DeviceStatus.on;
              return ValueListenableBuilder<bool>(
                valueListenable: deviceState.isFrontCamera,
                builder: (context, isFront, _) {
                  return _SettingToggleRow(
                    icon: Icons.camera_alt,
                    title: l10n.deviceSettingCamera,
                    isOn: cameraOn,
                    onToggle: (isOn) {
                      if (isOn) {
                        PermissionHelper.requestCameraPermission(
                          context,
                          onGranted: () {
                            DeviceStore.shared.openLocalCamera(isFront);
                          },
                        );
                      } else {
                        DeviceStore.shared.closeLocalCamera();
                      }
                    },
                  );
                },
              );
            },
          ),
          _buildSeparator(context),
          // Microphone toggle
          ValueListenableBuilder<DeviceStatus>(
            valueListenable: deviceState.microphoneStatus,
            builder: (context, micStatus, _) {
              final micOn = micStatus == DeviceStatus.on;
              return _SettingToggleRow(
                icon: Icons.mic,
                title: l10n.deviceSettingMicrophone,
                isOn: micOn,
                onToggle: (isOn) {
                  if (isOn) {
                    PermissionHelper.requestMicrophonePermission(
                      context,
                      onGranted: () {
                        DeviceStore.shared.openLocalMicrophone();
                      },
                    );
                  } else {
                    DeviceStore.shared.closeLocalMicrophone();
                  }
                },
              );
            },
          ),
          _buildSeparator(context),
          // Front/rear camera switch
          ValueListenableBuilder<bool>(
            valueListenable: deviceState.isFrontCamera,
            builder: (context, isFront, _) {
              return _SettingToggleRow(
                icon: Icons.flip_camera_ios,
                title: l10n.deviceSettingFrontCamera,
                isOn: isFront,
                onToggle: (isOn) {
                  DeviceStore.shared.switchCamera(isOn);
                },
              );
            },
          ),
          _buildSeparator(context),
          // Mirror mode toggle
          ValueListenableBuilder<MirrorType>(
            valueListenable: deviceState.localMirrorType,
            builder: (context, mirrorType, _) {
              final mirrorOn = mirrorType == MirrorType.enable;
              return _SettingToggleRow(
                icon: Icons.flip,
                title: l10n.deviceSettingMirror,
                isOn: mirrorOn,
                onToggle: (isOn) {
                  DeviceStore.shared.switchMirror(isOn ? MirrorType.enable : MirrorType.disable);
                },
              );
            },
          ),
          _buildSeparator(context),
          // Video quality selection
          ValueListenableBuilder<VideoQuality>(
            valueListenable: deviceState.localVideoQuality,
            builder: (context, quality, _) {
              final int videoQualityIndex;
              switch (quality) {
                case VideoQuality.quality360P:
                  videoQualityIndex = 0;
                case VideoQuality.quality540P:
                  videoQualityIndex = 1;
                case VideoQuality.quality720P:
                  videoQualityIndex = 2;
                case VideoQuality.quality1080P:
                  videoQualityIndex = 3;
              }
              return _SettingSegmentRow(
                icon: Icons.tune,
                title: l10n.deviceSettingVideoQuality,
                segments: const ['360P', '540P', '720P', '1080P'],
                selectedIndex: videoQualityIndex,
                onSegmentChanged: (index) {
                  final qualities = [
                    VideoQuality.quality360P,
                    VideoQuality.quality540P,
                    VideoQuality.quality720P,
                    VideoQuality.quality1080P,
                  ];
                  if (index < qualities.length) {
                    DeviceStore.shared.updateVideoQuality(qualities[index]);
                  }
                },
              );
            },
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

// MARK: - SettingToggleRow

/// Toggle row component in device settings - icon and title on the left, `Switch` on the right
class _SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  const _SettingToggleRow({required this.icon, required this.title, required this.isOn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Switch(value: isOn, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

// MARK: - SettingSegmentRow

/// Segmented selection row in device settings - icon and title on top, `SegmentedButton` below
class _SettingSegmentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentChanged;

  const _SettingSegmentRow({
    required this.icon,
    required this.title,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: List.generate(
                segments.length,
                (index) => ButtonSegment<int>(value: index, label: Text(segments[index])),
              ),
              selected: {selectedIndex},
              onSelectionChanged: (Set<int> selected) {
                onSegmentChanged(selected.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}
