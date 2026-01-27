import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/constants/index.dart';
import 'package:tencent_live_uikit/common/resources/colors.dart';
import 'package:tencent_live_uikit/common/resources/images.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';

import '../../../../common/language/index.dart';
import '../../../../common/widget/index.dart';

class CoHostForegroundWidget extends StatefulWidget {
  final SeatInfo seatInfo;
  final ValueListenable<bool> isFloatWindowMode;

  const CoHostForegroundWidget({
    super.key,
    required this.seatInfo,
    required this.isFloatWindowMode,
  });

  @override
  State<CoHostForegroundWidget> createState() => _CoHostForegroundWidgetState();
}

class _CoHostForegroundWidgetState extends State<CoHostForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.isFloatWindowMode,
        builder: (context, isFloatWindowMode, child) {
          return Visibility(
            visible: !isFloatWindowMode,
            child: LayoutBuilder(builder: (context, constraint) {
              return SizedBox(
                width: constraint.maxWidth,
                height: constraint.maxHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildConnectionStatusWidget(),
                    _buildMicAndNameWidget(),
                  ],
                ),
              );
            }),
          );
        });
  }

  Widget _buildMicAndNameWidget() {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    CoHostStore coHostStore = CoHostStore.create(liveID);
    return Visibility(
      visible: coHostStore.coHostState.connected.value.length > 1,
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
                visible: widget.seatInfo.userInfo.microphoneStatus != DeviceStatus.on,
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
                (widget.seatInfo.userInfo.userName.isNotEmpty)
                    ? widget.seatInfo.userInfo.userName
                    : widget.seatInfo.userInfo.userID,
                style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 10),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusWidget() {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    BattleStore battleStore = BattleStore.create(liveID);
    return Align(
      alignment: Alignment.topLeft,
      child: ListenableBuilder(
          listenable: Listenable.merge([
            battleStore.battleState.currentBattleInfo,
            battleStore.battleState.battleUsers,
          ]),
          builder: (context, _) {
            return Visibility(
                visible: _isConnectionStatusVisible(battleStore),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.width, right: 8.width, top: 3.height, bottom: 3.height),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(37.radius), color: LiveColors.userNameBlackColor),
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.width, right: 4.width, top: 5.height, bottom: 5.height),
                      child: Text(
                        LiveKitLocalizations.of(Global.appContext())!.common_battle_connecting,
                        style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                      ),
                    ),
                  ),
                ));
          }),
    );
  }
}

extension on _CoHostForegroundWidgetState {
  bool _isConnectionStatusVisible(BattleStore battleStore) {
    if (battleStore.battleState.currentBattleInfo.value != null &&
        !battleStore.battleState.battleUsers.value
            .any((battleUser) => battleUser.userID == widget.seatInfo.userInfo.userID)) {
      return true;
    }
    return false;
  }
}
