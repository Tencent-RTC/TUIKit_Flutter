library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../live_kit_resources.dart';

class LikeAnimationController extends ChangeNotifier {
  static const double mainSize = 52;
  static const Duration mainDuration = Duration(milliseconds: 660);
  static const double auxiliarySize = 24;
  static const int maximumAuxiliaryCount = 14;
  static const double buttonSize = 36;
  static const int maximumButtonCount = 14;
  static const List<String> reactionAssetNames = <String>[
    'livekit_like_thumb',
    'livekit_like_thumb',
    'livekit_like_heart',
    'livekit_like_heart',
    'livekit_like_double_heart',
    'livekit_like_fire',
    'livekit_like_sparkle',
  ];

  final List<_LikeEntry> _entries = <_LikeEntry>[];
  final math.Random _random = math.Random();
  int _nextEntryID = 0;
  bool _isDisposed = false;
  final Set<Timer> _pendingTimers = <Timer>{};

  List<_LikeEntry> get _visibleEntries => List<_LikeEntry>.unmodifiable(_entries);

  void showStageLike({required Offset point, required Offset auxiliaryOrigin}) {
    if (_isDisposed) return;
    final String assetName = _randomAssetName();
    _showMainReaction(point: point, assetName: assetName);
    _showAuxiliaryReaction(origin: auxiliaryOrigin, assetName: assetName);
  }

  void showLocalLike({required Offset point, required Offset auxiliaryOrigin}) {
    showStageLike(point: point, auxiliaryOrigin: auxiliaryOrigin);
  }

  void showReceivedLikes({required int count, required Offset auxiliaryOrigin}) {
    if (_isDisposed) return;
    final int animationCount = math.min(6, math.max(1, count));
    for (int index = 0; index < animationCount; index++) {
      late final Timer timer;
      timer = Timer(Duration(milliseconds: index * 120), () {
        _pendingTimers.remove(timer);
        if (_isDisposed) {
          return;
        }
        _showAuxiliaryReaction(origin: auxiliaryOrigin, assetName: _randomAssetName());
      });
      _pendingTimers.add(timer);
    }
  }

  void showButtonLike({required Offset origin}) {
    if (_isDisposed) return;
    _showButtonReaction(origin: origin, assetName: _randomAssetName());
  }

  void removeAllAnimations() {
    if (_isDisposed) return;
    _cancelPendingReactions();
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    notifyListeners();
  }

  void removeEntry(int id) {
    final int index = _entries.indexWhere((_LikeEntry entry) => entry.id == id);
    if (index < 0) {
      return;
    }
    _entries.removeAt(index);
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelPendingReactions();
    _entries.clear();
    super.dispose();
  }

  void _cancelPendingReactions() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
  }

  void _showMainReaction({required Offset point, required String assetName}) {
    _entries.add(
      _LikeEntry.main(id: _nextEntryID++, assetName: assetName, point: point),
    );
    notifyListeners();
  }

  void _showAuxiliaryReaction({required Offset origin, required String assetName}) {
    final Iterable<_LikeEntry> auxiliaries =
        _entries.where((_LikeEntry entry) => entry.kind == _LikeEntryKind.auxiliary);
    if (auxiliaries.length >= maximumAuxiliaryCount) {
      _entries.remove(auxiliaries.first);
    }
    _entries.add(
      _LikeEntry.auxiliary(
        id: _nextEntryID++,
        assetName: assetName,
        origin: origin.translate(_randomBetween(-8, 8), 0),
        rise: _randomBetween(120, 140),
        offsets: <double>[
          -_randomBetween(4, 6),
          -_randomBetween(1, 3),
          -_randomBetween(5, 7),
          -_randomBetween(3, 5),
        ],
        duration: Duration(milliseconds: _randomBetween(1800, 2050).round()),
      ),
    );
    notifyListeners();
  }

  void _showButtonReaction({required Offset origin, required String assetName}) {
    final Iterable<_LikeEntry> buttons = _entries.where((_LikeEntry entry) => entry.kind == _LikeEntryKind.button);
    if (buttons.length >= maximumButtonCount) {
      _entries.remove(buttons.first);
    }
    _entries.add(
      _LikeEntry.button(
        id: _nextEntryID++,
        assetName: assetName,
        origin: origin.translate(_randomBetween(-5, 5), 0),
        rise: _randomBetween(120, 150),
        offsets: <double>[
          -_randomBetween(4, 6),
          -_randomBetween(1, 3),
          -_randomBetween(5, 7),
          -_randomBetween(3, 5),
        ],
        duration: Duration(milliseconds: _randomBetween(1500, 1700).round()),
      ),
    );
    notifyListeners();
  }

  String _randomAssetName() {
    return reactionAssetNames[_random.nextInt(reactionAssetNames.length)];
  }

  double _randomBetween(double lower, double upper) {
    return lower + _random.nextDouble() * (upper - lower);
  }
}

