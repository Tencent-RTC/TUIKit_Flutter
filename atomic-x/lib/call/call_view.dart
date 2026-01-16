import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/call/component/widgets/float/call_float_widget.dart';
import 'package:tuikit_atomic_x/call/component/widgets/grid/call_grid_widget.dart';
import 'package:tuikit_atomic_x/call/component/widgets/pip/call_pip_widget.dart';

class CallView extends StatefulWidget {
  final bool isPipMode;

  const CallView({
    super.key,
    this.isPipMode = false,
  });

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  late final CallCoreController controller;

  @override
  void initState() {
    controller = CallCoreController.create();
    DeviceStore.shared.openLocalMicrophone();
    DeviceStore.shared.setAudioRoute(
      CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
          ? AudioRoute.earpiece
          : AudioRoute.speakerphone
    );
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.video) {
      DeviceStore.shared.openLocalCamera(true);
    }
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    DeviceStore.shared.closeLocalMicrophone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ValueListenableBuilder(
            valueListenable: CallStore.shared.state.activeCall,
            builder: (context, activeCall, child) {
              if (widget.isPipMode) {
                controller.setLayoutTemplate(CallLayoutTemplate.pip);
                return CallPipWidget(
                  controller: controller,
                );
              }

              if (activeCall.chatGroupId.isNotEmpty || activeCall.inviteeIds.length > 1) {
                controller.setLayoutTemplate(CallLayoutTemplate.grid);
                return CallGridWidget(
                  controller: controller,
                );
              }

              controller.setLayoutTemplate(CallLayoutTemplate.float);
              return CallFloatWidget(
                controller: controller,
              );
            }
        ),
      ),
    );
  }
}