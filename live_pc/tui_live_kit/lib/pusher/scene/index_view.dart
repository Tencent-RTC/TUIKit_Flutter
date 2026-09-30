import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import 'source_list_view.dart';
import 'scene_engine_sync.dart';
import 'scene_menu.dart';
import 'scene_store.dart';
import 'scene_switch_view.dart';
import 'source_config/camera_source_dialog.dart';
import 'source_config/image_source_dialog.dart';
import 'source_config/online_video_source_dialog.dart';
import 'source_config/screen_source_dialog.dart';
import 'source_config/video_file_source_dialog.dart';
import '../beauty/beauty_panel.dart';
import 'scene_tab_rail.dart';

/// 主播端左侧面板：图标 Tab 导航 + 内容区。
///
/// 本期实现「画面源」Tab（场景切换 + 画面源列表）与「美颜」Tab
/// （摄像头美颜滤镜）；「更多」为占位内容，待对应功能开发。
class PusherSceneView extends StatefulWidget {
  const PusherSceneView({
    super.key,
    required this.store,
    required this.engineSync,
  });

  final SceneStore store;
  final SceneEngineSync engineSync;

  @override
  State<PusherSceneView> createState() => _PusherSceneViewState();
}

class _PusherSceneViewState extends State<PusherSceneView> {
  SceneTab _tab = SceneTab.source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      decoration: PusherStyle.glassPanel(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SceneTabRail(
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          Expanded(
            child: switch (_tab) {
              SceneTab.source => _SourceTabContent(
                store: widget.store,
                engineSync: widget.engineSync,
              ),
              SceneTab.beauty => BeautyPanel(
                store: widget.store,
                engineSync: widget.engineSync,
              ),
              SceneTab.more => _TabPlaceholder(
                icon: RemixIcons.puzzle_line,
                title: LiveKitLocalizations.of(context).tabMore,
                subtitle: LiveKitLocalizations.of(context).featureComingSoon,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// 面板内容：场景切换区 + 画面源列表。
class _SourceTabContent extends StatelessWidget {
  const _SourceTabContent({required this.store, required this.engineSync});

  final SceneStore store;
  final SceneEngineSync engineSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SceneSwitchView(store: store),
        Container(height: 1, color: PusherStyle.white4),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    RemixIcons.layout_grid_line,
                    size: 12,
                    color: PusherStyle.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LiveKitLocalizations.of(context).tabSources,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: PusherStyle.textPrimary,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (iconContext) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _addSource(iconContext),
                  child: const Icon(
                    RemixIcons.add_line,
                    size: 14,
                    color: PusherStyle.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: SourceListView(store: store, engineSync: engineSync)),
      ],
    );
  }

  Future<void> _addSource(BuildContext context) async {
    final kind = await showSourceAddDialog(context);
    if (kind == null || !context.mounted) {
      return;
    }
    // 各类型先弹配置弹窗，再走引擎真实添加（屏幕共享后续期次接入）。
    final String? error;
    switch (kind) {
      case MediaSourceKind.camera:
        final config = await showCameraSourceDialog(context);
        error = config == null || !context.mounted
            ? null
            : await engineSync.addCameraSource(config);
      case MediaSourceKind.image:
        final config = await showImageSourceDialog(context);
        error = config == null || !context.mounted
            ? null
            : await engineSync.addImageSource(config);
      case MediaSourceKind.videoFile:
        final config = await showVideoFileSourceDialog(context);
        error = config == null || !context.mounted
            ? null
            : await engineSync.addVideoFileSource(config);
      case MediaSourceKind.onlineVideo:
        final config = await showOnlineVideoSourceDialog(context);
        error = config == null || !context.mounted
            ? null
            : await engineSync.addOnlineVideoSource(config);
      case MediaSourceKind.screen:
        final config = await showScreenSourceDialog(context);
        error = config == null || !context.mounted
            ? null
            : await engineSync.addScreenSource(config);
    }
    if (error != null && context.mounted) {
      await showSceneErrorDialog(context, error);
    }
  }
}

/// 其余 Tab 的占位内容。
class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: PusherStyle.textDisabled),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: PusherStyle.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: PusherStyle.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
