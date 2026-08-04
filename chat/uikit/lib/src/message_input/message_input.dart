import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/message/message_input_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_list_store_impl.dart';
import 'package:atomic_x_core/impl/message/message_action_store_impl.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tuikit_atomic_x/album_picker/album_picker.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:tencent_chat_uikit/src/message_input/album_picker_media_send_manager.dart';
import 'package:tencent_chat_uikit/src/message_input/utils/image_size_reader.dart';
import 'package:tencent_chat_uikit/src/audio_recoder/audio_recorder.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart';
import 'package:tencent_chat_uikit/src/chat_setting/pages/group_member_picker.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_manager.dart';
import 'package:tencent_chat_uikit/src/emoji_picker/emoji_picker.dart';
import 'package:tencent_chat_uikit/src/file_picker/file_picker.dart';
import 'package:tencent_chat_uikit/src/message_input/src/chat_special_text_span_builder.dart';
import 'package:tencent_chat_uikit/src/message_input/src/record_pointer_up_action.dart';
import 'package:tencent_chat_uikit/src/third_party/extended_text_field/extended_text_field.dart';
import 'package:tencent_chat_uikit/src/audio_player/audio_player_platform.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:tencent_chat_uikit/src/user_picker/user_picker.dart';
import 'package:tencent_chat_uikit/src/video_recorder/video_recorder.dart';

import 'mention/mention_info.dart';
import 'mention/mention_member_picker.dart';
import 'message_input_config.dart';
import 'widget/audio_record_overlay.dart';
import 'widget/quote_preview_bar.dart';

export 'mention/mention_info.dart';
export 'message_input_config.dart';