enum _LikeEntryKind { main, auxiliary, button }

class _LikeEntry {
  _LikeEntry.main({required this.id, required this.assetName, required Offset point})
      : kind = _LikeEntryKind.main,
        position = point,
        rise = 0,
        offsets = const <double>[],
        duration = LikeAnimationController.mainDuration;

  _LikeEntry.auxiliary({
    required this.id,
    required this.assetName,
    required Offset origin,
    required this.rise,
    required this.offsets,
    required this.duration,
  })  : kind = _LikeEntryKind.auxiliary,
        position = origin;

  _LikeEntry.button({
    required this.id,
    required this.assetName,
    required Offset origin,
    required this.rise,
    required this.offsets,
    required this.duration,
  })  : kind = _LikeEntryKind.button,
        position = origin;

  final int id;
  final _LikeEntryKind kind;
  final String assetName;
  final Offset position;
  final double rise;
  final List<double> offsets;
  final Duration duration;
}

class LikeAnimationView extends StatefulWidget {
  const LikeAnimationView({
    super.key,
    required this.controller,
    this.liveID,
    this.receivedLikeCounts,
    this.auxiliaryOriginProvider,
  });

  final LikeAnimationController controller;
  final String? liveID;
  final Stream<int>? receivedLikeCounts;
  final Offset? Function()? auxiliaryOriginProvider;

  @override
  State<LikeAnimationView> createState() => _LikeAnimationViewState();
}

class _LikeAnimationViewState extends State<LikeAnimationView> {
  LikeStore? _likeStore;
  LikeListener? _likeListener;
  StreamSubscription<int>? _countsSubscription;
  int _listenerGeneration = 0;
  int _streamGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bindListener();
    _bindStream();
  }

  @override
  void didUpdateWidget(covariant LikeAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeAllAnimations();
    }
    if (oldWidget.liveID != widget.liveID) {
      widget.controller.removeAllAnimations();
      _unbindListener();
      _bindListener();
    }
    if (oldWidget.receivedLikeCounts != widget.receivedLikeCounts) {
      widget.controller.removeAllAnimations();
      _streamGeneration++;
      _countsSubscription?.cancel();
      _countsSubscription = null;
      _bindStream();
    }
  }

  @override
  void dispose() {
    _unbindListener();
    _streamGeneration++;
    _countsSubscription?.cancel();
    _countsSubscription = null;
    widget.controller.removeAllAnimations();
    super.dispose();
  }

  void _bindListener() {
    final String? liveID = widget.liveID;
    if (liveID == null || liveID.isEmpty) {
      return;
    }
    final generation = ++_listenerGeneration;
    final LikeStore store = LikeStore.create(liveID);
    final LikeListener listener = LikeListener(
      onReceiveLikesMessage: (String eventLiveID, int totalLikesReceived, LiveUserInfo sender) {
        if (!mounted || generation != _listenerGeneration || eventLiveID != widget.liveID) {
          return;
        }
        _dispatchReceived(totalLikesReceived);
      },
    );
    store.addLikeListener(listener);
    _likeStore = store;
    _likeListener = listener;
  }

  void _unbindListener() {
    _listenerGeneration++;
    final LikeStore? store = _likeStore;
    final LikeListener? listener = _likeListener;
    if (store != null && listener != null) {
      store.removeLikeListener(listener);
    }
    _likeStore = null;
    _likeListener = null;
  }

  void _bindStream() {
    final generation = ++_streamGeneration;
    _countsSubscription = widget.receivedLikeCounts?.listen((count) {
      if (generation == _streamGeneration) _dispatchReceived(count);
    });
  }

  void _dispatchReceived(int count) {
    if (!mounted || count <= 0) {
      return;
    }
    final Offset? origin = widget.auxiliaryOriginProvider?.call();
    if (origin == null) {
      return;
    }
    final int clamped = count > 6 ? 6 : count;
    widget.controller.showReceivedLikes(count: clamped, auxiliaryOrigin: origin);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                for (final _LikeEntry entry in widget.controller._visibleEntries)
                  switch (entry.kind) {
                    _LikeEntryKind.main => _MainReactionView(
                        key: ObjectKey(entry),
                        entry: entry,
                        onCompleted: () => widget.controller.removeEntry(entry.id),
                      ),
                    _LikeEntryKind.auxiliary => _AuxiliaryReactionView(
                        key: ObjectKey(entry),
                        entry: entry,
                        onCompleted: () => widget.controller.removeEntry(entry.id),
                      ),
                    _LikeEntryKind.button => _ButtonReactionView(
                        key: ObjectKey(entry),
                        entry: entry,
                        onCompleted: () => widget.controller.removeEntry(entry.id),
                      ),
                  },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MainReactionView extends StatefulWidget {
  const _MainReactionView({super.key, required this.entry, required this.onCompleted});

  final _LikeEntry entry;
  final VoidCallback onCompleted;

  @override
  State<_MainReactionView> createState() => _MainReactionViewState();
}

class _MainReactionViewState extends State<_MainReactionView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;
  late final Animation<double> _translationY;
  late final Animation<double> _opacity;

  static const List<double> _weights = <double>[30.303, 21.212, 13.637, 34.848];

  static const List<Curve> _curves = <Curve>[
    Cubic(0.2, 0.82, 0.32, 1),
    Cubic(0.18, 0.72, 0.24, 1),
    Cubic(0.24, 0.76, 0.3, 1),
    Curves.easeOut,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LikeAnimationController.mainDuration,
      vsync: this,
    );
    _scale = _sequence(<double>[0.04, 1, 1, 1, 1.18]);
    _rotation = _sequence(<double>[-28, -28, 8, -4, -4]);
    _translationY = _sequence(<double>[0, 0, 0, 0, -6]);
    _opacity = _sequence(<double>[1, 1, 1, 1, 0], curved: false);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  Animation<double> _sequence(List<double> values, {bool curved = true}) {
    return TweenSequence<double>(<TweenSequenceItem<double>>[
      for (int index = 0; index < _weights.length; index++)
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: values[index], end: values[index + 1])
              .chain(CurveTween(curve: curved ? _curves[index] : Curves.linear)),
          weight: _weights[index],
        ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = LikeAnimationController.mainSize;

    return Positioned(
      left: widget.entry.position.dx - size * 0.5,
      top: widget.entry.position.dy - size,
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Opacity(
            opacity: _opacity.value.clamp(0, 1),
            child: Transform(
              alignment: const Alignment(0, 0.24),
              transform: Matrix4.identity()
                ..translate(0.0, _translationY.value)
                ..rotateZ(_rotation.value * math.pi / 180)
                ..scale(_scale.value),
              child: child,
            ),
          );
        },
        child: _ReactionImage(assetName: widget.entry.assetName, style: _ReactionShadowStyle.main),
      ),
    );
  }
}

