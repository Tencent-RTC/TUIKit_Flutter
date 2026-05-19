import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/constants/index.dart';
import 'package:tencent_live_uikit/common/resources/colors.dart';
import 'package:tencent_live_uikit/common/resources/images.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';

class CoGuestForegroundWidget extends StatefulWidget {
  final SeatInfo seatInfo;
  final ValueListenable<bool> isFloatWindowMode;
  final GestureTapCallback? onTap;

  const CoGuestForegroundWidget({
    super.key,
    required this.seatInfo,
    required this.isFloatWindowMode,
    this.onTap,
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
            child: LayoutBuilder(builder: (context, constraint) {
              return SizedBox(
                  width: constraint.maxWidth,
                  height: constraint.maxHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildMicAndNameWidget(constraint.maxWidth),
                      _buildGestureDetector(),
                    ],
                  ));
            }),
          );
        });
  }

  Widget _buildMicAndNameWidget(double maxWidth) {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty) return const SizedBox.shrink();
    CoGuestStore coGuestStore = CoGuestStore.create(liveID);
    return ValueListenableBuilder(
      valueListenable: coGuestStore.coGuestState.connected,
      builder: (context, connected, _) {
        return Visibility(
          visible: connected.length > 1,
          child: Positioned(
            left: 10.width,
            bottom: 4.height,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth - 20.width),
              child: Container(
                padding: EdgeInsets.only(left: 8.width, right: 8.width, top: 3.height, bottom: 3.height),
                decoration: BoxDecoration(
                  color: LiveColors.userNameBlackColor,
                  borderRadius: BorderRadius.circular(37.radius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: Text(
                        (widget.seatInfo.userInfo.userName.isNotEmpty)
                            ? widget.seatInfo.userInfo.userName
                            : widget.seatInfo.userInfo.userID,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 10),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestureDetector() {
    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: Container(color: Colors.transparent),
    );
  }
}
