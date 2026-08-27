import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tencent_chat_uikit/src/audio_recoder/audio_recorder.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/ai/ai_media_process_manager.dart';
import 'package:tencent_chat_uikit/src/ai/tts/tts_playback_helper.dart';
import 'package:tencent_chat_uikit/src/ai/tts/tts_text_sanitizer.dart';
import 'package:tencent_chat_uikit/src/ai/tts/voice_message_config.dart';
import 'package:tencent_chat_uikit/src/common/language/index.dart';

/// State machine of [AudioRecordOverlay].
///
/// - [recording]: default state on overlay show. Waveform + cancel (and optional
///   convert) buttons + release-to-* hint.
/// - [converting]: voice-to-text in progress. Three-dot animation in a blue
///   bubble. Bottom buttons stay visible but ignore taps.
/// - [editing]: conversion succeeded. Editable TextField with converted text +
///   three buttons (cancel / send original / send text).
/// - [error]: conversion failed (or returned empty / timed out). Red bubble
///   with localized error text. Any tap on the overlay closes it.
enum _OverlayState { recording, converting, editing, error }

/// Audio recording overlay widget that follows WeChat-style recording UI.
///
/// Design states (from Figma):
/// 1. Recording: gradient overlay + waveform + releaseToSend hint + centered
///    cancel button (and optional convert button when [enableVoiceToText] is
///    true).
/// 2. Cancel hover: cancel button highlights (red), hint becomes
///    releaseToCancel, waveform turns red.
/// 3. Convert hover: convert button highlights (blue), hint becomes
///    releaseToConvert.
/// 4. Countdown: last 10s shows recordCountdownTips hint.
/// 5. Converting / Editing / Error: see [_OverlayState].
class AudioRecordOverlay extends StatefulWidget {
  /// Fired when recording finishes successfully and the original audio is to
  /// be sent (default release-to-send, OR user pressed "send original voice"
  /// in editing state).
  final ValueChanged<RecordInfo> onRecordFinish;

  /// Fired when the recording is cancelled (user dragged to cancel button,
  /// pressed cancel in editing state, or tapped the error bubble).
  final VoidCallback onRecordCancelled;

  /// Fired when the user accepts the converted text (and optionally edits it)
  /// and presses "send" in editing state. Required when [enableVoiceToText]
  /// is true and the user reaches the editing state.
  final ValueChanged<String>? onSendText;

  /// When true, recording state shows an additional convert-to-text button
  /// next to cancel; releasing on it triggers voice-to-text conversion.
  final bool enableVoiceToText;

  /// Manager that performs upload + voice-to-text conversion. Defaults to a
  /// real [AiMediaProcessManager] backed by SDK experimental APIs; tests can
  /// inject a fake.
  final AiMediaProcessManager? mediaProcessManager;

  /// Optional: provide these when the overlay lives inside an [OverlayEntry],
  /// where the normal InheritedWidget lookup would fail.
  final SemanticColorScheme? colorScheme;
  final ChatLocalizations? chatLocalizations;

  const AudioRecordOverlay({
    super.key,
    required this.onRecordFinish,
    required this.onRecordCancelled,
    this.onSendText,
    this.enableVoiceToText = false,
    this.mediaProcessManager,
    this.colorScheme,
    this.chatLocalizations,
  });

  @override
  State<AudioRecordOverlay> createState() => AudioRecordOverlayState();
}

