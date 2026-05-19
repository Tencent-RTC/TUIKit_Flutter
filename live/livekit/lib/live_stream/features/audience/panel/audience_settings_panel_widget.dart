import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/live_stream/state/co_guest_state.dart';

import '../../../../common/widget/base_bottom_sheet.dart';
import '../../../../component/float_window/global_float_window_manager.dart';
import '../../../../component/float_window/pip_config_panel_widget.dart';

class AudienceSettingsPanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const AudienceSettingsPanelWidget({super.key, required this.liveStreamManager});

  @override
  State<StatefulWidget> createState() => _AudienceSettingsPanelWidgetState();
}

class _AudienceSettingsPanelWidgetState extends State<AudienceSettingsPanelWidget> {
  late final LiveStreamManager liveStreamManager;
  BottomSheetHandler? _pipConfigPanelHandler;
  BottomSheetHandler? _videoQualityPanelHandler;
  late final VoidCallback _coGuestStatusListener = _onCoGuestStatusChanged;

  @override
  void initState() {
    liveStreamManager = widget.liveStreamManager;
    liveStreamManager.coGuestState.coGuestStatus.addListener(_coGuestStatusListener);
    super.initState();
  }

  @override
  void dispose() {
    liveStreamManager.coGuestState.coGuestStatus.removeListener(_coGuestStatusListener);
    _closeAllDialog();
    super.dispose();
  }

  void _closeAllDialog() {
    _pipConfigPanelHandler?.close();
    _videoQualityPanelHandler?.close();
  }

  // When audience takes a seat while this panel is open, close the
  // already-opened video quality selection sub-panel because the resolution
  // entry is no longer applicable to a guest on seat.
  void _onCoGuestStatusChanged() {
    if (liveStreamManager.coGuestState.coGuestStatus.value == CoGuestStatus.linking) {
      _videoQualityPanelHandler?.close();
      _videoQualityPanelHandler = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 1.screenWidth,
        height: 198.height,
        child: Column(
          children: [
            SizedBox(height: 20.height),
            Center(
                child: Text(
              LiveKitLocalizations.of(context)!.common_more_features,
              style: TextStyle(
                  color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            )),
            SizedBox(height: 20.height),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.width),
              child: ValueListenableBuilder(
                valueListenable: liveStreamManager.coGuestState.coGuestStatus,
                builder: (context, coGuestStatus, _) {
                  // Video resolution entry is only available for audience
                  // members who are NOT on seat (off-mic). Once an audience
                  // takes a seat (becomes a guest), this entry must be hidden.
                  final isOnSeat = coGuestStatus == CoGuestStatus.linking;
                  final showPip = GlobalFloatWindowManager.instance.isEnableFloatWindowFeature();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 20.width,
                    children: [
                      if (!isOnSeat) _buildVideoSettingsItemWidget(context),
                      if (showPip) _buildPipItemWidget(context),
                    ],
                  );
                },
              ),
            )
          ],
        ));
  }

  Widget _buildVideoSettingsItemWidget(BuildContext context) {
    return _buildItemWidget(context, LiveKitLocalizations.of(context)!.live_video_resolution,
        LiveImages.videoResolution, () => _showVideoQualitySelectionPanel());
  }

  Widget _buildPipItemWidget(BuildContext context) {
    return _buildItemWidget(context, LiveKitLocalizations.of(context)!.common_video_settings_item_pip,
        LiveImages.settingsItemPip, () => _showPipConfigPanel());
  }

  Widget _buildItemWidget(BuildContext context, String title, String imageName, GestureTapCallback onTap) {
    return SizedBox(
      height: 80.height,
      width: 56.width,
      child: Column(children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
              decoration: BoxDecoration(
                  color: LiveColors.designBgColorInput, borderRadius: BorderRadius.all(Radius.circular(8.radius))),
              width: 56.radius,
              height: 56.radius,
              child: Center(
                child: SizedBox(
                  width: 27.radius,
                  height: 27.radius,
                  child: Image.asset(
                    imageName,
                    package: Constants.pluginName,
                  ),
                ),
              )),
        ),
        SizedBox(height: 6.height),
        Flexible(
            child: Center(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: LiveColors.designStandardFlowkitWhite.withAlpha(230),
                        fontSize: 12,
                        fontWeight: FontWeight.w400))))
      ]),
    );
  }
}

extension on _AudienceSettingsPanelWidgetState {
  void _showVideoQualitySelectionPanel() {
    final playbackQualityList = liveStreamManager.mediaState.playbackQualityList.value;
    final actions = [
      ...playbackQualityList.map((videoQuality) => ActionSheetItem(
            title: _getVideoQualityString(videoQuality),
            onTap: () => liveStreamManager.switchPlaybackQuality(videoQuality),
          )),
    ];
    _videoQualityPanelHandler = BaseBottomSheet.showWithHandler(
      context,
      actions: actions,
    );
  }

  String _getVideoQualityString(TUIVideoQuality videoQuality) {
    switch (videoQuality) {
      case TUIVideoQuality.videoQuality_1080P:
        return '1080P';
      case TUIVideoQuality.videoQuality_720P:
        return '720P';
      case TUIVideoQuality.videoQuality_540P:
        return '540P';
      case TUIVideoQuality.videoQuality_360P:
        return '360P';
      default:
        return 'unknown';
    }
  }

  void _showPipConfigPanel() {
    TUILiveKitPlatform.instance.hasPipPermission().then((hasPipPermission) {
      if (!mounted) return;
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
        context: context,
      );
    });
  }

  void _enablePictureInPicture(bool enable) {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      final roomId = liveStreamManager.roomState.roomId;
      liveStreamManager.enablePictureInPicture(roomId, enable).then((result) {
        LiveKitLogger.info("enablePictureInPicture,enable=$enable,result=$result");
        liveStreamManager.enablePipMode(enable && result);
      });
    }
  }
}
