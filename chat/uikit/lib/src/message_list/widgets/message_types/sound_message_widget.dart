import 'package:atomic_x_core/api/message/message_action_store.dart';
import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tencent_chat_uikit/src/audio_player/audio_player.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';

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
  /// Optional override for bubble background color (used for highlight animation)
  final Color? bubbleColor;

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
    this.bubbleColor,
  });

  @override
  State<SoundMessageWidget> createState() => _SoundMessageWidgetState();
}

class _SoundMessageWidgetState extends State<SoundMessageWidget> with MessageStatusMixin {
  bool _isPlaying = false;
  bool _isDownloading = false;

  Duration _currentPosition = Duration.zero;

  late AudioPlayer _audioPlayer;

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
            _currentPosition = Duration.zero;
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

    // The ASR (voice → text) bubble used to be rendered here as a sibling
    // of the voice bubble inside a Column. That made the read-receipt
    // and status-icon (placed by MessageItem with
    // CrossAxisAlignment.end) drift to the bottom of the column whenever
    // the ASR bubble was present, see Bug-956459. The ASR bubble is now
    // built by `MessageAttachmentBuilder` and rendered by `MessageItem`
    // *outside* the row that holds the receipt — see
    // `lib/src/message_list/widgets/message_attachments.dart`.
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: Container(
        key: widget.bubbleKey,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
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
    );
  }

  void _handleTap() {
    widget.onTap?.call();
    _playSoundMessage();
  }

  Widget _buildSoundContent(SemanticColorScheme colorsTheme) {
    final int soundDuration = (widget.message.messagePayload as AudioMessagePayload?)?.audioDuration ?? 0;
    final Color contentColor =
        widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary;

    // The base asset points the waves to the right (received look). The sender's
    // bubble mirrors it so the waves point back toward the sender on the right.
    Widget soundIcon = SvgPicture.asset(
      'chat_assets/icon/sound.svg',
      package: 'tencent_chat_uikit',
      height: 18,
      colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
    );
    if (widget.isSelf) {
      soundIcon = Transform.flip(flipX: true, child: soundIcon);
    }

    final Widget durationText = Text(
      '${_isPlaying ? _currentPosition.inSeconds : soundDuration}"',
      style: FontScheme.caption3Medium.copyWith(color: contentColor),
    );

    final List<Widget> content = widget.isSelf
        ? [durationText, const SizedBox(width: 6), soundIcon]
        : [soundIcon, const SizedBox(width: 6), durationText];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...content,
        if (_isDownloading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _playSoundMessage() async {
    final soundPath = (widget.message.messagePayload as AudioMessagePayload?)?.audioPath;

    if (soundPath == null || soundPath.isEmpty || !File(soundPath).existsSync()) {
      if (widget.messageListStore != null && widget.message.rawMessage != null) {
        if (_audioPlayer.isPlaying) {
          await _audioPlayer.stop();
        }

        setState(() {
          _isDownloading = true;
        });

        await MessageActionStore.create(widget.message).downloadMedia();

        final newSoundPath = (widget.message.messagePayload as AudioMessagePayload?)?.audioPath;
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

    if (_isPlaying && soundPath == (widget.message.messagePayload as AudioMessagePayload?)?.audioPath) {
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

  Color _getBubbleColor(SemanticColorScheme colorsTheme) {
    if (widget.bubbleColor != null) return widget.bubbleColor!;
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() => MessageUtil.bubbleBorderRadius(
        alignment: widget.config.alignment,
        isSelf: widget.isSelf,
        radius: widget.config.textBubbleCornerRadius,
      );
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
