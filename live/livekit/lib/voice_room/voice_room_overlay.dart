import 'package:atomic_x_core/atomicxcore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/voice_room/voice_room_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../common/widget/float_window/float_window_widget.dart';
import '../../component/float_window/index.dart';

class TUIVoiceRoomOverlay extends StatefulWidget {
  final String roomId;
  final RoomBehavior behavior;
  final RoomParams? params;

  const TUIVoiceRoomOverlay({
    super.key,
    required this.roomId,
    required this.behavior,
    this.params,
  });

  @override
  State<StatefulWidget> createState() => TUIVoiceRoomOverlayState();
}

class TUIVoiceRoomOverlayState extends State<TUIVoiceRoomOverlay> {
  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveKitLogger.info("TUIVoiceRoomOverlay initState");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
        String error = "Error: GlobalFloatWindowManager.isEnableFloatWindowFeature is false!\n"
            "You need to enable the floating window feature first.\n"
            "It is recommended to execute the following in main.dart first: GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);";
        LiveKitLogger.error(error);
        makeToast(msg: "Tip: GlobalFloatWindowManager.isEnableFloatWindowFeature is false!");
        if (mounted) Navigator.pop(context);
        return;
      }
      if (Global.secondaryNavigatorKey.currentState == null) {
        String error = "Error: Global.secondaryNavigatorKey is invalid!\n"
            "Please refer to the home parameter of MaterialApp in example's main.dart.\n"
            "You need to wrap the home page with a Navigator and use Global.secondaryNavigatorKey as the key for this Navigator.";
        LiveKitLogger.error(error);
        makeToast(msg: "Tip: Global.secondaryNavigatorKey is invalid!");
        if (mounted) Navigator.pop(context);
        return;
      }
      if (GlobalFloatWindowManager.instance.isFloating()) {
        GlobalFloatWindowState state = GlobalFloatWindowManager.instance.state;
        if (state.ownerId.value == TUIRoomEngine.getSelfInfo().userId) {
          makeToast(msg: LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip);
          if (mounted) Navigator.pop(context);
          return;
        } else {
          GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
        }
      }
      final overlayEntry = OverlayEntry(builder: (context) => buildOverlayContent());
      GlobalFloatWindowManager.instance.setRoomId(widget.roomId);
      GlobalFloatWindowManager.instance.overlayManager.showOverlayEntry(overlayEntry);
      if (mounted) Navigator.pop(context);
    });
  }

  Widget buildOverlayContent() {
    final width = 60.width;
    return FloatWindowWidget(
      padding: 0,
      size: Size(width, width),
      borderRadius: BorderRadius.circular(width / 2),
      builder: (context, controller) {
        switchToFullScreenMode() {
          controller.onTapSwitchFloatWindowInApp(false);
        }

        GlobalFloatWindowManager.instance.overlayManager.setSwitchToFullScreenCallback(switchToFullScreenMode);
        return Stack(
          children: [
            TUIVoiceRoomWidget(roomId: widget.roomId, behavior: widget.behavior, floatWindowController: controller),
            Visibility(
              visible: !controller.isFullScreen.value,
              child: CachedNetworkImage(
                imageUrl: LiveListStore.shared.liveState.currentLive.value.liveOwner.avatarURL,
                errorWidget: (BuildContext context, String url, Object error) {
                  return Image.asset(LiveImages.defaultAvatar, package: Constants.pluginName);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
