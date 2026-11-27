import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/live_toast_view.dart';
import 'pusher_cohost_store.dart';

class PusherCoHostRandomConnectionView extends StatefulWidget {
  const PusherCoHostRandomConnectionView(
      {super.key, required this.hostAvatarURL, required this.candidates, this.presentationEnabled = true});
  final String hostAvatarURL;
  final List<PusherCoHostUser> candidates;
  final bool presentationEnabled;
  @override
  State<PusherCoHostRandomConnectionView> createState() => _RandomConnectionState();
}

class _RandomConnectionState extends State<PusherCoHostRandomConnectionView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  final _positions = <Offset>[];
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    _randomize();
  }

  void _randomize() {
    final random = math.Random();
    const sizes = [18.0, 16.0, 15.0, 16.0, 17.0];
    for (int attempt = 0; attempt < 8; attempt++) {
      final points = <Offset>[];
      for (int i = 0; i < 5; i++) {
        final radius = sizes[i] * 1.08 / 2;
        Offset? point;
        for (int trial = 0; trial < 160; trial++) {
          final candidate = Offset(33 + radius + 6 + random.nextDouble() * (112 - 2 * radius - 10),
              radius + 3 + random.nextDouble() * (84 - 2 * radius - 6));
          final distance = (candidate - const Offset(89, 42)).distance;
          if (distance < 17 + radius + 5 || distance > 54) continue;
          if (List.generate(points.length, (j) => (candidate - points[j]).distance < radius + sizes[j] * 1.08 / 2 + 6)
              .any((overlaps) => overlaps)) {
            continue;
          }
          point = candidate;
          break;
        }
        if (point == null) break;
        points.add(point);
      }
      if (points.length == 5) {
        _positions
          ..clear()
          ..addAll(points);
        return;
      }
    }
    _positions
      ..clear()
      ..addAll(const [Offset(51, 17), Offset(129, 45), Offset(56, 72), Offset(104, 12), Offset(105, 74)]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant PusherCoHostRandomConnectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.presentationEnabled && widget.presentationEnabled) _randomize();
    _updateAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateAnimation();
  }

  void _updateAnimation() {
    final enabled =
        widget.presentationEnabled && _foreground && TickerMode.of(context) && !MediaQuery.disableAnimationsOf(context);
    if (enabled) {
      if (!_scan.isAnimating) _scan.repeat();
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _scan.stop();
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scan.dispose();
    _pulse.dispose();
    _toast.dispose();
    super.dispose();
  }

  final _toast = LiveToastController();
  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final peers = widget.candidates.where((u) => seen.add(u.userID)).take(5).toList();
    return ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Container(
            height: 142,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0x17FFFFFF)),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xEB121E32), Color(0xF00B0C14)])),
            child: LayoutBuilder(builder: (context, constraints) {
              final radarLeft = math.max(96.0, constraints.maxWidth - 184);
              return Stack(children: [
                const Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: RadialGradient(
                                center: Alignment(-.4, .1),
                                radius: .8,
                                colors: [Color(0x3D4A9EFF), Color(0x004A9EFF)])))),
                Positioned(
                    left: 17,
                    top: 19,
                    width: math.max(0, radarLeft + 8),
                    height: 22,
                    child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)))),
                Positioned(
                    left: 17,
                    top: 48,
                    width: math.max(0, radarLeft + 8),
                    height: 17,
                    child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Color(0xFFFFFFFF)))),
                Positioned(
                    left: radarLeft,
                    top: 2,
                    width: 132,
                    height: 84,
                    child: IgnorePointer(
                        child: AnimatedBuilder(
                            animation: Listenable.merge([_scan, _pulse]),
                            builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
                                  Positioned(
                                      left: 33,
                                      top: -14,
                                      width: 112,
                                      height: 112,
                                      child: Transform.rotate(
                                          angle: _scan.value * math.pi * 2,
                                          child: Stack(clipBehavior: Clip.none, children: [
                                            Positioned(
                                                left: -12,
                                                top: -18,
                                                width: 136,
                                                height: 142,
                                                child: ClipPath(
                                                    clipper: _RadarSweepClipper(),
                                                    child: Image(
                                                        image: LiveKitResources.image('livekit_cohost_radar_sweep'))))
                                          ]))),
                                  for (int i = 0; i < 2; i++) _pulseRing(i),
                                  for (int i = 0; i < 5; i++) _peer(i, i < peers.length ? peers[i].avatarURL : ''),
                                  Positioned(
                                      left: 72,
                                      top: 25,
                                      width: 34,
                                      height: 34,
                                      child: DecoratedBox(
                                          decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
                                            BoxShadow(color: Color(0x664A9EFF), blurRadius: 14),
                                            BoxShadow(color: Color(0x40000000), offset: Offset(0, 7), blurRadius: 18)
                                          ]),
                                          child: ClipOval(child: LiveAvatarImage(avatarURL: widget.hostAvatarURL)))),
                                ])))),
                Positioned(
                    left: 17,
                    right: 17,
                    top: 87,
                    height: 40,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _toast.show(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_developing')),
                        child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: const Color(0x6661AAFF)),
                                gradient: const LinearGradient(colors: [Color(0xFF0348B8), Color(0xFF3A76BD)])),
                            child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_button'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)))))),
                Positioned.fill(child: LiveToastView(controller: _toast)),
              ]);
            })));
  }

  Widget _peer(int index, String url) {
    final position = _positions[index];
    final size = const [18.0, 16.0, 15.0, 16.0, 17.0][index];
    final angle = ((math.atan2(position.dy - 42, position.dx - 89) + math.pi / 2) / (math.pi * 2) + 1) % 1;
    final elapsed = (_scan.lastElapsedDuration?.inMicroseconds ?? 0) / 4800000;
    final rawTime = elapsed - angle;
    final phase = rawTime % 1;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final opacity = reducedMotion
        ? .8
        : rawTime < 0
            ? 0.0
            : _sample(phase, const [0, 1, .92, .92, 0, 0]);
    final scale = reducedMotion ? 1.0 : _sample(phase, const [.72, 1.08, 1, 1, .96, .96]);
    return Positioned(
        left: position.dx - size / 2,
        top: position.dy - size / 2,
        width: size,
        height: size,
        child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x475B90E7),
                        boxShadow: [BoxShadow(color: Color(0x664A9EFF), blurRadius: 10)]),
                    child: ClipOval(
                        child: ColorFiltered(
                            colorFilter: reducedMotion
                                ? _identityColor
                                : _peerColors[phase < .04
                                    ? 0
                                    : phase < .08
                                        ? 1
                                        : phase < .42
                                            ? 2
                                            : 3],
                            child: LiveAvatarImage(avatarURL: url)))))));
  }

  Widget _pulseRing(int index) {
    final time = (_pulse.lastElapsedDuration?.inMicroseconds ?? 0) / 2800000 - index * .5;
    final phase = time % 1;
    final t = Curves.easeOut.transform((phase / .76).clamp(0.0, 1.0));
    return Positioned(
        left: 72,
        top: 25,
        width: 34,
        height: 34,
        child: Transform.scale(
            scale: .95 + .95 * t,
            child: Opacity(
                opacity: time < 0 ? 0 : .68 * (1 - t),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Color.lerp(const Color(0xD1FFFFFF), const Color(0x147EE8FF), t)!))))));
  }

  // Five small avatar layers use GPU color filters instead of UIKit's cached image variants.
  static const _identityColor = ColorFilter.matrix([1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
  static final _peerColors = [(0.55, 0.8), (1.0, 1.2), (1.0, 1.08), (0.65, 0.85)].map((variant) {
    final saturation = variant.$1, brightness = variant.$2;
    final r = (1 - saturation) * .213, g = (1 - saturation) * .715, b = (1 - saturation) * .072;
    return ColorFilter.matrix([
      (r + saturation) * brightness,
      g * brightness,
      b * brightness,
      0,
      0,
      r * brightness,
      (g + saturation) * brightness,
      b * brightness,
      0,
      0,
      r * brightness,
      g * brightness,
      (b + saturation) * brightness,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ]);
  }).toList(growable: false);

  double _sample(double phase, List<double> values) {
    const times = [0.0, .04, .08, .22, .42, 1.0];
    for (int i = 0; i < times.length - 1; i++) {
      if (phase <= times[i + 1]) {
        final t = Curves.easeOut.transform(((phase - times[i]) / (times[i + 1] - times[i])).clamp(0.0, 1.0));
        return values[i] + (values[i + 1] - values[i]) * t;
      }
    }
    return values.last;
  }
}

class _RadarSweepClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size),
      Path()..addOval(const Rect.fromLTWH(47.5, 53.5, 41, 41)));
  @override
  bool shouldReclip(_RadarSweepClipper oldClipper) => false;
}
