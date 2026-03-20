import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/utils/asr_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/call_ui_extension.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_text_parser.dart';
import 'package:tuikit_atomic_x/message_list/widgets/asr_popup_menu.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_item.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_tongue_widget.dart';
import 'package:tuikit_atomic_x/message_list/widgets/forward/forward_service.dart';
import 'package:tuikit_atomic_x/third_party/scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuikit_atomic_x/third_party/visibility_detector/visibility_detector.dart';

export 'message_list_config.dart';
export 'widgets/message_bubble.dart';
export 'widgets/message_item.dart';
export 'widgets/message_types/custom_message_widget.dart';
export 'widgets/message_types/system_message_widget.dart';
export 'widgets/multi_select_bottom_bar.dart';
export 'widgets/message_checkbox.dart';
export 'widgets/message_reaction_bar.dart';
export 'widgets/reaction_emoji_picker.dart';
export 'widgets/reaction_detail_sheet.dart';
export 'utils/recent_emoji_manager.dart';
export 'widgets/message_tongue_widget.dart';

typedef OnUserClick = void Function(String userID);

/// Callback when user long presses on avatar (for @ mention feature)
/// [userID] is the user ID of the message sender
/// [displayName] is the display name of the message sender
typedef OnUserLongPress = void Function(String userID, String displayName);

/// Callback when call message is clicked in C2C conversation
/// [userID] is the user ID of the other party
/// [isVideoCall] is true for video call, false for voice call
typedef OnCallMessageClick = void Function(String userID, bool isVideoCall);

/// Multi-select mode state callback
typedef OnMultiSelectModeChanged = void Function(bool isMultiSelectMode, int selectedCount);

/// Multi-select mode state
class MultiSelectState {
  final bool isActive;
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final Future<void> Function(BuildContext context) onForward;

  const MultiSelectState({
    required this.isActive,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
    required this.onForward,
  });
}

/// Multi-select mode action callbacks
class MultiSelectCallbacks {
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onForward;

  const MultiSelectCallbacks({
    required this.onCancel,
    required this.onDelete,
    required this.onForward,
  });
}

class MessageCustomAction {
  final String title;
  final String assetName;
  final String? package;
  final IconData? systemIconFallback;
  final void Function(MessageInfo) action;

  const MessageCustomAction({
    required this.title,
    this.assetName = '',
    this.package,
    this.systemIconFallback,
    required this.action,
  });
}

class MessageList extends StatefulWidget {
  final String conversationID;
  final MessageListConfigProtocol config;
  final MessageInfo? locateMessage;
  final OnUserClick? onUserClick;
  /// Callback when user long presses on avatar (for @ mention feature in group chat)
  final OnUserLongPress? onUserLongPress;
  /// Callback when call message is clicked in C2C conversation
  final OnCallMessageClick? onCallMessageClick;
  final List<MessageCustomAction> customActions;
  /// Multi-select mode change callback
  final OnMultiSelectModeChanged? onMultiSelectModeChanged;
  /// Multi-select state change callback (includes action methods)
  final void Function(MultiSelectState? state)? onMultiSelectStateChanged;
  /// Group at-mention info list from ConversationInfo for tongue navigation
  final List<GroupAtInfo>? groupAtInfoList;
  /// Initial unread count from ConversationInfo when entering the chat
  final int initialUnreadCount;

