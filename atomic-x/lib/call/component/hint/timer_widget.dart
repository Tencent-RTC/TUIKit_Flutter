import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: CallParticipantStore.shared.state.selfInfo,
        builder: (context, info, child) {
          if (info.status == CallParticipantStatus.accept) {
            return ValueListenableBuilder(
              valueListenable: CallStore.shared.state.activeCall,
              builder: (context, activeCall, child) {
                return Text(
                  formatDuration(activeCall.duration.toInt()),
                  style: const TextStyle(color: Colors.white),
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
    String hourShow = hour <= 9 ? "0$hour" : "$hour";
    int minute = (timeCount % 3600) ~/ 60;
    String minuteShow = minute <= 9 ? "0$minute" : "$minute";
    int second = timeCount % 60;
    String secondShow = second <= 9 ? "0$second" : "$second";

    return '$hourShow:$minuteShow:$secondShow';
  }

}