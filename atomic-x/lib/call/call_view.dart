import 'package:atomic_x/call/component/controls/multi_call_controls_widget.dart';
import 'package:atomic_x/call/component/controls/single_call_controls_widget.dart';
import 'package:atomic_x/call/component/hint/timer_widget.dart';
import 'package:atomic_x/call/component/stream_widget/multi_call_stream_widget.dart';
import 'package:atomic_x/call/component/stream_widget/single_call_stream_widget.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CallView extends StatefulWidget {
  final List<CallFeature> disableFeatures;

  const CallView({
    super.key,
    this.disableFeatures = const [],
  });

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  bool isMultiPerson = false;

  @override
  void initState() {
    DeviceStore.shared.openLocalMicrophone();
    DeviceStore.shared.setAudioRoute(
      CallListStore.shared.state.activeCall.value.mediaType == TUICallMediaType.audio
          ? AudioRoute.earpiece
          : AudioRoute.speakerphone
    );
    super.initState();
  }

  @override
  void dispose() {
    DeviceStore.shared.closeLocalMicrophone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: ValueListenableBuilder(
            valueListenable: CallListStore.shared.state.activeCall,
            builder: (context, activeCall, child) {
              return ValueListenableBuilder(
                  valueListenable: CallParticipantStore.shared.state.allParticipants,
                  builder: (context, allParticipants, child) {
                    Widget streamWidget = SingleCallStreamWidget(disableFeatures: widget.disableFeatures,);
                    Widget controlsWidget = SingleCallControlsWidget(disableFeatures: widget.disableFeatures,);
                    if (activeCall.chatGroupId.isNotEmpty || isMultiPerson || activeCall.inviteeIds.length >= 2) {
                      isMultiPerson = true;
                      streamWidget = MultiCallStreamWidget(disableFeatures: widget.disableFeatures,);
                      controlsWidget = MultiCallControlsWidget(disableFeatures: widget.disableFeatures,);
                    }

                    return Stack(
                      children: [
                        streamWidget,
                        if (!widget.disableFeatures.contains(CallFeature.all)
                            && !widget.disableFeatures.contains(CallFeature.timer))
                          getTimerWidget(),
                        Positioned(
                          right: 0,
                          left: 0,
                          bottom: isMultiPerson ? 0 : 40,
                          child: widget.disableFeatures.contains(CallFeature.all)
                              ? Container()
                              : controlsWidget,
                        ),
                      ],
                    );
                  }
              );
            }
        ),
      ),
    );
  }

  Widget getTimerWidget() {
    return ValueListenableBuilder(
      valueListenable: SingleCallUserWidgetData.isOnlyShowVideoView,
      builder: (context, value, child) {
        if (value) {
          return Container();
        }
        return Positioned(
          top: 20,
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: Center(child: TimerWidget(),),
        );
      },
    );
  }
}

enum CallFeature {
  timer,
  networkQuality,
  openFloatWindow,
  invite,
  accept,
  hangup,
  toggleMicrophone,
  toggleCamera,
  selectAudioRoute,
  switchCamera,
  virtualBackground,
  all,
}