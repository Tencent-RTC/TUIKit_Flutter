import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_widget.dart';

import '../../component/float_window/index.dart';
import '../../tencent_live_uikit.dart';

class TUILiveRoomAnchorOverlay extends StatefulWidget {
  final String roomId;
  final bool needPrepare;
  final LiveInfo? liveInfo;
  final VoidCallback? onStartLive;

  const TUILiveRoomAnchorOverlay(
      {super.key, required this.roomId, this.needPrepare = true, this.liveInfo, this.onStartLive});

  @override
  State<StatefulWidget> createState() {
    return TUILiveRoomAnchorOverlayState();
  }
}

class TUILiveRoomAnchorOverlayState extends State<TUILiveRoomAnchorOverlay> {
  @override
  void initState() {
    super.initState();
    LiveKitLogger.info('LiveKit Version: ${Constants.pluginVersion}');
    LiveKitLogger.info("TUILiveRoomAnchorOverlay initState");
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
      GlobalFloatWindowManager.instance.setOwnerId(TUIRoomEngine.getSelfInfo().userId);
      GlobalFloatWindowManager.instance.overlayManager.showOverlayEntry(overlayEntry);
      if (mounted) Navigator.pop(context);
    });
  }

  Widget buildOverlayContent() {
    return FloatWindowWidget(builder: (context, controller) {
      switchToFullScreenMode() {
        controller.onTapSwitchFloatWindowInApp(false);
      }

      GlobalFloatWindowManager.instance.overlayManager.setSwitchToFullScreenCallback(switchToFullScreenMode);
      return TUILiveRoomAnchorWidget(
          roomId: widget.roomId,
          needPrepare: widget.needPrepare,
          liveInfo: widget.liveInfo,
          onStartLive: widget.onStartLive,
          floatWindowController: controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
