import 'dart:math' as math;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../common/live_avatar_image.dart';
import '../../common/live_kit_resources.dart';

class PreviewView extends StatefulWidget {
  const PreviewView({
    super.key,
    required this.liveInfo,
    this.onTapEnter,
  });

  final LiveInfo liveInfo;
  final VoidCallback? onTapEnter;

  @override
  State<PreviewView> createState() => PreviewViewState();
}

class PreviewViewState extends State<PreviewView> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _EntranceBarsPainter.cycleDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PreviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveInfo.liveID != widget.liveInfo.liveID && !_enabled) {
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_enabled) return;
    setState(() => _enabled = false);
    widget.onTapEnter?.call();
  }

  @override
  Widget build(BuildContext context) {
    final LiveInfo liveInfo = widget.liveInfo;
    if (liveInfo.liveID.isEmpty) return const SizedBox.shrink();
    final String roomName = liveInfo.liveName.isEmpty ? liveInfo.liveID : liveInfo.liveName;
    final String hostName =
        liveInfo.liveOwner.userName.isEmpty ? liveInfo.liveOwner.userID : liveInfo.liveOwner.userName;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomInset + 234,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _enabled ? _handleTap : null,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 0.3,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (BuildContext context, Widget? child) {
                          return CustomPaint(
                            painter: _EntranceBarsPainter(
                              _animationController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LiveKitResources.localizedString(
                        'tuilivekit.player.enter_room_hint',
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: bottomInset + 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: ClipOval(
                      child: LiveAvatarImage(
                        avatarURL: liveInfo.liveOwner.avatarURL,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

/// 对应 iOS `EntranceAnimationView`：三根竖条按 1 秒往返、2 秒一个周期起伏。
class _EntranceBarsPainter extends CustomPainter {
  const _EntranceBarsPainter(this.value);

  final double value;

  static const Duration cycleDuration = Duration(seconds: 2);
  static const int barCount = 3;
  static const double barWidth = 2;
  static const double barSpacing = 3;
  static const double barBaseHeight = 4;
  static const double barAmplitude = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white;
    final double raw = value * 2;
    final double progress = raw <= 1 ? raw : 2 - raw;
    const double totalWidth = barWidth * barCount + barSpacing * (barCount - 1);
    final double startX = (size.width - totalWidth) / 2;
    for (int index = 0; index < barCount; index++) {
      final double adjusted = (progress + index * 0.6) % 1.0;
      final double wave = math.sin(adjusted * math.pi).abs();
      final double height = barBaseHeight + wave * barAmplitude;
      final double x = startX + index * (barWidth + barSpacing);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EntranceBarsPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
