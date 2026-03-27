import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/audio_recoder/audio_recorder.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

/// Audio recording overlay widget that follows WeChat-style recording UI.
///
/// Design states (from Figma):
/// 1. Recording: gradient overlay + waveform + releaseToSend hint + centered cancel button
/// 2. Cancel hover: cancel button turns red, hint becomes releaseToCancel, waveform turns red
/// 3. Countdown: last 10s shows recordCountdownTips hint
class AudioRecordOverlay extends StatefulWidget {
  final ValueChanged<RecordInfo> onRecordFinish;
  final VoidCallback onRecordCancelled;

  /// Optional: provide these when the overlay lives inside an [OverlayEntry],
  /// where the normal InheritedWidget lookup would fail.
  final SemanticColorScheme? colorScheme;
  final AtomicLocalizations? atomicLocalizations;

  const AudioRecordOverlay({
    super.key,
    required this.onRecordFinish,
    required this.onRecordCancelled,
    this.colorScheme,
    this.atomicLocalizations,
  });

  @override
  State<AudioRecordOverlay> createState() => AudioRecordOverlayState();
}

class AudioRecordOverlayState extends State<AudioRecordOverlay> with TickerProviderStateMixin {
  late AudioRecorder _audioRecorder;
  late AnimationController _waveAnimationController;

  bool _isRecording = false;
  bool _isFingerOverCancel = false;
  int _recordingDurationMs = 0;

  /// Max recording duration in seconds
  static const int _maxDurationSec = 60;

  /// Countdown threshold in seconds (show countdown in last N seconds)
  static const int _countdownThresholdSec = 10;

  final GlobalKey _cancelButtonKey = GlobalKey();

  // Random wave heights for animation
  final List<double> _waveHeights = List.generate(20, (_) => 0.5);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addListener(_updateWaveHeights);

