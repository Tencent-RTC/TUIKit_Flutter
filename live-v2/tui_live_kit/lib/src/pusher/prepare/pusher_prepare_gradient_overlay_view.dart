/// 开播准备预览的顶部与底部渐变遮罩，倒计时期间隐藏。
library;

import 'package:flutter/widgets.dart';

import '../video/pusher_video_view.dart';

class PusherPrepareGradientOverlayView extends StatelessWidget {
  const PusherPrepareGradientOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bottomInset = PusherVideoView.bottomInsetOf(context);
          final double stageHeight =
              (constraints.maxHeight - bottomInset) < 0 ? 0 : constraints.maxHeight - bottomInset;

          return Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: stageHeight * 337 / 732,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        _PusherPrepareGradientStyle.topStart,
                        _PusherPrepareGradientStyle.topMiddle,
                        Color(0x00000000),
                      ],
                      stops: <double>[0, 0.4, 1],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: stageHeight * 425 / 732,
                height: stageHeight * 307 / 732,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x00000000),
                        _PusherPrepareGradientStyle.bottomMiddle,
                        _PusherPrepareGradientStyle.bottomEnd,
                      ],
                      stops: <double>[0, 0.62, 1],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

abstract final class _PusherPrepareGradientStyle {
  static const topStart = Color(0x8C000000);
  static const topMiddle = Color(0x47000000);
  static const bottomMiddle = Color(0x52000000);
  static const bottomEnd = Color(0xB3000000);
}
