import 'dart:math';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_calls_uikit/src/bridge/voip/fcm_data_sync_handler.dart';
import 'package:tencent_calls_uikit/src/common/utils/foreground_service.dart';
import 'package:tencent_calls_uikit/src/state/global_state.dart';
import 'package:tencent_calls_uikit/src/manager/call_page_router.dart';
import 'package:tencent_calls_uikit/src/view/callview/call_view.dart';


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
  final GlobalKey _callViewKey = GlobalKey();
  bool isMultiPerson = false;
  CallPageType? _currentPageType;
  bool _isInitializing = true;

  double get originWidth => widget.callbacks?.getOriginScreenSize?.call().width ?? 0;
  double get originHeight => widget.callbacks?.getOriginScreenSize?.call().height ?? 0;

  @override
  void initState() {
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
    final view = View.of(context);
    final realScreenSize = view.physicalSize / view.devicePixelRatio;
    final mediaSize = MediaQuery.of(context).size;
    final bestWidth = max(mediaSize.width, realScreenSize.width);
    final bestHeight = max(mediaSize.height, realScreenSize.height);
    widget.callbacks?.setOriginScreenSize?.call(Size(bestWidth, bestHeight));

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
    final scale = originWidth > 0 ? pipWidth / originWidth : 1.0;

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
                  size: Size(originWidth > 0 ? originWidth : pipWidth, originHeight > 0 ? originHeight : pipHeight)
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
                      enableAITranscriber: GlobalState.instance.enableAITranscriber,
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
    
    return SizedBox(
      width: 121,
      height: 181,
      child: Stack(
        children: [
          Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: OverflowBox(
              maxWidth: screenWidth,
              maxHeight: 180 / scale,
              alignment: Alignment.center,
              child: CallView(
                key: _callViewKey,
                isPipMode: true,
                enableAITranscriber: GlobalState.instance.enableAITranscriber,
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
                final screenSize = MediaQuery.of(context).size;
                widget.callbacks?.onFloatDragUpdate?.call(e, screenSize);
              },
            ),
          ),
        ],
      ),
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
        enableAITranscriber: GlobalState.instance.enableAITranscriber,
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