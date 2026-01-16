import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import '../../../common/constants.dart';
import '../../hint/timer_widget.dart';

class CallPipWidget extends StatefulWidget {
  final CallCoreController controller;

  const CallPipWidget({
    super.key,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() => _CallPipWidgetState();
}

class _CallPipWidgetState extends State<CallPipWidget> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CallCoreView(
          controller: widget.controller,
          defaultAvatar: Constants.defaultAvatarImage,
        ),
        Positioned(
          bottom: 40,
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: const Center(
            child: TimerWidget(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}