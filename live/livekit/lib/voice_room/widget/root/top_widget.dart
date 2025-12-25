import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/component/index.dart';

enum TopWidgetTapEvent { stop, audienceList, liveInfo, floatWindow }

class TopWidget extends StatefulWidget {
  final String liveID;
  final bool isOwner;
  final void Function(TopWidgetTapEvent event)? onTapTopWidget;

  const TopWidget({super.key, required this.liveID, required this.isOwner, this.onTapTopWidget});

  @override
  State<TopWidget> createState() => _TopWidgetState();
}

class _TopWidgetState extends State<TopWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _initLiveInfoWidget(),
      _initAudienceListWidget(),
      _initFloatWindowButton(),
      _initLeaveButton(),
    ]);
  }

  Widget _initLiveInfoWidget() {
    return GestureDetector(
      onTap: () {
        widget.onTapTopWidget?.call(TopWidgetTapEvent.liveInfo);
      },
      child: Container(
          constraints: BoxConstraints(maxHeight: 40.height, maxWidth: 200.width),
          height: 40.height,
          child: LiveInfoWidget(roomId: widget.liveID)),
    );
  }

  Widget _initAudienceListWidget() {
    return Positioned(
        top: 8.height,
        bottom: 8.height,
        right: GlobalFloatWindowManager.instance.isEnableFloatWindowFeature() ? 60.width : 30.width,
        child: GestureDetector(
          onTap: () {
            widget.onTapTopWidget?.call(TopWidgetTapEvent.audienceList);
          },
          child: Container(
              constraints: BoxConstraints(maxWidth: 107.width), child: AudienceListWidget(roomId: widget.liveID)),
        ));
  }

  Widget _initFloatWindowButton() {
    if (!GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      return const SizedBox.shrink();
    }
    return Positioned(
        top: 8.height,
        bottom: 8.height,
        right: 30.width,
        child: SizedBox(
            width: 20.radius,
            height: 20.radius,
            child: GestureDetector(
              onTap: () => widget.onTapTopWidget?.call(TopWidgetTapEvent.floatWindow),
              child: Image.asset(
                LiveImages.floatWindow,
                package: Constants.pluginName,
                fit: BoxFit.contain,
              ),
            )));
  }

  Widget _initLeaveButton() {
    return Positioned(
        top: 10.height,
        bottom: 10.height,
        right: 0,
        child: SizedBox(
            width: 20.radius,
            height: 20.radius,
            child: GestureDetector(
              onTap: () => widget.onTapTopWidget?.call(TopWidgetTapEvent.stop),
              child: Image.asset(
                widget.isOwner ? LiveImages.close : LiveImages.audienceClose,
                package: Constants.pluginName,
              ),
            )));
  }
}
