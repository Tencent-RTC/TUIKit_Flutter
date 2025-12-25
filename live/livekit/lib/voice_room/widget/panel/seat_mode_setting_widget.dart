import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';

class SeatModeSettingPanelWidget extends StatefulWidget {
  final VoiceRoomPrepareStore prepareStore;

  const SeatModeSettingPanelWidget({super.key, required this.prepareStore});

  @override
  State<SeatModeSettingPanelWidget> createState() => _SeatModeSettingPanelWidgetState();
}

class _SeatModeSettingPanelWidgetState extends State<SeatModeSettingPanelWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.screenWidth,
      height: 300,
      child: Column(children: [
        SizedBox(height: 20.height),
        SizedBox(
          height: 44.height,
          width: 1.screenWidth,
          child: Stack(
            children: [
              Positioned(
                  left: 14.width,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                          width: 44.radius,
                          height: 44.radius,
                          padding: EdgeInsets.all(10.radius),
                          child: Image.asset(
                            LiveImages.returnArrow,
                            package: Constants.pluginName,
                          )))),
              Center(
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_settings,
                  style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(16.radius),
              child: Text(LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_need_agree,
                  style: const TextStyle(fontSize: 16, color: LiveColors.designStandardFlowkitWhite)),
            ),
            Expanded(
                child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ValueListenableBuilder(
                    valueListenable: ValueSelector(widget.prepareStore.state.liveInfo, (liveInfo) => liveInfo.seatMode),
                    builder: (context, seatMode, child) {
                      return SizedBox(
                        height: 32.height,
                        child: FittedBox(
                          child: CupertinoSwitch(
                              inactiveTrackColor: LiveColors.designStandardG3,
                              activeTrackColor: LiveColors.designStandardB1,
                              value: seatMode == TakeSeatMode.apply,
                              onChanged: (opened) {
                                final mode = opened ? TUISeatMode.applyToTake : TUISeatMode.freeToTake;
                                widget.prepareStore.onChangedSeatMode(mode);
                              }),
                        ),
                      );
                    }),
              ),
            ))
          ],
        )
      ]),
    );
  }
}
