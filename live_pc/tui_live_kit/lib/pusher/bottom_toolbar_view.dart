import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../l10n/live_kit_localizations.dart';
import 'pusher_style.dart';

class PusherBottomToolbarView extends StatelessWidget {
  const PusherBottomToolbarView({
    super.key,
    required this.isLiveStarted,
    required this.liveStartTime,
    required this.micOn,
    required this.speakerMuted,
    required this.captureVolume,
    required this.outputVolume,
    required this.onToggleMicrophone,
    required this.onToggleSpeakerMute,
    required this.onCaptureVolumeChanged,
    required this.onOutputVolumeChanged,
    required this.onStartLive,
    required this.onEndLive,
  });

  final ValueNotifier<bool> isLiveStarted;
  final ValueNotifier<DateTime?> liveStartTime;
  final ValueListenable<bool> micOn;
  final ValueListenable<bool> speakerMuted;
  final ValueListenable<int> captureVolume;
  final ValueListenable<int> outputVolume;
  final VoidCallback onToggleMicrophone;
  final VoidCallback onToggleSpeakerMute;
  final ValueChanged<int> onCaptureVolumeChanged;
  final ValueChanged<int> onOutputVolumeChanged;
  final VoidCallback onStartLive;
  final VoidCallback onEndLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: PusherStyle.glassPanel(radius: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: micOn,
                builder: (context, on, _) =>
                    _MicToggle(on: on, onToggle: onToggleMicrophone),
              ),
              const SizedBox(width: 8),
              _VolumeSlider(
                value: captureVolume,
                onChanged: onCaptureVolumeChanged,
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<int>(
                valueListenable: captureVolume,
                builder: (context, volume, _) => SizedBox(
                  width: 32,
                  child: Text(
                    '$volume%',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        fontSize: 10, color: PusherStyle.textHint),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                  width: 1, height: 16, color: PusherStyle.white10),
              const SizedBox(width: 16),
              ValueListenableBuilder<bool>(
                valueListenable: speakerMuted,
                builder: (context, muted, _) =>
                    _SpeakerToggle(muted: muted, onToggle: onToggleSpeakerMute),
              ),
              const SizedBox(width: 8),
              _VolumeSlider(
                value: outputVolume,
                onChanged: onOutputVolumeChanged,
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<int>(
                valueListenable: outputVolume,
                builder: (context, volume, _) => SizedBox(
                  width: 32,
                  child: Text(
                    '$volume%',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        fontSize: 10, color: PusherStyle.textHint),
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLiveStarted,
            builder: (context, started, _) => _LiveButton(
              started: started,
              startTime: liveStartTime.value,
              onTap: started ? onEndLive : onStartLive,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveButton extends StatefulWidget {
  const _LiveButton({
    required this.started,
    required this.startTime,
    required this.onTap,
  });

  final bool started;
  final DateTime? startTime;
  final VoidCallback onTap;

  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton> {
  static const double _minWidth = 124;
  Timer? _timer;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    if (widget.started) _startTimer();
  }

  @override
  void didUpdateWidget(covariant _LiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.started && !oldWidget.started) {
      _startTimer();
    } else if (!widget.started && oldWidget.started) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final started = widget.started;
    final startTime = widget.startTime;

    final strings = LiveKitLocalizations.of(context);
    final String label;
    if (!started) {
      label = strings.liveStart;
    } else if (!_hovering && startTime != null) {
      label = _formatDuration(DateTime.now().difference(startTime));
    } else {
      label = strings.liveEnd;
    }

    final bool showElapsed = started && !_hovering && startTime != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 36,
          constraints: const BoxConstraints(minWidth: _minWidth),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: started
                ? (_hovering ? PusherStyle.white15 : PusherStyle.white10)
                : (_hovering ? PusherStyle.brand2 : PusherStyle.danger),
            borderRadius: BorderRadius.circular(8),
            boxShadow: started
                ? null
                : [
                    BoxShadow(
                      color: PusherStyle.danger.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (started) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: PusherStyle.whitePure,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: started ? PusherStyle.textSecondary : Colors.white,
                  fontFeatures: showElapsed
                      ? const [ui.FontFeature.tabularFigures()]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider({
    required this.value,
    required this.onChanged,
  });

  final ValueListenable<int> value;
  final ValueChanged<int> onChanged;

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  static const double _trackWidth = 96;

  static const double _thumbSize = 12;

  bool _hovering = false;
  bool _dragging = false;

  int _toVolume(double dx) =>
      ((dx / _trackWidth).clamp(0.0, 1.0) * 100).round();

  void _handlePanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final pos = box.globalToLocal(details.globalPosition);
    widget.onChanged(_toVolume(pos.dx));
  }

  @override
  Widget build(BuildContext context) {
    final bool showThumb = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ValueListenableBuilder<int>(
        valueListenable: widget.value,
        builder: (context, volume, _) {
          final double thumbLeft =
              (volume / 100 * _trackWidth - _thumbSize / 2)
                  .clamp(0.0, _trackWidth - _thumbSize);
          return SizedBox(
            width: _trackWidth,
            height: 20,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  widget.onChanged(_toVolume(details.localPosition.dx)),
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: _handlePanUpdate,
              onPanEnd: (_) => setState(() => _dragging = false),
              onPanCancel: () => setState(() => _dragging = false),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      width: _trackWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PusherStyle.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: volume / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [PusherStyle.brand, PusherStyle.brand2],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbLeft,
                    top: (20 - _thumbSize) / 2,
                    child: AnimatedOpacity(
                      opacity: showThumb ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PusherStyle.whitePure,
                          border: Border.all(
                            color: PusherStyle.brand,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: PusherStyle.shadowBlack,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 麦克风开关图标：开 mic_fill / 关 mic_off_fill 置灰。
class _MicToggle extends StatelessWidget {
  const _MicToggle({required this.on, required this.onToggle});

  final bool on;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Icon(
          on ? RemixIcons.mic_fill : RemixIcons.mic_off_fill,
          size: 14,
          color: on ? PusherStyle.textSecondary : PusherStyle.textHint,
        ),
      ),
    );
  }
}

class _SpeakerToggle extends StatelessWidget {
  const _SpeakerToggle({required this.muted, required this.onToggle});

  final bool muted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Icon(
          muted ? RemixIcons.volume_mute_fill : RemixIcons.volume_up_fill,
          size: 14,
          color: muted ? PusherStyle.textHint : PusherStyle.textSecondary,
        ),
      ),
    );
  }
}
