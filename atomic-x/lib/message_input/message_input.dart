import 'dart:async';

import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/message_input/src/chat_special_text_span_builder.dart';
import 'package:tuikit_atomic_x/video_recorder/video_recorder.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../album_picker/album_picker.dart';
import '../audio_recoder/audio_recorder.dart';
import '../emoji_picker/emoji_picker.dart';
import '../file_picker/file_picker.dart';
import '../permission/permission.dart';
import 'message_input_config.dart';
import 'widget/audio_record_widget.dart';

class MessageInput extends StatefulWidget {
  final String conversationID;
  final MessageInputConfigProtocol config;

  const MessageInput({
    super.key,
    required this.conversationID,
    this.config = const ChatMessageInputConfig(),
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with TickerProviderStateMixin {
  late MessageInputStore _messageInputStore;
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textEditingFocusNode = FocusNode();
  Widget stickerWidget = Container();

  late AtomicLocalizations atomicLocale;
  late LocaleProvider localeProvider;

  Timer? _recordingStarter;
  bool _isWaitingToStartRecord = false;
  final bool _isEmojiPickerExist = true;
  bool _showSendButton = false;
  bool _showEmojiPanel = false;
  bool _showMorePanel = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey<AudioRecordWidgetState> _recordingWidgetKey = GlobalKey();

  double? _bottomPadding;

  final GlobalKey<TooltipState> _micTooltipKey = GlobalKey<TooltipState>();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _messageInputStore = MessageInputStore.create(conversationID: widget.conversationID);
    _textEditingController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textEditingController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) {
      setState(() {
        _showSendButton = hasText;
      });
    }
  }

  void _onEmojiClicked(Map<String, dynamic> data) {
    if (data.containsKey("eventType")) {
      if (data["eventType"] == "stickClick") {
        if (data["type"] == 0) {
          var space = "";
          if (_textEditingController.text == "") {
            space = " ";
          }
          _textEditingController.text = "$space${_textEditingController.text}${data["name"]}";
        }
      }
    }
  }

  void _onDeleteClick() {
    final text = _textEditingController.text;
    if (text.isEmpty) return;

    final cursorPos = _textEditingController.selection.baseOffset;
    final targetPos = cursorPos == -1 ? text.length : cursorPos;

    final deletedText = _deleteEmojiOrCharacter(text, targetPos);
    if (deletedText != text) {
      final deletedLength = text.length - deletedText.length;
      _textEditingController.text = deletedText;

      final newCursorPos = (targetPos - deletedLength).clamp(0, deletedText.length);
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      );
    }
  }

  String _deleteEmojiOrCharacter(String text, int cursorPos) {
    if (cursorPos <= 0) return text;

    final emojiPattern = RegExp(r'\[TUIEmoji_\w{2,}\]');
    final matches = emojiPattern.allMatches(text);

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (cursorPos == end) {
        return text.substring(0, start) + text.substring(end);
      }

      if (cursorPos > start && cursorPos < end) {
        return text.substring(0, start) + text.substring(end);
      }
    }

