import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide AlertDialog;

/// Voice clone page: record a short clip and submit it for cloning.
class VoiceClonePage extends StatefulWidget {
  const VoiceClonePage({super.key});

  @override
  State<VoiceClonePage> createState() => _VoiceClonePageState();
}

class _VoiceClonePageState extends State<VoiceClonePage> {
  /// Minimum acceptable clip length for cloning.
  static const int _minCloneSeconds = 3;

  /// Maximum clip length; recording auto-stops when reached.
  static const int _maxCloneSeconds = 30;

  /// Number of bars in the live waveform.
  static const int _waveformBars = 28;

  late final AudioRecorder _recorder;
  bool _isRecording = false;
  int _durationMs = 0;
  String? _recordedPath;
  bool _submitting = false;
  final TextEditingController _nameController = TextEditingController();

  /// Per-bar amplitudes (0..1) for the waveform. The TXUGC recorder does not
  /// expose microphone volume, so the waveform is driven by a random animation
  /// while recording instead of real audio levels.
  final List<double> _amplitudes = List<double>.filled(_waveformBars, 0.0);
  Timer? _waveformTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _recorder.initialize(
      onProgressUpdate: (durationMs, _) {
        if (mounted) setState(() => _durationMs = durationMs);
      },
      onStateChanged: (recording) {
        if (!mounted) return;
        setState(() => _isRecording = recording);
        if (recording) {
          _startWaveform();
        } else {
          _stopWaveform();
        }
      },
    );
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _recorder.cancelRecord();
    _recorder.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startWaveform() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _amplitudes.length; i++) {
          final target = 0.2 + _random.nextDouble() * 0.8;
          _amplitudes[i] = _amplitudes[i] + (target - _amplitudes[i]) * 0.6;
        }
      });
    });
  }

  void _stopWaveform() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
    if (mounted) {
      setState(() {
        for (var i = 0; i < _amplitudes.length; i++) {
          _amplitudes[i] = 0.0;
        }
      });
    }
  }

  String get _formattedDuration {
    final totalSec = (_durationMs / 1000).floor();
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      _recorder.stopRecord();
      return;
    }
    final status = await Permission.check(PermissionType.microphone);
    if (status != PermissionStatus.granted) {
      if (mounted) {
        await Permission.checkAndRequest(context, [PermissionType.microphone]);
      }
      return;
    }
    final path = ChatUtil.generateMediaPath(
      messageType: MessageType.audio,
      prefix: 'voice_clone_',
      withExtension: 'wav',
      isCache: true,
    );
    setState(() {
      _recordedPath = null;
      _durationMs = 0;
    });
    _recorder.startRecord(
      filePath: path,
      maxDurationMs: _maxCloneSeconds * 1000,
      onComplete: (info) {
        if (!mounted) return;
        final isSuccess = info != null &&
            (info.errorCode == AudioRecordResultCode.success ||
                info.errorCode == AudioRecordResultCode.successExceedMaxDuration) &&
            info.path.isNotEmpty;
        if (isSuccess && info.duration >= _minCloneSeconds) {
          setState(() => _recordedPath = info.path);
        } else {
          setState(() => _recordedPath = null);
          _showTooShortDialog();
        }
      },
    );
  }

  Future<void> _showTooShortDialog() async {
    final chatLocale = ChatLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(chatLocale.voiceCloneTooShortTitle),
        content: Text(chatLocale.voiceCloneTooShortMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(chatLocale.voiceConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final chatLocale = ChatLocalizations.of(context);
    if (_recordedPath == null) {
      Toast.warning(context, chatLocale.voiceCloneEmptyRecord);
      return;
    }
    final inputName = _nameController.text.trim();
    final voiceName =
        inputName.isEmpty ? chatLocale.voiceCloneDefaultName : inputName;
    setState(() => _submitting = true);
    final result = await AiMediaProcessManager.shared.voiceCloneFromFile(
      filePath: _recordedPath!,
      voiceName: voiceName,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success && result.voiceId != null) {
      // Auto-select the freshly cloned voice.
      await VoiceMessageConfig.instance
          .setSelectedVoice(voiceId: result.voiceId!, name: voiceName);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(chatLocale.voiceCloneSuccessTitle),
          content: Text(chatLocale.voiceCloneSuccessMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(chatLocale.voiceConfirm),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      Toast.error(context, chatLocale.voiceCloneFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final chatLocale = ChatLocalizations.of(context);
    final canSubmit = _recordedPath != null && !_submitting;

    return Scaffold(
      backgroundColor: colors.bgColorInput,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: chatLocale.voiceClone,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 1),
        color: colors.bgColorOperate,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              chatLocale.voiceCloneTip,
              textAlign: TextAlign.center,
              style: FontScheme.caption3Regular.copyWith(
                color: colors.textColorSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              chatLocale.voiceCloneReadingTipTitle,
              textAlign: TextAlign.center,
              style: FontScheme.caption2Medium.copyWith(
                color: colors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '“${chatLocale.voiceCloneSampleText}”',
              textAlign: TextAlign.center,
              style: FontScheme.caption2Regular.copyWith(
                color: colors.textColorPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildWaveform(colors),
            const SizedBox(height: 12),
            Text(
              _formattedDuration,
              textAlign: TextAlign.center,
              style: FontScheme.title4Bold.copyWith(
                color: colors.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _toggleRecord,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? colors.textColorError
                        : colors.buttonColorPrimaryDefault,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: colors.textColorButton,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? chatLocale.voiceCloneStopRecord
                  : (_recordedPath != null
                      ? chatLocale.voiceCloneRecordDone
                      : chatLocale.voiceCloneStartRecord),
              textAlign: TextAlign.center,
              style: FontScheme.caption3Regular.copyWith(
                color: colors.textColorSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              chatLocale.voiceCloneAuthTip,
              style: FontScheme.caption4Regular.copyWith(
                color: colors.textColorTertiary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: FontScheme.caption1Regular.copyWith(
                color: colors.textColorPrimary,
              ),
              decoration: InputDecoration(
                hintText: chatLocale.voiceCloneNameHint,
                hintStyle: FontScheme.caption1Regular.copyWith(
                  color: colors.textColorTertiary,
                ),
                filled: true,
                fillColor: colors.bgColorInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonColorPrimaryDefault,
                  disabledBackgroundColor: colors.buttonColorPrimaryDisabled,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors.textColorButton),
                        ),
                      )
                    : Text(
                        chatLocale.voiceCloneSubmit,
                        style: FontScheme.caption1Medium.copyWith(
                          color: colors.textColorButton,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Live waveform bar; amplitude reflects the recorded volume when available.
  /// Bars are always blue and centered (with side gaps, not edge-to-edge).
  Widget _buildWaveform(SemanticColorScheme colors) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgColorInput,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_waveformBars, (i) {
          final amp = _amplitudes[i];
          final height = _isRecording ? (4.0 + amp * 28.0) : 4.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3,
              height: height.clamp(4.0, 32.0),
              decoration: BoxDecoration(
                color: colors.buttonColorPrimaryDefault,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}