  const MessageList({
    super.key,
    required this.conversationID,
    this.config = const ChatMessageListConfig(),
    this.locateMessage,
    this.onUserClick,
    this.onUserLongPress,
    this.onCallMessageClick,
    this.customActions = const [],
    this.onMultiSelectModeChanged,
    this.onMultiSelectStateChanged,
    this.groupAtInfoList,
    this.initialUnreadCount = 0,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late MessageListStore _messageListStore;
  GroupSettingStore? _groupSettingStore;
  late AtomicLocalizations _atomicLocale;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  List<MessageInfo> _messages = [];
  StreamSubscription<MessageEvent>? _messageEventSubscription;
  bool isLoading = false;
  bool _isLoadingNewer = false;
  bool _isNavigatingToUnread = false;
  bool _isNavigatingToAtMention = false;
  bool _isReloadingLatest = false;
  int? _navigatingAtTargetSeq;

  bool hasMoreOlderMessages = true;
  bool hasMoreNewerMessages = false;
  bool _isInitialLoad = true;

  String? _highlightedMessageId;

  Widget? _callStatusWidget;

  static const int _messageAggregationTime = 300;

  final Set<String> _pendingReceiptMessageIDs = {};
  final Set<String> _sentReceiptMessageIDs = {};
  Timer? _receiptTimer;
  static const Duration _receiptDebounceInterval = Duration(milliseconds: 800);
  // Threshold: auto-load older messages when within this many items of the oldest message
  static const int _loadOlderMessagesThreshold = 5;

  // Multi-select mode state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIDs = {};

  // Tongue (小舌头) state
  TongueType _tongueType = TongueType.none;
  int _newMessageCount = 0;
  String? _atMentionText;
  int? _atMessageSeq;
  static const int _tongueScrollThreshold = 15;

  // Unread messages tongue (右上角未读消息小舌头) state
  TongueType _unreadTongueType = TongueType.none;
  int _initialUnreadCount = 0;
  int? _oldestUnreadMessageSeq;
  bool _pendingUnreadCheck = false; // Defer tongue display until visibility check

  // @mention tracking for sequential navigation
  List<GroupAtInfo> _remainingAtInfoList = [];

  // ASR display manager for voice-to-text feature
  late AsrDisplayManager _asrDisplayManager;

  // Translation display manager for text translation feature
  late TranslationDisplayManager _translationDisplayManager;

  // Listener references for proper removal
  late final VoidCallback _messageListStateChangedListener;
  late final VoidCallback _scrollListenerCallback;
  late final VoidCallback _groupSettingStateChangedListener;

  // AutomaticKeepAliveClientMixin requires this method to be implemented
  // Returning true indicates that the state is maintained even if the Widget is not in the view.
  @override
  bool get wantKeepAlive => true;

  /// Whether in multi-select mode
  bool get isMultiSelectMode => _isMultiSelectMode;

  /// List of selected messages
  List<MessageInfo> get selectedMessages => 
      _messages.where((m) => m.msgID != null && _selectedMessageIDs.contains(m.msgID)).toList();

  /// Number of selected messages
  int get selectedCount => _selectedMessageIDs.length;

  @override
  void initState() {
    super.initState();

    _asrDisplayManager = AsrDisplayManager();
    _translationDisplayManager = TranslationDisplayManager();

    // Initialize listener references
    _messageListStateChangedListener = _onMessageListStateChanged;
    _scrollListenerCallback = _scrollListener;
    _groupSettingStateChangedListener = _onGroupSettingStateChanged;

    _messageListStore =
        MessageListStore.create(conversationID: widget.conversationID, messageListType: MessageListType.history);
    _messageListStore.addListener(_messageListStateChangedListener);
    _messageEventSubscription = _messageListStore.messageEventStream.listen(_onMessageEvent);
    _itemPositionsListener.itemPositions.addListener(_scrollListenerCallback);

    if (widget.conversationID.startsWith(groupConversationIDPrefix)) {
      final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
      _groupSettingStore = GroupSettingStore.create(groupID: groupId);
      _groupSettingStore!.addListener(_groupSettingStateChangedListener);
      _loadGroupAttributes();
    }

    _initAtMentionTongue();
    _initUnreadTongue();
    _loadInitialMessages();
  }

  Widget _buildTimeDivider(String timeString, SemanticColorScheme colorsTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorsTheme.strokeColorPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              color: colorsTheme.textColorTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageListStore.removeListener(_messageListStateChangedListener);
    _messageEventSubscription?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListenerCallback);
    _groupSettingStore?.removeListener(_groupSettingStateChangedListener);
    _receiptTimer?.cancel();
    _asrDisplayManager.dispose();
    _translationDisplayManager.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final positions = _itemPositionsListener.itemPositions.value;

    // Load newer messages when scrolled to top (index 0 = newest)
    if (!_isLoadingNewer && !_isNavigatingToUnread && hasMoreNewerMessages) {
      if (_highlightedMessageId == null && positions.isNotEmpty && positions.any((pos) => pos.index <= 0)) {
        _loadNewerMessages();
      }
    }

    // Auto-load older messages when scrolled near the oldest message (reverse list: largest index = oldest)
    if (!isLoading && !_isReloadingLatest && hasMoreOlderMessages && positions.isNotEmpty) {
      final maxIndex = positions.map((p) => p.index).reduce((a, b) => a > b ? a : b);
      if (maxIndex >= _messages.length - _loadOlderMessagesThreshold) {
        _loadPreviousMessages();
      }
    }

    // Tongue visibility logic
    if (!widget.config.isSupportTongue) return;
    _updateTongueState(positions);
  }

  void _updateTongueState(Iterable<ItemPosition> positions) {
    if (positions.isEmpty) return;

    // Don't change tongue state while reloading latest messages — keep the
    // loading spinner visible until the reload finishes.
    if (_isReloadingLatest) return;

    final minIndex = positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
    final isScrolledPastThreshold = minIndex > _tongueScrollThreshold;
    final isAtBottom = positions.any((pos) => pos.index <= 1);

    if (isAtBottom) {
      if (_tongueType != TongueType.none || _newMessageCount > 0) {
        setState(() {
          _newMessageCount = 0;
          if (_remainingAtInfoList.isEmpty) {
            // Only hide tongue when truly at the bottom of ALL messages.
            // If there are still newer messages to load, keep backToLatest
            // visible so the user can tap to jump to the latest.
            if (hasMoreNewerMessages) {
              _tongueType = TongueType.backToLatest;
            } else {
              _tongueType = TongueType.none;
            }
          }
        });
      }
      return;
    }

    if (isScrolledPastThreshold) {
      final newType = _computeTongueType();
      if (newType != _tongueType) {
        setState(() {
          _tongueType = newType;
        });
      }
    } else {
      // Not scrolled past threshold — only hide tongue types that require
      // the threshold (atMention).  Keep newMessages and backToLatest tongue
      // visible: the user is NOT at bottom (handled above) so they should
      // still see the indicator to jump back to the latest position.
      if (_tongueType != TongueType.none
          && _tongueType != TongueType.newMessages
          && _tongueType != TongueType.backToLatest
          && _remainingAtInfoList.isEmpty) {
        setState(() {
          _tongueType = TongueType.none;
        });
      }
    }
  }

  TongueType _computeTongueType() {
    if (_remainingAtInfoList.isNotEmpty && _unreadTongueType == TongueType.none) return TongueType.atMention;
    if (_newMessageCount > 0) return TongueType.newMessages;
    return TongueType.backToLatest;
  }

  Future<void> _loadInitialMessages() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    if (widget.locateMessage != null) {
      debugPrint('messageList, _loadInitialMessages->_loadMessagesAround');
      await _loadMessagesAround(widget.locateMessage!);
    } else {
      debugPrint('messageList, _loadInitialMessages->_loadLatestMessages');
      await _loadLatestMessages();
    }

    setState(() {
      isLoading = false;
      _isInitialLoad = false;
    });
  }

