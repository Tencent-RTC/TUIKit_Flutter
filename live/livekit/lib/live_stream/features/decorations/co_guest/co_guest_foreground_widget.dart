import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';
import 'package:tencent_live_uikit/common/constants/index.dart';
import 'package:tencent_live_uikit/common/resources/colors.dart';
import 'package:tencent_live_uikit/common/resources/images.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';

class CoGuestForegroundWidget extends StatefulWidget {
  final SeatFullInfo userInfo;
  final ValueListenable<bool> isFloatWindowMode;

  const CoGuestForegroundWidget({
    super.key,
    required this.userInfo,
    required this.isFloatWindowMode,
  });

  @override
  State<CoGuestForegroundWidget> createState() => _CoGuestWidgetState();
}

class _CoGuestWidgetState extends State<CoGuestForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.isFloatWindowMode,
        builder: (context, isFloatWindowMode, child) {
          return Visibility(
            visible: !isFloatWindowMode,
            child: Container(
                child: LayoutBuilder(builder: (context, constraint) {
                  return SizedBox(width: constraint.maxWidth, height: constraint.maxHeight, child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildMicAndNameWidget(),
                    ],
                  ));
                })),
          );
        });
  }

  _buildMicAndNameWidget() {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    CoGuestStore coGuestStore = CoGuestStore.create(liveID);
    return Visibility(
      visible: coGuestStore.coGuestState.connected.value.length > 1,
      child: Positioned(
        left: 10.width,
        bottom: 4.height,
        child: Container(
          padding: EdgeInsets.only(left: 8.width, right: 8.width, top: 3.height, bottom: 3.height),
          decoration: BoxDecoration(
            color: LiveColors.userNameBlackColor,
            borderRadius: BorderRadius.circular(37.radius),
          ),
          child: Row(
            children: [
              Visibility(
                visible: widget.userInfo.userMicrophoneStatus != DeviceStatus.opened,
                child: SizedBox(
                  width: 12.width,
                  height: 12.width,
                  child: Image.asset(
                    LiveImages.muteMicrophone,
                    package: Constants.pluginName,
                  ),
                ),
              ),
              SizedBox(
                width: 2.width,
              ),
              Text(
                (widget.userInfo.userName.isNotEmpty) ? widget.userInfo.userName : widget.userInfo.userId,
                style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 10),
              )
            ],
          ),
        ),
      ),
    );
  }
}