    return text.substring(0, cursorPos - 1) + text.substring(cursorPos);
  }

  void _toggleMorePanel() {
    if (_showMorePanel) {
      _removeOverlay();
    } else {
      // hide keyboard
      _textEditingFocusNode.unfocus();
      // hide emoji panel
      if (_showEmojiPanel) {
        setState(() {
          _showEmojiPanel = false;
        });
      }
      _showOverlay();
    }
    setState(() {
      _showMorePanel = !_showMorePanel;
    });
  }

  void _showOverlay() {
    final RenderBox renderBox = _moreButtonKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildMorePanelOverlay(position, size),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _handleSendFromEmojiPanel() async {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) return;

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.text;
    MessageBody messageBody = MessageBody();
    messageBody.text = text;
    messageInfo.messageBody = messageBody;

    _textEditingController.clear();
    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_handleSend, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  void _onPickAlbum() async {
    AlbumPickerConfig config = AlbumPickerConfig(locale: localeProvider.locale);
    await AlbumPicker.pickMedia(
      context: context,
      config: config,
      onProgress: (model, index, progress) async {
        if (model.mediaType == PickMediaType.image) {
          final messageInfo = MessageInfo();
          messageInfo.messageType = MessageType.image;
          MessageBody messageBody = MessageBody();
          messageBody.originalImagePath = model.mediaPath;
          messageInfo.messageBody = messageBody;
          final result = await _sendMessage(messageInfo);
          if (!result.isSuccess) {
            debugPrint("_onPickAlbum image, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
          }
        } else if (model.mediaType == PickMediaType.video) {
          String? snapshotPath = model.videoThumbnailPath;

          final messageInfo = MessageInfo();
          messageInfo.messageType = MessageType.video;
          MessageBody messageBody = MessageBody();
          messageBody.videoPath = model.mediaPath;
          messageBody.videoSnapshotPath = snapshotPath;
          messageBody.videoType = model.fileExtension;
          messageInfo.messageBody = messageBody;
          final result = await _sendMessage(messageInfo);
          if (!result.isSuccess) {
            debugPrint("_onPickAlbum video, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
          }
        }
      },
    );
  }

  Future<CompletionHandler> _sendMessage(MessageInfo messageInfo) async {
    final result = await _messageInputStore.sendMessage(message: messageInfo);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, atomicLocale.sendMessageFail);
      }
    }

    return result;
  }

  void _onPickFile() async {
    List<PickerResult> filePickerResults = await FilePicker.pickFiles(
      context: context,
      config: FilePickerConfig(maxCount: 1),
    );

    if (filePickerResults.isNotEmpty) {
      final filePickerResult = filePickerResults.first;

      final messageInfo = MessageInfo();
      messageInfo.messageType = MessageType.file;
      MessageBody messageBody = MessageBody();
      messageBody.filePath = filePickerResult.filePath;
      messageBody.fileName = filePickerResult.fileName;
      messageBody.fileSize = filePickerResult.fileSize;
      messageInfo.messageBody = messageBody;
      final result = await _sendMessage(messageInfo);
      if (!result.isSuccess) {
        debugPrint("_onPickFile, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
      }
    }
  }

  void _onTakeVideo() async {
    _requestCameraPermission(context);
    VideoRecorderResult videoRecorderResult = await VideoRecorder.instance.takeVideo();

    final videoThumbnailPlugin = FcNativeVideoThumbnail();
    String? snapshotPath =
        ChatUtil.generateMediaPath(messageType: MessageType.video, prefix: "snapshot", isCache: true);
    await videoThumbnailPlugin.getVideoThumbnail(
      srcFile: videoRecorderResult.filePath,
      destFile: snapshotPath,
      format: 'jpeg',
      width: 1280,
      height: 1280,
      quality: 100,
    );

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.video;
    MessageBody messageBody = MessageBody();
    messageBody.videoPath = videoRecorderResult.filePath;
    messageBody.videoSnapshotPath = snapshotPath;
    messageBody.videoType = videoRecorderResult.filePath.split('.').last;
    messageInfo.messageBody = messageBody;
    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_onPickFile, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(atomicLocal.permissionNeeded),
          content: Text(atomicLocal.permissionDeniedContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(atomicLocal.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(atomicLocal.confirm),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  static  _requestCameraPermission(BuildContext context) async {
    if (kIsWeb) {
      return;
    }

    PermissionType permissionType = PermissionType.camera;
    Map<PermissionType, PermissionStatus> statusMap =  await Permission.request([permissionType]);
    PermissionStatus status = statusMap[permissionType] ?? PermissionStatus.denied;

    if (status == PermissionStatus.granted) {
      return;
    }

    if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
      if (context.mounted) {
        final bool shouldOpenSettings = await _showPermissionDialog(context);
        if (shouldOpenSettings) {
          await Permission.openAppSettings();
        }
      }
    }
  }

  void _onTakePhoto() async {
    _requestCameraPermission(context);
    VideoRecorderResult videoRecorderResult = await VideoRecorder.instance.takePhoto();
    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.image;
    MessageBody messageBody = MessageBody();
    messageBody.originalImagePath = videoRecorderResult.filePath;
    messageInfo.messageBody = messageBody;
    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_onPickFile, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  void _onAudioRecorderFinished(RecordInfo recordInfo) async {
    if (recordInfo.errorCode != 0) {
      debugPrint("_onAudioRecorderFinished, errorCode:$recordInfo.errorCode, errorMessage:$recordInfo.errorMessage");
      return;
    }

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.sound;
    MessageBody messageBody = MessageBody();
    messageBody.soundPath = recordInfo.path;
    messageBody.soundDuration = recordInfo.duration;
    messageInfo.messageBody = messageBody;

    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_onRecordFinish, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  void _onStartRecording(PointerDownEvent event) {
    setState(() {
      _isRecording = true;
    });

    _recordingStarter?.cancel();
    _isWaitingToStartRecord = true;

    _recordingStarter = Timer(const Duration(milliseconds: 100), () {
      _isWaitingToStartRecord = false;
      String path =
          ChatUtil.generateMediaPath(messageType: MessageType.sound, prefix: "", withExtension: ".m4a", isCache: true);
      _recordingWidgetKey.currentState?.startRecord(filePath: path);
    });
  }

  void _onStopRecording(PointerUpEvent event) {
    if (_isWaitingToStartRecord) {
      _recordingStarter?.cancel();
      _recordingStarter = null;
      _isWaitingToStartRecord = false;

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      _micTooltipKey.currentState?.ensureTooltipVisible();
      Future.delayed(const Duration(seconds: 1), () {
        Tooltip.dismissAllToolTips();
      });
    } else {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      bool gestureCancel = _recordingWidgetKey.currentState?.isPointerOverTrashIcon(event.position) ?? false;
      if (gestureCancel) {
        _recordingWidgetKey.currentState?.cancelRecord();
      } else {
        _recordingWidgetKey.currentState?.stopRecord();
      }
    }
  }

  Widget _buildMorePanelOverlay(Offset position, Size buttonSize) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              _toggleMorePanel();
            },
            child: Container(
              color: colorsTheme.bgColorMask,
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
          left: 8,
          right: 8,
          child: _buildActionSheet(colorsTheme),
        ),
      ],
    );
  }

  Widget _buildActionSheet(SemanticColorScheme colorsTheme) {
    final List<Widget> actionItems = [];
    bool isFirst = true;

    if (widget.config.isShowPhotoTaker) {
      actionItems.add(_buildActionItem(
        icon: 'chat_assets/icon/camera_action.svg',
        title: atomicLocale.takeAPhoto,
        onTap: () {
          _toggleMorePanel();
          _onTakePhoto();
        },
        colorsTheme: colorsTheme,
        isFirst: isFirst,
      ));
      isFirst = false;
    }

    if (widget.config.isShowPhotoTaker) {
      if (actionItems.isNotEmpty) {
        actionItems.add(_buildDivider(colorsTheme));
      }
      actionItems.add(_buildActionItem(
        icon: 'chat_assets/icon/record_action.svg',
        title: atomicLocale.recordAVideo,
        onTap: () {
          _toggleMorePanel();
          _onTakeVideo();
        },
        colorsTheme: colorsTheme,
        isFirst: isFirst,
      ));
      isFirst = false;
    }

    if (actionItems.isNotEmpty) {
      actionItems.add(_buildDivider(colorsTheme));
    }
    actionItems.add(_buildActionItem(
      icon: 'chat_assets/icon/image_action.svg',
      title: atomicLocale.album,
      onTap: () {
        _toggleMorePanel();
        _onPickAlbum();
      },
      colorsTheme: colorsTheme,
      isFirst: isFirst,
    ));
    isFirst = false;

    actionItems.add(_buildDivider(colorsTheme));
    actionItems.add(_buildActionItem(
      icon: 'chat_assets/icon/file_action.svg',
      title: atomicLocale.file,
      onTap: () {
        _toggleMorePanel();
        _onPickFile();
      },
      colorsTheme: colorsTheme,
      isLast: true,
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorsTheme.bgColorOperate,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: actionItems,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: colorsTheme.bgColorOperate,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextButton(
            onPressed: _toggleMorePanel,
            child: Text(
              atomicLocale.cancel,
              style: TextStyle(
                color: colorsTheme.textColorLink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    required SemanticColorScheme colorsTheme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorsTheme.bgColorOperate,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 14 : 0),
            topRight: Radius.circular(isFirst ? 14 : 0),
            bottomLeft: Radius.circular(isLast ? 14 : 0),
            bottomRight: Radius.circular(isLast ? 14 : 0),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              package: 'tuikit_atomic_x',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colorsTheme.textColorLink,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(SemanticColorScheme colorsTheme) {
    return Container(
      height: 1,
      color: colorsTheme.bgColorBubbleReciprocal,
    );
  }

  @override
  Widget build(BuildContext context) {
    _bottomPadding ??= MediaQuery.of(context).padding.bottom;
    atomicLocale = AtomicLocalizations.of(context);
    localeProvider = Provider.of<LocaleProvider>(context);

    var panelHeight = _getBottomContainerHeight();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final colors = BaseThemeProvider.colorsOf(context);
        return Column(
          children: [
            IndexedStack(
              index: _isRecording ? 1 : 0,
              alignment: Alignment.bottomCenter,
              children: [
                _buildInputWidget(colors),
                _buildAudioRecordWidget(),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              height: panelHeight,
              constraints: _showEmojiPanel ? BoxConstraints(minHeight: panelHeight) : null,
              child: _showEmojiPanel
                  ? Center(
                      child: FutureBuilder<bool>(
                        future: getEmojiPanelWidget(),
                        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          return stickerWidget;
                        },
                      ),
                    )
                  : Container(),
            )
          ],
        );
      },
    );
  }

  Future<bool> getEmojiPanelWidget() async {
    stickerWidget = EmojiPicker(
      onEmojiClick: _onEmojiClicked,
      onSendClick: _handleSendFromEmojiPanel,
      onDeleteClick: _onDeleteClick,
    );
    return true;
  }

  Widget _buildInputWidget(SemanticColorScheme colorsTheme) {
    return Container(
      color: colorsTheme.bgColorOperate,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            child: Row(
              children: [
                if (widget.config.isShowMore) _buildAddButton(colorsTheme),
                if (widget.config.isShowMore) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorsTheme.bgColorBubbleReciprocal,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputTextField(colorsTheme: colorsTheme),
                        ),
                        if (_isEmojiPickerExist)
                          GestureDetector(
                            onTap: () {
                              if (!_showEmojiPanel) {
                                _textEditingFocusNode.unfocus();
                              } else {
                                _textEditingFocusNode.requestFocus();
                              }
                              setState(() {
                                _showEmojiPanel = !_showEmojiPanel;
                              });
                            },
                            child: _showEmojiPanel
                                ? Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    child: const Icon(Icons.keyboard_alt_outlined),
                                  )
                                : _buildInputButton(
                                    icon: 'chat_assets/icon/emoji.svg',
                                    isActive: _showEmojiPanel,
                                    colorsTheme: colorsTheme,
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (_showSendButton)
                      _buildSendButton(colorsTheme)
                    else if (!_showSendButton && widget.config.isShowAudioRecorder)
                      Tooltip(
                        preferBelow: false,
                        verticalOffset: 36,
                        message: atomicLocale.sendSoundTips,
                        child: Listener(
                          onPointerDown: _onStartRecording,
                          onPointerUp: _onStopRecording,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorsTheme.buttonColorSecondaryDefault,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'chat_assets/icon/mic.svg',
                                package: 'tuikit_atomic_x',
                                colorFilter: ColorFilter.mode(
                                  colorsTheme.textColorLink,
                                  BlendMode.srcIn,
                                ),
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTextField({required SemanticColorScheme colorsTheme}) {
    return ExtendedTextField(
      onTap: () {
        _textEditingFocusNode.requestFocus();
        setState(() {
          _showEmojiPanel = false;
        });
      },
      focusNode: _textEditingFocusNode,
      controller: _textEditingController,
      minLines: 1,
      maxLines: 4,
      style: TextStyle(
        color: colorsTheme.textColorPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: colorsTheme.textColorTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
      ),
      specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
        colorScheme: colorsTheme,
        onTapUrl: (_) {},
      ),
    );
  }

  Widget _buildInputButton({
    Key? key,
    required String icon,
    required SemanticColorScheme colorsTheme,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return IconButton.buttonContent(
      key: key,
      content: IconOnlyContent(
        SvgPicture.asset(
          icon,
          package: 'tuikit_atomic_x',
          colorFilter: ColorFilter.mode(
            colorsTheme.textColorLink,
            BlendMode.srcIn,
          ),
        ),
      ),
      type: ButtonType.noBorder,
      size: ButtonSize.m,
      onClick: onPressed,
      colorType: ButtonColorType.secondary,
    );
  }

  Widget _buildSendButton(SemanticColorScheme colorsTheme) {
    return InkWell(
      onTap: _handleSendFromEmojiPanel,
      child: Container(
        width: 64,
        height: 32,
        decoration: BoxDecoration(
          color: colorsTheme.buttonColorPrimaryDefault,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            atomicLocale.send,
            style: TextStyle(
              color: colorsTheme.textColorButton,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(SemanticColorScheme colorsTheme) {
    return IconButton(
      key: _moreButtonKey,
      colorType: ButtonColorType.secondary,
      icon: SvgPicture.asset(
        'chat_assets/icon/add.svg',
        package: 'tuikit_atomic_x',
        colorFilter: ColorFilter.mode(
          colorsTheme.textColorLink,
          BlendMode.srcIn,
        ),
        width: 24,
        height: 24,
      ),
      onClick: _toggleMorePanel,
    );
  }

  double _getBottomContainerHeight() {
    if (_showEmojiPanel) {
      return 280;
    }

    return _bottomPadding ?? 0.0;
  }

  Widget _buildAudioRecordWidget() {
    return AudioRecordWidget(key: _recordingWidgetKey, onRecordFinish: _onAudioRecorderFinished);
  }
}