  void _onMessageListStateChanged() {
    final state = _messageListStore.messageListState;

    debugPrint('messageList, _onMessageListStateChanged, '
        'msgCount: ${state.messageList.length}, '
        'navUnread: $_isNavigatingToUnread, navAt: $_isNavigatingToAtMention');

    if (_isNavigatingToUnread && _oldestUnreadMessageSeq != null && _oldestUnreadMessageSeq! > 0) {
      // When navigating to unread, set ALL state in one setState call so that
      // only a single build frame is produced.  The await in
      // _onUnreadTongueTap creates a microtask boundary, so any setState
      // after the await would cause a second build.  By doing everything
      // here (synchronously during notifyListeners) we avoid that.
      setState(() {
        _messages = state.messageList.reversed.toList();
        hasMoreNewerMessages = state.hasMoreNewerMessage;
        hasMoreOlderMessages = state.hasMoreOlderMessage;
        isLoading = false;
      });
      _scrollToSeq(_oldestUnreadMessageSeq!);
      return;
    }

    if (_isNavigatingToAtMention && _navigatingAtTargetSeq != null) {
      final targetSeq = _navigatingAtTargetSeq!;
      debugPrint('messageList, _onMessageListStateChanged [AT_MENTION], targetSeq: $targetSeq, messageCount: ${state.messageList.length}');
      setState(() {
        _messages = state.messageList.reversed.toList();
        hasMoreNewerMessages = state.hasMoreNewerMessage;
        hasMoreOlderMessages = state.hasMoreOlderMessage;
        isLoading = false;
      });
      _scrollToSeq(targetSeq, alignment: 0);
      // Highlight the target @message
      final idx = _messages.indexWhere((m) {
        final seq = int.tryParse(m.rawMessage?.seq ?? '') ?? 0;
        return seq == targetSeq;
      });
      if (idx != -1 && _messages[idx].msgID != null) {
        setState(() {
          _highlightedMessageId = _messages[idx].msgID;
        });
      }
      _remainingAtInfoList.removeWhere((info) => info.msgSeq == targetSeq);
      _navigatingAtTargetSeq = null;
      _activateAtMentionTongueIfNeeded();
      return;
    }

    final oldLength = _messages.length;
    // Remember the first message's ID to detect head-insertion (new messages)
    // vs tail-append (older history messages).
    final oldFirstMsgID = _messages.isNotEmpty ? _messages.first.msgID : null;

    setState(() {
      _messages = state.messageList.reversed.toList();
    });

    // Only compensate when new messages are inserted at the HEAD of the list
    // (index 0 = newest in reverse list).  Detect this by checking whether
    // the first message's ID has changed — if it changed, newer messages were
    // prepended; if it didn't, older messages were appended at the tail and
    // no compensation is needed (existing item indices are unchanged).
    final insertedCount = _messages.length - oldLength;
    final newFirstMsgID = _messages.isNotEmpty ? _messages.first.msgID : null;
    final isHeadInsertion = insertedCount > 0 && oldFirstMsgID != null && newFirstMsgID != oldFirstMsgID;

    // Skip compensation when _loadNewerMessages is in progress — it already
    // does its own jumpTo after the await returns.
    if (isHeadInsertion && !_isLoadingNewer && !_isUserAtBottom() && _itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final anchor = positions.reduce(
          (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
        );
        // Jump immediately (synchronously) — same approach as _loadNewerMessages —
        // to avoid the visible "scroll then snap back" flicker that
        // addPostFrameCallback would cause.
        _itemScrollController.jumpTo(
          index: anchor.index + insertedCount,
          alignment: anchor.itemLeadingEdge,
        );
      }
    }

    if (widget.locateMessage != null && _isInitialLoad) {
      _isInitialLoad = false;
      _scrollToMessageAndHighlight(widget.locateMessage!.msgID!);
      return;
    }
  }

