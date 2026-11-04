import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../live_avatar_image.dart';
import '../live_kit_resources.dart';
import 'live_text.dart';
import 'live_theme.dart';

/// 音浪圆环描边与外扩距离，三端一致（对应设计 `inset: -2px` 与 `border: 2px`）。
const double _waveRingOffset = 2;
const double _waveRingWidth = 2;
const Color _waveRingColor = Color(0xE6FFFFFF);

/// 扩散到 1.38 倍后消失，对应设计关键帧末态 `transform: scale(1.38)`。
const double _waveMaxScale = 1.38;

/// 设计给出的 cubic-bezier(0.16, 0.5, 0.4, 1)。
const Cubic _waveCurve = Cubic(0.16, 0.5, 0.4, 1);

/// 对应 iOS `Common/Theme/LiveSeat.swift`：席位的三层公共视觉。
///
/// 子类（Player 的 `UnitView` 与 Pusher 的 `PusherCoGuestUnitView`）负责把
/// `UnitInfo` + 自身状态投影成这里的入参，不读取 AtomicXCore 或 Login/Device Store。
///
/// 构造参数即 iOS `init(emptyTitle:) + updateContent + updateVisibility` 的全集：
/// - `emptyTitle`：空席位的邀请/申请文案；
/// - `name` / `avatarURL` / `microphoneOn`：对应 `updateContent`；
/// - `isEmpty` / `showsNoVideo` / `showsOverlay`：对应 `updateVisibility`，三者
///   互斥且优先级与 iOS 一致（`isEmpty` 为 true 时压制其余两层）；
/// - `volume`：对应 iOS / Android 的 `updateVolume`，声明式地驱动无视频头像外圈音浪。
///
/// 音浪显示阈值见 [LiveSeat.volumeWaveThreshold]。
class LiveSeat extends StatelessWidget {
  const LiveSeat({
    super.key,
    required this.emptyTitle,
    this.name = '',
    this.avatarURL = '',
    this.microphoneOn = false,
    this.isEmpty = true,
    this.showsNoVideo = false,
    this.showsOverlay = false,
    this.volume = 0,
  });

  /// 音浪显示阈值：当前策略为 volume 达到该值即显示，后续调整只改这里。
  static const int volumeWaveThreshold = 0;

  final String emptyTitle;
  final String name;
  final String avatarURL;
  final bool microphoneOn;
  final bool isEmpty;
  final bool showsNoVideo;
  final bool showsOverlay;
  final int volume;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (!isEmpty && showsNoVideo)
            _LiveSeatNoVideoView(avatarURL: avatarURL, volume: volume),
          if (!isEmpty && showsOverlay)
            _LiveSeatOverlayView(name: name, microphoneOn: microphoneOn),
          if (isEmpty) _LiveSeatEmptyView(title: emptyTitle),
        ],
      ),
    );
  }
}

class _LiveSeatEmptyView extends StatelessWidget {
  const _LiveSeatEmptyView({required this.title});

  final String title;

