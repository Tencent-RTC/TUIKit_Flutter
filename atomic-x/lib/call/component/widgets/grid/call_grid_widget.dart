import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:tuikit_atomic_x/call/component/widgets/grid/call_grid_waiting_widget.dart';

import '../../../common/constants.dart';
import '../../../common/utils/utils.dart';
import '../../aisubtitle/ai_subtitle.dart';
import '../../controls/multi_call_controls_widget.dart';
import '../../hint/timer_widget.dart';

class CallGridWidget extends StatefulWidget {
  final CallCoreController controller;

  const CallGridWidget({
    super.key,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() => _CallGridWidgetState();
}

class _CallGridWidgetState extends State<CallGridWidget> {

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: NetworkImage(
                  StringStream.makeNull(selfInfo.avatarURL, Constants.defaultAvatar),
                ),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stackTrace) => Image.asset(
                  'call_assets/user_icon.png',
                  package: 'tuikit_atomic_x',
                ),
              ),
            ),
            Opacity(
              opacity: 1,
              child: Container(
                color: const Color.fromRGBO(45, 45, 45, 0.9),
              ),
            ),
            selfInfo.id != CallStore.shared.state.activeCall.value.inviterId
                && selfInfo.status == CallParticipantStatus.waiting
                ? _buildReceivedGroupCallWaiting(context)
                : _buildCallGridView(),
            Positioned(
              top: 20,
              width: MediaQuery.of(context).size.width,
              height: 100,
              child: const Center(
                child: TimerWidget(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 240,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: AISubtitle(userId: CallStore.shared.state.selfInfo.value.id),
              ),
            ),
            const Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: MultiCallControlsWidget(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCallGridView() {
    return Container(
      margin: const EdgeInsets.only(top: 90),
      child: CallCoreView(
        controller: widget.controller,
        defaultAvatar: Constants.defaultAvatarImage,
        loadingAnimation: Constants.loading,
        volumeIcons: Constants.volumeIcons,
        networkQualityIcons: Constants.networkQualityIcons,
      ),
    );
  }

  Widget _buildReceivedGroupCallWaiting(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      width: MediaQuery.of(context).size.width,
      child: const CallGridWaitingWidget(),
    );
  }
}