    _audioRecorder = AudioRecorder();
    _audioRecorder.initialize(
      onProgressUpdate: _onProgressUpdate,
      onStateChanged: _onStateChanged,
    );
  }

  @override
  void dispose() {
    _waveAnimationController.removeListener(_updateWaveHeights);
    _waveAnimationController.dispose();
    _audioRecorder.cancelRecord();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _updateWaveHeights() {
    if (!_isRecording || !mounted) return;
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        // Smoothly interpolate toward new random target
        final target = 0.2 + _random.nextDouble() * 0.8;
        _waveHeights[i] = _waveHeights[i] + (target - _waveHeights[i]) * 0.3;
      }
    });
  }

  void _onProgressUpdate(int durationMs, double progress) {
    if (mounted) {
      setState(() {
        _recordingDurationMs = durationMs;
      });
    }
  }

  void _onStateChanged(bool isRecording) {
    if (mounted) {
      setState(() {
        _isRecording = isRecording;
      });

      if (isRecording) {
        _waveAnimationController.repeat();
      } else {
        _waveAnimationController.stop();
        _waveAnimationController.reset();
      }
    }
  }

  Future<void> startRecord({required String filePath}) async {
    await _audioRecorder.startRecord(
      filePath: filePath,
      onComplete: (recordInfo) {
        if (recordInfo != null) {
          if (recordInfo.errorCode == AudioRecordResultCode.errorLessThanMinDuration && mounted) {
            final atomicLocalizations = widget.atomicLocalizations ?? AtomicLocalizations.of(context);
            Toast.warning(context, atomicLocalizations.sayTimeShort);
          }
          if (recordInfo.errorCode == AudioRecordResultCode.successExceedMaxDuration && mounted) {
            final atomicLocalizations = widget.atomicLocalizations ?? AtomicLocalizations.of(context);
            Toast.warning(context, atomicLocalizations.recordLimitTips);
          }
          widget.onRecordFinish(recordInfo);
        }
      },
    );
  }

  void stopRecord() {
    _audioRecorder.stopRecord();
  }

  Future<void> cancelRecord() async {
    await _audioRecorder.cancelRecord();
    widget.onRecordCancelled();
  }

  /// Reset recording state to initial values
  void resetRecordingState() {
    if (mounted) {
      setState(() {
        _recordingDurationMs = 0;
        _isFingerOverCancel = false;
      });
    }
  }

  /// Check if a global position is over the cancel button
  bool isPointerOverCancelButton(Offset globalPosition) {
    final RenderBox? renderBox = _cancelButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final localPos = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;
    // Expand hit area a bit for easier targeting
    const expandPx = 20.0;
    return localPos.dx >= -expandPx &&
        localPos.dx <= size.width + expandPx &&
        localPos.dy >= -expandPx &&
        localPos.dy <= size.height + expandPx;
  }

  /// Update finger position (called from parent's pointer move handler)
  void updatePointerPosition(Offset globalPosition) {
    if (!_isRecording) return;
    final isOver = isPointerOverCancelButton(globalPosition);
    if (isOver != _isFingerOverCancel) {
      setState(() {
        _isFingerOverCancel = isOver;
      });
    }
  }

  int get _remainingSeconds {
    final elapsed = (_recordingDurationMs / 1000).floor();
    return _maxDurationSec - elapsed;
  }

  bool get _showCountdown => _remainingSeconds <= _countdownThresholdSec && _isRecording;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme ?? BaseThemeProvider.colorsOf(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final atomicLocale = widget.atomicLocalizations ?? AtomicLocalizations.of(context);

    return Stack(
      children: [
        // Semi-transparent top area: tap-through gradient that fades into
        // the solid bottom panel, allowing the message list to remain visible.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.bgColorOperate.withValues(alpha: 0.0),
                    colorScheme.bgColorOperate.withValues(alpha: 0.6),
                    colorScheme.bgColorOperate,
                  ],
                  stops: const [0.0, 0.55, 0.7],
                ),
              ),
            ),
          ),
        ),

        // Bottom-aligned content panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: colorScheme.bgColorOperate,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),

                // Hint text: releaseToSend / releaseToCancel / recordCountdownTips
                _buildHintText(colorScheme, atomicLocale),

                const SizedBox(height: 16),

                // Cancel button (pill shape, centered)
                _buildCancelButton(colorScheme, atomicLocale),

                const SizedBox(height: 16),

                // Waveform bar at bottom (full-width rounded container)
                _buildWaveformBar(colorScheme),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Full-width rounded waveform bar at the bottom of the overlay.
  /// Normal: blue/primary background. Cancel hover: red background.
  Widget _buildWaveformBar(SemanticColorScheme colorScheme) {
    final barColor = _isFingerOverCancel ? colorScheme.textColorError : colorScheme.buttonColorPrimaryDefault;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_waveHeights.length, (index) {
            // Varied base heights for visual rhythm
            const baseHeights = [6.0, 8.0, 14.0, 10.0, 18.0, 8.0, 12.0, 6.0, 14.0, 18.0];
            final baseHeight = baseHeights[index % baseHeights.length];
            final animatedHeight = _isRecording ? baseHeight * _waveHeights[index] : baseHeight * 0.3;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: animatedHeight.clamp(3.0, 24.0),
                decoration: BoxDecoration(
                  color: colorScheme.switchColorButton,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHintText(SemanticColorScheme colorScheme, AtomicLocalizations atomicLocale) {
    String hintText;

    if (_showCountdown) {
      hintText = atomicLocale.recordCountdownTips(_remainingSeconds);
    } else if (_isFingerOverCancel) {
      hintText = atomicLocale.releaseToCancel;
    } else {
      hintText = atomicLocale.releaseToSend;
    }

    return Text(
      hintText,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.textColorSecondary,
        decoration: TextDecoration.none,
      ),
    );
  }

  /// Circular cancel button, centered.
  /// Normal: light gray bg + dark text, no border.
  /// Cancel hover: red bg + white text.
  Widget _buildCancelButton(SemanticColorScheme colorScheme, AtomicLocalizations atomicLocale) {
    final isHover = _isFingerOverCancel;
    final bgColor = isHover ? colorScheme.textColorError : colorScheme.buttonColorSecondaryDefault;
    final textColor = isHover ? colorScheme.textColorButton : colorScheme.textColorPrimary;

    return Center(
      child: AnimatedContainer(
        key: _cancelButtonKey,
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            atomicLocale.cancel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
