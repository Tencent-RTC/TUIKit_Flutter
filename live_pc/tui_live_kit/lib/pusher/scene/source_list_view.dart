import 'package:flutter/material.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import 'source_item_view.dart';
import 'scene_engine_sync.dart';
import 'scene_menu.dart';
import 'scene_store.dart';
import 'source_config/camera_source_dialog.dart';
import 'source_config/image_source_dialog.dart';
import 'source_config/online_video_source_dialog.dart';
import 'source_config/screen_source_dialog.dart';
import 'source_config/video_file_source_dialog.dart';

/// 画面源列表：按倒序展示（最上层在顶部），支持拖拽调整层级、
/// 可见性开关、摄像头编辑与删除；空场景显示引导空态。
class SourceListView extends StatelessWidget {
  const SourceListView({
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
        final sources = store.currentSourcesForDisplay;
        if (sources.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                LiveKitLocalizations.of(context).sourceListEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: PusherStyle.textDisabled,
                ),
              ),
            ),
          );
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          buildDefaultDragHandles: false,
          // 拖拽浮层：行背景透明，浮起时补面板底色 + 描边 + 轻微放大。
          proxyDecorator: (child, index, animation) => Container(
            decoration: PusherStyle.glassPanel(radius: 6),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          itemCount: sources.length,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            store.reorderDisplaySources(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final source = sources[index];
            return SourceItemView(
              key: ValueKey(source.id),
              source: source,
              displayIndex: index,
              selected: source.id == store.selectedSourceId,
              onTap: () => store.selectSource(source.id),
              onToggleVisible: () => store.toggleSourceVisible(source.id),
              onEdit: source.isEngineBound
                  ? () => _editSource(context, source)
                  : null,
              onRemove: () => store.removeSource(source.id),
            );
          },
        );
      },
    );
  }

  /// 编辑画面源：按类型复用对应配置弹窗（预填现有配置），
  /// 保存后走引擎更新。
  Future<void> _editSource(BuildContext context, MediaSourceConfig source) async {
    final String? error;
    switch (source.kind) {
      case MediaSourceKind.camera:
        final config = await showCameraSourceDialog(
          context,
          initial: source.camera,
        );
        error = config == null || !context.mounted
            ? null
            : await engineSync.updateCameraSource(source.id, config);
      case MediaSourceKind.image:
        final config = await showImageSourceDialog(
          context,
          initial: source.image,
        );
        error = config == null || !context.mounted
            ? null
            : await engineSync.updateImageSource(source.id, config);
      case MediaSourceKind.videoFile:
        final config = await showVideoFileSourceDialog(
          context,
          initial: source.videoFile,
        );
        error = config == null || !context.mounted
            ? null
            : await engineSync.updateVideoFileSource(source.id, config);
      case MediaSourceKind.onlineVideo:
        final config = await showOnlineVideoSourceDialog(
          context,
          initial: source.onlineVideo,
        );
        error = config == null || !context.mounted
            ? null
            : await engineSync.updateOnlineVideoSource(source.id, config);
      case MediaSourceKind.screen:
        final config = await showScreenSourceDialog(
          context,
          initial: source.screen,
        );
        error = config == null || !context.mounted
            ? null
            : await engineSync.updateScreenSource(source.id, config);
    }
    if (error != null && context.mounted) {
      await showSceneErrorDialog(context, error);
    }
  }
}
