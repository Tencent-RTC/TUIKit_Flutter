import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/api/room/tui_room_define.dart';
import 'package:tencent_live_uikit/common/constants/index.dart';
import 'package:tencent_live_uikit/common/resources/colors.dart';
import 'package:tencent_live_uikit/common/resources/images.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';

class CoGuestBackgroundWidget extends StatefulWidget {
  final SeatFullInfo userInfo;
  final ValueListenable<bool> isFloatWindowMode;

  const CoGuestBackgroundWidget({
    super.key,
    required this.userInfo,
    required this.isFloatWindowMode,
  });

  @override
  State<CoGuestBackgroundWidget> createState() => _CoGuestWidgetState();
}

class _CoGuestWidgetState extends State<CoGuestBackgroundWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.isFloatWindowMode,
        builder: (context, isFloatWindowMode, child) {
          return Visibility(
            visible: !isFloatWindowMode,
            child: LayoutBuilder(builder: (context, constraint) {
              return Container(
                width: constraint.maxWidth, height: constraint.maxHeight,
                decoration:
                BoxDecoration(color: LiveColors.grayDark2, border: Border.all(color: LiveColors.black6, width: 0.5)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAvatarWidget(),
                  ],
                ),
              );
            }),
          );
        });
  }

  Widget _buildAvatarWidget() {
    return Center(
      child: SizedBox(
        width: 45.width,
        height: 45.width,
        child: ClipOval(
          child: Image.network(
            widget.userInfo.userAvatar,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                LiveImages.defaultAvatar,
                package: Constants.pluginName,
              );
            },
          ),
        ),
      ),
    );
  }
}
