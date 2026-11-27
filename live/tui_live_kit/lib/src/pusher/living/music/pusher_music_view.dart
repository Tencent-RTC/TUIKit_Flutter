/// 背景音乐抽屉：三首固定音乐、播放/暂停控制与播放中的波形动画。
library;

import 'package:flutter/widgets.dart';

import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class PusherMusicView extends StatefulWidget {
  const PusherMusicView({
    super.key,
    required this.liveID,
    required this.isPresented,
    this.isSuspended = false,
    this.musicStore,
    required this.onDismiss,
  });

  final String liveID;
  final bool isPresented;
  final bool isSuspended;
  final MusicStore? musicStore;

  /// 抽屉关闭。
  final VoidCallback onDismiss;

  @override
  State<PusherMusicView> createState() => PusherMusicViewState();
}

class PusherMusicViewState extends State<PusherMusicView> {
  static const double _sheetHeight = 370;
  late final MusicStore _musicStore;
  final _MusicState _state = _MusicState();
  bool _active = false;
  bool _suspended = false;
  String? _resumeURL;

  @override
  void initState() {
    super.initState();
    _musicStore = widget.musicStore ?? MusicStore.create(liveID: widget.liveID);
    _active = true;
    _musicStore.musicState.playURL.addListener(_updateState);
    _musicStore.musicState.playStatus.addListener(_updateState);
    _updateState();
    setSuspended(widget.isSuspended);
  }

  @override
  void didUpdateWidget(PusherMusicView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSuspended != widget.isSuspended) {
      setSuspended(widget.isSuspended);
    }
  }

  void _updateState() {
    if (!_active || !mounted) return;
    setState(() {
      _state.currentURL = _musicStore.musicState.playURL.value;
      _state.playStatus = _musicStore.musicState.playStatus.value;
    });
    if (_suspended && _state.playStatus == MusicPlayStatus.playing) {
      _musicStore.pausePlay();
    }
  }

  void setSuspended(bool suspended) {
    if (_suspended == suspended) return;
    _suspended = suspended;
    if (!_active) return;
    final current = _musicStore.musicState;
    if (suspended) {
      _resumeURL =
          current.playStatus.value == MusicPlayStatus.playing || current.playStatus.value == MusicPlayStatus.loading
              ? current.playURL.value
              : null;
      if (_resumeURL != null) _musicStore.pausePlay();
    } else {
      final resume = _resumeURL != null &&
          _resumeURL == current.playURL.value &&
          current.playStatus.value == MusicPlayStatus.paused;
      _resumeURL = null;
      if (resume) _musicStore.resumePlay();
    }
  }

  void _toggle(_Track track) {
    if (!_active || _suspended) return;
    if (_state.currentURL == track.url) {
      switch (_state.playStatus) {
        case MusicPlayStatus.playing:
        case MusicPlayStatus.loading:
          _musicStore.pausePlay();
          return;
        case MusicPlayStatus.paused:
          _musicStore.resumePlay();
          return;
        case MusicPlayStatus.idle:
          break;
      }
    } else if (_state.currentURL != null) {
      _musicStore.stopPlay();
    }
    _musicStore.setPitch(0);
    _musicStore.startPlay(AudioMusicParam(id: track.id, path: track.url));
  }

  void deactivateMusic() {
    _suspended = false;
    _resumeURL = null;
    if (!_active) return;
    _active = false;
    _musicStore.musicState.playURL.removeListener(_updateState);
    _musicStore.musicState.playStatus.removeListener(_updateState);
    _musicStore.stopPlay();
  }

  @override
  void dispose() {
    deactivateMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetView(
      sheetHeight: _sheetHeight,
      isPresented: widget.isPresented,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.living.music'),
      onDismiss: widget.onDismiss,
      child: TickerMode(
          enabled: widget.isPresented,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                bottom: 0,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemExtent: 72,
                  itemCount: _state.tracks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final _Track track = _state.tracks[index];
                    return _PusherMusicCell(
                      track: track,
                      isCurrent: _state.isCurrent(track),
                      isPlaying: _state.isPlaying(track),
                      onPressed: () => _toggle(track),
                    );
                  },
                ),
              ),
            ],
          )),
    );
  }
}

class _PusherMusicCell extends StatelessWidget {
  const _PusherMusicCell({
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.onPressed,
  });

