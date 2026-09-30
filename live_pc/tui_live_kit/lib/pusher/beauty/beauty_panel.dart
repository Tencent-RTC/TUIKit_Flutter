import 'package:flutter/material.dart';

import '../../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import '../scene/scene_engine_sync.dart';
import '../scene/scene_store.dart';
import '../scene/source_config/source_dialog.dart';

/// 美颜 Tab 面板：摄像头选择 + 美颜滤镜开关 + 四项效果滑杆。
///
/// 摄像头列表来自当前场景已有的摄像头画面源（无则提示并整体禁用）；
/// 美颜参数按源存储在 CameraSourceConfig.beauty（随场景持久化），
/// 编辑实时经 SceneEngineSync 下发引擎，源重建（切场景等）后自动恢复。
class BeautyPanel extends StatelessWidget {
  const BeautyPanel({
    super.key,
    required this.store,
    required this.engineSync,
  });

  final SceneStore store;
  final SceneEngineSync engineSync;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cameras = store.currentSources
            .where((source) => source.kind == MediaSourceKind.camera)
            .toList();
        if (cameras.isEmpty) {
          return _NoCameraHint();
        }
        return _BeautyContent(
          store: store,
          engineSync: engineSync,
          cameras: cameras,
        );
      },
    );
  }
}

/// 当前场景无摄像头画面源时的提示。
class _NoCameraHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          LiveKitLocalizations.of(context).beautyNoCamera,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: PusherStyle.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _BeautyContent extends StatefulWidget {
  const _BeautyContent({
    required this.store,
    required this.engineSync,
    required this.cameras,
  });

  final SceneStore store;
  final SceneEngineSync engineSync;
  final List<MediaSourceConfig> cameras;

  @override
  State<_BeautyContent> createState() => _BeautyContentState();
}

class _BeautyContentState extends State<_BeautyContent> {
  late String _cameraId;

  @override
  void initState() {
    super.initState();
    _cameraId = widget.cameras.first.id;
  }

  @override
  void didUpdateWidget(covariant _BeautyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cameras.isNotEmpty &&
        !widget.cameras.any((c) => c.id == _cameraId)) {
      _cameraId = widget.cameras.first.id;
    }
  }

  MediaSourceConfig? get _camera =>
      widget.store.currentSources
          .where((s) => s.id == _cameraId && s.kind == MediaSourceKind.camera)
          .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    final camera = _camera;
    if (camera == null) {
      // 编辑目标已被删除（store 重建时会整体重建本面板）。
      return _NoCameraHint();
    }
    final beauty = camera.camera!.beauty;
    // 显式靠上：避免外层给松约束时内容被居中摆放。
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          SourceFieldLabel(strings.sourceNameCamera),
          const SizedBox(height: 6),
          SourceDropdown<String>(
            value: _cameraId,
            items: [
              for (final c in widget.cameras)
                SourceDropdownItem(value: c.id, label: c.name),
            ],
            onChanged: (value) => setState(() => _cameraId = value),
          ),
          const SizedBox(height: 16),
          // 美颜滤镜开关行。
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.beautyFilterTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PusherStyle.textPrimary,
                  ),
                ),
              ),
              SourceToggleSwitch(
                value: beauty.enabled,
                onChanged: (value) => _update(beauty.copyWith(enabled: value)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 效果滑杆：开关关闭时禁用置灰（值保留）。
          Opacity(
            opacity: beauty.enabled ? 1 : 0.4,
            child: AbsorbPointer(
              absorbing: !beauty.enabled,
              child: Column(
                children: [
                  _BeautySlider(
                    label: strings.beautySkinSmooth,
                    value: beauty.skinSmooth,
                    onChanged: (v) =>
                        _update(beauty.copyWith(skinSmooth: v)),
                  ),
                  _BeautySlider(
                    label: strings.beautyWhiteness,
                    value: beauty.whiteness,
                    onChanged: (v) =>
                        _update(beauty.copyWith(whiteness: v)),
                  ),
                  _BeautySlider(
                    label: strings.beautySharpen,
                    value: beauty.sharpen,
                    onChanged: (v) =>
                        _update(beauty.copyWith(sharpen: v)),
                  ),
                  _BeautySlider(
                    label: strings.beautyRuddy,
                    value: beauty.ruddy,
                    onChanged: (v) =>
                        _update(beauty.copyWith(ruddy: v)),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// 更新美颜配置：写 store（随场景持久）+ 实时下发引擎。
  void _update(CameraBeautySettings beauty) {
    widget.store.updateCameraBeauty(_cameraId, beauty);
    widget.engineSync.updateCameraBeauty(_cameraId, beauty);
  }
}

/// 单个美颜效果滑杆（label + 数值 + 项目配色 GradientSlider）。
class _BeautySlider extends StatelessWidget {
  const _BeautySlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LabeledSliderGroup(
        label: label,
        value: value.toDouble(),
        max: 100,
        display: '$value',
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}
