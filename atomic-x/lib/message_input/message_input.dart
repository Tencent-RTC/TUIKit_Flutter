import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
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
import 'package:tuikit_atomic_x/third_party/extended_text_field/extended_text_field.dart';
import 'package:tuikit_atomic_x/audio_player/audio_player_platform.dart';
import 'package:tuikit_atomic_x/video_recorder/video_recorder.dart';

import 'mention/mention_info.dart';
import 'mention/mention_member_picker.dart';
import 'message_input_config.dart';
import 'widget/audio_record_overlay.dart';

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
  bool _showSendButton = false;
  bool _showEmojiPanel = false;
  bool _showMorePanel = false;
  int _morePanelPageIndex = 0;
  final GlobalKey<AudioRecordOverlayState> _recordOverlayKey = GlobalKey();
  OverlayEntry? _recordOverlayEntry;

  double _bottomPadding = 0.0;

  /// Flag to indicate we are actively switching to emoji/more panel.
  /// When true, _onFocusChanged should NOT collapse panels.
  bool _isSwitchingPanel = false;

  final GlobalKey<TooltipState> _micTooltipKey = GlobalKey<TooltipState>();

  /// Whether the input is in voice mode (WeChat-style: tap mic button to toggle)
  bool _isVoiceMode = false;

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
    _textEditingFocusNode.addListener(_onFocusChanged);
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

  void _onFocusChanged() {
    if (!_textEditingFocusNode.hasFocus) {
      // If we are actively switching to emoji/more panel, do NOT collapse panels.
      if (_isSwitchingPanel) {
        _isSwitchingPanel = false;
        return;
      }
      // When focus is truly lost (e.g., tapping outside), collapse emoji and more panels
      if (_showEmojiPanel || _showMorePanel) {
        setState(() {
          _showEmojiPanel = false;
          _showMorePanel = false;
        });
      }
    }
  }

  /// Collapse all panels (emoji, more). Called externally when user taps blank area.
  void collapseAllPanels() {
    bool needsRebuild = false;
    if (_showEmojiPanel) {
      _showEmojiPanel = false;
      needsRebuild = true;
    }
    if (_showMorePanel) {
      _showMorePanel = false;
      needsRebuild = true;
    }
    if (needsRebuild) {
      setState(() {});
    }
  }

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
    _removeRecordOverlay();
    _textEditingController.removeListener(_onTextChanged);
    _textEditingFocusNode.removeListener(_onFocusChanged);
    _draftSaveTimer?.cancel();
    // Save draft immediately on dispose (fallback mechanism)
    _saveDraftImmediately();
    _textEditingController.dispose();
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
      // Closing more panel
      setState(() {
        _showMorePanel = false;
      });
    } else {
      // Opening more panel: hide keyboard and emoji panel
      _isSwitchingPanel = true;
      _textEditingFocusNode.unfocus();
      setState(() {
        _showEmojiPanel = false;
        _showMorePanel = true;
      });
    }
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
    AlbumPickerConfig config = const AlbumPickerConfig();
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
    try {
      VideoRecorderResult result = await VideoRecorder.startRecord(
        context: context,
        config: const VideoRecorderConfig(
          recordMode: RecordMode.mixed,
          minDurationMs: 500
        ),
      );

      if (result.filePath.isEmpty) {
        return;
      }

      final messageInfo = MessageInfo();
      MessageBody messageBody = MessageBody();

      if (result.mediaType == RecordMediaType.photo) {
        messageInfo.messageType = MessageType.image;
        messageBody.originalImagePath = result.filePath;
      } else {
        messageInfo.messageType = MessageType.video;
        messageBody.videoPath = result.filePath;
        messageBody.videoSnapshotPath = result.thumbnailPath;
        messageBody.videoType = result.filePath.split('.').last;
        messageBody.videoDuration = (result.durationMs != null) ? (result.durationMs! / 1000).round() : 0;
      }

      messageInfo.messageBody = messageBody;
      final sendResult = await _sendMessage(messageInfo);
      if (!sendResult.isSuccess) {
        debugPrint("_onTakeVideo, errorCode:${sendResult.errorCode}, errorMessage:${sendResult.errorMessage}");
      }
    } catch (e) {
      debugPrint("_onTakeVideo error: $e");
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

  void _showRecordOverlay() {
    _removeRecordOverlay();

    // Capture inherited dependencies from current context before creating
    // the OverlayEntry, since the overlay lives in a different widget subtree
    // and cannot look up these InheritedWidgets.
    final colorScheme = BaseThemeProvider.colorsOf(context);
    final atomicLocalizations = AtomicLocalizations.of(context);
    final overlay = Overlay.of(context);

    _recordOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          type: MaterialType.transparency,
          child: AudioRecordOverlay(
            key: _recordOverlayKey,
            colorScheme: colorScheme,
            atomicLocalizations: atomicLocalizations,
            onRecordFinish: (recordInfo) {
              _removeRecordOverlay();
              _onAudioRecorderFinished(recordInfo);
            },
            onRecordCancelled: () {
              _removeRecordOverlay();
            },
          ),
        );
      },
    );
    overlay.insert(_recordOverlayEntry!);
  }

  void _removeRecordOverlay() {
    _recordOverlayEntry?.remove();
    _recordOverlayEntry = null;
  }

  void _onAudioRecorderFinished(RecordInfo recordInfo) async {
    if (recordInfo.errorCode != AudioRecordResultCode.success &&
        recordInfo.errorCode != AudioRecordResultCode.successExceedMaxDuration) {
      debugPrint("_onAudioRecorderFinished, errorCode:${recordInfo.errorCode}");
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
    // Stop any currently playing audio to prevent it from being captured
    // by the microphone during recording.
    AudioPlayerPlatform.stop();

    _showRecordOverlay();

    // Immediately reset recording state to avoid showing old progress
    _recordOverlayKey.currentState?.resetRecordingState();

    _recordingStarter?.cancel();
    _isWaitingToStartRecord = true;

    _recordingStarter = Timer(const Duration(milliseconds: 100), () {
      _isWaitingToStartRecord = false;
      String path =
          ChatUtil.generateMediaPath(messageType: MessageType.sound, prefix: "", withExtension: "m4a", isCache: true);
      _recordOverlayKey.currentState?.startRecord(filePath: path);
    });
  }

  void _onStopRecording(PointerUpEvent event) {
    if (_isWaitingToStartRecord) {
      _recordingStarter?.cancel();
      _recordingStarter = null;
      _isWaitingToStartRecord = false;
      _removeRecordOverlay();

      _micTooltipKey.currentState?.ensureTooltipVisible();
      Future.delayed(const Duration(seconds: 1), () {
        Tooltip.dismissAllToolTips();
      });
    } else {
      // Check if finger is over cancel button on the overlay
      bool gestureCancel = _recordOverlayKey.currentState?.isPointerOverCancelButton(event.position) ?? false;
      if (gestureCancel) {
        // cancelRecord callback will call _removeRecordOverlay
        _recordOverlayKey.currentState?.cancelRecord();
      } else {
        // stopRecord callback will call _removeRecordOverlay via onRecordFinish
        _recordOverlayKey.currentState?.stopRecord();
      }
    }
  }

  /// Handle pointer cancel events (e.g. system gesture interception on Android
  /// such as edge-swipe for payment shortcuts or back navigation).
  /// When the system steals the pointer, we need to gracefully stop/cancel
  /// the ongoing recording to avoid leaving it in a stuck state.
  void _onRecordingPointerCancel(PointerCancelEvent event) {
    if (_isWaitingToStartRecord) {
      _recordingStarter?.cancel();
      _recordingStarter = null;
      _isWaitingToStartRecord = false;
      _removeRecordOverlay();
    } else {
      // System cancelled the gesture — treat as user cancellation
      // (don't send the recording) since the pointer position is unreliable.
      // cancelRecord's callback (onRecordCancelled) will call _removeRecordOverlay.
      _recordOverlayKey.currentState?.cancelRecord();
    }
  }

  /// Build the WeChat-style "more" panel with grid icons
  /// Figma spec (750px canvas = 2x):
  /// - Panel bg: #EBF0F6 (same as input bar)
  /// - Icon container: 128×128px → 64×64pt, border-radius: 28px → 14pt, bg: white
  /// - Icon inner: ~40×40pt (path content)
  /// - Label: font-size 24px → 12pt, color #8F959D, PingFang SC Regular
  /// - Grid: 4 columns, horizontal spacing ~88pt center-to-center
  /// - Panel padding: ~24pt horizontal, ~22pt from divider line
  /// - Divider at top: opacity 0.10 black
  Widget _buildMorePanelContent(SemanticColorScheme colorsTheme) {
    final List<_MorePanelItem> items = [];

    if (widget.config.isShowPhotoTaker) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/camera_action.svg',
        title: atomicLocale.takeAPhoto,
        onTap: _onTakePhoto,
      ));
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/record_action.svg',
        title: atomicLocale.recordAVideo,
        onTap: _onTakeVideo,
      ));
    }

    items.add(_MorePanelItem(
      icon: 'chat_assets/icon/image_action.svg',
      title: atomicLocale.album,
      onTap: _onPickAlbum,
    ));

    items.add(_MorePanelItem(
      icon: 'chat_assets/icon/file_action.svg',
      title: atomicLocale.file,
      onTap: _onPickFile,
    ));

    // Each page shows 2 rows × 4 columns = 8 items max
    const int itemsPerPage = 8;
    final int pageCount = (items.length / itemsPerPage).ceil();

    return Container(
      color: colorsTheme.bgColorInput,
      child: Column(
        children: [
          Container(
            height: 0.5,
            color: colorsTheme.textColorPrimary.withValues(alpha: 0.1),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: pageCount,
              onPageChanged: (index) {
                setState(() {
                  _morePanelPageIndex = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                final startIndex = pageIndex * itemsPerPage;
                final endIndex = (startIndex + itemsPerPage).clamp(0, items.length);
                final pageItems = items.sublist(startIndex, endIndex);

                // Each item row: icon 64 + spacing 8 + text ~14 = ~86pt
                // Two-row content height: 86 + 20 (gap) + 86 = 192pt
                const double twoRowHeight = 192;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final topPadding = ((constraints.maxHeight - twoRowHeight) / 2)
                        .clamp(8.0, double.infinity);
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: topPadding,
                      ),
                      child: _buildMorePanelPage(pageItems, colorsTheme),
                    );
                  },
                );
              },
            ),
          ),
          // Page indicator dots — always reserve space, hide when only 1 page
          Opacity(
            opacity: pageCount > 1 ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount > 1 ? pageCount : 1, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _morePanelPageIndex
                          ? colorsTheme.textColorTertiary
                          : colorsTheme.switchColorOff,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single page of the more panel grid (up to 2 rows × 4 columns)
  Widget _buildMorePanelPage(List<_MorePanelItem> pageItems, SemanticColorScheme colorsTheme) {
    const int columns = 4;
    // Split items into rows of 4
    final List<List<_MorePanelItem>> rows = [];
    for (int i = 0; i < pageItems.length; i += columns) {
      rows.add(pageItems.sublist(i, (i + columns).clamp(0, pageItems.length)));
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            if (rowIndex > 0) const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int colIndex = 0; colIndex < columns; colIndex++)
                  if (colIndex < rows[rowIndex].length)
                    _buildMorePanelItemWidget(rows[rowIndex][colIndex], colorsTheme)
                  else
                    const SizedBox(width: 64), // Placeholder for grid alignment
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build a single action item widget in the more panel
  Widget _buildMorePanelItemWidget(_MorePanelItem item, SemanticColorScheme colorsTheme) {
    return GestureDetector(
      onTap: item.onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorsTheme.bgColorOperate,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SvgPicture.asset(
                  item.icon,
                  package: 'tuikit_atomic_x',
                  colorFilter: ColorFilter.mode(
                    colorsTheme.textColorSecondary,
                    BlendMode.srcIn,
                  ),
                  width: 26,
                  height: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                color: colorsTheme.textColorSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _bottomPadding = MediaQuery.of(context).padding.bottom;
    atomicLocale = AtomicLocalizations.of(context);
    localeProvider = Provider.of<LocaleProvider>(context);

    final panelHeight = _getBottomContainerHeight();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final colors = BaseThemeProvider.colorsOf(context);
        return Column(
          children: [
            _buildInputWidget(colors),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              height: panelHeight,
              constraints: (_showEmojiPanel || _showMorePanel) 
                  ? BoxConstraints(minHeight: panelHeight) 
                  : null,
              child: _showEmojiPanel
                  ? Center(
                      child: FutureBuilder<bool>(
                        future: getEmojiPanelWidget(),
                        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                          return stickerWidget;
                        },
                      ),
                    )
                  : _showMorePanel
                      ? _buildMorePanelContent(colors)
                      : Container(),
            ),
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

  /// WeChat-style input bar layout (aligned to Figma spec):
  /// [Voice/Keyboard toggle] [Input field / Hold-to-talk] [Emoji] [More / Send]
  ///
  /// Figma spec (750px canvas = 2x, all values in logical pt):
  /// - Bar background: #EBF0F6, top shadow: 0px -2px #E6E9EB (via divider)
  /// - Horizontal padding: ~16pt, vertical padding: 8pt
  /// - Icon size: 26pt (52px@2x), input height: 34pt (68px@2x)
  /// - Input field bg: white, border-radius: 4pt (8px@2x)
  /// - Gap between icon and input: ~10pt
  Widget _buildInputWidget(SemanticColorScheme colorsTheme) {
    return Container(
      color: colorsTheme.bgColorInput,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: Voice / Keyboard toggle button (28×28pt icon)
                // SizedBox height matches input field minHeight so button is
                // vertically centered when single-line, and stays at bottom when multi-line.
                if (widget.config.isShowAudioRecorder)
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: GestureDetector(
                        onTap: _toggleVoiceMode,
                        child: _isVoiceMode
                            ? SvgPicture.asset(
                                'chat_assets/icon/keyboard.svg',
                                package: 'tuikit_atomic_x',
                                colorFilter: ColorFilter.mode(
                                  colorsTheme.textColorPrimary,
                                  BlendMode.srcIn,
                                ),
                                width: 26,
                                height: 26,
                              )
                            : SvgPicture.asset(
                                'chat_assets/icon/mic.svg',
                                package: 'tuikit_atomic_x',
                                colorFilter: ColorFilter.mode(
                                  colorsTheme.textColorPrimary,
                                  BlendMode.srcIn,
                                ),
                                width: 26,
                                height: 26,
                              ),
                      ),
                    ),
                  ),
                // Gap: 10pt between voice icon and input field
                const SizedBox(width: 10),

                // Middle: Input field or "Hold to talk" button
                Expanded(
                  child: _isVoiceMode
                      ? _buildHoldToTalkButton(colorsTheme)
                      : Container(
                          constraints: const BoxConstraints(minHeight: 34),
                          decoration: BoxDecoration(
                            color: colorsTheme.textColorButtonDisabled,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildInputTextField(colorsTheme: colorsTheme),
                        ),
                ),

                // Gap: 10pt between input field and emoji icon
                const SizedBox(width: 10),

                // Right: Emoji button (28×28pt icon)
                SizedBox(
                  height: 34,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleEmojiPanel,
                      child: _showEmojiPanel
                          ? SvgPicture.asset(
                              'chat_assets/icon/keyboard.svg',
                              package: 'tuikit_atomic_x',
                              colorFilter: ColorFilter.mode(
                                colorsTheme.textColorPrimary,
                                BlendMode.srcIn,
                              ),
                              width: 28,
                              height: 28,
                            )
                          : SvgPicture.asset(
                              'chat_assets/icon/emoji.svg',
                              package: 'tuikit_atomic_x',
                              colorFilter: ColorFilter.mode(
                                colorsTheme.textColorPrimary,
                                BlendMode.srcIn,
                              ),
                              width: 26,
                              height: 26,
                            ),
                    ),
                  ),
                ),

                // Gap: 10pt between emoji and more/send
                const SizedBox(width: 10),

                // Right: More button or Send button (28×28pt icon)
                SizedBox(
                  height: 34,
                  child: Center(
                    child: _showSendButton && !_isVoiceMode
                        ? _buildSendButton(colorsTheme)
                        : widget.config.isShowMore
                            ? GestureDetector(
                                onTap: _toggleMorePanel,
                                child: SvgPicture.asset(
                                  'chat_assets/icon/add.svg',
                                  package: 'tuikit_atomic_x',
                                  colorFilter: ColorFilter.mode(
                                    colorsTheme.textColorPrimary,
                                    BlendMode.srcIn,
                                  ),
                                  width: 26,
                                  height: 26,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Toggle between voice mode and text input mode
  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (_isVoiceMode) {
        // Switching to voice mode: hide keyboard and panels
        _textEditingFocusNode.unfocus();
        _showEmojiPanel = false;
        _showMorePanel = false;
      } else {
        // Switching back to text mode: show keyboard
        _textEditingFocusNode.requestFocus();
      }
    });
  }

  /// Toggle emoji panel
  void _toggleEmojiPanel() {
    if (!_showEmojiPanel) {
      // Opening emoji panel: hide keyboard
      _isSwitchingPanel = true;
      _textEditingFocusNode.unfocus();
      setState(() {
        _isVoiceMode = false;
        _showEmojiPanel = true;
        _showMorePanel = false;
      });
    } else {
      // Closing emoji panel: show keyboard
      setState(() {
        _showEmojiPanel = false;
      });
      _textEditingFocusNode.requestFocus();
    }
  }

  /// Build the "Hold to talk" button for voice recording
  /// Height: 34pt, bg: white, border-radius: 4pt (aligned to Figma input field spec)
  Widget _buildHoldToTalkButton(SemanticColorScheme colorsTheme) {
    return Listener(
      onPointerDown: _onStartRecording,
      onPointerUp: _onStopRecording,
      onPointerCancel: _onRecordingPointerCancel,
      onPointerMove: (PointerMoveEvent event) {
        _recordOverlayKey.currentState?.updatePointerPosition(event.position);
      },
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: colorsTheme.textColorButtonDisabled,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            atomicLocale.holdToTalk,
            style: TextStyle(
              color: colorsTheme.textColorPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
          _showMorePanel = false;
          _isVoiceMode = false;
        });
      },
    );
  }

  Widget _buildSendButton(SemanticColorScheme colorsTheme) {
    return GestureDetector(
      onTap: _handleSendTextMessage,
      child: Container(
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: colorsTheme.buttonColorPrimaryDefault,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            atomicLocale.send,
            style: TextStyle(
              color: colorsTheme.textColorButton,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  double _getBottomContainerHeight() {
    if (_showEmojiPanel || _showMorePanel) {
      return 280;
    }

    return _bottomPadding;
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
      maxLines: 5,
      style: TextStyle(
        color: widget.colorsTheme.textColorPrimary,
        fontSize: 15,
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintStyle: TextStyle(
          color: widget.colorsTheme.textColorTertiary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 6,
        ),
      ),
      specialTextSpanBuilder: ChatSpecialTextSpanBuilder(
        colorScheme: widget.colorsTheme,
        onTapUrl: (_) {},
      ),
    );
  }
}

/// Data model for a "more" panel grid item
class _MorePanelItem {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const _MorePanelItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