/// Three-state input mode for the message input bar.
/// - [idle]: Default state on chat entry. Shows hint "发消息或按住说话...", mic icon, keyboard not shown.
/// - [text]: Text input active. Keyboard shown, mic icon on left.
/// - [voice]: Voice recording mode. Shows "Hold to talk" button, keyboard icon on left.
enum _InputMode { idle, text, voice }

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

  /// Timer for distinguishing tap vs long-press in idle mode.
  /// If the pointer is lifted before this fires, it's a tap (→ text mode).
  /// If the timer fires while the pointer is still down, it's a long-press (→ start recording).
  Timer? _idleLongPressTimer;
  bool _isIdleLongPressing = false;
  /// Set when the idle long-press timer has fired (i.e. recording was triggered).
  /// Used to suppress the synthetic GestureDetector.onTap that Flutter still
  /// emits after a long press, so we don't accidentally switch into text mode
  /// and pop up the keyboard right after the user just sent a voice message.
  bool _idleLongPressHandled = false;
  bool _showEmojiPanel = false;
  bool _showMorePanel = false;
  int _morePanelPageIndex = 0;
  final GlobalKey<AudioRecordOverlayState> _recordOverlayKey = GlobalKey();
  OverlayEntry? _recordOverlayEntry;

  /// When `true`, the next [AudioRecordOverlay.onRecordFinish] callback should
  /// be routed to the overlay's voice-to-text state machine instead of being
  /// sent as a voice message. Set to `true` by [_onStopRecording] when the
  /// user released on the convert-to-text button, and reset back to `false`
  /// inside the overlay callback or when the overlay is cancelled.
  bool _pendingConvertRecord = false;

  double _bottomPadding = 0.0;

  /// Flag to indicate we are actively switching to emoji/more panel.
  /// When true, _onFocusChanged should NOT collapse panels.
  bool _isSwitchingPanel = false;

  final GlobalKey<TooltipState> _micTooltipKey = GlobalKey<TooltipState>();

  /// Current input mode: idle (default), text (keyboard shown), or voice (hold-to-talk).
  _InputMode _inputMode = _InputMode.idle;

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
  
  late final _AlbumPickerMediaSendListenerImpl _albumPickerListener;

  // Quote reply state
  MessageInfo? _quotedMessage;

  @override
  void initState() {
    super.initState();
    _messageInputStore = MessageInputStore.create(conversationID: widget.conversationID);
    _conversationListStore = ConversationListStore.create();
    _albumPickerListener = _AlbumPickerMediaSendListenerImpl(this);
    AlbumPickerMediaSendManager.shared.restorePlaceholders(
      conversationID: widget.conversationID,
      listener: _albumPickerListener,
    );
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
      // While the @ mention picker is being shown, focus loss is caused by the
      // route push, not by the user dismissing the input. Keep the current
      // text mode so we can resume editing after picker returns.
      if (_isMentionPickerShowing) {
        return;
      }
      // When focus is truly lost (e.g., tapping outside), collapse emoji and more panels.
      // Only fall back to idle when the input is empty; if the user has typed
      // anything (including @ mentions), keep text mode so the entered content
      // remains visible after the keyboard collapses.
      bool needsRebuild = false;
      if (_showEmojiPanel || _showMorePanel) {
        _showEmojiPanel = false;
        _showMorePanel = false;
        needsRebuild = true;
      }
      if (_inputMode == _InputMode.text && _textEditingController.text.isEmpty) {
        _inputMode = _InputMode.idle;
        needsRebuild = true;
      }
      if (needsRebuild) {
        setState(() {});
      }
    }
  }

  /// Collapse all panels (emoji, more). Called externally when user taps blank area.
  /// In text mode, dismisses the keyboard. Only falls back to idle when the input
  /// is empty, so any already-entered text (including @ mentions) stays visible
  /// after the keyboard collapses. Voice mode is unaffected.
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
    if (_inputMode == _InputMode.text) {
      _textEditingFocusNode.unfocus();
      if (_textEditingController.text.isEmpty) {
        _inputMode = _InputMode.idle;
      }
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

    // Update send button state and switch to text mode
    setState(() {
      _showSendButton = newText.trim().isNotEmpty;
      _inputMode = _InputMode.text;
      _showEmojiPanel = false;
      _showMorePanel = false;
    });
  }

  /// Set a message to be quoted. Shows the quote preview bar and raises keyboard.
  void setQuotedMessage(MessageInfo message) {
    setState(() {
      _quotedMessage = message;
      _inputMode = _InputMode.text;
      // Collapse the more / emoji panels so they don't stay layered under
      // the keyboard and obscure the message list once the user enters
      // quote-reply mode (TAPD bug 1020398462158964479).
      _showEmojiPanel = false;
      _showMorePanel = false;
    });
    _textEditingFocusNode.requestFocus();
  }

  /// Clear the quoted message.
  void clearQuotedMessage() {
    setState(() {
      _quotedMessage = null;
    });
  }

  Future<void> _fetchConversationInfo() async {
    final result = await _conversationListStore.getConversationInfo(
      conversationID: widget.conversationID,
    );
    if (result.isSuccess && result.conversationInfo != null) {
      _conversationInfo = result.conversationInfo;
    }
  }

  @override
  void dispose() {
    _removeRecordOverlay();
    _idleLongPressTimer?.cancel();
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
    final result = await _conversationListStore.getConversationInfo(
      conversationID: widget.conversationID,
    );
    if (result.isSuccess && result.conversationInfo != null) {
      final draft = result.conversationInfo!.draft;
      if (draft != null && draft.isNotEmpty) {
        _setDraftToInput(draft);
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
    // Switch to text mode synchronously so the very first build after the
    // draft load renders the input field with the draft content, instead of
    // briefly showing the idle placeholder "发消息或按住说话..." until the
    // keyboard pops up and triggers a rebuild via viewInsets changes.
    if (mounted) {
      setState(() {
        _inputMode = _InputMode.text;
      });
    } else {
      _inputMode = _InputMode.text;
    }
    // Auto focus after frame is built (keyboard pop-up requires post-frame).
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
      // After the picker route pops (whether by selecting members or by
      // cancelling), restore the input state so the typed text is visible
      // and the keyboard pops back up for continued editing.
      if (!mounted) return;
      if (_textEditingController.text.isNotEmpty && _inputMode != _InputMode.voice) {
        if (_inputMode != _InputMode.text) {
          setState(() {
            _inputMode = _InputMode.text;
          });
        }
        _textEditingFocusNode.requestFocus();
      }
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

    // Explicitly switch back to text mode so the input field renders the
    // mention text instead of the idle hint. Defensive: even if focus state
    // gets out of sync, the UI will still show the typed content.
    setState(() {
      _inputMode = _InputMode.text;
      _showSendButton = newText.trim().isNotEmpty;
    });
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
  Future<void> _handleTextSendMessagePayload() async {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) return;

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.text;
    messageInfo.messagePayload = TextMessagePayload(text: text);

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
      debugPrint("_handleTextSendMessagePayload, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }
  
  void _onPickAlbum() async {
    final themeState = BaseThemeProvider.of(context);
    final locale = localeProvider.locale;

    AlbumPickerConfig config = AlbumPickerConfig(
      mediaFilter: AlbumPickerMediaFilter.imageAndVideo,
      maxSelectionCount: 9,
      itemsPerRow: 3,
      showsCameraItem: false,
      style: AlbumPickerStyle.likeWeChat,
      language: _localeToAlbumPickerLanguage(locale),
    );

    AlbumPickerTheme theme = AlbumPickerTheme(
      primaryColor: themeState.hasCustomPrimaryColor
          ? _hexToColor(themeState.currentPrimaryColor)
          : null,
    );

    try {
      await AlbumPickerMediaSendManager.shared.pickAlbumMedia(
        conversationID: widget.conversationID,
        listener: _albumPickerListener,
        config: config,
        theme: theme,
      );
    } catch (e) {
      debugPrint("_onPickAlbum error: $e");
    }
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  AlbumPickerLanguage _localeToAlbumPickerLanguage(Locale? locale) {
    if (locale == null) return AlbumPickerLanguage.system;
    if (locale.languageCode == 'zh') {
      return (locale.scriptCode == 'Hant')
          ? AlbumPickerLanguage.zhHant
          : AlbumPickerLanguage.zhHans;
    }
    if (locale.languageCode == 'ar') return AlbumPickerLanguage.ar;
    if (locale.languageCode == 'en') return AlbumPickerLanguage.en;
    return AlbumPickerLanguage.system;
  }

  Future<CompletionHandler> _sendMessage(MessageInfo messageInfo) async {
    final payload = _convertToSendPayload(messageInfo.messagePayload);
    if (payload == null) {
      return CompletionHandler()..errorCode = -1..errorMessage = "Unsupported payload";
    }

    // If quoting a message, set quoteInfo on the outgoing message
    MessageInfo? quotedMsg = _quotedMessage;
    if (quotedMsg != null) {
      messageInfo.quoteInfo = MessageQuoteInfo(
        msgID: quotedMsg.msgID,
        timestamp: quotedMsg.timestamp ?? 0,
        sequence: quotedMsg.sequence ?? 0,
        sender: quotedMsg.from,
        messageType: quotedMsg.messageType,
        messagePayload: quotedMsg.messagePayload,
      );
    }

    final option = SendMessageOption(
      atUserList: messageInfo.atUserList.isNotEmpty ? messageInfo.atUserList : null,
      quotedMessage: quotedMsg,
      needReadReceipt: widget.config.enableReadReceipt,
      offlinePushInfo: _createOfflinePushInfo(messageInfo),
    );

    final result = await _messageInputStore.sendMessage(payload: payload, option: option);
    if (!result.isSuccess) {
      if (mounted) {
        Toast.error(context, atomicLocale.sendMessageFail);
      }
    } else {
      // Clear quoted message after successful send
      clearQuotedMessage();
    }

    return result;
  }

  void _sendPlaceholderMessage(MessageInfo placeholder) {
    notificationCenter.post(
      MessageSendNotifyKey.messageSendBegin,
      MessageSendEventData(conversationID: widget.conversationID, message: placeholder),
    );
  }

  void _removePlaceholderMessage(MessageInfo placeholder) {
    if (placeholder.msgID.isNotEmpty) {
      notificationCenter.post(
        MessageActionNotifyKey.messageDelete,
        MessageDeleteEventData(messageIDList: [placeholder.msgID]),
      );
    }
  }

  static SendMessagePayload? _convertToSendPayload(MessagePayload? payload) {
    if (payload == null) return null;
    switch (payload) {
      case TextMessagePayload p:
        return TextSendMessagePayload(text: p.text);
      case ImageMessagePayload p:
        return ImageSendMessagePayload(
          imagePath: p.originalImagePath ?? '',
          imageWidth: p.originalImageWidth,
          imageHeight: p.originalImageHeight,
        );
      case VideoMessagePayload p:
        return VideoSendMessagePayload(
          videoFilePath: p.videoPath ?? '', videoType: p.videoType ?? '',
          duration: p.videoDuration, snapshotPath: p.videoSnapshotPath ?? '',
        );
      case AudioMessagePayload p:
        return AudioSendMessagePayload(audioFilePath: p.audioPath ?? '', duration: p.audioDuration);
      case FileMessagePayload p:
        return FileSendMessagePayload(filePath: p.filePath ?? '', fileName: p.fileName ?? '', fileSize: p.fileSize);
      case FaceMessagePayload p:
        return FaceSendMessagePayload(index: p.faceIndex, data: p.faceData ?? '');
      case CustomMessagePayload p:
        return CustomSendMessagePayload(
          customData: p.customData,
          description: p.description,
          extensionInfo: p.extensionInfo,
        );
      default:
        return null;
    }
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
        content = EmojiManager.createLocalizedStringFromEmojiCodes(context, (message.messagePayload as TextMessagePayload?)?.text ?? '');
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
      case MessageType.audio:
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
      messageInfo.messagePayload = FileMessagePayload(
        filePath: filePickerResult.filePath,
        fileName: filePickerResult.fileName,
        fileSize: filePickerResult.fileSize,
      );
      final result = await _sendMessage(messageInfo);
      if (!result.isSuccess) {
        debugPrint("_onPickFile, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
      }
    }
  }

  Future<void> _onAudioCallTap() => _startCall(CallMediaType.audio);

  Future<void> _onVideoCallTap() => _startCall(CallMediaType.video);

  Future<void> _startCall(CallMediaType mediaType) async {
    final groupID = ChatUtil.getGroupID(widget.conversationID);
    final isGroup = groupID.isNotEmpty;

    List<String> participantIds;
    String? chatGroupId;

    if (!isGroup) {
      // c2c — single peer derived from the conversationID.
      participantIds = [ChatUtil.getUserID(widget.conversationID)];
    } else {
      chatGroupId = groupID;
      final selectedMembers = await Navigator.push<List<UserPickerData>>(
        context,
        MaterialPageRoute(
          builder: (_) => GroupMemberPicker(groupID: groupID),
        ),
      );
      if (selectedMembers == null || selectedMembers.isEmpty) {
        // User cancelled the picker — abort the call.
        return;
      }
      participantIds = selectedMembers.map((member) => member.key).toList();
    }

    final params = PublishParams()
      ..isSticky = false
      ..data = {
        "participantIds": participantIds,
        "mediaType": mediaType,
        "chatGroupId": chatGroupId,
        "timeout": 30,
      };
    TUIEventBus.shared.publish("call.startCall", null, params);
    UIKitUtil.reportChatInvokeCall();
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

      if (result.mediaType == RecordMediaType.photo) {
        messageInfo.messageType = MessageType.image;
        final size = await ImageSizeReader.read(result.filePath);
        messageInfo.messagePayload = ImageMessagePayload(
          originalImagePath: result.filePath,
          originalImageWidth: size?.width ?? 0,
          originalImageHeight: size?.height ?? 0,
        );
      } else {
        messageInfo.messageType = MessageType.video;
        messageInfo.messagePayload = VideoMessagePayload(
          videoPath: result.filePath,
          videoSnapshotPath: result.thumbnailPath,
          videoType: result.filePath.split('.').last,
          videoDuration: (result.durationMs != null) ? (result.durationMs! / 1000).round() : 0,
        );
      }

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
      final size = await ImageSizeReader.read(result.filePath);
      messageInfo.messagePayload = ImageMessagePayload(
        originalImagePath: result.filePath,
        originalImageWidth: size?.width ?? 0,
        originalImageHeight: size?.height ?? 0,
      );
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
    final enableConvert = widget.config.enableVoiceToTextOnRecord;

    _recordOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          type: MaterialType.transparency,
          child: AudioRecordOverlay(
            key: _recordOverlayKey,
            colorScheme: colorScheme,
            atomicLocalizations: atomicLocalizations,
            enableVoiceToText: enableConvert,
            onRecordFinish: (recordInfo) {
              // When the user released on the convert button, we DO NOT close
              // the overlay or send the audio: instead, hand the captured
              // file path to the overlay's converting state machine.
              if (_pendingConvertRecord) {
                _pendingConvertRecord = false;
                if (recordInfo.errorCode == AudioRecordResultCode.success ||
                    recordInfo.errorCode == AudioRecordResultCode.successExceedMaxDuration) {
                  _recordOverlayKey.currentState
                      ?.enterConverting(recordInfo.path, recordInfo.duration);
                  return;
                }
                // Recording too short / failed: fall through to default
                // close-and-toast behavior (legacy path).
              }
              _removeRecordOverlay();
              _onAudioRecorderFinished(recordInfo);
            },
            onRecordCancelled: () {
              _pendingConvertRecord = false;
              _removeRecordOverlay();
            },
            onSendText: (text) {
              _removeRecordOverlay();
              _sendTextMessageFromVoice(text);
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
    messageInfo.messageType = MessageType.audio;
    messageInfo.messagePayload = AudioMessagePayload(
      audioPath: recordInfo.path,
      audioDuration: recordInfo.duration,
    );

    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint("_onRecordFinish, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}");
    }
  }

  /// Send a plain-text message constructed from voice-to-text conversion.
  /// Used by [AudioRecordOverlay]'s editing-state "send" button.
  void _sendTextMessageFromVoice(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.text;
    messageInfo.messagePayload = TextMessagePayload(text: trimmed);
    final result = await _sendMessage(messageInfo);
    if (!result.isSuccess) {
      debugPrint(
        "_sendTextMessageFromVoice, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}",
      );
    }
  }

  void _onStartRecording(PointerDownEvent event) async {
    AudioPlayerPlatform.stop();

    // Set flag BEFORE async permission check so that _onStopRecording
    // can correctly cancel if the user lifts their finger during the await.
    _recordingStarter?.cancel();
    _isWaitingToStartRecord = true;

    final micStatus = await Permission.check(PermissionType.microphone);
    if (micStatus != PermissionStatus.granted) {
      // If PointerUp already fired during await, _isWaitingToStartRecord
      // was reset — no further cleanup needed.
      if (_isWaitingToStartRecord) {
        _isWaitingToStartRecord = false;
      }
      // [bug#161275344] Known caveat on HarmonyOS: the finger is still down
      // here, and the permission dialog is a system UIExtension window layered
      // over ours, so it receives the PointerUp instead of us. OhosTouchProcessor
      // (inside libflutter.so) never sees the sequence close and discards the
      // *next* PointerDown as a duplicate — the long-press right after granting
      // does nothing, and only the one after that works. Nothing in the Dart or
      // ArkTS layer can reset that state; it needs a flutter_ohos fix.
      await Permission.checkAndRequest(context, [PermissionType.microphone]);
      return;
    }

    // If PointerUp fired during the await above, abort — recording was
    // already cancelled by _onStopRecording.
    if (!_isWaitingToStartRecord) {
      return;
    }

    // [bug#161275344] Defer overlay insertion to the moment recording actually
    // starts. Rationale: the overlay is a full-screen transparent Material and
    // steals all pointer events once inserted. When _onStartRecording is fired
    // by the 200ms idle-longpress timer (see _buildIdleInputArea), the user may
    // still lift their finger shortly after; if the overlay is up already, the
    // resulting PointerUp is routed to the overlay (with no matching PointerDown
    // there) and _onStopRecording — which lives on the original Listener — is
    // never invoked, leaving the recording UI stuck. Keeping the overlay off
    // until the 100ms starter fires means PointerUp during the "waiting" window
    // still reaches _onStopRecording and correctly cancels via the
    // _isWaitingToStartRecord branch.
    _recordingStarter = Timer(const Duration(milliseconds: 100), () {
      if (!_isWaitingToStartRecord) return;
      _isWaitingToStartRecord = false;

      _showRecordOverlay();

      // Overlay's State needs a frame to be constructed before we can drive it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlayState = _recordOverlayKey.currentState;
        if (overlayState == null) return;
        overlayState.resetRecordingState();
        final String path = ChatUtil.generateMediaPath(
          messageType: MessageType.audio,
          prefix: "",
          withExtension: "m4a",
          isCache: true,
        );
        overlayState.startRecord(filePath: path);
      });
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
      final overlayState = _recordOverlayKey.currentState;
      final overCancel = overlayState?.isPointerOverCancelButton(event.position) ?? false;
      final overConvert = overlayState?.isPointerOverConvertButton(event.position) ?? false;
      final action = recordPointerUpAction(
        overCancel: overCancel,
        overConvert: overConvert,
      );
      switch (action) {
        case RecordPointerUpAction.cancel:
          // cancelRecord callback will call _removeRecordOverlay.
          overlayState?.cancelRecord();
          break;
        case RecordPointerUpAction.convert:
          // Stop recording; the captured file is routed to the overlay's
          // converting state machine in the onRecordFinish handler.
          _pendingConvertRecord = true;
          overlayState?.stopRecord();
          break;
        case RecordPointerUpAction.send:
          // stopRecord callback will call _removeRecordOverlay via onRecordFinish.
          overlayState?.stopRecord();
          break;
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

  Widget _buildMorePanelContent(SemanticColorScheme colorsTheme) {
    final List<_MorePanelItem> items = [];

    if (widget.config.isShowAlbum) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/image_action.svg',
        title: atomicLocale.album,
        onTap: _onPickAlbum,
      ));
    }

    if (widget.config.isShowPhotoTaker) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/camera_action.svg',
        title: atomicLocale.takeAPhoto,
        onTap: _onTakePhoto,
      ));
    }

    if (widget.config.isShowVideoRecorder) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/record_action.svg',
        title: atomicLocale.recordAVideo,
        onTap: _onTakeVideo,
      ));
    }

    if (widget.config.isShowFile) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/file_action.svg',
        title: atomicLocale.file,
        onTap: _onPickFile,
      ));
    }

    // HarmonyOS: CallKit (client_uikit/atomic-x/flutter/call) 暂未适配纯血鸿蒙,
    // 底层 tencent_calls_uikit 在 ohos 上不可用,点了会 crash / no-op。
    // 先在鸿蒙平台隐藏音视频通话入口;等 CallKit 拉出 ohos 分支后去掉这个判断即可。
    final bool hideCallOnOhos = Platform.operatingSystem == 'ohos';

    if (widget.config.isShowVideoCall && !hideCallOnOhos) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/video_call_action.svg',
        title: atomicLocale.videoCall,
        onTap: _onVideoCallTap,
      ));
    }
    if (widget.config.isShowAudioCall && !hideCallOnOhos) {
      items.add(_MorePanelItem(
        icon: 'chat_assets/icon/audio_call_action.svg',
        title: atomicLocale.audioCall,
        onTap: _onAudioCallTap,
      ));
    }

    // Each page shows 2 rows × 4 columns = 8 items max
    const int itemsPerPage = 8;
    final int pageCount = items.isEmpty ? 0 : (items.length / itemsPerPage).ceil();

    return Container(
      color: colorsTheme.bgColorInput,
      child: Column(
        children: [
          Container(
            height: 0.5,
            color: colorsTheme.textColorPrimary.withValues(alpha: 0.1),
          ),
          Expanded(
            child: pageCount == 0
                ? const SizedBox.shrink()
                : PageView.builder(
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
                  package: 'tencent_chat_uikit',
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
              style: FontScheme.caption3Regular.copyWith(
                color: colorsTheme.textColorSecondary,
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
    _bottomPadding = MediaQuery.paddingOf(context).bottom;
    atomicLocale = AtomicLocalizations.of(context);
    localeProvider = Provider.of<LocaleProvider>(context);

    final panelHeight = _getBottomContainerHeight();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final colors = BaseThemeProvider.colorsOf(context);
        return Column(
          children: [
            _buildInputWidget(colors),
            if (_quotedMessage != null)
              QuotePreviewBar(
                quotedMessage: _quotedMessage!,
                onClose: clearQuotedMessage,
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(color: colors.bgColorInput),
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
      onSendClick: _handleTextSendMessagePayload,
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
                        child: _inputMode == _InputMode.voice
                            ? SvgPicture.asset(
                                'chat_assets/icon/keyboard.svg',
                                package: 'tencent_chat_uikit',
                                colorFilter: ColorFilter.mode(
                                  colorsTheme.textColorPrimary,
                                  BlendMode.srcIn,
                                ),
                                width: 26,
                                height: 26,
                              )
                            : SvgPicture.asset(
                                'chat_assets/icon/mic.svg',
                                package: 'tencent_chat_uikit',
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
                  child: _inputMode == _InputMode.voice
                      ? _buildHoldToTalkButton(colorsTheme)
                      : _inputMode == _InputMode.idle
                          ? _buildIdleInputArea(colorsTheme)
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
                              package: 'tencent_chat_uikit',
                              colorFilter: ColorFilter.mode(
                                colorsTheme.textColorPrimary,
                                BlendMode.srcIn,
                              ),
                              width: 28,
                              height: 28,
                            )
                          : SvgPicture.asset(
                              'chat_assets/icon/emoji.svg',
                              package: 'tencent_chat_uikit',
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
                    child: _showSendButton && _inputMode != _InputMode.voice
                        ? _buildSendButton(colorsTheme)
                        : widget.config.isShowMore
                            ? GestureDetector(
                                onTap: _toggleMorePanel,
                                child: SvgPicture.asset(
                                  'chat_assets/icon/add.svg',
                                  package: 'tencent_chat_uikit',
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

  /// Toggle between voice mode and text input mode.
  /// From text/idle → voice: dismiss keyboard and panels.
  /// From voice → text: show keyboard.
  void _toggleVoiceMode() {
    setState(() {
      if (_inputMode != _InputMode.voice) {
        // Switching to voice mode: hide keyboard and panels
        _inputMode = _InputMode.voice;
        _textEditingFocusNode.unfocus();
        _showEmojiPanel = false;
        _showMorePanel = false;
      } else {
        // Switching back to text mode: show keyboard
        _inputMode = _InputMode.text;
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
        _inputMode = _InputMode.text;
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
            style: FontScheme.caption1Medium.copyWith(
              color: colorsTheme.textColorPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the idle-mode input area.
  /// - Tap: switch to text mode and show keyboard (via GestureDetector to win arena over parent).
  /// - Long press (pointer held > 200ms): start recording directly (stay in idle mode).
  Widget _buildIdleInputArea(SemanticColorScheme colorsTheme) {
    return GestureDetector(
      onTap: () {
        // Cancel any pending long-press timer
        _idleLongPressTimer?.cancel();
        _idleLongPressTimer = null;
        // Flutter's TapGestureRecognizer has no time upper bound, so a long
        // press that already triggered recording will still fire onTap when
        // the pointer is released. Detect that here and stay in idle mode,
        // otherwise we'd switch to text mode + pop the keyboard right after
        // the user sent a voice message.
        if (_idleLongPressHandled) {
          _idleLongPressHandled = false;
          return;
        }
        setState(() {
          _showEmojiPanel = false;
          _showMorePanel = false;
          _inputMode = _InputMode.text;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textEditingFocusNode.requestFocus();
          }
        });
      },
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          _isIdleLongPressing = false;
          _idleLongPressHandled = false;
          _idleLongPressTimer?.cancel();
          _idleLongPressTimer = Timer(const Duration(milliseconds: 200), () {
            _isIdleLongPressing = true;
            _idleLongPressHandled = true;
            _onStartRecording(event);
          });
        },
        onPointerUp: (PointerUpEvent event) {
          if (_isIdleLongPressing) {
            _onStopRecording(event);
            _isIdleLongPressing = false;
          }
          // Tap case is handled by GestureDetector.onTap above; the
          // _idleLongPressHandled flag tells onTap whether to suppress
          // the mode switch (long-press → recording path).
        },
        onPointerCancel: (PointerCancelEvent event) {
          if (_isIdleLongPressing) {
            _onRecordingPointerCancel(event);
            _isIdleLongPressing = false;
          } else {
            _idleLongPressTimer?.cancel();
            _idleLongPressTimer = null;
          }
        },
        onPointerMove: (PointerMoveEvent event) {
          if (_isIdleLongPressing) {
            _recordOverlayKey.currentState?.updatePointerPosition(event.position);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          decoration: BoxDecoration(
            color: colorsTheme.textColorButtonDisabled,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Text(
            atomicLocale.sendMessageOrHoldToTalk,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FontScheme.caption1Regular.copyWith(
              color: colorsTheme.textColorTertiary,
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
      hintText: null,
      onTap: () {
        _textEditingFocusNode.requestFocus();
        setState(() {
          _showEmojiPanel = false;
          _showMorePanel = false;
          _inputMode = _InputMode.text;
        });
      },
    );
  }

  Widget _buildSendButton(SemanticColorScheme colorsTheme) {
    return GestureDetector(
      onTap: _handleTextSendMessagePayload,
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
            style: FontScheme.caption2Regular.copyWith(
              color: colorsTheme.textColorButton,
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
  final String? hintText;

  const _MentionTextField({
    required this.controller,
    required this.focusNode,
    required this.colorsTheme,
    this.onTap,
    this.hintText,
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
      style: FontScheme.caption1Regular.copyWith(
        color: widget.colorsTheme.textColorPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: FontScheme.caption1Regular.copyWith(
          color: widget.colorsTheme.textColorTertiary,
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

// MARK: - AlbumPickerMediaSendListener Implementation

class _AlbumPickerMediaSendListenerImpl implements AlbumPickerMediaSendListener {
  final MessageInputState _state;

  _AlbumPickerMediaSendListenerImpl(this._state);

  @override
  void onSendMessage(MessageInfo messageInfo) {
    _state._sendMessage(messageInfo).then((result) {
      if (!result.isSuccess) {
        debugPrint("AlbumPicker onSendMessage failed: ${result.errorCode}, ${result.errorMessage}");
      }
    });
  }

  @override
  void onSendPlaceholderMessage(MessageInfo placeholder) {
    _state._sendPlaceholderMessage(placeholder);
  }

  @override
  void onRemovePlaceholderMessage(MessageInfo placeholder) {
    _state._removePlaceholderMessage(placeholder);
  }
}
