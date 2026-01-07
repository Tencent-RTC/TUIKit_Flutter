import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/audio_player/audio_player.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_status_mixin.dart';

class SoundMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;
  final GlobalKey? bubbleKey;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;
  // ASR related properties
  final bool isConverting;
  /// Whether the ASR text bubble is hidden in this session (default: false, meaning shown if asrText exists)
  final bool isAsrHidden;
  /// Callback when ASR bubble is long pressed, provides the GlobalKey for positioning popup menu
  final void Function(GlobalKey asrBubbleKey)? onAsrBubbleLongPress;

  const SoundMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onTap,
    this.onLongPress,
    this.messageListStore,
    this.bubbleKey,
    this.isInMergedDetailView = false,
    this.isConverting = false,
    this.isAsrHidden = false,
    this.onAsrBubbleLongPress,
  });

  @override
  State<SoundMessageWidget> createState() => _SoundMessageWidgetState();
}

class _SoundMessageWidgetState extends State<SoundMessageWidget> with MessageStatusMixin {
  bool _isPlaying = false;
  bool _isDownloading = false;

  Duration _currentPosition = Duration.zero;

  late AudioPlayer _audioPlayer;

  // GlobalKey for ASR text bubble positioning
  final GlobalKey _asrBubbleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer.createInstance().setListener(_AudioPlayerListenerImpl(
      onProgressUpdate: (currentPosition, duration) {
        if (mounted && _isPlaying) {
          setState(() {
            _currentPosition = Duration(milliseconds: currentPosition);
          });
        }
      },
      onCompletion: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      },
      onError: (errorMessage) {
        debugPrint('Audio player error: $errorMessage');
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      },
    ));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    final statusAndTimeWidgets = buildStatusAndTimeWidgets(
      message: widget.message,
      isSelf: widget.isSelf,
      colors: colors,
      isShowTimeInBubble: widget.config.isShowTimeInBubble,
      enableReadReceipt: widget.config.enableReadReceipt,
      isInMergedDetailView: widget.isInMergedDetailView,
    );

    final bool hasAsrText = widget.message.messageBody?.asrText?.isNotEmpty == true;
    // Show ASR bubble when: converting OR (has asrText AND not hidden in this session)
    final bool shouldShowAsrBubble = widget.isConverting || (hasAsrText && !widget.isAsrHidden);

    return Column(
      crossAxisAlignment: widget.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Voice message bubble
        GestureDetector(
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          child: Container(
            key: widget.bubbleKey,
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth * 0.7,
            ),
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: _getBubbleColor(colors),
              borderRadius: _getBubbleBorderRadius(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: widget.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildSoundContent(colors),
                if (statusAndTimeWidgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: statusAndTimeWidgets,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // ASR text bubble (shown when converting or when converted and expanded)
        if (shouldShowAsrBubble) _buildAsrTextBubble(colors),
      ],
    );
  }

  void _handleTap() {
    widget.onTap?.call();
    _playSoundMessage();
  }

  Widget _buildSoundContent(SemanticColorScheme colorsTheme) {
    final int soundDuration = widget.message.messageBody?.soundDuration ?? 0;

    return Container(
      width: 160,
      child: Row(
        children: [
          Icon(
            widget.isSelf ? Icons.volume_up : Icons.volume_down,
            color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                8,
                (index) {
                  final height = 4.0 + (index % 3) * 4.0;
                  final isActive = _isPlaying && (index % 2 == 0);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 2,
                    height: isActive ? height * 1.5 : height,
                    decoration: BoxDecoration(
                      color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPlaying ? _formatDuration(_currentPosition.inSeconds) : _formatDuration(soundDuration),
            style: TextStyle(
              fontSize: 12,
              color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _playSoundMessage() async {
    final soundPath = widget.message.messageBody?.soundPath;

    if (soundPath == null || soundPath.isEmpty || !File(soundPath).existsSync()) {
      if (widget.messageListStore != null && widget.message.rawMessage != null) {
        if (_audioPlayer.isPlaying) {
          await _audioPlayer.stop();
        }

        setState(() {
          _isDownloading = true;
        });

        await widget.messageListStore!.downloadMessageResource(
          message: widget.message,
          resourceType: MessageMediaFileType.sound,
        );

        final newSoundPath = widget.message.messageBody?.soundPath;
        if (newSoundPath != null && newSoundPath.isNotEmpty && File(newSoundPath).existsSync()) {
          setState(() {
            _isDownloading = false;
          });

          setState(() {
            _isPlaying = true;
          });

          try {
            await _audioPlayer.play(newSoundPath);
          } catch (e) {
            debugPrint('play sound failed: $e');
            setState(() {
              _isPlaying = false;
            });
          }
        } else {
          setState(() {
            _isDownloading = false;
          });
        }
        return;
      }
      return;
    }

    if (_isPlaying && soundPath == widget.message.messageBody?.soundPath) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    if (_audioPlayer.isPlaying) {
      await _audioPlayer.stop();
    }

    setState(() {
      _isPlaying = true;
    });

    try {
      await _audioPlayer.play(soundPath);
    } catch (e) {
      debugPrint('play sound failed: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getBubbleColor(SemanticColorScheme colorsTheme) {
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    if (widget.isSelf) {
      return const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(0),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(18),
      );
    }
  }

  /// Build the ASR text bubble widget
  Widget _buildAsrTextBubble(SemanticColorScheme colors) {
    return GestureDetector(
      onLongPress: widget.isConverting ? null : () {
        widget.onAsrBubbleLongPress?.call(_asrBubbleKey);
      },
      child: Container(
        key: _asrBubbleKey,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth * 0.7,
        ),
        decoration: BoxDecoration(
          color: _getBubbleColor(colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.isConverting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary,
                  ),
                ),
              )
            : Text(
                widget.message.messageBody?.asrText ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isSelf ? colors.textColorAntiPrimary : colors.textColorPrimary,
                ),
              ),
      ),
    );
  }
}

class _AudioPlayerListenerImpl extends AudioPlayerListener {
  final Function(int currentPosition, int duration)? _onProgressUpdate;
  final VoidCallback? _onCompletion;
  final Function(String errorMessage)? _onError;

  _AudioPlayerListenerImpl({
    Function(int currentPosition, int duration)? onProgressUpdate,
    VoidCallback? onCompletion,
    Function(String errorMessage)? onError,
  })  : _onProgressUpdate = onProgressUpdate,
        _onCompletion = onCompletion,
        _onError = onError;

  @override
  void onProgressUpdate(int currentPosition, int duration) {
    _onProgressUpdate?.call(currentPosition, duration);
  }

  @override
  void onCompletion() {
    _onCompletion?.call();
  }

  @override
  void onError(String errorMessage) {
    _onError?.call(errorMessage);
  }
}
