import 'dart:io';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/float_window/pip_config_panel_widget.dart';

import '../../../../component/audio_effect/index.dart';
import '../../../../component/beauty/index.dart';
import '../../../../component/bgm/index.dart';
import '../../../../component/float_window/global_float_window_manager.dart';
import '../../../manager/live_stream_manager.dart';

class MoreFeaturesPanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const MoreFeaturesPanelWidget({super.key, required this.liveStreamManager});

  @override
  State<MoreFeaturesPanelWidget> createState() => _MoreFeaturesPanelWidgetState();
}

class _MoreFeaturesPanelWidgetState extends State<MoreFeaturesPanelWidget> {
  late final LiveStreamManager liveStreamManager;
  late final List<FeaturesItem> list;

  BottomSheetHandler? _beautySheetHandler;
  BottomSheetHandler? _audioEffectSheetHandler;
  BottomSheetHandler? _bgmSheetHandler;
  BottomSheetHandler? _pipConfigPanelHandler;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    _initData();
  }

  @override
  void dispose() {
    _closeAllDialog();
    super.dispose();
  }

  void _closeAllDialog() {
    _beautySheetHandler?.close();
    _audioEffectSheetHandler?.close();
    _bgmSheetHandler?.close();
    _pipConfigPanelHandler?.close();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24.height),
          _buildTitleWidget(),
          SizedBox(height: 24.height),
          _buildFeaturesListWidget(),
          SizedBox(height: 24.height),
        ],
      ),
    );
  }

  Widget _buildTitleWidget() {
    return SizedBox(
      height: 24.height,
      width: 1.screenWidth,
      child: Stack(
        children: [
          Center(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_more_features,
              style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesListWidget() {
    // Each row shows up to 5 items. Items are placed into fixed grid slots
    // (5 slots per row) so that an item's horizontal center is identical
    // across rows. When the last row is not full, empty slots are appended
    // on the right side, which makes the remaining items align from left
    // to right while every item still has equal spacing on both sides.
    const int itemsPerRow = 5;
    final List<List<int?>> rows = [];
    for (int i = 0; i < list.length; i += itemsPerRow) {
      final List<int?> row = [];
      for (int j = 0; j < itemsPerRow; j++) {
        final int idx = i + j;
        row.add(idx < list.length ? idx : null);
      }
      rows.add(row);
    }
    return SizedBox(
      width: 1.screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: 16.height),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: rows[r].map((idx) {
                return idx == null ? SizedBox(width: 56.width) : _buildFeatureItem(idx);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(int index) {
    return GestureDetector(
      onTap: () => _onTapIndex(index),
      child: SizedBox(
        width: 56.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.width,
              height: 56.width,
              decoration: BoxDecoration(
                color: LiveColors.notStandardBlue30Transparency,
                border: Border.all(color: LiveColors.notStandardBlue30Transparency),
                borderRadius: BorderRadius.circular(10.radius),
              ),
              child: Center(
                child: SizedBox(
                  width: 30.width,
                  height: 30.width,
                  child: Image.asset(
                    list[index].icon,
                    package: Constants.pluginName,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.height),
            Text(
              list[index].title,
              style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _MoreFeaturesPanelWidgetState {
  void _onTapIndex(int index) {
    final item = list[index];
    switch (item.type) {
      case FeaturesItemType.beauty:
        _beautySheetHandler = popupWidget(const BeautyPanelWidget(),
            context: context, barrierColor: LiveColors.designStandardTransparent);
        break;
      case FeaturesItemType.audioEffect:
        _audioEffectSheetHandler = popupWidget(
            context: context,
            AudioEffectPanelWidget(
              roomId: liveStreamManager.roomState.roomId,
              onDone: () => _audioEffectSheetHandler?.close(),
            ));
        break;
      case FeaturesItemType.music:
        _bgmSheetHandler = popupWidget(
          context: context,
          BGMPanelWidget(
            roomId: liveStreamManager.roomState.roomId,
          ),
        );
        break;
      case FeaturesItemType.flip:
        DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
        break;
      case FeaturesItemType.mirror:
        DeviceStore.shared.switchMirror(DeviceStore.shared.state.localMirrorType.value == MirrorType.enable
            ? MirrorType.disable
            : MirrorType.enable);
        break;
      case FeaturesItemType.pip:
        _showPipConfigPanel();
        break;
    }
  }

  void _showPipConfigPanel() {
    TUILiveKitPlatform.instance.hasPipPermission().then((hasPipPermission) {
      if (!mounted) return;
      if (!hasPipPermission) {
        liveStreamManager.enablePipMode(false);
      }
      _pipConfigPanelHandler = popupWidget(
        context: context,
        PipConfigPanelWidget(
          enablePipMode: liveStreamManager.floatWindowState.enablePipMode,
          onChanged: (enable) {
            _pipConfigPanelHandler?.close();
            _enablePictureInPicture(enable);
            if (enable && !hasPipPermission) {
              TUILiveKitPlatform.instance.openPipSettings();
            }
          },
        ),
      );
    });
  }

  void _enablePictureInPicture(bool enable) {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      final roomId = widget.liveStreamManager.roomState.roomId;
      widget.liveStreamManager.enablePictureInPicture(roomId, enable).then((result) {
        LiveKitLogger.info("enablePictureInPicture,enable=$enable,result=$result");
        liveStreamManager.enablePipMode(enable && result);
      });
    }
  }

  void _initData() {
    list = [
      FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_beauty,
          icon: LiveImages.settingsItemBeauty,
          type: FeaturesItemType.beauty),
      FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_audio_effect,
          icon: LiveImages.settingsItemAudioEffect,
          type: FeaturesItemType.audioEffect),
      FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_music,
          icon: LiveImages.settingsItemMusic,
          type: FeaturesItemType.music),
      FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_flip,
          icon: LiveImages.settingsItemFlip,
          type: FeaturesItemType.flip),
      FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_mirror,
          icon: LiveImages.settingsItemMirror,
          type: FeaturesItemType.mirror),
    ];
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() && Platform.isAndroid) {
      list.add(FeaturesItem(
          title: LiveKitLocalizations.of(Global.appContext())!.common_video_settings_item_pip,
          icon: LiveImages.settingsItemPip,
          type: FeaturesItemType.pip));
    }
  }
}

enum FeaturesItemType { beauty, audioEffect, music, flip, mirror, pip }

class FeaturesItem {
  String title;
  String icon;
  FeaturesItemType type;

  FeaturesItem({
    required this.title,
    required this.icon,
    required this.type,
  });
}