class _AuxiliaryReactionView extends StatefulWidget {
  const _AuxiliaryReactionView({super.key, required this.entry, required this.onCompleted});

  final _LikeEntry entry;
  final VoidCallback onCompleted;

  @override
  State<_AuxiliaryReactionView> createState() => _AuxiliaryReactionViewState();
}

class _AuxiliaryReactionViewState extends State<_AuxiliaryReactionView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _translation;
  late final Animation<double> _opacity;

  static const List<double> _weights = <double>[34, 32, 12, 22];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.entry.duration, vsync: this);
    final double rise = widget.entry.rise;
    final List<double> offsets = widget.entry.offsets;
    final List<Offset> values = <Offset>[
      Offset.zero,
      Offset(offsets[0], -rise * 0.34),
      Offset(offsets[1], -rise * 0.66),
      Offset(offsets[2], -rise * 0.78),
      Offset(offsets[3], -rise),
    ];
    _translation = TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
      for (int index = 0; index < _weights.length; index++)
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(begin: values[index], end: values[index + 1]),
          weight: _weights[index],
        ),
    ]).animate(_controller);
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: ConstantTween<double>(0.38), weight: 78),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.38, end: 0), weight: 22),
    ]).animate(_controller);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = LikeAnimationController.auxiliarySize;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Positioned(
          left: widget.entry.position.dx - size * 0.5 + _translation.value.dx,
          top: widget.entry.position.dy - size * 0.5 + _translation.value.dy,
          width: size,
          height: size,
          child: Opacity(opacity: _opacity.value.clamp(0, 1), child: child),
        );
      },
      child: _ReactionImage(assetName: widget.entry.assetName, style: _ReactionShadowStyle.auxiliary),
    );
  }
}

class _ButtonReactionView extends StatefulWidget {
  const _ButtonReactionView({super.key, required this.entry, required this.onCompleted});

  final _LikeEntry entry;
  final VoidCallback onCompleted;

  @override
  State<_ButtonReactionView> createState() => _ButtonReactionViewState();
}

