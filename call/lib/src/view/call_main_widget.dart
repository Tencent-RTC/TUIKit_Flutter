import 'dart:math';

import 'package:tuikit_atomic_x/atomicx.dart';
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
  double originWidth = 0;
  double originHeight = 0;
  bool isMultiPerson = false;
  CallPageType? _currentPageType;
  bool _isInitializing = true;

  @override
  void initState() {
    _floatViewTop = 128;
    _floatViewRight = 20;
    _currentPageType = widget.callPageType;
    _isInitializing = true;
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      ForegroundService.start();
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(CallMainWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.callPageType != widget.callPageType) {
      _currentPageType = widget.callPageType;
      _isInitializing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      });
    }
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
    originWidth = max(MediaQuery.of(context).size.width, originWidth);
    originHeight = max(MediaQuery.of(context).size.height, originHeight);
    final pageType = _currentPageType ?? widget.callPageType;
    
    switch (pageType) {
      case CallPageType.calling:
        return _buildCallingPageWidget();
      case CallPageType.floating:
        return _buildFloatWindowWidget();
      case CallPageType.pip:
        return _buildPipWindowWidget();
      default:
        return _buildCallingPageWidget();
    }
  }


  _buildPipWindowWidget() {
    final pipWidth = MediaQuery.of(context).size.width;
    final pipHeight = MediaQuery.of(context).size.height;
    final scale = pipWidth / originWidth;

    return Scaffold(
      body: SizedBox(
        width: pipWidth,
        height: pipHeight,
        child: Container(
          width: pipWidth,
          height: pipHeight,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  size: Size(originWidth ?? pipWidth, originHeight ?? pipHeight)
              ),
              child: ClipRect(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: OverflowBox(
                    maxWidth: originWidth,
                    maxHeight: originHeight,
                    alignment: Alignment.center,
                    child: CallView(
                      key: _callViewKey,
                      isPipMode: true,
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
    );
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
              Container(
                width: 120 + 1,
                height: 180 + 1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: OverflowBox(
                          maxWidth: screenWidth,
                          maxHeight: 180 / scale,
                          alignment: Alignment.center,
                          child: CallView(
                            key: _callViewKey,
                            isPipMode: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _openCallingPage();
                    });
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
    return CallStore.shared.state.activeCall.value.chatGroupId.isNotEmpty
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
    if (_isInitializing) {
      return;
    }
    widget.callbacks?.onShowCalling?.call();
  }
}