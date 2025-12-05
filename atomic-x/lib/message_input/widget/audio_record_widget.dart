import 'dart:async';

import 'package:tuikit_atomic_x/audio_recoder/audio_recorder.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AudioRecordWidget extends StatefulWidget {
  final ValueChanged<RecordInfo> onRecordFinish;

  const AudioRecordWidget({
    super.key,
    required this.onRecordFinish,
  });

  @override
  State<AudioRecordWidget> createState() => AudioRecordWidgetState();
}

class AudioRecordWidgetState extends State<AudioRecordWidget> with SingleTickerProviderStateMixin {
  late SemanticColorScheme colorScheme;
  late AnimationController _shakeAnimationController;
  late AudioRecorder _audioRecorder;

  bool _isRecording = false;
  double _recordingProgress = 0.0;
  int _recordingDuration = 0;
  bool _isFingerOverDelete = false;

  PointerRoute? _pointerEventListener;
  final GlobalKey _trashIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _shakeAnimationController = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _audioRecorder = AudioRecorder();
    _audioRecorder.initialize(
      onProgressUpdate: _onProgressUpdate,
      onStateChanged: _onStateChanged,
    );
  }

  @override
  void dispose() {
    _shakeAnimationController.dispose();
    _audioRecorder.dispose();
    if (_pointerEventListener != null) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_pointerEventListener!);
      _pointerEventListener = null;
    }
    super.dispose();
  }

  void _onProgressUpdate(int duration, double progress) {
    if (mounted) {
      setState(() {
        _recordingDuration = duration;
        _recordingProgress = progress;
      });

      if (_audioRecorder.isMaxDurationReached()) {
        AtomicLocalizations atomicLocalizations = AtomicLocalizations.of(context);
        stopRecord();
        Toast.warning(context, atomicLocalizations.recordLimitTips);
      }
    }
  }

  void _onStateChanged(bool isRecording) {
    if (mounted) {
      setState(() {
        _isRecording = isRecording;
      });

      if (isRecording) {
        _shakeAnimationController.repeat(reverse: true);
        _addPointerEventListener();
      } else {
        _shakeAnimationController.stop();
        _shakeAnimationController.reset();
        _removePointerEventListener();
        _isFingerOverDelete = false;
      }
    }
  }

  Future<void> startRecord({required String filePath}) async {
    await _audioRecorder.startRecord(filePath: filePath);
  }

  Future<void> stopRecord() async {
    final recordInfo = await _audioRecorder.stopRecord();
    if (recordInfo != null) {
      if (recordInfo.errorCode == AudioRecordCode.tooShort && mounted) {
        AtomicLocalizations atomicLocalizations = AtomicLocalizations.of(context);
        Toast.warning(context, atomicLocalizations.sayTimeShort);
      }
      widget.onRecordFinish(recordInfo);
    }
  }

  Future<void> cancelRecord() async {
    await _audioRecorder.cancelRecord();
  }

  bool isPointerOverTrashIcon(Offset globalPosition) {
    final RenderBox? trashIconRenderBox = _trashIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (trashIconRenderBox == null) {
      return false;
    }

    return trashIconRenderBox.hitTest(BoxHitTestResult(), position: trashIconRenderBox.globalToLocal(globalPosition));
  }

  void _addPointerEventListener() {
    _pointerEventListener = (event) {
      if (event is PointerMoveEvent && _isRecording) {
        if (_trashIconKey.currentContext == null) {
          return;
        }

        final trashIconRenderBox = _trashIconKey.currentContext!.findRenderObject() as RenderBox;
        final trashIconOffset = trashIconRenderBox.localToGlobal(Offset.zero);
        final trashIconSize = trashIconRenderBox.size;
        final isOverDeleteIcon = event.position.dx >= trashIconOffset.dx &&
            event.position.dx <= trashIconOffset.dx + trashIconSize.width &&
            event.position.dy >= trashIconOffset.dy &&
            event.position.dy <= trashIconOffset.dy + trashIconSize.height;

        if (isOverDeleteIcon != _isFingerOverDelete) {
          setState(() {
            _isFingerOverDelete = isOverDeleteIcon;
          });

          if (_isFingerOverDelete) {
            _shakeAnimationController.repeat(reverse: true);
          } else {
            _shakeAnimationController.stop();
            _shakeAnimationController.reset();
          }
        }
      }
    };
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_pointerEventListener!);
  }

  void _removePointerEventListener() {
    if (_pointerEventListener != null) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(_pointerEventListener!);
      _pointerEventListener = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    colorScheme = BaseThemeProvider.colorsOf(context);
    return Container(
      color: colorScheme.bgColorInput,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            key: _trashIconKey,
            padding: const EdgeInsets.only(
              bottom: 8,
              right: 14,
              left: 8,
              top: 8,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isFingerOverDelete ? colorScheme.textColorError : BaseColors.transparent,
                border: _isFingerOverDelete
                    ? Border.all(color: colorScheme.textColorError, width: 12)
                    : Border.all(color: BaseColors.transparent, width: 0),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _isRecording
                      ? (_isFingerOverDelete ? colorScheme.textColorButton : colorScheme.buttonColorPrimaryDefault)
                      : BaseColors.transparent,
                  fontSize: _isFingerOverDelete ? 52 : 42,
                ),
                child: Text(
                  String.fromCharCode(Icons.delete.codePoint),
                  style: const TextStyle(fontFamily: 'MaterialIcons'),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _isRecording ? colorScheme.buttonColorPrimaryDefault : BaseColors.transparent,
                border: _isRecording
                    ? Border.all(color: colorScheme.buttonColorPrimaryDefault)
                    : Border.all(color: BaseColors.transparent),
                borderRadius: BorderRadius.circular(25),
              ),
              duration: const Duration(milliseconds: 50),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${((_recordingDuration ~/ 1000) ~/ 60).toString().padLeft(2, '0')}:${((_recordingDuration ~/ 1000) % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 14, color: colorScheme.textColorButton),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _recordingProgress,
                      backgroundColor: BaseColors.transparent,
                      color: colorScheme.textColorButton,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
