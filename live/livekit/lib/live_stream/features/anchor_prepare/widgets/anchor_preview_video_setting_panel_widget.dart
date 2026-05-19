import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../../../../common/widget/base_bottom_sheet.dart';
import '../../../manager/live_stream_manager.dart';

class AnchorPreviewVideoSettingPanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const AnchorPreviewVideoSettingPanelWidget({super.key, required this.liveStreamManager});

  @override
  State<AnchorPreviewVideoSettingPanelWidget> createState() => _AnchorPreviewVideoSettingPanelWidgetState();
}

class _AnchorPreviewVideoSettingPanelWidgetState extends State<AnchorPreviewVideoSettingPanelWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252.height,
      width: 1.screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.height),
          Center(
              child: Text(LiveKitLocalizations.of(context)!.common_video_settings,
                  style: TextStyle(
                      color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                      fontSize: 16,
                      fontWeight: FontWeight.w500))),
          SizedBox(height: 20.height),
          _buildVideoSettingsItemWidget()
        ],
      ),
    );
  }

  Widget _buildVideoSettingsItemWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.width),
      decoration: BoxDecoration(
          color: LiveColors.designBgColorInput, borderRadius: BorderRadius.all(Radius.circular(8.radius))),
      height: 113.height,
      child: Column(
        children: [
          Container(
            height: 56.height,
            padding: EdgeInsets.all(12.width),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LiveKitLocalizations.of(context)!.common_video_settings_item_mirror,
                    style: TextStyle(
                        color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                        fontSize: 16,
                        fontWeight: FontWeight.w400)),
                GestureDetector(
                  onTap: () {
                    _showMirrorSelectionPanel();
                  },
                  child: ValueListenableBuilder(
                      valueListenable: DeviceStore.shared.state.localMirrorType,
                      builder: (context, videoQuality, _) {
                        return Row(
                          spacing: 4.width,
                          children: [
                            Text(_getMirrorString(DeviceStore.shared.state.localMirrorType.value),
                                style: TextStyle(
                                    color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400)),
                            Image.asset(LiveImages.downArrow, package: Constants.pluginName)
                          ],
                        );
                      }),
                )
              ],
            ),
          ),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 16.width),
              child: Container(height: 1.height, color: LiveColors.designStrokeColorPrimary)),
          Container(
            height: 56.height,
            padding: EdgeInsets.all(12.width),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LiveKitLocalizations.of(context)!.live_video_resolution,
                    style: TextStyle(
                        color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                        fontSize: 16,
                        fontWeight: FontWeight.w400)),
                GestureDetector(
                  onTap: () {
                    _showVideoQualitySelectionPanel();
                  },
                  child: ValueListenableBuilder(
                      valueListenable: DeviceStore.shared.state.localVideoQuality,
                      builder: (context, videoQuality, _) {
                        return Row(
                          spacing: 4.width,
                          children: [
                            Text(_getVideoQualityString(DeviceStore.shared.state.localVideoQuality.value),
                                style: TextStyle(
                                    color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400)),
                            Image.asset(LiveImages.downArrow, package: Constants.pluginName)
                          ],
                        );
                      }),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

extension on _AnchorPreviewVideoSettingPanelWidgetState {
  void _showVideoQualitySelectionPanel() {
    BaseBottomSheet.showWithHandler(
      context,
      actions: [
        ActionSheetItem(
          title: _getVideoQualityString(VideoQuality.quality1080P),
          onTap: () => widget.liveStreamManager.updateVideoQuality(VideoQuality.quality1080P),
        ),
        ActionSheetItem(
          title: _getVideoQualityString(VideoQuality.quality720P),
          onTap: () => widget.liveStreamManager.updateVideoQuality(VideoQuality.quality720P),
        ),
      ],
    );
  }

  String _getVideoQualityString(VideoQuality videoQuality) {
    switch (videoQuality) {
      case VideoQuality.quality1080P:
        return '1080P';
      case VideoQuality.quality720P:
        return '720P';
      case VideoQuality.quality540P:
        return '540P';
      case VideoQuality.quality360P:
        return '360P';
      default:
        return 'unknown';
    }
  }

  void _showMirrorSelectionPanel() {
    BaseBottomSheet.showWithHandler(
      context,
      actions: [
        ActionSheetItem(
          title: _getMirrorString(MirrorType.auto),
          onTap: () => DeviceStore.shared.switchMirror(MirrorType.auto),
        ),
        ActionSheetItem(
          title: _getMirrorString(MirrorType.enable),
          onTap: () => DeviceStore.shared.switchMirror(MirrorType.enable),
        ),
        ActionSheetItem(
          title: _getMirrorString(MirrorType.disable),
          onTap: () => DeviceStore.shared.switchMirror(MirrorType.disable),
        ),
      ],
    );
  }

  String _getMirrorString(MirrorType mirrorType) {
    switch (mirrorType) {
      case MirrorType.auto:
        return LiveKitLocalizations.of(context)!.mirror_type_auto;
      case MirrorType.enable:
        return LiveKitLocalizations.of(context)!.mirror_type_enable;
      case MirrorType.disable:
        return LiveKitLocalizations.of(context)!.mirror_type_disable;
      }
  }
}
