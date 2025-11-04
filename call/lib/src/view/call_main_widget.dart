import 'package:atomic_x/atomicx.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_calls_uikit/src/bridge/voip/fcm_data_sync_handler.dart';
import 'package:tencent_calls_uikit/src/common/utils/foreground_service.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:tencent_calls_uikit/src/view/call_page_manager.dart';

class CallMainWidget extends StatefulWidget {
  final CallPageCallbacks? callbacks;
  final CallPageType? callPageType;
  const CallMainWidget({
    Key? key,
    this.callbacks,
    this.callPageType,
  }) : super(key: key);

  @override
  State<CallMainWidget> createState() => _CallMainWidgetState();
}

class _CallMainWidgetState extends State<CallMainWidget> with WidgetsBindingObserver {
  static double _floatViewTop = 128;
  static double _floatViewRight = 20;

  final GlobalKey _callViewKey = GlobalKey();
  bool isMultiPerson = false;

  @override
  void initState() {
    _floatViewTop = 128;
    _floatViewRight = 20;
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      ForegroundService.start();
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FcmDataSyncHandler().closeNotificationView();
      ForegroundService.start();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.callPageType) {
      case CallPageType.calling:
        return _buildCallingPageWidget();
      case CallPageType.floating:
        return _buildFloatWindowWidget();
      default:
        return _buildCallingPageWidget();
    }
  }

  Widget _buildFloatWindowWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = 120 / screenWidth;
    
    return Stack(
      children: [
        Positioned(
          top: _floatViewTop - 40,
          right: _floatViewRight,
          child: Stack(
            children: [
              SizedBox(
                width: 120,
                height: 180,
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: ClipRect(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: OverflowBox(
                        maxWidth: screenWidth,
                        maxHeight: 180 / scale,
                        alignment: Alignment.center,
                        child: CallView(
                          key: _callViewKey,
                          disableFeatures: const [CallFeature.all],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _openCallingPage();
                  },
                  onPanUpdate: (DragUpdateDetails e) {
                    _refreshViewPosition(e);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallingPageWidget() {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            _buildCallView(),
            _buildFloatingWindowBtnWidget(),
            _buildInviterUserBtnWidget(),
          ],
        ),
      ),
    );
  }

  _buildCallView() {
    return Positioned(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: CallView(
        key: _callViewKey,
      ),
    );
  }

  _buildFloatingWindowBtnWidget() {
    return GlobalState.instance.enableFloatWindow ? Positioned(
      left: 12,
      top: 52,
      width: 40,
      height: 40,
      child: InkWell(
          onTap: () => _openFloatWindow(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: 20,
              height: 20,
              child:
              Image.asset(
                'assets/images/floating_button.png',
                package: 'tencent_calls_uikit',
              ),
            ),
          )),
    ) : const SizedBox();
  }

  _buildInviterUserBtnWidget() {
    return CallListStore.shared.state.activeCall.value.chatGroupId.isNotEmpty
        ? Positioned(
      right: 12,
      top: 52,
      width: 40,
      height: 40,
      child: InkWell(
          onTap: () => _openInviteUser(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                'assets/images/add_user.png',
                package: 'tencent_calls_uikit',
              ),
            ),
          )),
    )
        : const SizedBox();
  }

  _refreshViewPosition(DragUpdateDetails e) {
    _floatViewRight -= e.delta.dx;
    _floatViewTop += e.delta.dy;
    if (_floatViewTop < 100) {
      _floatViewTop = 100;
    }
    if (_floatViewTop > MediaQuery.of(context).size.height - 216) {
      _floatViewTop = MediaQuery.of(context).size.height - 216;
    }
    if (_floatViewRight < 0) {
      _floatViewRight = 0;
    }
    if (_floatViewRight > MediaQuery.of(context).size.width - 110) {
      _floatViewRight = MediaQuery.of(context).size.width - 110;
    }
    setState(() {});
  }

  _openFloatWindow() {
    widget.callbacks?.onShowFloating?.call();
  }

  _openInviteUser() {
    widget.callbacks?.onShowInvitePage?.call();
  }

  _openCallingPage() {
    widget.callbacks?.onShowCalling?.call();
  }
}