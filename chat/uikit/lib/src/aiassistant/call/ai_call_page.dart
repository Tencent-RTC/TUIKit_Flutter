import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/atomicx.dart';

import '../../common/language/gen/chat_localizations.dart';
import '../../message_input/asr/realtime_audio_capture.dart';
import 'ai_call_controller.dart';
import 'ai_call_state.dart';
import 'ui/transcript_view.dart';
import 'ui/voice_orb.dart';

@visibleForTesting
SystemUiOverlayStyle aiCallSystemUiOverlayStyle() {
  const background = Color(0xFF121417);
  return const SystemUiOverlayStyle(
    statusBarColor: background,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
}

/// AI voice call page.
///
/// Listening, speaking and subtitles are states of one set of widgets, not
/// separate pages.
class AICallPage extends StatefulWidget {
  const AICallPage({super.key, required this.robotUserID});

  final String robotUserID;

  @override
  State<AICallPage> createState() => _AICallPageState();
}

class _AICallPageState extends State<AICallPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFF121417);
  static const Color _buttonBackground = Color(0x1FFFFFFF);
  static const Color _hangupBackground = Color(0xFFFF5A5F);
  static const Color _statusColor = Color(0xFFB8BDC4);
  static const Color _disclaimerColor = Color(0xFF6E747C);

  static const double _orbSizeFull = 280;
  static const double _orbSizeCompact = 72;
  static const Duration _orbLayoutAnimDuration = Duration(milliseconds: 320);

  AICallController? _controller;

  /// [AICallController.start] resolved true. Mute, pause and resume are only
  /// forwarded after that.
  bool _controllerStarted = false;

  AICallState _state = AICallState.idle;
  bool _muted = false;

  /// The ASR session could not start; the mic button becomes a retry button
  /// until a non-idle state arrives.
  bool _listeningFailed = false;

  bool _subtitleVisible = true;
  List<TranscriptEntry> _entries = const [];
  final ValueNotifier<double> _level = ValueNotifier<double>(0);

  late final AnimationController _compactController =
      AnimationController(vsync: this, duration: _orbLayoutAnimDuration);
  late final Animation<double> _compactAnimation =
      CurvedAnimation(parent: _compactController, curve: Curves.fastOutSlowIn);

  /// The app is resumed. Focus gains in the background are ignored: capturing
  /// then only yields all-zero frames.
  bool _visible = true;
  bool _focusLost = false;
  StreamSubscription<bool>? _focusSubscription;
  bool _inVoiceCallMode = false;

  String? _asrUnavailableDialogID;
  bool _closing = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _visible = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _focusSubscription?.cancel();
    final dialogID = _asrUnavailableDialogID;
    if (dialogID != null && AtomicAlertDialog.exists(dialogID)) {
      AtomicAlertDialog.dismiss(dialogID);
    }
    _controller?.release();
    _controller = null;
    _exitVoiceCallMode();
    SystemChrome.setPreferredOrientations(const []);
    _compactController.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (visible == _visible) return;
    _visible = visible;
    final controller = _controller;
    if (controller == null || !_controllerStarted) return;
    // Pressing Home does not cost audio focus, so the lifecycle has to pause
    // the call as well: in the background the system hands out all-zero
    // microphone frames.
    if (visible) {
      controller.resume();
    } else {
      controller.pause();
    }
  }

  void _onFocusChanged(bool gained) {
    _focusLost = !gained;
    final controller = _controller;
    if (controller == null || !_controllerStarted) return;
    // A permanent loss only pauses as well: the page is still there when the
    // user comes back from the phone call, and hanging up is their call.
    if (!gained) {
      controller.pause();
    } else if (_visible) {
      controller.resume();
    }
  }

  Future<void> _prepare() async {
    if (_disposed) return;
    if (widget.robotUserID.isEmpty) {
      _close();
      return;
    }
    final granted = await _ensureMicrophonePermission();
    if (!mounted || _disposed) return;
    if (!granted) {
      Toast.simple(
          context, ChatLocalizations.of(context).aiCallPermissionDenied,
          useRootOverlay: true);
      _close();
      return;
    }

    _focusSubscription =
        RealtimeAudioCapture.instance.focusChanges.listen(_onFocusChanged);
    // Focus before the microphone: other apps' music has to pause first or it
    // gets captured too.
    _inVoiceCallMode = true;
    final focused = await RealtimeAudioCapture.instance.enterVoiceCallMode();
    if (!focused) {
      // Most often a phone call is in progress. Whether the microphone works is
      // up to the capture, so the call goes on.
      debugPrint('AICallPage: voice call mode not granted');
    }
    if (_disposed) return;

    final controller = AICallController(
      robotUserID: widget.robotUserID,
      callbacks: AICallCallbacks(
        onStateChanged: _onStateChanged,
        onTranscriptChanged: _onTranscriptChanged,
        onAudioLevel: (level) {
          if (!_disposed) _level.value = level;
        },
        onError: _onError,
        onListeningFailed: () {
          if (_disposed) return;
          setState(() => _listeningFailed = true);
        },
        onAsrServiceUnavailable: _showAsrUnavailableDialog,
      ),
    );
    _controller = controller;
    final started = await controller.start();
    if (_disposed) return;
    if (!started) {
      // Cannot go on; do not keep holding the focus.
      _controller = null;
      _exitVoiceCallMode();
      _close();
      return;
    }
    _controllerStarted = true;
    if (!_visible || _focusLost) {
      controller.pause();
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.check(PermissionType.microphone);
    if (status == PermissionStatus.granted) return true;
    if (!mounted || _disposed) return false;
    return Permission.checkAndRequest(context, [PermissionType.microphone]);
  }

  void _exitVoiceCallMode() {
    if (!_inVoiceCallMode) return;
    _inVoiceCallMode = false;
    // The call mode is global; not restoring it routes later media playback
    // to the earpiece.
    RealtimeAudioCapture.instance.exitVoiceCallMode();
  }

  void _close() {
    if (_closing || _disposed) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _onStateChanged(AICallState state) {
    if (_disposed) return;
    setState(() {
      if (state != AICallState.idle) {
        _listeningFailed = false;
      }
      _state = state;
    });
  }

  void _onTranscriptChanged(List<TranscriptEntry> entries) {
    if (_disposed) return;
    setState(() => _entries = entries);
    _applySubtitleVisibility();
  }

  void _onError(AICallError error) {
    if (_disposed) return;
    final locale = ChatLocalizations.of(context);
    final String message;
    switch (error) {
      case AICallError.replyTimeout:
        message = locale.aiCallReplyTimeout;
        break;
      case AICallError.startFailed:
        message = locale.aiCallStartFailed;
        break;
      case AICallError.sendFailed:
        message = locale.aiCallSendFailed;
        break;
      case AICallError.audioUnavailable:
        message = locale.aiCallAudioUnavailable;
        break;
      case AICallError.playbackUnavailable:
        message = locale.aiCallPlaybackUnavailable;
        break;
    }
    Toast.simple(context, message, useRootOverlay: true);
  }

  /// Nothing can be done on the page when the service is unavailable, so the
  /// only button ends the call and tapping outside does not close it. Running
  /// out mid-call lands here too: it is noticed when the next session opens.
  void _showAsrUnavailableDialog() {
    if (_disposed || _closing) return;
    final existing = _asrUnavailableDialogID;
    if (existing != null && AtomicAlertDialog.exists(existing)) return;
    final locale = ChatLocalizations.of(context);
    _asrUnavailableDialogID = AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        title: locale.aiCallAsrUnavailableTitle,
        content: locale.aiCallAsrUnavailableContent,
        confirmConfig: ButtonConfig(
          text: locale.aiCallAsrUnavailableExit,
          type: TextColorPreset.blue,
          isBold: true,
          onClick: _close,
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// In the failed state the button retries first: the call has stopped and
  /// the user wants it running again, not to mute a microphone nobody listens
  /// to. Muted goes the other way: unmuting reopens the session itself.
  void _onMicTap() {
    final controller = _controller;
    if (controller == null || !_controllerStarted) return;
    if (_listeningFailed && !_muted) {
      controller.retryListening();
      return;
    }
    setState(() => _muted = !_muted);
    controller.setMuted(_muted);
  }

  void _onSubtitleTap() {
    setState(() => _subtitleVisible = !_subtitleVisible);
    _applySubtitleVisibility();
  }

  /// Subtitles may be on by default, but they only push the orb up once there
  /// is at least one non-blank line.
  bool get _showTranscriptPanel =>
      _subtitleVisible && _entries.any((entry) => entry.text.trim().isNotEmpty);

  void _applySubtitleVisibility() {
    if (_showTranscriptPanel) {
      _compactController.forward();
    } else {
      _compactController.reverse();
    }
  }

  String _statusText(ChatLocalizations locale) {
    // Muted and failed both sit in idle, whose text is "listening"; shown as
    // is it would claim to listen while muted, or hide the failure after one
    // toast.
    if (_muted) return locale.aiCallMuted;
    if (_listeningFailed) return locale.aiCallStartFailedRetry;
    switch (_state) {
      case AICallState.listening:
      case AICallState.idle:
        return locale.aiCallListening;
      case AICallState.thinking:
        return locale.aiCallThinking;
      case AICallState.speaking:
        return locale.aiCallSpeaking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ChatLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: aiCallSystemUiOverlayStyle(),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                  height: 56, child: Center(child: _buildModePill(locale))),
              Expanded(child: _buildStage(context)),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  _statusText(locale),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _statusColor),
                ),
              ),
              _buildButtons(),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Text(
                  locale.aiCallDisclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: _disclaimerColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(ChatLocalizations locale) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: _buttonBackground, borderRadius: BorderRadius.circular(16)),
      child: Text(locale.aiCallModeFree,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }

  /// With subtitles and at least one line the orb shrinks to [_orbSizeCompact]
  /// and gives the space to the list; otherwise it is the large centered orb.
  Widget _buildStage(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    // Muted keeps the listening breath: muting only closes the microphone, the
    // button icon and the status text say so.
    final orbState = _muted ? AICallState.listening : _state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _compactAnimation,
          builder: (context, _) {
            final t = _compactAnimation.value;
            final orbAreaHeight = lerpDouble(height, _orbSizeCompact, t)!;
            final orbSize = math.min(
                lerpDouble(_orbSizeFull, _orbSizeCompact, t)!, orbAreaHeight);
            return Column(
              children: [
                SizedBox(
                  height: orbAreaHeight,
                  child: Center(
                    child: SizedBox.square(
                      dimension: orbSize,
                      child: VoiceOrb(
                        state: orbState,
                        level: _level,
                        colorLight: colors.buttonColorPrimaryHover,
                        colorCore: colors.buttonColorPrimaryDefault,
                        colorDark: colors.buttonColorPrimaryActive,
                      ),
                    ),
                  ),
                ),
                if (t > 0)
                  Expanded(
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0).toDouble(),
                      child: TranscriptView(entries: _entries),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Off states use slashed icons instead of dimming: only one state of
          // each button is ever on screen, with nothing to compare against.
          _buildRoundButton(
            asset:
                'chat_assets/icon/aiassistant/${_muted ? 'ai_call_mic_off.svg' : 'ai_call_mic.svg'}',
            background: _buttonBackground,
            onTap: _onMicTap,
          ),
          const SizedBox(width: 16),
          _buildRoundButton(
            asset:
                'chat_assets/icon/aiassistant/${_subtitleVisible ? 'ai_call_subtitle.svg' : 'ai_call_subtitle_off.svg'}',
            background: _buttonBackground,
            onTap: _onSubtitleTap,
          ),
          const SizedBox(width: 16),
          _buildRoundButton(
            asset: 'chat_assets/icon/aiassistant/ai_call_hangup.svg',
            background: _hangupBackground,
            onTap: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
      {required String asset,
      required Color background,
      required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: SvgPicture.asset(
          asset,
          package: 'tencent_chat_uikit',
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}
