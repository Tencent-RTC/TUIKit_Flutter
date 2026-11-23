import 'package:flutter/material.dart';

import '../../../l10n/live_kit_localizations.dart';
import '../../../common/style/live_kit_style.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';
import '../../../common/widget/form_controls.dart';
import '../../../common/widget/form_dropdown.dart';
import '../../../common/widget/form_slider.dart';

class BeautyPanel extends StatelessWidget {
  const BeautyPanel({super.key, required this.store, required this.controller});

  final SceneStoreView store;
  final SceneController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final allCameras = store.currentSources.where((source) => source.kind == MediaSourceKind.camera).toList();
        final cameras = allCameras.where((source) => source.visible).toList();
        if (cameras.isEmpty) {
          return _NoCameraHint(allHidden: allCameras.isNotEmpty);
        }
        return _BeautyContent(store: store, controller: controller, cameras: cameras);
      },
    );
  }
}

class _NoCameraHint extends StatelessWidget {
  const _NoCameraHint({this.allHidden = false});

  final bool allHidden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          allHidden
              ? LiveKitLocalizations.of(context).beautyAllCamerasHidden
              : LiveKitLocalizations.of(context).beautyNoCamera,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: LiveKitStyle.textTertiary),
        ),
      ),
    );
  }
}

class _BeautyContent extends StatefulWidget {
  const _BeautyContent({required this.store, required this.controller, required this.cameras});

  final SceneStoreView store;
  final SceneController controller;
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
    if (widget.cameras.isNotEmpty && !widget.cameras.any((c) => c.id == _cameraId)) {
      _cameraId = widget.cameras.first.id;
    }
  }

  MediaSourceConfig? get _camera =>
      widget.store.currentSources
          .where((s) => s.id == _cameraId && s.kind == MediaSourceKind.camera && s.visible)
          .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    final camera = _camera;
    if (camera == null) {
      final cameras = widget.store.currentSources.where((s) => s.kind == MediaSourceKind.camera);
      final allHidden = cameras.isNotEmpty && cameras.every((s) => !s.visible);
      return _NoCameraHint(allHidden: allHidden);
    }
    final beauty = camera.camera!.beauty;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldLabel(strings.sourceNameCamera),
            const SizedBox(height: 6),
            FormDropdown<String>(
              value: _cameraId,
              items: [for (final c in widget.cameras) FormDropdownItem(value: c.id, label: c.name)],
              onChanged: (value) => setState(() => _cameraId = value),
              menuStyle: FormDropdownMenuStyle.ambientMenu,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.beautyFilterTitle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LiveKitStyle.textPrimary),
                  ),
                ),
                FormToggleSwitch(
                  value: beauty.enabled,
                  onChanged: (value) => _update(beauty.copyWith(enabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: beauty.enabled ? 1 : 0.4,
              child: AbsorbPointer(
                absorbing: !beauty.enabled,
                child: Column(
                  children: [
                    _BeautySlider(
                      label: strings.beautySkinSmooth,
                      value: beauty.skinSmooth,
                      onChanged: (v) => _update(beauty.copyWith(skinSmooth: v)),
                    ),
                    _BeautySlider(
                      label: strings.beautyWhiteness,
                      value: beauty.whiteness,
                      onChanged: (v) => _update(beauty.copyWith(whiteness: v)),
                    ),
                    _BeautySlider(
                      label: strings.beautyRuddy,
                      value: beauty.ruddy,
                      onChanged: (v) => _update(beauty.copyWith(ruddy: v)),
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

  void _update(CameraBeautyConfig beauty) {
    widget.controller.setCameraBeauty(_cameraId, beauty);
  }
}

class _BeautySlider extends StatelessWidget {
  const _BeautySlider({required this.label, required this.value, required this.onChanged});

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
