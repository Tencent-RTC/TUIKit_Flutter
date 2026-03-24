import 'dart:math';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

/// Like button widget (TikTok-style particle animation)
///
/// Related APIs:
/// - `LikeStore.create(liveID)` - Create the like management instance (positional parameter)
/// - `LikeStore.sendLike(count)` - Send likes (positional parameter, returns `Future`)
/// - `LikeStore.addLikeListener / removeLikeListener` - Like event listeners (`Listener` pattern)
///
/// Features:
/// - Floating circular like button
/// - Play a TikTok-style particle animation when tapped or when likes are received from others (hearts float along a curve, scale and rotate, then fade out)
class LikeButton extends StatefulWidget {
  final String liveID;

  const LikeButton({super.key, required this.liveID});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  // MARK: - Properties

  late final LikeStore _likeStore;
  late final LikeListener _likeListener;
  final Random _random = Random();

  /// List of active heart particles
  final List<_HeartParticle> _particles = [];
  int _particleIdCounter = 0;

  /// Heart color palette (TikTok-style multicolor gradient)
  static const List<Color> _heartColors = [
    Color.fromRGBO(255, 64, 107, 1.0), // Pink
    Color.fromRGBO(255, 102, 102, 1.0), // Coral red
    Color.fromRGBO(242, 77, 153, 1.0), // Rose pink
    Color.fromRGBO(204, 51, 204, 1.0), // Purple
    Color.fromRGBO(102, 153, 255, 1.0), // Blue-violet
    Color.fromRGBO(255, 140, 0, 1.0), // Orange
    Color.fromRGBO(255, 204, 0, 1.0), // Golden yellow
  ];

  /// Button scale animation
  AnimationController? _buttonScaleController;

