import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/material.dart';
import '../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../../pusher_style.dart';
import '../scene_store.dart';
import 'source_dialog.dart';

/// 添加 / 编辑摄像头弹窗：先选择摄像头，再设置采集参数。
///
/// 设置项：采集分辨率、是否镜像（设计稿的旋转角度 / 填充模式按
/// 产品结论裁剪，不支持）。
/// 返回用户确认后的 [CameraSourceConfig]；取消返回 null。
/// [initial] 非空时为编辑模式（预填现有配置）。
Future<CameraSourceConfig?> showCameraSourceDialog(
  BuildContext context, {
  CameraSourceConfig? initial,
}) {
  return showSourceConfigDialog<CameraSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _CameraSourceDialog(initial: initial),
  );
}

class _CameraSourceDialog extends StatefulWidget {
  const _CameraSourceDialog({this.initial});

  final CameraSourceConfig? initial;

  @override
  State<_CameraSourceDialog> createState() => _CameraSourceDialogState();
}

class _CameraSourceDialogState extends State<_CameraSourceDialog> {
  String? _selectedDeviceId;
  late ({int width, int height}) _selectedResolution;
  late bool _mirror;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    DeviceStore.shared.refreshDeviceList();
    final initial = widget.initial;
    _selectedDeviceId = initial?.deviceId;
    final initialResolution = (
      width: initial?.width ?? 1920,
      height: initial?.height ?? 1080,
    );
    _selectedResolution = kCameraCapturePresets.contains(initialResolution)
        ? initialResolution
        : (width: 1920, height: 1080);
    _mirror = initial?.mirror ?? false;
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
          confirmEnabled: cameras.isNotEmpty && _selectedDeviceId != null,
          onConfirm: () => _confirm(cameras),
          children: [
            SourceFieldLabel(strings.cameraDeviceLabel),
            const SizedBox(height: 8),
            _buildDeviceDropdown(cameras),
            if (cameras.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                strings.cameraNotFound,
                style: TextStyle(fontSize: 12, color: PusherStyle.danger),
              ),
            ],
            const SizedBox(height: 16),
            SourceFieldLabel(strings.cameraResolutionLabel),
            const SizedBox(height: 8),
            _buildResolutionDropdown(),
            const SizedBox(height: 16),
            SourceFieldLabel(strings.cameraMirrorLabel),
            const SizedBox(height: 8),
            SourceToggleSwitch(
              value: _mirror,
              onChanged: (value) => setState(() => _mirror = value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceDropdown(List<DeviceInfo> cameras) {
    return SourceDropdown<String>(
      value: _selectedDeviceId,
      hint: LiveKitLocalizations.of(context).cameraDeviceHint,
      items: [
        for (final camera in cameras)
          SourceDropdownItem(
            value: camera.deviceId,
            label: camera.deviceName,
          ),
      ],
      onChanged: (value) => setState(() => _selectedDeviceId = value),
    );
  }

  Widget _buildResolutionDropdown() {
    return SourceDropdown<({int width, int height})>(
      value: _selectedResolution,
      items: [
        for (final preset in kCameraCapturePresets)
          SourceDropdownItem(
            value: preset,
            label: '${preset.width} × ${preset.height}',
          ),
      ],
      onChanged: (value) => setState(() => _selectedResolution = value),
    );
  }

  void _confirm(List<DeviceInfo> cameras) {
    final device = cameras.firstWhere(
      (camera) => camera.deviceId == _selectedDeviceId,
    );
    Navigator.pop(
      context,
      CameraSourceConfig(
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        width: _selectedResolution.width,
        height: _selectedResolution.height,
        mirror: _mirror,
      ),
    );
  }

  /// 设备列表刷新后校正选中项：无选中或选中项已拔出时，
  /// 回退到引擎当前摄像头 / 列表首个。
  void _ensureDeviceSelection(List<DeviceInfo> cameras) {
    if (cameras.isEmpty) {
      _selectedDeviceId = null;
      return;
    }
    final exists =
        cameras.any((camera) => camera.deviceId == _selectedDeviceId);
    if (exists) {
      return;
    }
    final current = DeviceStore.shared.state.currentCamera.value;
    final hasCurrent =
        cameras.any((camera) => camera.deviceId == current.deviceId);
    _selectedDeviceId =
        hasCurrent ? current.deviceId : cameras.first.deviceId;
  }
}
