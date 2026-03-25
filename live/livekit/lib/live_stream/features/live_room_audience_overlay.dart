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
    GlobalFloatWindowManager.instance.enableFloatWindowFeature(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      switchToFullScreenMode() {
        controller.onTapSwitchFloatWindowInApp(false);
      }

      GlobalFloatWindowManager.instance.overlayManager.setSwitchToFullScreenCallback(switchToFullScreenMode);
      return Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => TUILiveRoomAudienceWidget(roomId: widget.roomId, floatWindowController: controller),
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
