import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tuikit_atomic_x/album_picker/album_picker.dart';
import 'package:tuikit_atomic_x/audio_recoder/audio_recorder.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/emoji_picker/emoji_manager.dart';
import 'package:tuikit_atomic_x/emoji_picker/emoji_picker.dart';
import 'package:tuikit_atomic_x/file_picker/file_picker.dart';
import 'package:tuikit_atomic_x/message_input/src/chat_special_text_span_builder.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:tuikit_atomic_x/third_party/extended_text_field/extended_text_field.dart';
import 'package:tuikit_atomic_x/video_recorder/video_recorder.dart';

import 'mention/mention_info.dart';
import 'mention/mention_member_picker.dart';
import 'message_input_config.dart';
import 'widget/audio_record_widget.dart';

export 'mention/mention_info.dart';
export 'message_input_config.dart';

class MessageInput extends StatefulWidget {
  final String conversationID;
  final MessageInputConfigProtocol config;

  const MessageInput({
    super.key,
    required this.conversationID,
    this.config = const ChatMessageInputConfig(),
  });

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> with TickerProviderStateMixin {
  /// Group conversation ID prefix
  static const String _groupConversationIDPrefix = 'group_';

  late MessageInputStore _messageInputStore;
  late ConversationListStore _conversationListStore;
  late _MentionTextEditingController _textEditingController;
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

  // Draft related state
  Timer? _draftSaveTimer;
  bool _isLoadingDraft = false;
  static const _draftSaveDelay = Duration(milliseconds: 800);

  // @ mention related state
  String? _groupID;
  int _previousTextLength = 0;
  bool _isMentionPickerShowing = false;

  // Conversation info for offline push
  ConversationInfo? _conversationInfo;

  @override
  void initState() {
    super.initState();
    _messageInputStore = MessageInputStore.create(conversationID: widget.conversationID);
    _conversationListStore = ConversationListStore.create();
    _textEditingController = _MentionTextEditingController();
    _textEditingController.addListener(_onTextChanged);
    _loadDraft();
    _extractGroupID();
    _fetchConversationInfo();
  }

  /// Extract groupID from conversationID for group chats
  void _extractGroupID() {
    String groupID = ChatUtil.getGroupID(widget.conversationID);
    _groupID = groupID.isEmpty ? null : groupID;
  }

  bool get _isGroupChat => _groupID != null;

  /// Insert a mention into the input field from external source (e.g., long press on avatar)
  /// This is called when user long presses on another member's avatar in the message list
  void insertMention({required String userID, required String displayName}) {
    if (!_isGroupChat) return;
    
    // Don't allow mentioning self
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (userID == currentUserID) return;

    final text = _textEditingController.text;
    final cursorPos = _textEditingController.selection.baseOffset;
    final insertPos = cursorPos < 0 ? text.length : cursorPos;

    // Create mention info
    final mention = MentionInfo(
      userID: userID,
      displayName: displayName,
      startIndex: insertPos,
    );
    final mentionText = mention.mentionText; // "@displayName "

    // Build new text
    final beforeCursor = text.substring(0, insertPos);
    final afterCursor = text.substring(insertPos);
    final newText = '$beforeCursor$mentionText$afterCursor';
    final newCursorPos = insertPos + mentionText.length;

    // Update mention positions for existing mentions after insert position
    for (final m in _textEditingController._mentions) {
      if (m.startIndex >= insertPos) {
        m.startIndex += mentionText.length;
      }
    }

    // Add the new mention
    _textEditingController.addMention(mention);

    // Update text field
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController._isInternalUpdate = true;
    _textEditingController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _textEditingController._isInternalUpdate = false;
    _previousTextLength = newText.length;
    _textEditingController.addListener(_onTextChanged);

    // Request focus on the input field
    _textEditingFocusNode.requestFocus();

    // Update send button state
    setState(() {
      _showSendButton = newText.trim().isNotEmpty;
    });
  }

  /// Fetch conversation info for offline push (same as Swift's fetchConversationInfo)
  Future<void> _fetchConversationInfo() async {
    final result = await _conversationListStore.fetchConversationInfo(
      conversationID: widget.conversationID,
    );
    if (result.isSuccess) {
      final conversationList = _conversationListStore.conversationListState.conversationList;
      _conversationInfo = conversationList
          .where((conv) => conv.conversationID == widget.conversationID)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onTextChanged);
    _draftSaveTimer?.cancel();
    // Save draft immediately on dispose (fallback mechanism)
    _saveDraftImmediately();
    _textEditingController.dispose();
    _removeOverlay();
    super.dispose();
  }

  /// Load draft from IM SDK when entering conversation
  Future<void> _loadDraft() async {
    _isLoadingDraft = true;
    final result = await _conversationListStore.fetchConversationInfo(
      conversationID: widget.conversationID,
    );
    if (result.isSuccess) {
      final conversationList = _conversationListStore.conversationListState.conversationList;
      if (conversationList.isNotEmpty) {
        final draft = conversationList.first.draft;
        if (draft != null && draft.isNotEmpty) {
          _setDraftToInput(draft);
        }
      }
    }
    _isLoadingDraft = false;
  }

  /// Set draft content to input field
  void _setDraftToInput(String draft) {
    _textEditingController.text = draft;
    // Position cursor at the end
    _textEditingController.selection = TextSelection.fromPosition(
      TextPosition(offset: draft.length),
    );
    // Auto focus after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _textEditingFocusNode.requestFocus();
      }
    });
  }

  /// Save draft with debounce
  void _scheduleDraftSave() {
    if (_isLoadingDraft) return;

    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftSaveDelay, () {
      _saveDraftImmediately();
    });
  }

  /// Save draft immediately (for dispose fallback)
  void _saveDraftImmediately() {
    final draftText = _textEditingController.text;
    _conversationListStore.setConversationDraft(
      conversationID: widget.conversationID,
      draft: draftText.isEmpty ? null : draftText,
    );
  }

  /// Clear draft (called before sending message)
  void _clearDraft() {
    _draftSaveTimer?.cancel();
    _conversationListStore.setConversationDraft(
      conversationID: widget.conversationID,
      draft: null,
    );
  }

  void _onTextChanged() {
    final hasText = _textEditingController.text.trim().isNotEmpty;
    if (hasText != _showSendButton) {
      setState(() {
        _showSendButton = hasText;
      });
    }
    // Schedule draft save with debounce
    _scheduleDraftSave();

    // Handle @ mention detection
    _handleMentionDetection();
  }

  /// Detect @ input and show member picker
  void _handleMentionDetection() {
    if (!widget.config.enableMention) return;
    if (_isMentionPickerShowing) return;

    final text = _textEditingController.text;
    final currentLength = text.length;

    // Only trigger when adding a single '@' or '＠' character
    if (currentLength == _previousTextLength + 1 && _isGroupChat) {
      final cursorPos = _textEditingController.selection.baseOffset;
      if (cursorPos > 0) {
        final lastChar = text[cursorPos - 1];
        // Support both half-width '@' and full-width '＠'
        if (lastChar == '@' || lastChar == '＠') {
          _showMentionPicker();
        }
      }
    }

    _previousTextLength = currentLength;
  }

  /// Show the mention member picker
  void _showMentionPicker() {
    if (_groupID == null) return;
    _isMentionPickerShowing = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MentionMemberPicker(
          groupID: _groupID!,
          onMembersSelected: _onMembersSelected,
          onCancel: () {
            _isMentionPickerShowing = false;
            // Keep the '@' character when cancelled (per spec requirement)
            // No action needed - '@' remains in input
          },
        ),
      ),
    ).then((_) {
      _isMentionPickerShowing = false;
    });
  }

  /// Handle selected members from picker
  void _onMembersSelected(List<MentionInfo> mentions) {
    Navigator.of(context).pop();
    _isMentionPickerShowing = false;

    if (mentions.isEmpty) {
      // Keep the '@' character when no member selected (per spec requirement)
      return;
    }

    final text = _textEditingController.text;
    final cursorPos = _textEditingController.selection.baseOffset;

    // Find the position of the '@' or '＠' that triggered the picker
    int atPos = cursorPos - 1;
    bool isAtSymbol(String char) => char == '@' || char == '＠';

    if (atPos < 0 || !isAtSymbol(text[atPos])) {
      // '@' not found at expected position, try to find it
      for (int i = cursorPos - 1; i >= 0; i--) {
        if (isAtSymbol(text[i])) {
          atPos = i;
          break;
        }
      }
    }

    // Remove the triggering '@' character - use atPos + 1 to skip the '@'
    final beforeAt = text.substring(0, atPos);
    final afterAt = text.substring(atPos + 1); // Skip the '@' that triggered the picker

    // Build the mention text to insert (each mention includes its own '@')
    final StringBuffer mentionBuffer = StringBuffer();
    int currentPos = atPos;
    
    for (int i = 0; i < mentions.length; i++) {
      final mention = mentions[i];
      final mentionText = mention.mentionText; // "@displayName "
      mentionBuffer.write(mentionText);
      
      // Update mention with correct position and add to controller
      final updatedMention = mention.copyWith(startIndex: currentPos);
      _textEditingController.addMention(updatedMention);
      currentPos += mentionText.length;
    }

    final newText = '$beforeAt$mentionBuffer$afterAt';
    
    // Temporarily disable listener and mark as internal update to prevent
    // the value setter from incorrectly adjusting mention positions
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController._isInternalUpdate = true;
    _textEditingController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: currentPos),
    );
    _textEditingController._isInternalUpdate = false;
    _previousTextLength = newText.length;
    _textEditingController.addListener(_onTextChanged);

    _textEditingFocusNode.requestFocus();
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

    // First check if we're deleting a mention (cursor at end or inside)
    MentionInfo? mentionToDelete = _textEditingController.getMentionEndingAt(targetPos);
    mentionToDelete ??= _textEditingController.getMentionAt(targetPos);
    
    if (mentionToDelete != null) {
      // Delete the entire mention
      _textEditingController._isInternalUpdate = true;
      final newText = text.substring(0, mentionToDelete.startIndex) + 
                      text.substring(mentionToDelete.endIndex);
      _textEditingController._mentions.remove(mentionToDelete);
      
      // Update positions of mentions after the removed one
      final removedLength = mentionToDelete.length;
      for (final m in _textEditingController._mentions) {
        if (m.startIndex > mentionToDelete.startIndex) {
          m.startIndex -= removedLength;
        }
      }
      
      _textEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: mentionToDelete.startIndex),
      );
      _textEditingController._isInternalUpdate = false;
      return;
    }

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

  /// Handle sending text message from input field or emoji panel
  Future<void> _handleSendTextMessage() async {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) return;

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.text;
    MessageBody messageBody = MessageBody();
    messageBody.text = text;
    messageInfo.messageBody = messageBody;

    // Add @ mention info to message
    final mentionList = _textEditingController.mentionList;
    if (mentionList.isNotEmpty) {
      // Add all mentioned user IDs (including AT_ALL_USER_ID if present)
      messageInfo.atUserList = mentionList.map((m) => m.userID).toList();
    }

    // Clear draft and mentions BEFORE sending (not dependent on send result)
    // Must clear mentions first to prevent value setter from incorrectly handling the clear operation
    _textEditingController.clearMentions();
    _textEditingController._isInternalUpdate = true;
    _textEditingController.clear();
    _textEditingController._isInternalUpdate = false;
    _clearDraft();

    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_handleSendTextMessage, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  void _onPickAlbum() async {
    AlbumPickerConfig config = AlbumPickerConfig();
    await AlbumPicker.pickMedia(
      context: context,
      config: config,
      onProgress: (model, index, progress) async {
        if (progress >= 1.0) {
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
        }
      },
    );
  }

  Future<CompletionHandler> _sendMessage(MessageInfo messageInfo) async {
    messageInfo.needReadReceipt = widget.config.enableReadReceipt;
    messageInfo.offlinePushInfo = _createOfflinePushInfo(messageInfo);

    final result = await _messageInputStore.sendMessage(message: messageInfo);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, atomicLocale.sendMessageFail);
      }
    }

    return result;
  }

  // ==================== Offline Push Info ====================

  /// Create offline push info for a message
  OfflinePushInfo _createOfflinePushInfo(MessageInfo message) {
    final conversationID = widget.conversationID;
    final isGroup = conversationID.startsWith(_groupConversationIDPrefix);
    final groupId = isGroup ? conversationID.substring(_groupConversationIDPrefix.length) : '';

    final loginUserInfo = LoginStore.shared.loginState.loginUserInfo;
    final selfUserId = loginUserInfo?.userID ?? '';
    final selfName = loginUserInfo?.nickname ?? selfUserId;

    final chatName = (_conversationInfo?.title?.isNotEmpty ?? false)
        ? _conversationInfo?.title
        : null;

    final senderNickName = isGroup ? (chatName ?? groupId) : selfName;

    final description = _createOfflinePushDescription(message);
    final ext = _createOfflinePushExtJson(
      isGroup: isGroup,
      senderId: isGroup ? groupId : selfUserId,
      senderNickName: senderNickName,
      faceUrl: loginUserInfo?.avatarURL,
      version: 1,
      action: 1,
      content: description,
      customData: null,
    );

    final pushInfo = OfflinePushInfo();
    pushInfo.title = senderNickName;
    pushInfo.description = description;
    pushInfo.extensionInfo = {
      'ext': ext,
      'AndroidOPPOChannelID': 'tuikit',
      'AndroidHuaWeiCategory': 'IM',
      'AndroidVIVOCategory': 'IM',
      'AndroidHonorImportance': 'NORMAL',
      'AndroidMeizuNotifyType': 1,
      'iOSInterruptionLevel': 'time-sensitive',
      'enableIOSBackgroundNotification': false,
    };

    return pushInfo;
  }

  /// Create offline push description for a message
  String _createOfflinePushDescription(MessageInfo message) {
    String content;
    switch (message.messageType) {
      case MessageType.text:
        // Convert emoji codes to localized names
        content = EmojiManager.createLocalizedStringFromEmojiCodes(context, message.messageBody?.text ?? '');
        break;
      case MessageType.image:
        content = atomicLocale.messageTypeImage;
        break;
      case MessageType.video:
        content = atomicLocale.messageTypeVideo;
        break;
      case MessageType.file:
        content = atomicLocale.messageTypeFile;
        break;
      case MessageType.sound:
        content = atomicLocale.messageTypeVoice;
        break;
      case MessageType.face:
        content = atomicLocale.messageTypeSticker;
        break;
      case MessageType.merged:
        content = '[${atomicLocale.chatHistory}]';
        break;
      default:
        content = '';
    }
    return _trimPushDescription(content);
  }

  /// Trim push description to max length
  String _trimPushDescription(String text, {int maxLength = 50}) {
    final normalized = text.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  /// Create offline push ext JSON string (same as Swift's createOfflinePushExtJson)
  String _createOfflinePushExtJson({
    required bool isGroup,
    required String senderId,
    required String senderNickName,
    String? faceUrl,
    required int version,
    required int action,
    String? content,
    String? customData,
  }) {
    final entity = <String, dynamic>{
      'sender': senderId,
      'nickname': senderNickName,
      'chatType': isGroup ? 2 : 1,
      'version': version,
      'action': action,
    };

    if (content != null && content.isNotEmpty) {
      entity['content'] = content;
    }
    if (faceUrl != null) {
      entity['faceUrl'] = faceUrl;
    }
    if (customData != null) {
      entity['customData'] = customData;
    }

    final timPushFeatures = <String, int>{
      'fcmPushType': 0,
      'fcmNotificationType': 0,
    };

    final extDict = <String, dynamic>{
      'entity': entity,
      'timPushFeatures': timPushFeatures,
    };

    try {
      return jsonEncode(extDict);
    } catch (e) {
      return '{}';
    }
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
    try {
      VideoRecorderResult result = await VideoRecorder.startRecord(
        context: context,
        config: const VideoRecorderConfig(
          recordMode: RecordMode.mixed,
        ),
      );

      if (result.filePath.isEmpty) {
        return;
      }

      final messageInfo = MessageInfo();
      messageInfo.messageType = MessageType.video;
      MessageBody messageBody = MessageBody();
      messageBody.videoPath = result.filePath;
      messageBody.videoSnapshotPath = result.thumbnailPath;
      messageBody.videoType = result.filePath.split('.').last;
      messageInfo.messageBody = messageBody;
      final sendResult = await _sendMessage(messageInfo);
      if (!sendResult.isSuccess) {
        debugPrint("_onTakeVideo, errorCode:${sendResult.errorCode}, errorMessage:${sendResult.errorMessage}");
      }
    } catch (e) {
      debugPrint("_onTakeVideo error: $e");
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

  static _requestCameraPermission(BuildContext context) async {
    if (kIsWeb) {
      return;
    }

    PermissionType permissionType = PermissionType.camera;
    Map<PermissionType, PermissionStatus> statusMap = await Permission.request([permissionType]);
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
    try {
      VideoRecorderResult result = await VideoRecorder.startRecord(
        context: context,
        config: const VideoRecorderConfig(
          recordMode: RecordMode.photoOnly,
        ),
      );

      if (result.filePath.isEmpty) {
        return;
      }

      final messageInfo = MessageInfo();
      messageInfo.messageType = MessageType.image;
      MessageBody messageBody = MessageBody();
      messageBody.originalImagePath = result.filePath;
      messageInfo.messageBody = messageBody;
      final sendResult = await _sendMessage(messageInfo);
      if (!sendResult.isSuccess) {
        debugPrint("_onTakePhoto, errorCode:${sendResult.errorCode}, errorMessage:${sendResult.errorMessage}");
      }
    } catch (e) {
      debugPrint("_onTakePhoto error: $e");
    }
  }

  void _onAudioRecorderFinished(RecordInfo recordInfo) async {
    if (recordInfo.errorCode != AudioRecordResultCode.success) {
      debugPrint("_onAudioRecorderFinished, errorCode:$recordInfo.errorCode");
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

    // Immediately reset recording state to avoid showing old progress
    _recordingWidgetKey.currentState?.resetRecordingState();

    _recordingStarter?.cancel();
    _isWaitingToStartRecord = true;

    _recordingStarter = Timer(const Duration(milliseconds: 100), () {
      _isWaitingToStartRecord = false;
      String path =
          ChatUtil.generateMediaPath(messageType: MessageType.sound, prefix: "", withExtension: "m4a", isCache: true);
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
      onSendClick: _handleSendTextMessage,
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
    return _MentionTextField(
      controller: _textEditingController,
      focusNode: _textEditingFocusNode,
      colorsTheme: colorsTheme,
      onTap: () {
        _textEditingFocusNode.requestFocus();
        setState(() {
          _showEmojiPanel = false;
        });
      },
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
      onTap: _handleSendTextMessage,
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

/// Custom TextEditingController that manages mention ranges
class _MentionTextEditingController extends TextEditingController {
  final List<MentionInfo> _mentions = [];
  bool _isInternalUpdate = false;

  List<MentionInfo> get mentionList => List.unmodifiable(_mentions);

  void addMention(MentionInfo mention) {
    _mentions.add(mention);
    _mentions.sort((a, b) => a.startIndex.compareTo(b.startIndex));
  }

  void removeMention(MentionInfo mention) {
    _mentions.remove(mention);
    // Update positions of mentions after the removed one
    final removedLength = mention.length;
    for (final m in _mentions) {
      if (m.startIndex > mention.startIndex) {
        m.startIndex -= removedLength;
      }
    }
  }

  void clearMentions() {
    _mentions.clear();
  }

  /// Get mention that ends at the given position
  MentionInfo? getMentionEndingAt(int position) {
    for (final mention in _mentions) {
      if (mention.endIndex == position) {
        return mention;
      }
    }
    return null;
  }

  /// Get mention that contains the given position (exclusive of boundaries)
  MentionInfo? getMentionContaining(int position) {
    for (final mention in _mentions) {
      if (position > mention.startIndex && position < mention.endIndex) {
        return mention;
      }
    }
    return null;
  }

  /// Get mention that the position is at or inside (for deletion detection)
  MentionInfo? getMentionAt(int position) {
    for (final mention in _mentions) {
      if (position > mention.startIndex && position <= mention.endIndex) {
        return mention;
      }
    }
    return null;
  }

  /// Get the anchor position for a mention (jump to nearest boundary)
  int getAnchorPosition(MentionInfo mention, int position) {
    final distanceToStart = position - mention.startIndex;
    final distanceToEnd = mention.endIndex - position;
    return distanceToStart <= distanceToEnd ? mention.startIndex : mention.endIndex;
  }

  @override
  set value(TextEditingValue newValue) {
    if (_isInternalUpdate) {
      super.value = newValue;
      return;
    }

    final oldText = text;
    final newText = newValue.text;
    
    // Skip if no text change
    if (oldText == newText) {
      super.value = newValue;
      return;
    }

    final delta = newText.length - oldText.length;
    
    // Handle deletion
    if (delta < 0) {
      final cursorPos = newValue.selection.baseOffset;
      // The deletion happened at cursorPos, and deleted (-delta) characters
      final deleteStart = cursorPos;
      final deleteEnd = cursorPos - delta; // This is the position in old text
      
      // Check if the deletion affects any mention
      // We need to find if any mention overlaps with [deleteStart, deleteEnd) in old text
      MentionInfo? affectedMention;
      for (final mention in _mentions) {
        // Check if the deletion overlaps with this mention
        if (deleteStart < mention.endIndex && deleteEnd > mention.startIndex) {
          affectedMention = mention;
          break;
        }
      }
      
      if (affectedMention != null) {
        // Delete the entire mention
        _isInternalUpdate = true;
        
        final beforeMention = oldText.substring(0, affectedMention.startIndex);
        final afterMention = oldText.substring(affectedMention.endIndex);
        final updatedText = '$beforeMention$afterMention';
        
        // Remove the mention from list
        _mentions.remove(affectedMention);
        
        // Update positions of mentions after the removed one
        final removedLength = affectedMention.length;
        for (final m in _mentions) {
          if (m.startIndex > affectedMention.startIndex) {
            m.startIndex -= removedLength;
          }
        }
        
        super.value = TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(offset: affectedMention.startIndex),
        );
        
        _isInternalUpdate = false;
        return;
      }
      
      // No mention affected, update mention positions normally
      for (final mention in _mentions) {
        if (mention.startIndex >= deleteEnd) {
          mention.startIndex += delta;
        }
      }
    } else if (delta > 0) {
      // Handle insertion - update mention positions
      final insertPos = newValue.selection.baseOffset - delta;
      for (final mention in _mentions) {
        if (mention.startIndex >= insertPos) {
          mention.startIndex += delta;
        }
      }
    }
    
    super.value = newValue;
  }
}

/// Custom TextField that handles mention selection and cursor movement
class _MentionTextField extends StatefulWidget {
  final _MentionTextEditingController controller;
  final FocusNode focusNode;
  final SemanticColorScheme colorsTheme;
  final VoidCallback? onTap;

  const _MentionTextField({
    required this.controller,
    required this.focusNode,
    required this.colorsTheme,
    this.onTap,
  });

  @override
  State<_MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<_MentionTextField> {
  bool _isAdjustingSelection = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (_isAdjustingSelection) return;

    final selection = widget.controller.selection;
    if (!selection.isValid) return;

    final selStart = selection.start;
    final selEnd = selection.end;

    // Check if cursor is inside a mention
    if (selStart == selEnd) {
      // Single cursor
      final mention = widget.controller.getMentionContaining(selStart);
      if (mention != null) {
        // Jump to nearest boundary
        final anchorPos = widget.controller.getAnchorPosition(mention, selStart);
        
        // Only adjust if cursor is actually inside the mention (not at boundary)
        if (selStart != anchorPos) {
          _isAdjustingSelection = true;
          // Use microtask to ensure adjustment happens immediately but after current event
          Future.microtask(() {
            if (mounted) {
              widget.controller.selection = TextSelection.collapsed(offset: anchorPos);
            }
            _isAdjustingSelection = false;
          });
        }
      }
    } else {
      // Selection range - expand to include full mentions
      int newStart = selStart;
      int newEnd = selEnd;
      bool needsUpdate = false;

      for (final mention in widget.controller.mentionList) {
        // If selection starts inside a mention, extend to mention start
        if (selStart > mention.startIndex && selStart < mention.endIndex) {
          newStart = mention.startIndex;
          needsUpdate = true;
        }
        // If selection ends inside a mention, extend to mention end
        if (selEnd > mention.startIndex && selEnd < mention.endIndex) {
          newEnd = mention.endIndex;
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        _isAdjustingSelection = true;
        Future.microtask(() {
          if (mounted) {
            widget.controller.selection = TextSelection(baseOffset: newStart, extentOffset: newEnd);
          }
          _isAdjustingSelection = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedTextField(
      onTap: widget.onTap,
      focusNode: widget.focusNode,
      controller: widget.controller,
      minLines: 1,
      maxLines: 4,
      style: TextStyle(
        color: widget.colorsTheme.textColorPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: widget.colorsTheme.textColorTertiary,
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
        colorScheme: widget.colorsTheme,
        onTapUrl: (_) {},
      ),
    );
  }
}
