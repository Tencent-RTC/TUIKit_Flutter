import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';
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
    GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      return Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => TUILiveRoomAnchorWidget(
                roomId: widget.roomId,
                needPrepare: widget.needPrepare,
                liveInfo: widget.liveInfo,
                onStartLive: widget.onStartLive,
                floatWindowController: controller),
            settings: settings,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