  @override
  void initState() {
    super.initState();
    _likeStore = LikeStore.create(widget.liveID);
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 1.0,
      upperBound: 1.3,
    );
    _setupBindings();
  }

  @override
  void dispose() {
    _likeStore.removeLikeListener(_likeListener);
    _buttonScaleController?.dispose();
    for (final particle in _particles) {
      particle.controller.dispose();
    }
    _particles.clear();
    super.dispose();
  }

  // MARK: - Setup

  void _setupBindings() {
    // Use `LikeListener` to listen for received like events and play particle animations
    _likeListener = LikeListener(
      onReceiveLikesMessage: (liveID, totalLikesReceived, sender) {
        if (!mounted) return;
        _emitParticles(count: 1);
      },
    );
    _likeStore.addLikeListener(_likeListener);
  }

  // MARK: - Actions

  /// Send a like
  void _likeTapped() {
    _likeStore.sendLike(1);

    // Button scale feedback
    _buttonScaleController?.forward().then((_) {
      _buttonScaleController?.reverse();
    });

    // Play particles for local likes as well
    _emitParticles(count: 1);
  }

  // MARK: - Particle Animation (TikTok-style)

  /// Emit heart particle animations
  void _emitParticles({required int count}) {
    for (int i = 0; i < count; i++) {
      final delay = Duration(milliseconds: (i * 50));
      Future.delayed(delay, () {
        if (!mounted) return;
        _launchSingleHeart();
      });
    }
  }

  /// Launch a single heart particle that floats along a Bézier curve
  void _launchSingleHeart() {
    final particleId = _particleIdCounter++;
    final heartSize = _random.nextDouble() * 16.0 + 20.0; // 20~36
    final color = _heartColors[_random.nextInt(_heartColors.length)];
    final duration = Duration(milliseconds: (2000 + _random.nextInt(1000))); // 2.0~3.0s

    // Start point: directly above the button
    const startX = 25.0; // Button center x (relative to the 50-width container)
    final startY = 5.0 - heartSize / 2; // Above the button

    // End point: float upward by 120~220pt with a random horizontal offset
    final endY = startY - (_random.nextDouble() * 100.0 + 120.0);
    final endX = startX + (_random.nextDouble() * 100.0 - 50.0);

    // Bézier control points (S-shaped floating path)
    final cp1x = startX + (_random.nextDouble() * 80.0 - 40.0);
    final cp1y = startY - (_random.nextDouble() * 40.0 + 40.0);
    final cp2x = endX + (_random.nextDouble() * 60.0 - 30.0);
    final cp2y = endY + (_random.nextDouble() * 40.0 + 20.0);

    // Rotation angle
    final maxAngle = _random.nextDouble() * 0.3 + 0.2;

    final controller = AnimationController(vsync: this, duration: duration);

    final particle = _HeartParticle(
      id: particleId,
      controller: controller,
      heartSize: heartSize,
      color: color,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      cp1x: cp1x,
      cp1y: cp1y,
      cp2x: cp2x,
      cp2y: cp2y,
      maxAngle: maxAngle,
    );

    setState(() {
      _particles.add(particle);
    });

    controller.forward().then((_) {
      if (!mounted) return;
      controller.dispose();
      setState(() {
        _particles.removeWhere((p) => p.id == particleId);
      });
    });
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ClipRect(
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Heart particles
            ..._particles.map((particle) {
              return AnimatedBuilder(
                animation: particle.controller,
                builder: (context, child) {
                  final t = particle.controller.value;

                  // Bézier curve position
                  final x = _cubicBezier(t, particle.startX, particle.cp1x, particle.cp2x, particle.endX);
                  final y = _cubicBezier(t, particle.startY, particle.cp1y, particle.cp2y, particle.endY);

                  // Rotation (slight sway)
                  double rotation;
                  if (t < 0.25) {
                    rotation = particle.maxAngle * (t / 0.25);
                  } else if (t < 0.5) {
                    rotation = particle.maxAngle * (1.0 - (t - 0.25) / 0.25) * -1;
                  } else if (t < 0.75) {
                    rotation = -particle.maxAngle * 0.5 * (1.0 - (t - 0.5) / 0.25);
                  } else {
                    rotation = 0;
                  }

                  // Scale: pop in from 0~0.07, shrink from 0.4~1.0
                  double scale;
                  if (t < 0.07) {
                    scale = 0.2 + 0.8 * (t / 0.07);
                  } else if (t < 0.4) {
                    scale = 1.0;
                  } else {
                    scale = 1.0 - 0.7 * ((t - 0.4) / 0.6);
                  }

                  // Opacity: fade out from 0.4~1.0
                  final opacity = t < 0.4 ? 1.0 : (1.0 - (t - 0.4) / 0.6).clamp(0.0, 1.0);

                  return Positioned(
                    left: x - particle.heartSize / 2,
                    top: y - particle.heartSize / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: scale,
                          child: Icon(Icons.favorite, size: particle.heartSize, color: particle.color),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            // Like button
            Center(
              child: ScaleTransition(
                scale: _buttonScaleController!,
                child: GestureDetector(
                  onTap: _likeTapped,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite, size: 20, color: Colors.pink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Helpers

  /// Cubic Bézier curve calculation
  double _cubicBezier(double t, double p0, double p1, double p2, double p3) {
    final mt = 1.0 - t;
    return mt * mt * mt * p0 + 3 * mt * mt * t * p1 + 3 * mt * t * t * p2 + t * t * t * p3;
  }
}

// MARK: - HeartParticle

/// Heart particle data
class _HeartParticle {
  final int id;
  final AnimationController controller;
  final double heartSize;
  final Color color;
  final double startX, startY;
  final double endX, endY;
  final double cp1x, cp1y;
  final double cp2x, cp2y;
  final double maxAngle;

  _HeartParticle({
    required this.id,
    required this.controller,
    required this.heartSize,
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.cp1x,
    required this.cp1y,
    required this.cp2x,
    required this.cp2y,
    required this.maxAngle,
  });
}
