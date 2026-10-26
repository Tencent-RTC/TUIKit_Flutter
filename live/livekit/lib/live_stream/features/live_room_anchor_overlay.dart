import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/float_window/float_window_widget.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final overlayEntry = OverlayEntry(builder: (context) => buildOverlayContent());
      GlobalFloatWindowManager.instance.setRoomId(widget.roomId);
      GlobalFloatWindowManager.instance.setOwnerId(LoginStore.shared.loginState.loginUserInfo?.userID ?? '');
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
