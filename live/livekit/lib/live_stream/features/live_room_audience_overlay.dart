import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../common/widget/float_window/float_window_widget.dart';
import '../../component/float_window/index.dart';
import 'live_room_audience_widget.dart';

class TUILiveRoomAudienceOverlay extends StatefulWidget {
  final String roomId;

  const TUILiveRoomAudienceOverlay({super.key, required this.roomId});

  @override
  State<StatefulWidget> createState() {
    return TUILiveRoomAudienceOverlayState();
  }
}

class TUILiveRoomAudienceOverlayState extends State<TUILiveRoomAudienceOverlay> {
  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveKitLogger.info("TUILiveRoomAudienceOverlay initState");
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
        makeToast(msg: LiveKitLocalizations.of(Global.appContext())!.livelist_exit_float_window_tip);
        if (mounted) Navigator.pop(context);
        return;
      }
      final overlayEntry = OverlayEntry(builder: (context) => buildOverlayContent());
      GlobalFloatWindowManager.instance.setRoomId(widget.roomId);
      GlobalFloatWindowManager.instance.overlayManager.showOverlayEntry(overlayEntry);
      if (mounted) Navigator.pop(context);
    });
  }

  Widget buildOverlayContent() {
    return FloatWindowWidget(builder: (context, controller) {
      switchToFullScreenMode() {controller.onTapSwitchFloatWindowInApp(false);}
      GlobalFloatWindowManager.instance.overlayManager.setSwitchToFullScreenCallback(switchToFullScreenMode);
      return TUILiveRoomAudienceWidget(roomId: widget.roomId, floatWindowController: controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
