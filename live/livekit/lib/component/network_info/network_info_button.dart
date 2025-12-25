import 'dart:async';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/network_info/index.dart';
import 'package:tencent_live_uikit/component/network_info/manager/network_info_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

class NetworkInfoButton extends StatefulWidget {
  final NetworkInfoManager manager;
  final int createTime;
  final bool isAudience;
  final ValueListenable<bool>? isFloatWindowMode;

  const NetworkInfoButton({
    super.key,
    required this.manager,
    required this.createTime,
    required this.isAudience,
    this.isFloatWindowMode,
  });

  @override
  State<NetworkInfoButton> createState() => _NetworkInfoButtonState();
}

class _NetworkInfoButtonState extends State<NetworkInfoButton> {
  BottomSheetHandler? _bottomSheetHandler;
  late final LiveListListener _liveListListener;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;
  Timer? _durationTimer;
  final ValueNotifier<String> _formatDuration = ValueNotifier('00:00:00');

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeBottomSheet();
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
    widget.isFloatWindowMode?.addListener(_floatWindowModeListener);
  }

  @override
  void dispose() {
    _stopDurationTimer();
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    widget.isFloatWindowMode?.removeListener(_floatWindowModeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _popupWidget(NetworkInfoWidget(manager: widget.manager, isAudience: widget.isAudience));
      },
      child: Container(
          constraints: BoxConstraints(maxHeight: 20.height, maxWidth: 86.width),
          decoration: BoxDecoration(
              color: LiveColors.notStandardPureBlack.withAlpha(0x60), borderRadius: BorderRadius.circular(11.height)),
          padding: EdgeInsets.only(left: 4.width, top: 2.height, bottom: 2.height, right: 8.width),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ValueListenableBuilder(
                valueListenable: widget.manager.state.networkQuality,
                builder: (context, networkQuality, _) {
                  final imagePath = _getNetworkWifiImagePathByNetworkQuality(networkQuality);
                  return Image.asset(imagePath, package: Constants.pluginName, width: 14.radius, height: 14.radius);
                }),
            SizedBox(width: 8.width),
            ValueListenableBuilder(
                valueListenable: _formatDuration,
                builder: (context, formatDuration, _) {
                  return Text(formatDuration,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          color: LiveColors.designStandardFlowkitWhite.withAlpha(0xE6)));
                })
          ])),
    );
  }

  void _closeBottomSheet() {
    _bottomSheetHandler?.close();
  }

  void _onFloatWindowModeChanged() {
    if (widget.isFloatWindowMode != null) {
      if (widget.isFloatWindowMode!.value) {
        _closeBottomSheet();
      }
    }
  }
}

extension on _NetworkInfoButtonState {
  String _getNetworkWifiImagePathByNetworkQuality(TUINetworkQuality quality) {
    switch (quality) {
      case TUINetworkQuality.qualityExcellent:
        return LiveImages.networkInfoWifi;
      case TUINetworkQuality.qualityGood:
        return LiveImages.networkInfoWifi;
      case TUINetworkQuality.qualityPoor:
        return LiveImages.networkInfoWifiPoor;
      case TUINetworkQuality.qualityBad:
        return LiveImages.networkInfoWifiBad;
      case TUINetworkQuality.qualityVeryBad:
        return LiveImages.networkInfoWifiError;
      case TUINetworkQuality.qualityDown:
        return LiveImages.networkInfoWifiError;
      default:
        return LiveImages.networkInfoWifiError;
    }
  }
}

extension on _NetworkInfoButtonState {
  void _popupWidget(Widget widget, {Color? barrierColor}) {
    _bottomSheetHandler = BaseBottomSheet.showModalSheet(
      barrierColor: barrierColor,
      isScrollControlled: true,
      context: Global.appContext(),
      backgroundColor: LiveColors.designStandardTransparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.width),
            topRight: Radius.circular(20.width),
          ),
          color: LiveColors.designStandardTransparent,
        ),
        child: widget,
      ),
    );
  }
}

extension on _NetworkInfoButtonState {
  void _startDurationTimer() {
    _stopDurationTimer();

    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateFormatTime();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _updateFormatTime() {
    final currentDuration = (DateTime.now().millisecondsSinceEpoch / 1000.0 - widget.createTime / 1000.0).toInt();
    final hours = (currentDuration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((currentDuration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (currentDuration % 60).toString().padLeft(2, '0');
    _formatDuration.value = '$hours:$minutes:$seconds';
  }
}