  final _Track track;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 72,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 16,
              top: 11,
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ColoredBox(
                        color: _PusherMusicStyle.coverBackground,
                        child: Center(
                          child: Image(
                            image: LiveKitResources.image('livekit_living_setting_music'),
                            width: 18,
                            height: 21,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Positioned.fill(
                        // UIColor(red: 5/255, green: 7/255, blue: 12/255, alpha: 0.56)
                        child: ColoredBox(
                          color: _PusherMusicStyle.playingOverlay,
                          child: Center(
                            child: SizedBox(
                              width: 25,
                              height: 18,
                              child: _MusicWaveView(isPlaying: isPlaying),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 78,
              right: 16 + 28 + 12,
              top: 17,
              height: 17,
              child: Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 14,
                ),
              ),
            ),
            Positioned(
              left: 78,
              top: 41,
              height: 15,
              child: Text(
                track.duration,
                style: const TextStyle(
                  color: Color(0x7AFFFFFF),
                  fontSize: 12,
                ),
              ),
            ),
            if (isCurrent)
              Positioned(
                right: 16,
                top: 22,
                width: 28,
                height: 28,
                child: CustomPaint(
                  painter: _MusicPlaybackControlPainter(isPlaying: isPlaying),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MusicPlaybackControlPainter extends CustomPainter {
  _MusicPlaybackControlPainter({required this.isPlaying});

  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      // UIColor.white.withAlphaComponent(0.92)
      ..color = const Color(0xEBFFFFFF);
    // iOS shapeLayer.frame = (4.5, 4.5, 19, 19)，路径坐标在该子层内。
    canvas.save();
    canvas.translate(4.5, 4.5);
    canvas.drawPath(isPlaying ? _pausePath() : _playPath(), paint);
    canvas.restore();
  }

  Path _playPath() {
    return Path()
      ..moveTo(6.49, 4.12)
      ..cubicTo(6.49, 3.31, 7.38, 2.81, 8.06, 3.25)
      ..lineTo(16.14, 8.33)
      ..cubicTo(17.02, 8.88, 17.02, 9.52, 16.14, 10.07)
      ..lineTo(8.06, 15.15)
      ..cubicTo(7.38, 15.59, 6.49, 15.09, 6.49, 14.28)
      ..close();
  }

  Path _pausePath() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5.54, 3.96, 2.85, 11.08),
          const Radius.circular(1.19),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10.61, 3.96, 2.85, 11.08),
          const Radius.circular(1.19),
        ),
      );
  }

  @override
  bool shouldRepaint(_MusicPlaybackControlPainter oldDelegate) {
    return oldDelegate.isPlaying != isPlaying;
  }
}

class _MusicWaveView extends StatelessWidget {
  const _MusicWaveView({required this.isPlaying});

  final bool isPlaying;

  /// 时长、负延迟、低位与高位偏移。
  static const List<(double, double, double, double)> _parameters = <(double, double, double, double)>[
    (0.620, -0.180, 3, -4),
    (0.790, -0.510, 2, -5),
    (0.530, -0.340, 4, -3),
    (0.710, -0.620, 2, -4),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final (double, double, double, double) item in _parameters)
          _MusicWaveDot(
            isPlaying: isPlaying,
            duration: item.$1,
            delay: item.$2,
            low: item.$3,
            high: item.$4,
          ),
      ],
    );
  }
}

class _MusicWaveDot extends StatefulWidget {
  const _MusicWaveDot({
    required this.isPlaying,
    required this.duration,
    required this.delay,
    required this.low,
    required this.high,
  });

  final bool isPlaying;
  final double duration;
  final double delay;
  final double low;
  final double high;

  @override
  State<_MusicWaveDot> createState() => _MusicWaveDotState();
}

class _MusicWaveDotState extends State<_MusicWaveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(microseconds: (widget.duration * 1000000).round()),
      vsync: this,
    );
    _syncPlaying();
  }

  @override
  void didUpdateWidget(_MusicWaveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncPlaying();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncPlaying() {
    if (!widget.isPlaying) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    // 用起始进度实现四个点的错峰。
    final double phase = (-widget.delay / widget.duration) % 1;
    // Setting value stops a running controller. Seed the staggered phase
    // before starting the repeating animation.
    _controller.value = phase;
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double progress = widget.isPlaying ? const Cubic(0.37, 0, 0.63, 1).transform(_controller.value) : 0;
        final double translationY = widget.isPlaying ? widget.low + (widget.high - widget.low) * progress : 0;
        final double scale = widget.isPlaying ? 0.82 + (1.08 - 0.82) * progress : 1;
        final double opacity = widget.isPlaying ? 0.64 + (1 - 0.64) * progress : 0.9;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translationY),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF7DE8FF),
          borderRadius: BorderRadius.all(Radius.circular(2)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Color(0xF27DE8FF), blurRadius: 5),
          ],
        ),
        child: SizedBox(width: 4, height: 4),
      ),
    );
  }
}

class _Track {
  const _Track({
    required this.id,
    required this.name,
    required this.url,
    required this.duration,
  });

  final int id;
  final String name;
  final String url;
  final String duration;
}

class _MusicState {
  List<_Track> tracks = <_Track>[
    _Track(
      id: 1,
      name: LiveKitResources.localizedString('tuilivekit.pusher.music.happy'),
      url: 'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/PositiveHappyAdvertising.mp3',
      duration: '05:45',
    ),
    _Track(
      id: 2,
      name: LiveKitResources.localizedString('tuilivekit.pusher.music.sad'),
      url: 'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/SadCinematicPiano.mp3',
      duration: '06:06',
    ),
    _Track(
      id: 3,
      name: LiveKitResources.localizedString('tuilivekit.pusher.music.wonder_world'),
      url: 'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/WonderWorld.mp3',
      duration: '02:05',
    ),
  ];
  String? currentURL;
  MusicPlayStatus playStatus = MusicPlayStatus.idle;

  bool isPlaying(_Track track) {
    return currentURL == track.url && (playStatus == MusicPlayStatus.playing || playStatus == MusicPlayStatus.loading);
  }

  bool isCurrent(_Track track) {
    return currentURL == track.url && playStatus != MusicPlayStatus.idle;
  }
}

abstract final class _PusherMusicStyle {
  static const coverBackground = Color(0x0FFFFFFF);
  static const playingOverlay = Color(0x8F05070C);
}
