import 'dart:async';
import 'dart:math';

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/network_info/index.dart';
import 'package:tencent_live_uikit/component/network_info/manager/network_info_manager.dart';

class NetworkInfoButton extends StatefulWidget {
  final NetworkInfoManager manager;
  final bool isAudience;
  final ValueListenable<bool>? isFloatWindowMode;

  const NetworkInfoButton({
    super.key,
    required this.manager,
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
          constraints: BoxConstraints(maxHeight: 20.height),
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
  String _getNetworkWifiImagePathByNetworkQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return LiveImages.networkInfoWifi;
      case NetworkQuality.good:
        return LiveImages.networkInfoWifi;
      case NetworkQuality.poor:
        return LiveImages.networkInfoWifiPoor;
      case NetworkQuality.bad:
        return LiveImages.networkInfoWifiBad;
      case NetworkQuality.veryBad:
        return LiveImages.networkInfoWifiError;
      case NetworkQuality.down:
        return LiveImages.networkInfoWifiError;
      default:
        return LiveImages.networkInfoWifiError;
    }
  }
}

extension on _NetworkInfoButtonState {
  void _popupWidget(Widget widget) {
    _bottomSheetHandler = popupWidget(widget, context: context);
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
    final createTime = LiveListStore.shared.liveState.currentLive.value.createTime;
    int duration = (DateTime.now().millisecondsSinceEpoch / 1000.0 - createTime / 1000.0).toInt();
    if (createTime <= 0) duration = 0;
    final currentDuration = max(duration, 0);
    final hours = (currentDuration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((currentDuration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (currentDuration % 60).toString().padLeft(2, '0');
    _formatDuration.value = '$hours:$minutes:$seconds';
  }
}
