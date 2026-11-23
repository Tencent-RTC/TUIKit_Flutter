import 'package:flutter/material.dart';

import '../../../../common/widget/toast.dart';
import '../../../../l10n/language_store.dart';
import '../../../../common/style/live_kit_style.dart';
import 'source_item_view.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_image_utils.dart';
import '../scene_localization.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';
import 'dialog/camera_source_dialog.dart';
import 'dialog/image_source_dialog.dart';
import 'dialog/online_video_source_dialog.dart';
import 'dialog/screen_source_dialog.dart';
import 'dialog/video_file_source_dialog.dart';

class SourceListView extends StatelessWidget {
  const SourceListView({super.key, required this.store, required this.controller});

  final SceneStoreView store;
  final SceneController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, store.selection]),
      builder: (context, _) {
        final sources = store.currentSourcesForDisplay;
        if (sources.isEmpty) {
          return const SizedBox.shrink();
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          buildDefaultDragHandles: false,
          proxyDecorator:
              (child, index, animation) =>
                  Container(decoration: LiveKitStyle.glassPanel(radius: 6), clipBehavior: Clip.antiAlias, child: child),
          itemCount: sources.length,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            controller.reorderSources(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final source = sources[index];
            return SourceItemView(
              key: ValueKey(source.id),
              source: source,
              displayIndex: index,
              selected: source.id == store.selectedSourceId,
              onTap: () => controller.selectSource(source.id),
              onToggleVisible: () => controller.toggleSourceVisible(source.id),
              onEdit: source.isEngineBound ? () => _editSource(context, source) : null,
              onRemove: () {
                controller.removeSource(source.id);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _editSource(BuildContext context, MediaSourceConfig source) async {
    String? error;
    try {
      switch (source.kind) {
        case MediaSourceKind.camera:
          final config = await showCameraSourceDialog(
            context,
            initial: source.camera,
            occupiedDeviceIds: controller.occupiedCameraDeviceIds(exceptSourceId: source.id),
          );
          error =
              config == null || !context.mounted
                  ? null
                  : await controller.updateCameraSource(source.id, device: config.device, capture: config.capture);
        case MediaSourceKind.image:
          final config = await showImageSourceDialog(context, initial: source.image);
          if (config == null || !context.mounted) {
            error = null;
          } else {
            final size = await decodeImageSize(config.path);
            final sizeError = imageSizeError(const LiveKitSceneStrings(), size);
            if (sizeError != null) {
              if (context.mounted) {
                showToast(context, sizeError, duration: errorToastDuration);
              }
              return;
            }
            error = await controller.updateImageSource(source.id, config, knownSize: size);
          }
        case MediaSourceKind.videoFile:
          final config = await showVideoFileSourceDialog(context, initial: source.videoFile);
          error = config == null || !context.mounted ? null : await controller.updateVideoFileSource(source.id, config);
        case MediaSourceKind.onlineVideo:
          final config = await showOnlineVideoSourceDialog(context, initial: source.onlineVideo);
          error =
              config == null || !context.mounted ? null : await controller.updateOnlineVideoSource(source.id, config);
        case MediaSourceKind.screen:
          final config = await showScreenSourceDialog(
            context,
            initial: source.screen,
            occupiedSourceIds: controller.occupiedScreenSourceIds(exceptSourceId: source.id),
          );
          error = config == null || !context.mounted ? null : await controller.updateScreenSource(source.id, config);
      }
    } catch (e, stack) {
      debugPrint('_editSource(${source.kind}) failed: $e\n$stack');
      error = currentLiveKitStrings().errorOperationFailed;
    }
    if (error != null && context.mounted) {
      showToast(context, error, duration: errorToastDuration);
    }
  }
}
