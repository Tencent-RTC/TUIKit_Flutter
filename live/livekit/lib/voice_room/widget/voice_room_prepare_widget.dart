import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';

import '../../common/index.dart';
import '../../component/float_window/global_float_window_manager.dart';
import '../index.dart';

class VoiceRoomPrepareWidget extends StatefulWidget {
  final void Function()? didClickStart;
  final VoiceRoomPrepareStore prepareStore;
  final ToastService toastService;

  const VoiceRoomPrepareWidget({super.key, required this.prepareStore, required this.toastService, this.didClickStart});

  @override
  State<VoiceRoomPrepareWidget> createState() => _VoiceRoomPrepareWidgetState();
}

class _VoiceRoomPrepareWidgetState extends State<VoiceRoomPrepareWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SizedBox(
        width: 1.screenWidth,
        child: Stack(
          children: [
            _initBackgroundWidget(),
            _initLiveInfoEditWidget(),
            _initSeatPreviewWidget(),
            _initFunctionWidget(),
            _initBackWidget(),
            _initStartLiveWidget(),
          ],
        ),
      ),
    );
  }

  Widget _initBackgroundWidget() {
    return SizedBox(
      width: 1.screenWidth,
      height: 1.screenHeight,
      child: ValueListenableBuilder(
          valueListenable: ValueSelector(widget.prepareStore.state.liveInfo, (liveInfo) => liveInfo.backgroundURL),
          builder: (context, backgroundURL, _) {
            final defaultImage =
                Image.asset(LiveImages.defaultBackground, fit: BoxFit.cover, package: Constants.pluginName);
            return CachedNetworkImage(
              imageUrl: backgroundURL,
              fit: BoxFit.cover,
              placeholder: (context, url) => defaultImage,
              errorWidget: (context, url, error) => defaultImage,
            );
          }),
    );
  }

  Widget _initLiveInfoEditWidget() {
    return Positioned(
        top: 96.height,
        left: 16.width,
        right: 16.width,
        height: 112.height,
        child: LivePrepareInfoEditWidget(prepareStore: widget.prepareStore));
  }

  Widget _initSeatPreviewWidget() {
    return Positioned(top: 212.height, left: 0, bottom: 0, right: 0, child: const SeatPreviewWidget());
  }

  Widget _initFunctionWidget() {
    return Positioned(
        left: 0,
        bottom: 134.height,
        width: 375.width,
        height: 62.height,
        child: LivePrepareFunctionWidget(prepareStore: widget.prepareStore));
  }

  Widget _initBackWidget() {
    return Positioned(
        left: 16.width,
        top: 56.height,
        width: 24.radius,
        height: 24.radius,
        child: GestureDetector(
            onTap: () {
              _closeWidget();
            },
            child: Image.asset(LiveImages.returnArrow, package: Constants.pluginName)));
  }

  Widget _initStartLiveWidget() {
    return Positioned(
      left: 50.width,
      right: 50.width,
      bottom: 64.height,
      height: 40.height,
      child: GestureDetector(
        onTap: () {
          _createRoom();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.height),
            color: LiveColors.designStandardB1,
          ),
          child: Text(
            LiveKitLocalizations.of(Global.appContext())!.common_start_live,
            style: const TextStyle(
                color: LiveColors.designStandardFlowkitWhite, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

extension on _VoiceRoomPrepareWidgetState {
  void _createRoom() {
    widget.didClickStart?.call();
  }

  void _closeWidget() {
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      Navigator.of(context).pop();
    }
  }
}