  static const double _contentInset = 1;
  static const double _compactThreshold = 110;
  static const double _plusHeightCompact = 32;
  static const double _plusHeightRegular = 30;
  static const double _spacing = 3;
  static const double _invitationHeight = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        if (width <= 0 || height <= 0 || !width.isFinite || !height.isFinite) {
          return const SizedBox.shrink();
        }
        final double inset = math.min(
          _contentInset,
          math.min(width, height) / 4,
        );
        final double contentWidth = width - inset * 2;
        final double contentHeight = height - inset * 2;
        if (contentWidth <= 0 || contentHeight <= 0) {
          return const SizedBox.shrink();
        }
        final bool isCompact =
            math.min(contentWidth, contentHeight) <= _compactThreshold;
        final double plusHeight =
            isCompact ? _plusHeightCompact : _plusHeightRegular;
        final bool showsInvitation =
            contentHeight >= plusHeight + _spacing + _invitationHeight;
        final double contentStackHeight = showsInvitation
            ? plusHeight + _spacing + _invitationHeight
            : plusHeight;
        final double originY =
            math.max(0, (contentHeight - contentStackHeight) / 2);
        return Padding(
          padding: EdgeInsets.all(inset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  isCompact ? const Color(0x0EFFFFFF) : const Color(0x09FFFFFF),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 0,
                  right: 0,
                  top: originY,
                  height: plusHeight,
                  child: Center(
                    child: Text(
                      '+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0x75FFFFFF),
                        fontSize: isCompact ? 29 : 26,
                        fontWeight: FontWeight.w100,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                if (showsInvitation)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: originY + plusHeight + _spacing,
                    height: _invitationHeight,
                    child: LiveText(
                      LiveTextRole.metadata,
                      text: title,
                      tone: LiveTextTone.tertiary,
                      alignment: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveSeatNoVideoView extends StatelessWidget {
  const _LiveSeatNoVideoView({
    required this.avatarURL,
    required this.volume,
  });

  final String avatarURL;
  final int volume;

  static const Color _gradientStart = Color(0xFF1A2E45);
  static const Color _gradientEnd = Color(0xFF080F1F);

  static double _avatarSize(double shortSide) {
    if (shortSide <= 110) return 42;
    if (shortSide <= 140) return 30;
    if (shortSide > 250) return 67;
    return 63;
  }

  bool get _showsWave => volume > LiveSeat.volumeWaveThreshold;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_gradientStart, _gradientEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            if (width <= 0 || height <= 0 || !width.isFinite || !height.isFinite) {
              return const SizedBox.shrink();
            }
            final double shortSide = math.min(width, height);
            final double size = _avatarSize(shortSide);
            return Center(
              child: _LiveSeatSpeakingWave(
                showsWave: _showsWave,
                diameter: size,
                child: ClipOval(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: LiveAvatarImage(avatarURL: avatarURL),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 头像外圈音浪：双层白色圆环以 1.4s 周期、半周期错峰向外扩散。
///
/// 对应设计 `co-mic-effects.css` 的 `.comic-slot-portrait::before/::after`
/// 与 `@keyframes comic-speaking-wave`：圆环位于头像外扩 [_waveRingOffset] 处、
/// 描边 [_waveRingWidth]，透明度按 0 → 0.78 → 0.22 → 0 变化，同时缩放 1 → [_waveMaxScale]。
class _LiveSeatSpeakingWave extends StatefulWidget {
  const _LiveSeatSpeakingWave({
    required this.showsWave,
    required this.diameter,
    required this.child,
  });

  final bool showsWave;
  final double diameter;
  final Widget child;

  @override
  State<_LiveSeatSpeakingWave> createState() => _LiveSeatSpeakingWaveState();
}

class _LiveSeatSpeakingWaveState extends State<_LiveSeatSpeakingWave>
    with SingleTickerProviderStateMixin {
  /// 与 iOS / Android 一致的 1.4s 周期。
  static const Duration _duration = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..addListener(_onTick);

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _LiveSeatSpeakingWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  void _syncAnimation() {
    if (widget.showsWave && !_reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
      return;
    }
    if (_controller.isAnimating) _controller.stop();
  }

  /// 第一个圆环的缓动后进度：设计给出 cubic-bezier(0.16, 0.5, 0.4, 1)。
  double get _firstProgress => _waveCurve.transform(_controller.value);

  /// 第二个圆环相对第一个错开半个周期，等价于 CSS 的 `animation-delay: -0.7s`。
  double get _secondProgress =>
      _waveCurve.transform((_controller.value + 0.5) % 1.0);

  @override
  Widget build(BuildContext context) {
    if (!widget.showsWave) return widget.child;
    final double diameter = widget.diameter + _waveRingOffset * 2;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        if (_reduceMotion)
          _WaveRing(
            opacity: 0.72,
            scale: 1.0,
            diameter: diameter,
          )
        else ...<Widget>[
          _WaveRing(
            opacity: _waveOpacity(_firstProgress),
            scale: 1 + (_waveMaxScale - 1) * _firstProgress,
            diameter: diameter,
          ),
          _WaveRing(
            opacity: _waveOpacity(_secondProgress),
            scale: 1 + (_waveMaxScale - 1) * _secondProgress,
            diameter: diameter,
          ),
        ],
        widget.child,
      ],
    );
  }
}

/// 按设计的四个不透明度关键帧（0 / 0.78 / 0.22 / 0）线性插值。
double _waveOpacity(double progress) {
  if (progress <= 0) return 0;
  if (progress < 0.14) return 0.78 / 0.14 * progress;
  if (progress < 0.7) {
    return 0.78 + (0.22 - 0.78) / (0.7 - 0.14) * (progress - 0.14);
  }
  if (progress < 1) return 0.22 / (1 - 0.7) * (1 - progress);
  return 0;
}

class _WaveRing extends StatelessWidget {
  const _WaveRing({
    required this.opacity,
    required this.scale,
    required this.diameter,
  });

  final double opacity;
  final double scale;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _waveRingColor, width: _waveRingWidth),
          ),
        ),
      ),
    );
  }
}

class _LiveSeatOverlayView extends StatelessWidget {
  const _LiveSeatOverlayView({
    required this.name,
    required this.microphoneOn,
  });

  final String name;
  final bool microphoneOn;

  static const double _lineHeight = 14;
  static const double _iconSize = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double availableWidth = width - 12;
        if (availableWidth <= 0 ||
            height < _lineHeight ||
            !width.isFinite ||
            !height.isFinite) {
          return const SizedBox.shrink();
        }
        final double nameTop = math.max(0, height - _lineHeight);
        final double badgeWidth = math.min(_iconSize + 8, availableWidth);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              top: nameTop,
              bottom: 0,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00000000), Color(0x66000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              width: badgeWidth,
              height: _lineHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x52000000),
                  borderRadius: BorderRadius.circular(_lineHeight / 2),
                ),
                child: Center(
                  child: Image(
                    image: LiveKitResources.image(microphoneOn
                        ? 'livekit_coguest_seat_mic'
                        : 'livekit_coguest_seat_muted'),
                    width: _iconSize,
                    height: _iconSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: nameTop,
              width: math.max(0, width - 8),
              height: _lineHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 10,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