  void _onMessageEvent(MessageEvent event) {
    switch (event) {
      case FetchMessagesEvent():
        debugPrint('messageList, FetchMessagesEvent, locateMessage: ${widget.locateMessage}, '
            'isLoading: $isLoading, isNavigatingToUnread: $_isNavigatingToUnread, '
            'isNavigatingToAtMention: $_isNavigatingToAtMention');
        _clearUnreadCount();
        if (widget.locateMessage == null && !isLoading && !_isNavigatingToUnread && !_isNavigatingToAtMention && !_isReloadingLatest) {
          debugPrint('messageList, FetchMessagesEvent -> _scrollToBottom');
          _scrollToBottom();
        }
        // Fetch reactions for loaded messages
        if (widget.config.isSupportReaction) {
          _fetchMessageReactions(event.messageList);
        }
        // Check unread tongue visibility after initial messages are loaded.
        // Must wait for scroll and layout to settle (two frames):
        // Frame 1: _scrollToBottom's jumpTo executes
        // Frame 2: layout completes, itemPositions are updated
        if (_initialUnreadCount > 0 && _pendingUnreadCheck) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _checkUnreadTongueVisibility();
            });
          });
        }
        break;
      case FetchMoreMessagesEvent():
        // scrollable_positioned_list can keep position, no need to scroll
        // Fetch reactions for newly loaded messages
        if (widget.config.isSupportReaction) {
          _fetchMessageReactions(event.messageList);
        }
        break;
      case SendMessageEvent():
        if (!isLoading) {
          _scrollToBottom();
        }
        break;
      case RecvMessageEvent():
        _clearUnreadCount();
        if (!isLoading && _isUserAtBottom()) {
          _scrollToBottom();
        } else if (!_isUserAtBottom() && widget.config.isSupportTongue) {
          setState(() {
            _newMessageCount++;
            _tongueType = _computeTongueType();
          });
        }
        // Fetch reactions for new message
        if (widget.config.isSupportReaction) {
          _fetchMessageReactions([event.message]);
        }
        break;
      case DeleteMessagesEvent():
        // no need to scroll
        break;
    }
  }

  Future<void> _fetchMessageReactions(List<MessageInfo> messages) async {
    if (messages.isEmpty) return;
    await _messageListStore.fetchMessageReactions(
      messageList: messages,
      maxUserCountPerReaction: 3,
    );
  }

  bool _isUserAtBottom() {
    if (!_itemScrollController.isAttached) return true;
    final positions = _itemPositionsListener.itemPositions.value;
    return positions.isNotEmpty && positions.any((pos) => pos.index <= 1);
  }

  Future<void> _loadLatestMessages() async {
    final option = MessageFetchOption()
      ..direction = MessageFetchDirection.older
      ..pageCount = 20;

    final result = await _messageListStore.fetchMessageList(option: option);
    if (mounted) {
      setState(() {
        hasMoreOlderMessages = result.isSuccess && _messageListStore.messageListState.hasMoreOlderMessage;
        hasMoreNewerMessages = false;
      });
    }
  }

  Future<void> _loadMessagesAround(MessageInfo message) async {
    debugPrint('messageList, _loadMessagesAround');
    final option = MessageFetchOption()
      ..message = message
      ..direction = MessageFetchDirection.both
      ..pageCount = 20;
    final result = await _messageListStore.fetchMessageList(option: option);
    if (mounted) {
      setState(() {
        hasMoreNewerMessages = result.isSuccess && _messageListStore.messageListState.hasMoreNewerMessage;
        hasMoreOlderMessages = result.isSuccess && _messageListStore.messageListState.hasMoreOlderMessage;
      });
    }
  }

  Future<void> _loadPreviousMessages() async {
    if (isLoading || !hasMoreOlderMessages) return;

    debugPrint('messageList, _loadPreviousMessages');

    setState(() {
      isLoading = true;
    });

    final result = await _messageListStore.fetchMoreMessageList(direction: MessageFetchDirection.older);
    if (mounted) {
      setState(() {
        hasMoreOlderMessages = result.isSuccess && _messageListStore.messageListState.hasMoreOlderMessage;
        isLoading = false;
      });
    }
  }

  Future<void> _loadNewerMessages() async {
    if (_isLoadingNewer || !hasMoreNewerMessages) return;

    setState(() {
      _isLoadingNewer = true;
    });

    final oldListLength = _messages.length;
    final result = await _messageListStore.fetchMoreMessageList(direction: MessageFetchDirection.newer);
    final newListLength = _messages.length;
    if (mounted && newListLength > oldListLength) {
      final newIndex = newListLength - oldListLength;
      _itemScrollController.jumpTo(index: newIndex);
    }

    if (mounted) {
      setState(() {
        hasMoreNewerMessages = result.isSuccess && _messageListStore.messageListState.hasMoreNewerMessage;
        _isLoadingNewer = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && _messages.isNotEmpty) {
        _itemScrollController.jumpTo(index: 0);
      }
    });
  }

  void _scrollToMessageAndHighlight(String messageID) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_itemScrollController.isAttached) return;

      final targetIndex = _messages.indexWhere((m) => m.msgID == messageID);
      if (targetIndex != -1) {
        debugPrint('messageList, _scrollToMessageAndHighlight, jumpToIndex:$targetIndex');

        _itemScrollController.jumpTo(index: targetIndex);

        setState(() {
          _highlightedMessageId = messageID;
        });
      }
    });
  }

  String _getMessageKey(MessageInfo message) {
    return '${message.msgID}-${message.timestamp}';
  }

  Widget _renderItem(BuildContext context, int index) {
    if (index >= _messages.length) return Container();

    final message = _messages[index];
    final colors = BaseThemeProvider.colorsOf(context);

    final timeString = _getMessageTimeString(index);
    final shouldShowTime = widget.config.isShowTimeMessage && timeString != null;
    Widget messageWidget = _buildMessageItem(message, colors);

    // Add spacing between messages
    final spacing =
        index < _messages.length - 1 ? SizedBox(height: widget.config.cellSpacing) : const SizedBox.shrink();

    // Loading indicator at the newest end (index 0 area in reverse list, visually at bottom)
    if (_isLoadingNewer && index == _messages.length - 1) {
      return Column(
        children: [
          if (shouldShowTime) _buildTimeDivider(timeString, colors),
          messageWidget,
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CupertinoActivityIndicator(),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (shouldShowTime) _buildTimeDivider(timeString, colors),
        messageWidget,
        spacing,
      ],
    );
  }

  Widget _buildMessageItem(MessageInfo message, SemanticColorScheme colors) {
    bool isGroup = widget.conversationID.startsWith(groupConversationIDPrefix);

    final messageWidget = RepaintBoundary(
      child: ListenableBuilder(
        listenable: Listenable.merge([_asrDisplayManager, _translationDisplayManager]),
        builder: (context, child) {
          return MessageItem(
            key: ValueKey(_getMessageKey(message)),
            message: message,
            conversationID: widget.conversationID,
            isGroup: isGroup,
            maxWidth: MediaQuery.of(context).size.width - 32,
            messageListStore: _messageListStore,
            isHighlighted: _highlightedMessageId == message.msgID,
            onHighlightComplete: () {
              debugPrint('messageList, onHighlightComplete');
              if (_highlightedMessageId == message.msgID) {
                _highlightedMessageId = null;
              }
            },
            onUserClick: widget.onUserClick,
            onUserLongPress: isGroup ? widget.onUserLongPress : null,
            onCallMessageClick: widget.onCallMessageClick,
            customActions: widget.customActions,
            config: widget.config,
            isMultiSelectMode: _isMultiSelectMode,
            isSelected: isMessageSelected(message),
            onToggleSelection: () => toggleMessageSelection(message),
            onEnterMultiSelectMode: () => enterMultiSelectMode(initialMessage: message),
            asrDisplayManager: _asrDisplayManager,
            onAsrBubbleLongPress: _showAsrTextMenu,
            translationDisplayManager: _translationDisplayManager,
            onTranslationBubbleLongPress: _showTranslationTextMenu,
          );
        },
      ),
    );

    if (_shouldTrackVisibility(message)) {
      return VisibilityDetector(
        key: Key('visibility_${message.msgID}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            _handleMessageAppear(message);
          }
        },
        child: messageWidget,
      );
    }

    return messageWidget;
  }

  bool _shouldTrackVisibility(MessageInfo message) {
    if (message.isSelf) return false;

    if (!message.needReadReceipt) return false;

    if (message.messageType == MessageType.system) return false;

    final msgID = message.msgID;
    if (msgID == null) return false;

    if (_sentReceiptMessageIDs.contains(msgID)) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Super.build must be called; AutomaticKeepAliveClientMixin is required.
    super.build(context);

    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Expanded(
      child: Container(
        color: colorsTheme.bgColorOperate,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: _callStatusWidget != null ? 70 : 8,
                    bottom: 8,
                  ),
                  child: ScrollablePositionedList.builder(
                    reverse: true,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemCount: _messages.length,
                    itemBuilder: _renderItem,
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: true,
                    addSemanticIndexes: false,
                  ),
                ),
              ),
            ),
            if (_callStatusWidget != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _callStatusWidget!,
              ),
            // Top-right unread messages tongue
            if (widget.config.isSupportTongue && _unreadTongueType == TongueType.unreadMessages)
              Positioned(
                top: _callStatusWidget != null ? 78 : 16,
                right: 16,
                child: MessageTongueWidget(
                  tongueState: TongueState(
                    type: TongueType.unreadMessages,
                    unreadCount: _initialUnreadCount,
                    isLoading: _isNavigatingToUnread,
                  ),
                  onTap: _onUnreadTongueTap,
                  backToLatestText: _atomicLocale.backToLatest,
                  newMessageCountText: (count) => _atomicLocale.newMessageCount(count),
                ),
              ),
            // Bottom-right tongue (back to latest / new messages / @mention)
            if (widget.config.isSupportTongue && _tongueType != TongueType.none)
              Positioned(
                bottom: 16,
                right: 16,
                child: MessageTongueWidget(
                  tongueState: TongueState(
                    type: _tongueType,
                    newMessageCount: _newMessageCount,
                    atMentionText: _atMentionText,
                    atMessageSeq: _atMessageSeq,
                    isLoading: _isNavigatingToAtMention || _isReloadingLatest,
                  ),
                  onTap: _onTongueTap,
                  backToLatestText: _atomicLocale.backToLatest,
                  newMessageCountText: (count) => _atomicLocale.newMessageCount(count),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearUnreadCount() {
    ConversationListStore conversationListStore = ConversationListStore.create();
    conversationListStore.clearConversationUnreadCount(conversationID: widget.conversationID);
  }

  // ==================== Tongue (小舌头) ====================

  void _initAtMentionTongue() {
    final atInfoList = widget.groupAtInfoList;
    if (atInfoList == null || atInfoList.isEmpty) return;

    // Sort by msgSeq ascending (oldest first) for sequential navigation
    _remainingAtInfoList = List.from(atInfoList)
      ..sort((a, b) => a.msgSeq.compareTo(b.msgSeq));

    // Don't show @mention tongue immediately; it will be shown
    // after the unread tongue is consumed or if there's no unread tongue
    // and the @messages are not visible on screen
    final oldest = _remainingAtInfoList.first;
    _atMessageSeq = oldest.msgSeq;

    // Store atType for later text resolution
    _pendingAtType = oldest.atType;
  }

  /// Initialize unread messages tongue (右上角)
  void _initUnreadTongue() {
    if (!widget.config.isSupportTongue) return;
    if (widget.initialUnreadCount <= 0) return;
    if (widget.locateMessage != null) return;

    _initialUnreadCount = widget.initialUnreadCount;
    // Don't show tongue immediately — defer until _checkUnreadTongueVisibility
    // confirms that unread messages exceed the visible area.
    // This avoids the flash where tongue appears then disappears.
    _pendingUnreadCheck = true;
  }

  /// Check if unread messages exceed visible count; if so, show unread tongue.
  /// Called after messages are loaded and layout is settled.
  /// Tongue is NOT shown until this check confirms it's needed (avoids flash).
  void _checkUnreadTongueVisibility() {
    if (!_pendingUnreadCheck) return;
    _pendingUnreadCheck = false;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      // Layout not ready yet — show tongue as fallback (unread count > 0)
      setState(() {
        _unreadTongueType = TongueType.unreadMessages;
      });
      return;
    }

    // Count visible message items on screen
    int visibleMessageCount = 0;
    for (final pos in positions) {
      if (pos.itemLeadingEdge < 1.0 && pos.itemTrailingEdge > 0.0) {
        visibleMessageCount++;
      }
    }

    if (_initialUnreadCount <= visibleMessageCount) {
      // All unread messages are visible, no need for the tongue
      // _unreadTongueType remains TongueType.none — tongue was never shown
      _activateAtMentionTongueIfNeeded();
    } else {
      // Unread messages exceed visible area, NOW show the tongue
      setState(() {
        _unreadTongueType = TongueType.unreadMessages;
      });
      _computeOldestUnreadSeq();
    }
  }

  /// Compute the seq of the oldest unread message based on the latest message seq and unread count
  void _computeOldestUnreadSeq() {
    if (_messages.isEmpty) return;

    // Messages are in reverse order (newest first), so first message is newest
    final newestMessage = _messages.first;
    final newestSeq = int.tryParse(newestMessage.rawMessage?.seq ?? '') ?? 0;
    if (newestSeq > 0) {
      _oldestUnreadMessageSeq = newestSeq - _initialUnreadCount + 1;
    }
  }

  GroupAtType? _pendingAtType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atomicLocale = AtomicLocalizations.of(context);

    // Resolve @mention text after locale is available
    if (_pendingAtType != null) {
      _atMentionText = _getAtMentionTextForType(_pendingAtType!);
      _pendingAtType = null;
    }
  }

  String _getAtMentionTextForType(GroupAtType atType) {
    switch (atType) {
      case GroupAtType.atMe:
      case GroupAtType.atAllAtMe:
        return _atomicLocale.conversationListAtMe;
      case GroupAtType.atAll:
        return _atomicLocale.conversationListAtAll;
    }
  }

  void _onTongueTap() {
    switch (_tongueType) {
      case TongueType.atMention:
        _onAtMentionTongueTap();
        break;
      case TongueType.newMessages:
      case TongueType.backToLatest:
        _onBackToLatestTongueTap();
        break;
      case TongueType.none:
      case TongueType.unreadMessages:
        break;
    }
  }

  /// Handle tap on the top-right unread messages tongue
  Future<void> _onUnreadTongueTap() async {
    if (_initialUnreadCount <= 0) return;

    setState(() {
      _isNavigatingToUnread = true;
    });

    if (_initialUnreadCount <= 20) {
      // No network fetch needed, hide tongue immediately
      setState(() {
        _unreadTongueType = TongueType.none;
      });

      // Unread count within the loaded page, scroll to the oldest unread message
      // _messages is newest-first (reversed), so index = unreadCount - 1 is the oldest unread
      final targetIndex = _initialUnreadCount - 1;
      if (targetIndex >= 0 && targetIndex < _messages.length) {
        // In reverse:true list, a higher alignment moves the item towards the top.
        // alignment=1.0 leaves 0 paint extent so the item becomes invisible.
        // 0.9 places the item near the top of the viewport.
        _itemScrollController.jumpTo(index: targetIndex, alignment: 0.9);
      }
    } else {
      // Unread count exceeds default page size, need to load around oldest unread message.
      // Compute seq if not already computed
      if (_oldestUnreadMessageSeq == null || _oldestUnreadMessageSeq! <= 0) {
        _computeOldestUnreadSeq();
      }

      if (_oldestUnreadMessageSeq == null || _oldestUnreadMessageSeq! <= 0) {
        // Fallback: still can't compute seq, just scroll to the top of current list
        if (_messages.isNotEmpty) {
          _itemScrollController.jumpTo(index: _messages.length - 1);
        }
        _isNavigatingToUnread = false;
        setState(() {
          _unreadTongueType = TongueType.none;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _activateAtMentionTongueIfNeeded();
        });
        return;
      }

      setState(() {
        isLoading = true;
      });

      // Use both direction to load messages around the oldest unread message.
      // This gives us some older (read) messages above and newer (unread) messages below,
      // matching WeChat's experience of showing context above the first unread message.
      final option = MessageFetchOption()
        ..messageSeq = _oldestUnreadMessageSeq!
        ..direction = MessageFetchDirection.both
        ..pageCount = 20;

      final result = await _messageListStore.fetchMessageList(option: option);

      if (mounted) {
        // All state (messages, isLoading, hasMore*) and the jumpTo have
        // already been applied inside _onMessageListStateChanged (which
        // fires synchronously via notifyListeners during fetchMessageList).
        // No additional setState is needed here — doing one would cause a
        // second build frame (visible as a "list flicker").

        debugPrint('messageList, _onUnreadTongueTap, fetchComplete, '
            'result.isSuccess: ${result.isSuccess}, messageCount: ${_messages.length}, '
            'oldestUnreadSeq: $_oldestUnreadMessageSeq');
      }
    }

    // Delay clearing _isNavigatingToUnread by TWO frames.
    // After _scrollToSeq's jumpTo executes, _itemPositionsListener only
    // fires after layout completes (next frame).  _scrollListener then
    // checks _isNavigatingToUnread — if it's already false and
    // hasMoreNewerMessages is true with index 0 visible (few messages),
    // _loadNewerMessages would be triggered, pulling in the latest
    // messages and causing a second visual change.
    // Frame 1: jumpTo → build + layout, positions update
    // Frame 2: scroll listener has fired; safe to clear the flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isNavigatingToUnread = false;
        if (mounted) {
          setState(() {
            _unreadTongueType = TongueType.none;
          });
          _activateAtMentionTongueIfNeeded();
        }
      });
    });
  }

  /// Scroll to a message by its seq number.
  /// In a reversed list (reverse: true), the alignment is used as CustomScrollView's anchor.
  /// anchor: 0.0 places the center item at the top of the viewport.
  void _scrollToSeq(int targetSeq, {double alignment = 0.9}) {
    // Try exact match first
    int targetIndex = _messages.indexWhere((m) {
      final seq = int.tryParse(m.rawMessage?.seq ?? '') ?? 0;
      return seq == targetSeq;
    });

    // Fallback: find the message with the closest seq
    if (targetIndex == -1 && _messages.isNotEmpty) {
      int bestIndex = -1;
      int bestDiff = 999999999;
      for (int i = 0; i < _messages.length; i++) {
        final seq = int.tryParse(_messages[i].rawMessage?.seq ?? '') ?? 0;
        if (seq <= 0) continue;
        final diff = (seq - targetSeq).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          bestIndex = i;
        }
      }
      targetIndex = bestIndex;
    }

    if (targetIndex != -1) {
      _itemScrollController.jumpTo(index: targetIndex, alignment: alignment);
    }
  }

  /// Activate @mention tongue if there are remaining @messages
  void _activateAtMentionTongueIfNeeded() {
    if (_remainingAtInfoList.isEmpty) {
      setState(() {
        _tongueType = _computeTongueType();
      });
      return;
    }

    // Show tongue for the oldest remaining @message
    final nextAt = _remainingAtInfoList.first;
    setState(() {
      _atMessageSeq = nextAt.msgSeq;
      _atMentionText = _getAtMentionTextForType(nextAt.atType);
      // Only show @mention tongue when unread tongue is not displayed
      if (_unreadTongueType == TongueType.none) {
        _tongueType = TongueType.atMention;
      }
    });
  }

  void _onBackToLatestTongueTap() {
    if (hasMoreNewerMessages) {
      // Keep the tongue visible with a loading spinner while reloading.
      // _isReloadingLatest is cleared inside _reloadLatestMessages AFTER
      // scrollToBottom + layout settle.
      setState(() {
        _newMessageCount = 0;
        _isReloadingLatest = true;
      });

      _reloadLatestMessages();
    } else {
      setState(() {
        _tongueType = TongueType.none;
        _newMessageCount = 0;
      });
      _scrollToBottom();
    }
  }

  Future<void> _reloadLatestMessages() async {
    setState(() {
      isLoading = true;
    });

    await _loadLatestMessages();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
      // Use a Completer so we can await the scroll + layout settling.
      // Frame 1: jumpTo executes the scroll.
      // Frame 2: layout completes, itemPositions are updated.
      // Only then is it safe to clear _isReloadingLatest and hide the tongue.
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached && _messages.isNotEmpty) {
          _itemScrollController.jumpTo(index: 0);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isReloadingLatest = false;
              _tongueType = TongueType.none;
            });
          }
          completer.complete();
        });
      });
      await completer.future;
    }
  }

  Future<void> _onAtMentionTongueTap() async {
    if (_atMessageSeq == null) return;

    final targetSeq = _atMessageSeq!;
    debugPrint('messageList, _onAtMentionTongueTap, targetSeq: $targetSeq, messagesCount: ${_messages.length}');

    // Try to find the @message in the current list
    final targetIndex = _messages.indexWhere((m) {
      final seq = int.tryParse(m.rawMessage?.seq ?? '') ?? 0;
      return seq == targetSeq;
    });

    if (targetIndex != -1) {
      // Message found in current list
      final targetMessage = _messages[targetIndex];
      if (targetMessage.msgID != null) {
        // Only scroll if target is not already visible on screen
        final positions = _itemPositionsListener.itemPositions.value;
        final isVisible = positions.any((pos) => pos.index == targetIndex);
        if (!isVisible) {
          _itemScrollController.jumpTo(index: targetIndex, alignment: 0);
        }
        setState(() {
          _highlightedMessageId = targetMessage.msgID;
        });
      }
      // Mark this @message as consumed, activate next
      _remainingAtInfoList.removeWhere((info) => info.msgSeq == targetSeq);
      _activateAtMentionTongueIfNeeded();
    } else {
      // Message not in current list, reload around the target seq.
      // Set flags so _onMessageListStateChanged handles scroll/highlight
      // synchronously in one frame (same pattern as _isNavigatingToUnread).
      debugPrint('messageList, _onAtMentionTongueTap, message NOT in list, will fetchMessageList for seq: $targetSeq');
      _isNavigatingToAtMention = true;
      _navigatingAtTargetSeq = targetSeq;

      setState(() {
        isLoading = true;
      });

      final option = MessageFetchOption()
        ..messageSeq = targetSeq
        ..direction = MessageFetchDirection.both
        ..pageCount = 20;

      await _messageListStore.fetchMessageList(option: option);
    }

    // Delay clearing _isNavigatingToAtMention by TWO frames (same pattern
    // as _isNavigatingToUnread in _onUnreadTongueTap).
    // _onMessageListStateChanged fires synchronously via notifyListeners,
    // but FetchMessagesEvent arrives asynchronously via stream. If we clear
    // the flag immediately, FetchMessagesEvent handler would see
    // _isNavigatingToAtMention=false and call _scrollToBottom(), causing a
    // second list change.
    // Frame 1: jumpTo → build + layout, positions update
    // Frame 2: scroll listener has fired; safe to clear the flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isNavigatingToAtMention = false;
        }
      });
    });
  }

  // ==================== Multi-select mode ====================

  /// Enter multi-select mode
  void enterMultiSelectMode({MessageInfo? initialMessage}) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedMessageIDs.clear();
      if (initialMessage != null && initialMessage.msgID != null) {
        _selectedMessageIDs.add(initialMessage.msgID!);
      }
    });
    _notifyMultiSelectModeChanged();
  }

  /// Exit multi-select mode
  void exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIDs.clear();
    });
    _notifyMultiSelectModeChanged();
  }

  /// Toggle message selection state
  void toggleMessageSelection(MessageInfo message) {
    final msgID = message.msgID;
    if (msgID == null) return;
    
    setState(() {
      if (_selectedMessageIDs.contains(msgID)) {
        _selectedMessageIDs.remove(msgID);
      } else {
        _selectedMessageIDs.add(msgID);
      }
    });
    _notifyMultiSelectModeChanged();
  }

  /// Check if message is selected
  bool isMessageSelected(MessageInfo message) {
    return message.msgID != null && _selectedMessageIDs.contains(message.msgID);
  }

  /// Notify multi-select mode change
  void _notifyMultiSelectModeChanged() {
    widget.onMultiSelectModeChanged?.call(_isMultiSelectMode, _selectedMessageIDs.length);
    
    // Notify full state
    if (_isMultiSelectMode) {
      widget.onMultiSelectStateChanged?.call(MultiSelectState(
        isActive: true,
        selectedCount: _selectedMessageIDs.length,
        onCancel: exitMultiSelectMode,
        onDelete: deleteSelectedMessages,
        onForward: forwardSelectedMessages,
      ));
    } else {
      widget.onMultiSelectStateChanged?.call(null);
    }
  }

  /// Delete selected messages
  Future<void> deleteSelectedMessages() async {
    if (_selectedMessageIDs.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await AlertDialog.show(
      context,
      title: '',
      content: _atomicLocale.deleteMessagesConfirmTip,
      isDestructive: true,
    );

    if (confirmed != true) return;

    final messagesToDelete = selectedMessages;
    await _messageListStore.deleteMessages(messageList: messagesToDelete);
    exitMultiSelectMode();
  }

  /// Forward selected messages
  Future<void> forwardSelectedMessages(BuildContext context) async {
    if (_selectedMessageIDs.isEmpty) return;

    // Get selected messages in the order they appear in _messages.
    // _messages is reversed from messageListStore (newest first), so we need to reverse it back to get oldest first
    final messages = _messages.reversed
        .where((message) => message.msgID != null && _selectedMessageIDs.contains(message.msgID))
        .toList();

    // 1. Validate message status first (don't exit multi-select if failed)
    final statusError = ForwardService.validateMessagesStatus(context, messages);
    if (statusError != null) {
      Toast.error(context, statusError);
      return;
    }

    // 2. Select forward type
    final forwardType = await ForwardService.showForwardTypeSelector(context);
    if (forwardType == null) {
      return;
    }

    // 3. Validate separate forward limit (don't exit multi-select if failed)
    final limitError = ForwardService.validateSeparateForwardLimit(context, messages, forwardType);
    if (limitError != null) {
      Toast.error(context, limitError);
      return;
    }

    // 4. Exit multi-select mode before showing target selector
    exitMultiSelectMode();

    // 5. Continue with forward flow (target selection and execution)
    ForwardService.forwardMessagesWithType(
      context: context,
      messages: messages,
      messageListStore: _messageListStore,
      config: widget.config,
      forwardType: forwardType,
      sourceConversationID: widget.conversationID,
    );
  }

  // ==================== Multi-select mode end ====================

  bool _isSystemMessage(MessageInfo message) {
    if (message.messageType == MessageType.system) {
      return true;
    }

    if (MessageUtil.isSystemStyleCustomMessage(message, context)) {
      return true;
    }

    return false;
  }

  String? _getMessageTimeString(int index) {
    if (index < 0 || index >= _messages.length) return null;

    final message = _messages[index];

    // Skip time display for system messages when they are hidden
    if (!widget.config.isShowSystemMessage && _isSystemMessage(message)) {
      return null;
    }

    if (index == _messages.length - 1) {
      return _getTimeString(message.timestamp ?? 0);
    }

    // Find the previous message, skipping system messages if they are hidden
    int prevIndex = index + 1;
    MessageInfo? prevMessage;

    while (prevIndex < _messages.length) {
      final candidate = _messages[prevIndex];

      // If system messages are hidden, skip them when calculating time intervals
      if (!widget.config.isShowSystemMessage && _isSystemMessage(candidate)) {
        prevIndex++;
        continue;
      }

      prevMessage = candidate;
      break;
    }

    // If no valid previous message found, show time for this message
    if (prevMessage == null) {
      return _getTimeString(message.timestamp ?? 0);
    }

    final timeInterval = _getIntervalSeconds(message.timestamp!, prevMessage.timestamp!);
    if (timeInterval > _messageAggregationTime) {
      return _getTimeString(message.timestamp ?? 0);
    }

    return null;
  }

  int _getIntervalSeconds(int timestamp1, int timestamp2) {
    return (timestamp2 - timestamp1).abs();
  }

  String? _getTimeString(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    final now = DateTime.now();
    final nowYear = now.year;
    final nowMonth = now.month;
    final nowWeekOfMonth = _getWeekOfMonth(now);
    final nowDay = now.day;

    final dateYear = date.year;
    final dateMonth = date.month;
    final dateWeekOfMonth = _getWeekOfMonth(date);
    final dateDay = date.day;

    if (nowYear == dateYear) {
      if (nowMonth == dateMonth) {
        if (nowWeekOfMonth == dateWeekOfMonth) {
          if (nowDay == dateDay) {
            return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          } else {
            final weekdays = [
              _atomicLocale.weekdaySunday,
              _atomicLocale.weekdayMonday,
              _atomicLocale.weekdayTuesday,
              _atomicLocale.weekdayWednesday,
              _atomicLocale.weekdayThursday,
              _atomicLocale.weekdayFriday,
              _atomicLocale.weekdaySaturday,
            ];
            return weekdays[date.weekday % 7];
          }
        } else {
          return "${date.month}/${date.day}";
        }
      } else {
        return "${date.month}/${date.day}";
      }
    } else {
      return "${date.year}/${date.month}/${date.day}";
    }
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final dayOfMonth = date.day;

    return ((dayOfMonth + firstWeekday - 7) / 7).ceil();
  }

  void _onGroupSettingStateChanged() {
    _updateCallStatusWidget();
  }

  Future<void> _loadGroupAttributes() async {
    if (_groupSettingStore == null) return;

    await _groupSettingStore!.fetchGroupAttributes();

    debugPrint('_loadGroupAttributes: ${_groupSettingStore!.groupSettingState.groupAttributes}');
  }

  void _updateCallStatusWidget() {
    if (_groupSettingStore == null) return;

    final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
    final groupAttributes = _groupSettingStore!.groupSettingState.groupAttributes;

    debugPrint('_updateCallStatusWidget: $groupAttributes');

    final callWidget = CallUIExtension.getJoinInGroupCallWidget(groupId, groupAttributes);

    if (mounted) {
      setState(() {
        _callStatusWidget = callWidget is SizedBox ? null : callWidget;
      });
    }
  }

  // ==================== readReceipt ====================

  void _handleMessageAppear(MessageInfo message) {
    if (message.isSelf) return;

    if (!message.needReadReceipt) return;

    final msgID = message.msgID;
    if (msgID == null) return;

    if (_sentReceiptMessageIDs.contains(msgID)) return;

    _pendingReceiptMessageIDs.add(msgID);

    _debounceReadReceipt();
  }

  void _debounceReadReceipt() {
    _receiptTimer?.cancel();
    _receiptTimer = Timer(_receiptDebounceInterval, () {
      _sendBatchReadReceipts();
    });
  }

  Future<void> _sendBatchReadReceipts() async {
    if (_pendingReceiptMessageIDs.isEmpty) return;

    final messagesToSend = _messages.where((message) {
      final msgID = message.msgID;
      return msgID != null && _pendingReceiptMessageIDs.contains(msgID);
    }).toList();

    if (messagesToSend.isEmpty) {
      _pendingReceiptMessageIDs.clear();
      return;
    }

    debugPrint('messageList, _sendBatchReadReceipts: ${messagesToSend.length} messages');

    final result = await _messageListStore.sendMessageReadReceipts(messageList: messagesToSend);

    if (result.isSuccess) {
      for (final message in messagesToSend) {
        final msgID = message.msgID;
        if (msgID != null) {
          _sentReceiptMessageIDs.add(msgID);
        }
      }
    }

    // 清空待发送列表
    _pendingReceiptMessageIDs.clear();
  }

  // ==================== ASR text bubble menu ====================

  /// Show ASR text bubble long press menu (popup above the target)
  void _showAsrTextMenu(MessageInfo message, GlobalKey asrBubbleKey) {
    final asrText = message.messageBody?.asrText ?? '';
    if (asrText.isEmpty) return;

    showAsrPopupMenu(
      context: context,
      targetKey: asrBubbleKey,
      isSelf: message.isSelf,
      actions: [
        AsrPopupMenuAction(
          label: _atomicLocale.hide,
          iconAsset: 'chat_assets/icon/hide.svg',
          onTap: () => _hideAsrText(message),
        ),
        AsrPopupMenuAction(
          label: _atomicLocale.forward,
          iconAsset: 'chat_assets/icon/forward.svg',
          onTap: () => _forwardAsrText(message),
        ),
        AsrPopupMenuAction(
          label: _atomicLocale.copy,
          iconAsset: 'chat_assets/icon/copy.svg',
          onTap: () => _copyAsrText(message),
        ),
      ],
    );
  }

  /// Hide ASR text bubble (only for this session)
  void _hideAsrText(MessageInfo message) {
    final messageID = message.msgID ?? '';
    _asrDisplayManager.hide(messageID);
  }

  /// Forward ASR text as text message
  void _forwardAsrText(MessageInfo message) {
    final asrText = message.messageBody?.asrText ?? '';
    if (asrText.isEmpty) return;

    ForwardService.forwardText(
      context: context,
      text: asrText,
      excludeConversationID: widget.conversationID,
    );
  }

  /// Copy ASR text to clipboard
  void _copyAsrText(MessageInfo message) {
    final asrText = message.messageBody?.asrText ?? '';
    if (asrText.isEmpty) return;

    Clipboard.setData(ClipboardData(text: asrText));
  }

  // ==================== Translation text bubble menu ====================

  /// Show translation text bubble long press menu (popup above the target)
  void _showTranslationTextMenu(MessageInfo message, GlobalKey translationBubbleKey) {
    final translatedTextMap = message.messageBody?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    showAsrPopupMenu(
      context: context,
      targetKey: translationBubbleKey,
      isSelf: message.isSelf,
      actions: [
        AsrPopupMenuAction(
          label: _atomicLocale.hide,
          iconAsset: 'chat_assets/icon/hide.svg',
          onTap: () => _hideTranslationText(message),
        ),
        AsrPopupMenuAction(
          label: _atomicLocale.forward,
          iconAsset: 'chat_assets/icon/forward.svg',
          onTap: () => _forwardTranslationText(message),
        ),
        AsrPopupMenuAction(
          label: _atomicLocale.copy,
          iconAsset: 'chat_assets/icon/copy.svg',
          onTap: () => _copyTranslationText(message),
        ),
      ],
    );
  }

  /// Hide translation text bubble (only for this session)
  void _hideTranslationText(MessageInfo message) {
    final messageID = message.msgID ?? '';
    _translationDisplayManager.hide(messageID);
  }

  /// Forward translated text as text message
  void _forwardTranslationText(MessageInfo message) {
    final translatedTextMap = message.messageBody?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    // Get the original text for forwarding (no need to process @ and emoji)
    final originalText = message.messageBody?.text ?? '';
    if (originalText.isEmpty) return;

    ForwardService.forwardText(
      context: context,
      text: originalText,
      excludeConversationID: widget.conversationID,
    );
  }

  /// Copy translated text to clipboard
  void _copyTranslationText(MessageInfo message) {
    final translatedTextMap = message.messageBody?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    // Get the translated display text with emoji preserved (no need to fetch atUserNames)
    final originalText = message.messageBody?.text ?? '';
    final textToCopy = TranslationTextParser.buildTranslatedDisplayText(
      originalText,
      translatedTextMap,
      [],
    );
    
    Clipboard.setData(ClipboardData(text: textToCopy));
  }
}
