import 'dart:io';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/float_window/pip_config_panel_widget.dart';

import '../../../../component/audio_effect/index.dart';
import '../../../../component/beauty/index.dart';
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
    _pipConfigPanelHandler?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.screenWidth,
      height: 350.height,
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.radius), topRight: Radius.circular(20.radius)),
      ),
      child: Column(children: [
        SizedBox(height: 24.height),
        _buildTitleWidget(),
        SizedBox(height: 24.height),
        _buildFeaturesListWidget()
      ]),
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
    return SizedBox(
      width: 1.screenWidth,
      height: 79.height,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, index) => SizedBox(width: 12.width),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _onTapIndex(index),
              child: SizedBox(
                width: 56.width,
                height: 79.height,
                child: Column(
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
          },
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
        _beautySheetHandler = popupWidget(const BeautyPanelWidget(), barrierColor: LiveColors.designStandardTransparent);
        break;
      case FeaturesItemType.audioEffect:
        _audioEffectSheetHandler = popupWidget(AudioEffectPanelWidget(roomId: liveStreamManager.roomState.roomId));
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
      default:
        break;
    }
  }

  void _showPipConfigPanel() {
    TUILiveKitPlatform.instance.hasPipPermission().then((hasPipPermission) {
      if (!hasPipPermission) {
        liveStreamManager.enablePipMode(false);
      }
      _pipConfigPanelHandler = popupWidget(
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
          icon: LiveImages.settingsItemMusic,
          type: FeaturesItemType.audioEffect),
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

enum FeaturesItemType { beauty, audioEffect, flip, mirror, pip }

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