class _ButtonReactionViewState extends State<_ButtonReactionView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _translation;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  static const List<double> _weights = <double>[12.5, 29.75, 28, 10.5, 19.25];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.entry.duration, vsync: this);
    final double rise = widget.entry.rise;
    final List<double> offsets = widget.entry.offsets;
    final List<Offset> translations = <Offset>[
      Offset.zero,
      const Offset(0, -70),
      Offset(offsets[0], -(70 + rise * 0.34)),
      Offset(offsets[1], -(70 + rise * 0.66)),
      Offset(offsets[2], -(70 + rise * 0.78)),
      Offset(offsets[3], -(70 + rise)),
    ];
    _translation = TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: translations[0], end: translations[1])
            .chain(CurveTween(curve: const Cubic(0.16, 0.78, 0.24, 1))),
        weight: _weights[0],
      ),
      for (int index = 1; index < _weights.length; index++)
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(begin: translations[index], end: translations[index + 1]),
          weight: _weights[index],
        ),
    ]).animate(_controller);
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.2, end: 1).chain(CurveTween(curve: const Cubic(0.16, 0.78, 0.24, 1))),
        weight: _weights[0],
      ),
      for (int index = 1; index < _weights.length; index++)
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(1),
          weight: _weights[index],
        ),
    ]).animate(_controller);
    final List<double> opacities = <double>[1, 1, 0.66, 0.34, 0.22, 0];
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      for (int index = 0; index < _weights.length; index++)
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: opacities[index], end: opacities[index + 1]),
          weight: _weights[index],
        ),
    ]).animate(_controller);
    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = LikeAnimationController.buttonSize;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Positioned(
          left: widget.entry.position.dx - size * 0.5 + _translation.value.dx,
          top: widget.entry.position.dy - size * 0.5 + _translation.value.dy,
          width: size,
          height: size,
          child: Opacity(
            opacity: _opacity.value.clamp(0, 1),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: _ReactionImage(assetName: widget.entry.assetName, style: _ReactionShadowStyle.button),
    );
  }
}

enum _ReactionShadowStyle { main, auxiliary, button }

class _ReactionImage extends StatelessWidget {
  const _ReactionImage({required this.assetName, required this.style});

  final String assetName;
  final _ReactionShadowStyle style;

  double get _shadowOpacity {
    switch (style) {
      case _ReactionShadowStyle.main:
        return 0.3;
      case _ReactionShadowStyle.auxiliary:
        return 0.24;
      case _ReactionShadowStyle.button:
        return 0.28;
    }
  }

  Offset get _shadowOffset {
    switch (style) {
      case _ReactionShadowStyle.main:
        return const Offset(0, 5);
      case _ReactionShadowStyle.auxiliary:
      case _ReactionShadowStyle.button:
        return const Offset(0, 3);
    }
  }

  double get _shadowRadius {
    switch (style) {
      case _ReactionShadowStyle.main:
        return 7;
      case _ReactionShadowStyle.auxiliary:
      case _ReactionShadowStyle.button:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    // UIKit 无 shadowPath 时阴影沿图片 alpha 轮廓；用染色、平移、模糊
    // 保持透明边界，代价是额外的离屏合成，不能替换为矩形 BoxShadow。
    final double sigma = Shadow.convertRadiusToSigma(_shadowRadius);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: <Widget>[
        Transform.translate(
          offset: _shadowOffset,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Opacity(
              opacity: _shadowOpacity,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFF000000), BlendMode.srcIn),
                child: _buildImage(),
              ),
            ),
          ),
        ),
        _buildImage(),
      ],
    );
  }

  Widget _buildImage() {
    return Image(
      image: LiveKitResources.image(assetName),
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

/// Batches sends for one entry activation; the host retains SDK state and UI gates.
class LikeSender {
  LikeSender({Duration Function()? now}) : _now = now ?? (() => _clock.elapsed);

  static final _clock = Stopwatch()..start();
  static const _interval = Duration(seconds: 6);
  final Duration Function() _now;
  void Function(int)? _send;
  int _pendingCount = 0;
  Duration? _lastSendTime;
  Timer? _timer;
  int _generation = 0;

  void activate(void Function(int) send) {
    deactivate();
    _send = send;
  }

  void sendLike() {
    if (_send == null) return;
    _pendingCount++;
    final elapsed = _lastSendTime == null ? _interval : _now() - _lastSendTime!;
    if (elapsed >= _interval) {
      _flush();
    } else if (_timer == null) {
      final generation = _generation;
      _timer = Timer(_interval - elapsed, () {
        if (_generation == generation) _flush();
      });
    }
  }

  void deactivate({bool discardPending = false}) {
    _generation++;
    _timer?.cancel();
    _timer = null;
    final action = _send;
    final count = _pendingCount;
    _send = null;
    _pendingCount = 0;
    _lastSendTime = null;
    if (!discardPending && count > 0) action?.call(count);
  }

  void _flush() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    if (_pendingCount == 0) return;
    final count = _pendingCount;
    _pendingCount = 0;
    _lastSendTime = _now();
    _send?.call(count);
  }
}