class AudioRecordOverlayState extends State<AudioRecordOverlay>
    with TickerProviderStateMixin {
  late AudioRecorder _audioRecorder;
  late AnimationController _waveAnimationController;
  late AnimationController _dotsAnimationController;
  late AiMediaProcessManager _mediaProcessManager;

  _OverlayState _state = _OverlayState.recording;
  bool _isRecording = false;
  bool _isFingerOverCancel = false;
  bool _isFingerOverConvert = false;
  int _recordingDurationMs = 0;

  /// File path of the recorded audio file. Captured when [stopRecordAndConvert]
  /// finishes the recording so we can later "send original voice" from the
  /// editing state without re-recording.
  String? _capturedRecordPath;
  int _capturedRecordDurationSec = 0;

  /// Editing-state text controller. Created lazily when entering editing.
  TextEditingController? _editingController;

  /// Editing-state focus node. Initially does NOT request focus (so the
  /// keyboard stays hidden in the preview sub-state). When the user taps
  /// the text bubble, focus is requested and the bubble switches to its
  /// "active editing" appearance (blue bg + white text + waveform hidden).
  FocusNode? _editingFocusNode;

  /// First ASR transcription text — the immutable source for translation.
  /// Switching languages always translates from this, never from a prior
  /// translation, to avoid cumulative information loss.
  String _asrOriginalText = '';

  /// Current translated text; null when not translated (or translation undone).
  String? _translatedText;

  /// True while a translate request is in flight.
  bool _isTranslating = false;

  /// True while the editing-state "read aloud" TTS playback is active.
  bool _isPlayingTts = false;

  /// Lazily-created TTS helper, reusing [_mediaProcessManager].
  TtsPlaybackHelper? _ttsHelper;

  /// Translate target languages offered in the record-translation selector.
  /// Codes must match the IMSDK text-translation backend contract. Notably
  /// Traditional Chinese is `zh-TR`, NOT the more common BCP-47 `zh-TW` —
  /// the latter is rejected by the backend.
  static const List<Map<String, String>> _translateLanguageOptions = [
    {"code": "zh", "name": "简体中文"},
    {"code": "zh-TR", "name": "繁體中文"},
    {"code": "en", "name": "English"},
    {"code": "ja", "name": "日本語"},
    {"code": "ko", "name": "한국어"},
    {"code": "fr", "name": "Français"},
    {"code": "es", "name": "Español"},
    {"code": "it", "name": "Italiano"},
    {"code": "de", "name": "Deutsch"},
    {"code": "tr", "name": "Türkçe"},
    {"code": "ru", "name": "Русский"},
    {"code": "pt", "name": "Português"},
    {"code": "vi", "name": "Tiếng Việt"},
    {"code": "id", "name": "Bahasa Indonesia"},
    {"code": "th", "name": "ภาษาไทย"},
    {"code": "ms", "name": "Bahasa Melayu"},
  ];

  /// Max recording duration in seconds
  static const int _maxDurationSec = 60;

  /// Countdown threshold in seconds (show countdown in last N seconds)
  static const int _countdownThresholdSec = 10;

  /// Horizontal padding for the converting / editing / error panel content.
  /// Larger than the recording-state padding to give the bubble + buttons
  /// some breathing room near the screen edges.
  static const double _kPanelHPadding = 40.0;

  /// Vertical gap between the bubble (text/dots/error) and the three-button
  /// row in the converting / editing / error states.
  static const double _kBubbleToButtonsGap = 40.0;

  /// Distance from the right edge of the panel content (i.e., from the
  /// right edge of the bubble — they align by virtue of using the same
  /// horizontal padding) to the horizontal CENTER of the "send" button.
  /// Used to position the bubble's downward arrow so it points at the
  /// send button's circle. Send circle is 70 wide → its center sits at
  /// 35px from the row's right edge.
  static const double _kSendButtonCenterFromRight = 35.0;

  final GlobalKey _cancelButtonKey = GlobalKey();
  final GlobalKey _convertButtonKey = GlobalKey();

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

    // Three-dot pulse: 1.2s loop is comfortable.
    _dotsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _audioRecorder = AudioRecorder();
    _audioRecorder.initialize(
      onProgressUpdate: _onProgressUpdate,
      onStateChanged: _onStateChanged,
    );

    _mediaProcessManager =
        widget.mediaProcessManager ?? AiMediaProcessManager();
  }

  @override
  void dispose() {
    _waveAnimationController.removeListener(_updateWaveHeights);
    _waveAnimationController.dispose();
    _dotsAnimationController.dispose();
    _audioRecorder.cancelRecord();
    _audioRecorder.dispose();
    _ttsHelper?.stop();
    _editingController?.dispose();
    _editingFocusNode?.dispose();
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

  // ---------------------------------------------------------------------------
  // Public API consumed by the parent MessageInput
  // ---------------------------------------------------------------------------

  Future<void> startRecord({required String filePath}) async {
    await _audioRecorder.startRecord(
      filePath: filePath,
      onComplete: (recordInfo) {
        if (recordInfo != null) {
          if (recordInfo.errorCode == AudioRecordResultCode.errorLessThanMinDuration && mounted) {
            final chatLocalizations = widget.chatLocalizations ?? ChatLocalizations.of(context);
            Toast.warning(context, chatLocalizations.sayTimeShort);
          }
          if (recordInfo.errorCode == AudioRecordResultCode.successExceedMaxDuration && mounted) {
            final chatLocalizations = widget.chatLocalizations ?? ChatLocalizations.of(context);
            Toast.warning(context, chatLocalizations.recordLimitTips);
          }
          widget.onRecordFinish(recordInfo);
        }
      },
    );
  }

  /// Stop recording and send the audio as a voice message (legacy
  /// release-to-send path).
  void stopRecord() {
    _audioRecorder.stopRecord();
  }

  /// Production entry point: parent intercepts the record-finish callback
  /// and calls this with the captured file path + duration to drive the
  /// converting state machine. Implementation detail (see design.md):
  /// the parent `MessageInput` shows the overlay with `enableVoiceToText:
  /// true`, and when the user releases on the convert button, calls
  /// `_audioRecorder.stopRecord` then routes the resulting [RecordInfo] here
  /// instead of sending it as a voice message.
  void enterConverting(String filePath, int durationSec) {
    if (!mounted) return;
    _capturedRecordPath = filePath;
    _capturedRecordDurationSec = durationSec;
    setState(() {
      _state = _OverlayState.converting;
    });
    _dotsAnimationController.repeat();
    _runConversion(filePath);
  }

  /// Test-only convenience: same as [enterConverting] but with a default
  /// duration. Tests use this to skip the actual recording lifecycle.
  @visibleForTesting
  void enterConvertingForTest(String filePath) {
    enterConverting(filePath, 1);
  }

  Future<void> _runConversion(String filePath) async {
    final result = await _mediaProcessManager.convert(filePath);
    if (!mounted) return;

    if (result is AiAsrSuccess && result.text.isNotEmpty) {
      // Cache the original transcription and reset translation/TTS state for
      // this new editing session.
      _asrOriginalText = result.text;
      _translatedText = null;
      _isTranslating = false;
      _isPlayingTts = false;
      final controller = TextEditingController(text: result.text);
      controller.selection = TextSelection.collapsed(offset: result.text.length);
      _editingController?.dispose();
      _editingController = controller;
      // FocusNode is initially NOT focused: editing state opens in
      // "preview" sub-state (gray bubble, no keyboard, waveform visible).
      // The user must tap the text bubble to start editing.
      _editingFocusNode?.dispose();
      final focusNode = FocusNode()..addListener(_onEditingFocusChanged);
      _editingFocusNode = focusNode;
      setState(() {
        _state = _OverlayState.editing;
      });
      _dotsAnimationController.stop();
      _dotsAnimationController.reset();
      // Force a rebuild so listeners on the controller update the
      // send-button enabled state.
      controller.addListener(_onEditingTextChanged);
    } else {
      setState(() {
        _state = _OverlayState.error;
      });
      _dotsAnimationController.stop();
      _dotsAnimationController.reset();
    }
  }

  void _onEditingTextChanged() {
    if (mounted) setState(() {});
  }

  /// Triggered whenever the editing TextField gains/loses focus. We listen
  /// to it so the parent panel can re-layout (`AnimatedPadding`) when the
  /// keyboard pops up / is dismissed.
  void _onEditingFocusChanged() {
    if (mounted) setState(() {});
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
        _isFingerOverConvert = false;
        _state = _OverlayState.recording;
        _capturedRecordPath = null;
        _capturedRecordDurationSec = 0;
        _editingController?.removeListener(_onEditingTextChanged);
        _editingController?.dispose();
        _editingController = null;
        _editingFocusNode?.removeListener(_onEditingFocusChanged);
        _editingFocusNode?.dispose();
        _editingFocusNode = null;
        _asrOriginalText = '';
        _translatedText = null;
        _isTranslating = false;
        _isPlayingTts = false;
        _ttsHelper?.stop();
      });
    }
  }

  /// Check if a global position is over the cancel button
  bool isPointerOverCancelButton(Offset globalPosition) {
    return _isPointerOverButton(_cancelButtonKey, globalPosition);
  }

  /// Check if a global position is over the convert-to-text button.
  /// Always returns false when [AudioRecordOverlay.enableVoiceToText] is false
  /// or the convert button hasn't been laid out yet.
  bool isPointerOverConvertButton(Offset globalPosition) {
    if (!widget.enableVoiceToText) return false;
    return _isPointerOverButton(_convertButtonKey, globalPosition);
  }

  bool _isPointerOverButton(GlobalKey key, Offset globalPosition) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
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

  /// Update finger position (called from parent's pointer move handler).
  /// Updates both cancel and convert hover flags. Only effective in the
  /// recording state (after recording finishes, the gesture is over).
  void updatePointerPosition(Offset globalPosition) {
    if (!_isRecording || _state != _OverlayState.recording) return;
    final isOverCancel = isPointerOverCancelButton(globalPosition);
    // Cancel and convert are mutually exclusive (can't be on both at once),
    // and cancel takes precedence if buttons accidentally overlap.
    final isOverConvert =
        !isOverCancel && isPointerOverConvertButton(globalPosition);
    if (isOverCancel != _isFingerOverCancel ||
        isOverConvert != _isFingerOverConvert) {
      setState(() {
        _isFingerOverCancel = isOverCancel;
        _isFingerOverConvert = isOverConvert;
      });
    }
  }

  int get _remainingSeconds {
    final elapsed = (_recordingDurationMs / 1000).floor();
    return _maxDurationSec - elapsed;
  }

  bool get _showCountdown => _remainingSeconds <= _countdownThresholdSec && _isRecording;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme ?? BaseThemeProvider.colorsOf(context);
    final chatLocale = widget.chatLocalizations ?? ChatLocalizations.of(context);

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

        // Bottom-aligned content panel — content varies by state.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomPanel(colorScheme, chatLocale),
        ),

        // Error state overlays a tap-anywhere catcher across the full screen.
        if (_state == _OverlayState.error) _buildErrorTapCatcher(),
      ],
    );
  }

  Widget _buildBottomPanel(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    // viewInsets.bottom > 0 means the soft keyboard is up. Lift the entire
    // overlay panel above the keyboard so the bubble + buttons remain
    // visible while the user edits the converted text.
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final liftedAboveKeyboard = keyboardInset > 0;
    Widget content;
    switch (_state) {
      case _OverlayState.recording:
        content = _buildRecording(colorScheme, chatLocale);
        break;
      case _OverlayState.converting:
        content = _buildConverting(colorScheme, chatLocale);
        break;
      case _OverlayState.editing:
        content = _buildEditing(colorScheme, chatLocale);
        break;
      case _OverlayState.error:
        content = _buildError(colorScheme, chatLocale);
        break;
    }
    // NOTE: Do NOT wrap with AnimatedPadding — `viewInsets.bottom` is already
    // updated continuously by the framework in sync with the system keyboard
    // animation (iOS in particular). Layering an AnimatedPadding on top adds
    // a second easing curve, making the panel visibly lag behind the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        color: colorScheme.bgColorOperate,
        padding: EdgeInsets.only(
          // When keyboard is up the safe-area is irrelevant (keyboard already
          // covers it), so collapse padding to 0 to avoid extra empty space.
          bottom: liftedAboveKeyboard ? 0 : bottomPadding,
        ),
        child: content,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // recording state
  // ---------------------------------------------------------------------------

  Widget _buildRecording(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _buildHintText(colorScheme, chatLocale),
        const SizedBox(height: 16),
        _buildRecordingButtonsRow(colorScheme, chatLocale),
        const SizedBox(height: 16),
        _buildWaveformBar(colorScheme),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRecordingButtonsRow(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    final cancelBtn = _buildCancelButton(colorScheme, chatLocale);
    if (!widget.enableVoiceToText) {
      // Single button centered (legacy behavior).
      return Center(child: cancelBtn);
    }
    final convertBtn = _buildConvertButton(colorScheme, chatLocale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [cancelBtn, convertBtn],
    );
  }

  /// Full-width rounded waveform bar at the bottom of the overlay.
  /// Normal: blue/primary background. Cancel hover: red background.
  Widget _buildWaveformBar(SemanticColorScheme colorScheme) {
    final barColor = _isFingerOverCancel
        ? colorScheme.textColorError
        : colorScheme.buttonColorPrimaryDefault;

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
            final animatedHeight =
                _isRecording ? baseHeight * _waveHeights[index] : baseHeight * 0.3;

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

  Widget _buildHintText(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    String hintText;

    if (_showCountdown) {
      hintText = chatLocale.recordCountdownTips(_remainingSeconds);
    } else if (_isFingerOverCancel) {
      hintText = chatLocale.releaseToCancel;
    } else if (_isFingerOverConvert) {
      hintText = chatLocale.releaseToConvert;
    } else {
      hintText = chatLocale.releaseToSend;
    }

    return Text(
      hintText,
      style: FontScheme.caption2Regular.copyWith(
        color: colorScheme.textColorSecondary,
        decoration: TextDecoration.none,
      ),
    );
  }

  /// Circular cancel button.
  /// Normal: light gray bg + dark text, no border.
  /// Cancel hover: red bg + white text.
  Widget _buildCancelButton(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    final isHover = _isFingerOverCancel;
    final bgColor =
        isHover ? colorScheme.textColorError : colorScheme.buttonColorSecondaryDefault;
    final textColor =
        isHover ? colorScheme.textColorButton : colorScheme.textColorPrimary;

    return AnimatedContainer(
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
          chatLocale.cancel,
          key: const Key('vtt_cancel_button'),
          style: FontScheme.caption1Medium.copyWith(
            color: textColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  /// Circular convert-to-text button.
  /// Normal: light gray bg + dark text.
  /// Hover: primary bg + white text.
  Widget _buildConvertButton(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    final isHover = _isFingerOverConvert;
    final bgColor = isHover
        ? colorScheme.buttonColorPrimaryDefault
        : colorScheme.buttonColorSecondaryDefault;
    final textColor =
        isHover ? colorScheme.textColorButton : colorScheme.textColorPrimary;

    return AnimatedContainer(
      key: _convertButtonKey,
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          chatLocale.convertToText,
          key: const Key('vtt_convert_button'),
          textAlign: TextAlign.center,
          style: FontScheme.caption1Medium.copyWith(
            color: textColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // converting state
  // ---------------------------------------------------------------------------

  Widget _buildConverting(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPanelHPadding),
          child: _BubbleWithArrow(
            color: colorScheme.buttonColorPrimaryDefault,
            arrowRightOffset: _kSendButtonCenterFromRight,
            child: _ConvertingBubbleContent(
              key: const Key('vtt_converting_dots'),
              controller: _dotsAnimationController,
              dotColor: colorScheme.textColorButton,
            ),
          ),
        ),
        const SizedBox(height: _kBubbleToButtonsGap),
        // Buttons remain visible (Figma 1826-5936) but ignore taps.
        IgnorePointer(
          child: _buildEditingButtonsRow(
            colorScheme,
            chatLocale,
            disabled: true,
          ),
        ),
        const SizedBox(height: 16),
        // The static gray waveform bar is shown from the moment conversion
        // starts and stays through the editing state, providing visual
        // continuity with the recording state.
        _buildPreviewWaveformBar(colorScheme),
        const SizedBox(height: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // editing state
  // ---------------------------------------------------------------------------

  Widget _buildEditing(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    final controller = _editingController!;
    final focusNode = _editingFocusNode!;
    // Per Figma: bubble is ALWAYS blue with white text (independent of focus
    // state). The only thing focus changes is whether the keyboard is up.
    final bubbleColor = colorScheme.buttonColorPrimaryDefault;
    final textColor = colorScheme.textColorButton;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPanelHPadding),
          child: _BubbleWithArrow(
            color: bubbleColor,
            arrowRightOffset: _kSendButtonCenterFromRight,
            child: Container(
              constraints: const BoxConstraints(minHeight: 70, maxHeight: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // Tapping anywhere on the bubble (including padding) requests
              // focus, which raises the keyboard.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!focusNode.hasFocus) {
                    focusNode.requestFocus();
                  }
                },
                // Override the inherited TextSelectionTheme so the cursor,
                // the iOS-style water-drop selection handle, and the
                // selection highlight all stay visible on the blue bubble
                // background (default handle color comes from the app's
                // primary color, which is the same blue as the bubble).
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: textColor,
                      selectionHandleColor: textColor,
                      selectionColor: textColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: TextField(
                    key: const Key('vtt_editing_textfield'),
                    controller: controller,
                    focusNode: focusNode,
                    // Do NOT autofocus: editing opens with the keyboard hidden.
                    // User taps the bubble to start editing.
                    autofocus: false,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    cursorColor: textColor,
                    // Suppress the collapsed-state handle entirely.
                    // Material draws a 45°-rotated square (looks like a
                    // water-drop / diamond) directly below the caret on
                    // tap, and iOS draws an actual oval water-drop — both
                    // are visually distracting on the blue bubble. Custom
                    // controls return SizedBox.shrink() for collapsed so
                    // only the white caret line stays. Long-press text
                    // selection still draws normal left/right handles.
                    selectionControls: _NoCollapsedHandleSelectionControls.instance,
                    // Disable the iOS-style magnifier (floating lens that
                    // appears under the finger while tapping/dragging the
                    // caret). It also looks like a "water-drop" on the
                    // bubble, and the user wants the editing area to show
                    // only a plain caret line.
                    magnifierConfiguration: TextMagnifierConfiguration.disabled,
                    style: FontScheme.caption1Regular.copyWith(
                      color: textColor,
                      decoration: TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTranslateChipRow(colorScheme),
        const SizedBox(height: 16),
        _buildEditingButtonsRow(colorScheme, chatLocale, disabled: false),
        const SizedBox(height: 16),
        // Static gray waveform bar is shown both before AND after the
        // keyboard pops up — the parent's AnimatedPadding lifts the entire
        // panel above the keyboard, so the bar stays visible at the bottom
        // of the panel rather than being hidden.
        _buildPreviewWaveformBar(colorScheme),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Static, evenly-sized waveform bar shown in the editing-preview
  /// sub-state. Per Figma: equal-height short vertical bars in a neutral
  /// gray color on a light gray rounded-rectangle background. Not animated
  /// since recording is over.
  Widget _buildPreviewWaveformBar(SemanticColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.bgColorInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_waveHeights.length, (_) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: 3,
                // Equal-height bars per Figma 1783-12707 design.
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.textColorTertiary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // editing state — translate / read-aloud chip row
  // ---------------------------------------------------------------------------

  /// Row of action chips shown between the text bubble and the three buttons.
  /// Before translation: a single "Translate" chip. After translation:
  /// "Undo Translation" / "Switch Language" / "Read Aloud" (or "Stop").
  Widget _buildTranslateChipRow(SemanticColorScheme colorScheme) {
    final chatLocale = ChatLocalizations.of(context);
    final List<Widget> children;
    if (_translatedText == null) {
      children = [
        _buildActionChip(
          colorScheme,
          label: chatLocale.voiceTranslate,
          onTap: _isTranslating ? null : _onTranslateTapped,
        ),
      ];
    } else {
      children = [
        _buildActionChip(
          colorScheme,
          label: chatLocale.voiceCancelTranslation,
          onTap: _onCancelTranslationTapped,
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          colorScheme,
          label: chatLocale.voiceSwitchLanguage,
          onTap: _isTranslating ? null : _onSwitchLanguageTapped,
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          colorScheme,
          label: _isPlayingTts
              ? chatLocale.voiceStopReadAloud
              : chatLocale.voiceReadAloud,
          onTap: _onReadAloudTapped,
        ),
      ];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPanelHPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildActionChip(
    SemanticColorScheme colorScheme, {
    required String label,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.buttonColorSecondaryDefault,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: FontScheme.caption2Regular.copyWith(
            color: disabled
                ? colorScheme.textColorDisable
                : colorScheme.textColorPrimary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Future<void> _onTranslateTapped() async {
    final config = VoiceMessageConfig.instance;
    // Refresh from local storage so a previously saved language survives an
    // app restart (the singleton's in-memory cache starts empty).
    await config.load();
    var lang = config.recordTranslateTargetLanguage;
    if (lang.isEmpty) {
      final picked = await _showLanguageSelector();
      if (picked == null) return;
      await config.setRecordTranslateTargetLanguage(picked);
      lang = picked;
    }
    await _translateTo(lang);
  }

  Future<void> _onSwitchLanguageTapped() async {
    final picked = await _showLanguageSelector();
    if (picked == null) return;
    await VoiceMessageConfig.instance.setRecordTranslateTargetLanguage(picked);
    await _translateTo(picked);
  }

  /// Always translates from [_asrOriginalText] (never from a prior translation).
  Future<void> _translateTo(String languageCode) async {
    if (!mounted) return;
    setState(() => _isTranslating = true);
    final result = await _mediaProcessManager.translateSingleText(
      text: _asrOriginalText,
      targetLanguage: languageCode,
    );
    if (!mounted) return;
    setState(() => _isTranslating = false);
    if (result.success && result.text != null && result.text!.isNotEmpty) {
      _translatedText = result.text;
      _setControllerText(result.text!);
      setState(() {});
    } else {
      Toast.error(context, ChatLocalizations.of(context).voiceTranslateFailed);
    }
  }

  void _onCancelTranslationTapped() {
    _translatedText = null;
    _setControllerText(_asrOriginalText);
    setState(() {});
  }

  void _setControllerText(String text) {
    final controller = _editingController;
    if (controller == null) return;
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _onReadAloudTapped() async {
    if (_isPlayingTts) {
      await _ttsHelper?.stop();
      if (mounted) setState(() => _isPlayingTts = false);
      return;
    }
    // Strip emoji so they aren't spoken.
    final text = sanitizeTextForTts(_editingController?.text ?? '');
    if (text.isEmpty) return;
    // Refresh selected voice from local storage (survives app restart).
    await VoiceMessageConfig.instance.load();
    _ttsHelper ??= TtsPlaybackHelper(service: _mediaProcessManager);
    setState(() => _isPlayingTts = true);
    await _ttsHelper!.speak(
      text: text,
      voiceId: VoiceMessageConfig.instance.selectedVoiceId,
      onComplete: () {
        if (mounted) setState(() => _isPlayingTts = false);
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isPlayingTts = false);
          Toast.error(context, ChatLocalizations.of(context).voiceTtsFailed);
        }
      },
    );
  }

  /// Language picker shown as an [OverlayEntry] so it renders ABOVE the audio
  /// record overlay (which itself lives in an OverlayEntry). A modal bottom
  /// sheet would be a Navigator route and appear behind the record panel.
  /// Returns the selected language code, or null when dismissed.
  Future<String?> _showLanguageSelector() async {
    final overlay = Overlay.of(context);
    final colorScheme =
        widget.colorScheme ?? BaseThemeProvider.colorsOf(context);
    final chatLocale = ChatLocalizations.of(context);
    final currentLang =
        VoiceMessageConfig.instance.recordTranslateTargetLanguage;

    final completer = Completer<String?>();
    late OverlayEntry entry;

    void close(String? result) {
      if (entry.mounted) entry.remove();
      if (!completer.isCompleted) completer.complete(result);
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        final mediaQuery = MediaQuery.of(overlayContext);
        return Stack(
          children: [
            // Dimming barrier; tap to dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => close(null),
                child: const ColoredBox(color: Colors.black54),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: colorScheme.bgColorOperate,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: mediaQuery.size.height * 0.6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            chatLocale.voiceSwitchLanguageSheetTitle,
                            style: FontScheme.caption2Regular.copyWith(
                              color: colorScheme.textColorSecondary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _translateLanguageOptions.length,
                            itemBuilder: (context, index) {
                              final option = _translateLanguageOptions[index];
                              final selected = currentLang == option['code'];
                              return InkWell(
                                onTap: () => close(option['code']),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Text(
                                    option['name'] ?? '',
                                    style: FontScheme.caption1Regular.copyWith(
                                      color: selected
                                          ? colorScheme.textColorLink
                                          : colorScheme.textColorPrimary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    return completer.future;
  }

  Widget _buildEditingButtonsRow(
    SemanticColorScheme colorScheme,
    ChatLocalizations chatLocale, {
    required bool disabled,
  }) {
    // Layout:
    // - Outer horizontal padding `_kPanelHPadding` keeps the row away from
    //   screen edges.
    // - The three buttons are spaced evenly via `MainAxisAlignment.spaceBetween`,
    //   so the gap between cancel↔sendOriginal matches sendOriginal↔send.
    // - Send button stays anchored to the right edge (same horizontal padding
    //   as the bubble), which keeps the bubble's downward arrow aligned with
    //   its center (`_kSendButtonCenterFromRight`).
    // - The send button's vertical center aligns with the small icon-circles'
    //   vertical centers (24px from the row top): 70/2 - 48/2 = 11px upward
    //   translation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPanelHPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallActionButton(
            key: const Key('vtt_btn_cancel'),
            label: chatLocale.cancel,
            iconAsset: 'chat_assets/icon/close_audio_record.svg',
            colorScheme: colorScheme,
            onTap: disabled ? null : _onEditingCancelTapped,
          ),
          _SmallActionButton(
            key: const Key('vtt_btn_send_original'),
            label: chatLocale.sendOriginalVoice,
            iconAsset: 'chat_assets/icon/send_origin_audio.svg',
            colorScheme: colorScheme,
            onTap: disabled ? null : _onSendOriginalTapped,
          ),
          Transform.translate(
            offset: const Offset(0, -11),
            child: _SendTextButton(
              key: const Key('vtt_btn_send_text'),
              label: chatLocale.send,
              colorScheme: colorScheme,
              enabled: !disabled && (_editingController?.text.trim().isNotEmpty ?? false),
              onTap: _onSendTextTapped,
            ),
          ),
        ],
      ),
    );
  }

  void _onEditingCancelTapped() {
    widget.onRecordCancelled();
  }

  void _onSendOriginalTapped() {
    final path = _capturedRecordPath;
    if (path == null) {
      widget.onRecordCancelled();
      return;
    }
    final info = RecordInfo(duration: _capturedRecordDurationSec, path: path)
      ..errorCode = AudioRecordResultCode.success;
    widget.onRecordFinish(info);
  }

  void _onSendTextTapped() {
    final controller = _editingController;
    if (controller == null) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText?.call(text);
  }

  // ---------------------------------------------------------------------------
  // error state
  // ---------------------------------------------------------------------------

  Widget _buildError(
      SemanticColorScheme colorScheme, ChatLocalizations chatLocale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPanelHPadding),
          child: _BubbleWithArrow(
            key: const Key('vtt_error_bubble'),
            color: colorScheme.textColorError,
            arrowRightOffset: _kSendButtonCenterFromRight,
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              alignment: Alignment.center,
              child: Text(
                chatLocale.voiceToTextFailed,
                style: FontScheme.caption1Regular.copyWith(
                  color: colorScheme.textColorButton,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: _kBubbleToButtonsGap),
        // Buttons present but inert.
        IgnorePointer(
          child: _buildEditingButtonsRow(
            colorScheme,
            chatLocale,
            disabled: true,
          ),
        ),
        const SizedBox(height: 16),
        // Match editing/converting: keep the gray waveform visible so the
        // overall layout remains consistent across the three end-states.
        _buildPreviewWaveformBar(colorScheme),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Full-screen tap catcher in error state. Any tap closes the overlay.
  Widget _buildErrorTapCatcher() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onRecordCancelled,
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// Rounded rectangle "bubble" with a downward-pointing triangle tail at
/// the bottom edge. The tail is positioned via [arrowRightOffset] which
/// measures the distance from the bubble's RIGHT edge to the tail's
/// horizontal center — used to make the tail point at the send button.
class _BubbleWithArrow extends StatelessWidget {
  const _BubbleWithArrow({
    super.key,
    required this.color,
    required this.arrowRightOffset,
    required this.child,
  });

  final Color color;
  final double arrowRightOffset;
  final Widget child;

  static const double _kArrowWidth = 14.0;
  static const double _kArrowHeight = 8.0;
  static const double _kRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bubble body.
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          child: child,
        ),
        // Downward triangle tail. `bottom: -arrowHeight` makes the tail
        // protrude below the bubble. `right` positions its center along
        // the bubble's bottom edge.
        Positioned(
          right: arrowRightOffset - _kArrowWidth / 2,
          bottom: -_kArrowHeight + 0.5, // 0.5px overlap to avoid hairline gap
          child: CustomPaint(
            size: const Size(_kArrowWidth, _kArrowHeight),
            painter: _BubbleArrowPainter(color: color),
          ),
        ),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  _BubbleArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Animated three-dot content used in the converting state. Each dot
/// pulses out of phase, producing a smooth left-to-right shimmer.
/// Wrapped in a [_BubbleWithArrow] by the caller so the bubble shape +
/// downward arrow are consistent with the editing/error bubbles.
class _ConvertingBubbleContent extends StatelessWidget {
  const _ConvertingBubbleContent({
    super.key,
    required this.controller,
    required this.dotColor,
  });

  final AnimationController controller;

  /// Base color for the three pulsing dots. Each dot's alpha is multiplied
  /// by a staggered brightness value to produce the shimmer effect.
  /// Caller passes `colorScheme.textColorButton` (white) so the dots stay
  /// theme-aware on the bubble's primary background.
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // Stagger each dot's brightness by 1/3 cycle.
              final phase = (controller.value + i / 3) % 1.0;
              final brightness = 0.3 + 0.7 * (1 - (phase * 2 - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: brightness),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Small circular button used for cancel / send-original in editing state.
/// 48x48 light-gray background with a centered SVG icon (20x20) and a
/// caption label rendered below the circle. Disabled when [onTap] is null.
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final SemanticColorScheme colorScheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final iconColor = disabled
        ? colorScheme.textColorDisable
        : colorScheme.textColorPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: disabled
                  ? colorScheme.buttonColorSecondaryDisabled
                  : colorScheme.buttonColorSecondaryDefault,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              package: 'tencent_chat_uikit',
              width: 20,
              height: 20,
              // Force-tint the icon so it's always visible regardless of
              // the SVG's intrinsic fill color (works around cases where
              // some SVG fills don't render reliably under OverlayEntry).
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: FontScheme.caption2Regular.copyWith(
              color: disabled
                  ? colorScheme.textColorDisable
                  : colorScheme.textColorSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary "send" button used in editing state. Sized so its bottom edge
/// aligns with the bottom of the small-action buttons' label text — i.e.,
/// total height matches `48 (circle) + 5 (gap) + ~17 (label) = 70`.
class _SendTextButton extends StatelessWidget {
  const _SendTextButton({
    super.key,
    required this.label,
    required this.colorScheme,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final SemanticColorScheme colorScheme;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: enabled
              ? colorScheme.buttonColorPrimaryDefault
              : colorScheme.buttonColorPrimaryDisabled,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: FontScheme.caption1Medium.copyWith(
            color: colorScheme.textColorButton,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Selection controls that behave like [MaterialTextSelectionControls] for
/// the left/right (active selection) handles but draw NOTHING for the
/// collapsed (no-selection) handle — i.e., when the caret is just blinking
/// after a tap, no diamond/water-drop is shown below it.
///
/// Background:
/// - On iOS, [CupertinoTextSelectionControls] paints an oval "water-drop"
///   handle below the caret in collapsed state.
/// - On Android (Material), the collapsed handle is a 45°-rotated square
///   that visually reads as a diamond / water-drop too.
/// Both look distracting on top of the editing bubble's blue background,
/// so we suppress them while keeping long-press selection fully usable.
class _NoCollapsedHandleSelectionControls extends MaterialTextSelectionControls {
  _NoCollapsedHandleSelectionControls._();

  static final _NoCollapsedHandleSelectionControls instance =
      _NoCollapsedHandleSelectionControls._();

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    if (type == TextSelectionHandleType.collapsed) {
      return const SizedBox.shrink();
    }
    return super.buildHandle(context, type, textHeight, onTap);
  }

  @override
  Offset getHandleAnchor(
    TextSelectionHandleType type,
    double textLineHeight,
  ) {
    if (type == TextSelectionHandleType.collapsed) {
      return Offset.zero;
    }
    return super.getHandleAnchor(type, textLineHeight);
  }
}
