import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/material.dart';
import '../../../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../common/style/live_kit_style.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'source_dialog_shell.dart';
import '../../../../../common/widget/form_dropdown.dart';
import '../../../../../common/widget/form_controls.dart';

typedef CameraDialogResult = ({CameraDevice device, CameraCaptureConfig capture});

Future<CameraDialogResult?> showCameraSourceDialog(
  BuildContext context, {
  CameraSourceConfig? initial,
  Set<String> occupiedDeviceIds = const {},
}) {
  return showSourceConfigDialog<CameraDialogResult>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _CameraSourceDialog(initial: initial, occupiedDeviceIds: occupiedDeviceIds),
  );
}

class _CameraSourceDialog extends StatefulWidget {
  const _CameraSourceDialog({this.initial, this.occupiedDeviceIds = const {}});

  final CameraSourceConfig? initial;

  final Set<String> occupiedDeviceIds;

  @override
  State<_CameraSourceDialog> createState() => _CameraSourceDialogState();
}

class _CameraSourceDialogState extends State<_CameraSourceDialog> {
  String? _selectedDeviceId;
  late ({int width, int height}) _selectedResolution;
  late bool _mirror;

  bool get _isEdit => widget.initial != null;

  bool _isAvailable(String? deviceId) => deviceId != null && !widget.occupiedDeviceIds.contains(deviceId);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedDeviceId = initial?.device.deviceId;
    final capture = initial?.capture ?? const CameraCaptureConfig();
    final initialResolution = (width: capture.width, height: capture.height);
    _selectedResolution =
        kCameraCapturePresets.contains(initialResolution) ? initialResolution : (width: 1920, height: 1080);
    _mirror = capture.mirror;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DeviceInfo>>(
      valueListenable: DeviceStore.shared.state.cameraList,
      builder: (context, cameras, _) {
        final strings = LiveKitLocalizations.of(context);
        _ensureDeviceSelection(cameras);
        return SourceDialogShell(
          icon: RemixIcons.webcam_line,
          title: _isEdit ? strings.cameraEditTitle : strings.cameraAddTitle,
          confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
          confirmEnabled: _selectedDeviceId != null,
          onConfirm: () => _confirm(cameras),
          children: [
            FormFieldLabel(strings.cameraDeviceLabel),
            const SizedBox(height: 8),
            _buildDeviceDropdown(cameras),
            if (cameras.isEmpty) ...[
              const SizedBox(height: 10),
              Text(strings.cameraNotFound, style: TextStyle(fontSize: 12, color: LiveKitStyle.danger)),
            ],
            const SizedBox(height: 16),
            FormFieldLabel(strings.cameraResolutionLabel),
            const SizedBox(height: 8),
            _buildResolutionDropdown(),
            const SizedBox(height: 16),
            FormFieldLabel(strings.cameraMirrorLabel),
            const SizedBox(height: 8),
            FormToggleSwitch(value: _mirror, onChanged: (value) => setState(() => _mirror = value)),
          ],
        );
      },
    );
  }

  Widget _buildDeviceDropdown(List<DeviceInfo> cameras) {
    return FormDropdown<String>(
      value: _selectedDeviceId,
      hint: LiveKitLocalizations.of(context).cameraDeviceHint,
      items: [
        for (final camera in cameras)
          FormDropdownItem(
            value: camera.deviceId,
            label: camera.deviceName,
            enabled: !widget.occupiedDeviceIds.contains(camera.deviceId),
          ),
      ],
      onChanged: (value) => setState(() => _selectedDeviceId = value),
    );
  }

  Widget _buildResolutionDropdown() {
    return FormDropdown<({int width, int height})>(
      value: _selectedResolution,
      items: [
        for (final preset in kCameraCapturePresets)
          FormDropdownItem(value: preset, label: '${preset.width} × ${preset.height}'),
      ],
      onChanged: (value) => setState(() => _selectedResolution = value),
    );
  }

  void _confirm(List<DeviceInfo> cameras) {
    final device = cameras.firstWhere((camera) => camera.deviceId == _selectedDeviceId);
    final CameraDialogResult result = (
      device: CameraDevice(deviceId: device.deviceId, deviceName: device.deviceName),
      capture: (widget.initial?.capture ?? const CameraCaptureConfig()).copyWith(
        width: _selectedResolution.width,
        height: _selectedResolution.height,
        mirror: _mirror,
      ),
    );
    Navigator.pop(context, result);
  }

  void _ensureDeviceSelection(List<DeviceInfo> cameras) {
    if (cameras.isEmpty) {
      _selectedDeviceId = null;
      return;
    }
    if (_isAvailable(_selectedDeviceId)) {
      return;
    }
    final current = DeviceStore.shared.state.currentCamera.value;
    _selectedDeviceId = _firstAvailable(cameras, preferred: current.deviceId)?.deviceId;
  }

  DeviceInfo? _firstAvailable(List<DeviceInfo> cameras, {String? preferred}) {
    if (preferred != null) {
      for (final camera in cameras) {
        if (camera.deviceId == preferred && _isAvailable(camera.deviceId)) {
          return camera;
        }
      }
    }
    for (final camera in cameras) {
      if (_isAvailable(camera.deviceId)) {
        return camera;
      }
    }
    return null;
  }
}
