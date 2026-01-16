import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';

import '../../common/call_colors.dart';

class TimerWidget extends StatelessWidget {
  final double? fontSize;
  final FontWeight? fontWeight;

  const TimerWidget({
    super.key,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: CallStore.shared.state.selfInfo,
        builder: (context, info, child) {
          if (info.status == CallParticipantStatus.accept) {
            return ValueListenableBuilder(
              valueListenable: CallStore.shared.state.activeCall,
              builder: (context, activeCall, child) {
                return Text(
                  formatDuration(activeCall.duration.toInt()),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
                        ? CallColors.colorG7
                        : CallColors.colorWhite,
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        }
    );
  }

  String formatDuration(int timeCount) {
    int hour = timeCount ~/ 3600;
    int minute = (timeCount % 3600) ~/ 60;
    String minuteShow = minute <= 9 ? "0$minute" : "$minute";
    int second = timeCount % 60;
    String secondShow = second <= 9 ? "0$second" : "$second";

    if (hour > 0) {
      String hourShow = hour <= 9 ? "0$hour" : "$hour";
      return '$hourShow:$minuteShow:$secondShow';
    } else {
      return '$minuteShow:$secondShow';
    }
  }

}