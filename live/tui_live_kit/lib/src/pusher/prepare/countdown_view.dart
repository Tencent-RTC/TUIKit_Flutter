import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';

import '../video/pusher_video_view.dart';

class CountdownView extends StatefulWidget {
  const CountdownView({super.key, required this.number, this.onCancel});

  /// 当前倒计时数字。
  final int number;

  final VoidCallback? onCancel;

  @override
  State<CountdownView> createState() => _CountdownViewState();
}

class _CountdownViewState extends State<CountdownView> with SingleTickerProviderStateMixin {
  /// UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
  static const Color _darkBarColor = Color(0xFF0A0A0F);

  /// UIColor.white.withAlphaComponent(0.16)
  static const Color _circleColor = Color(0x29FFFFFF);

  /// UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 0.86)
  static const Color _cancelBackgroundColor = Color(0xDB26262B);

  /// UIColor.white.withAlphaComponent(0.92)
  static const Color _cancelTitleColor = Color(0xEBFFFFFF);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 62),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.6, end: 1).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 62),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0.85).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(CountdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double bottomInset = PusherVideoView.bottomInsetOf(context);

    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomInset,
          child: const IgnorePointer(
            child: ColoredBox(color: _darkBarColor, child: SizedBox.expand()),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, -bottomInset / 2),
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: _circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (BuildContext context, Widget? child) {
                      return Opacity(
                        opacity: _opacity.value,
                        child: Transform.scale(scale: _scale.value, child: child),
                      );
                    },
                    child: SizedBox(
                      width: 150,
                      height: 140,
                      child: Center(
                        child: Text(
                          '${widget.number}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 96,
                            fontWeight: FontWeight.w300,
                            shadows: <Shadow>[
                              Shadow(
                                color: Color(0x80000000),
                                offset: Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: padding.bottom + 8,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onCancel?.call(),
              child: Container(
                width: 200,
                height: 50,
                decoration: const BoxDecoration(
                  color: _cancelBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Center(
                  child: Text(
                    LiveKitResources.localizedString('tuilivekit.common.cancel'),
                    style: const TextStyle(
                      color: _cancelTitleColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
