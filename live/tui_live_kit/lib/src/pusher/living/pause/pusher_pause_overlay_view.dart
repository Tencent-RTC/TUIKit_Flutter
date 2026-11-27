/// 暂停遮罩：暂停提示、计时与"继续直播"。
library;

import 'package:flutter/widgets.dart';
import '../../../common/live_kit_resources.dart';

class PusherPauseOverlayView extends StatelessWidget {
  const PusherPauseOverlayView({super.key, required this.seconds, this.onResume});

  final int seconds;

  final VoidCallback? onResume;

  /// UIColor.black.withAlphaComponent(0.9)
  static const Color _backgroundColor = Color(0xE6000000);

  /// UIColor(white: 0.067, alpha: 1)
  static const Color _resumeTitleColor = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final String timerText =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

    return ColoredBox(
      color: _backgroundColor,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: constraints.maxHeight * 273 / 844,
                height: 87,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 29,
                      child: Text(
                        LiveKitResources.localizedString('tuilivekit.pusher.living.paused'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 21,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 50,
                      height: 37,
                      child: Text(
                        timerText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: padding.bottom + 42,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onResume,
                    child: Container(
                      width: 205,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const <BoxShadow>[
                          // opacity 0.28, offset (0, 8), radius 28
                          BoxShadow(
                            color: Color(0x47000000),
                            offset: Offset(0, 8),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          LiveKitResources.localizedString('tuilivekit.pusher.living.resume'),
                          style: const TextStyle(
                            color: _resumeTitleColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
