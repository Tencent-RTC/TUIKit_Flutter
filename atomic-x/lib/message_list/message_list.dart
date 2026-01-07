import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/utils/asr_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/call_ui_extension.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_display_manager.dart';
import 'package:tuikit_atomic_x/message_list/utils/translation_text_parser.dart';
import 'package:tuikit_atomic_x/message_list/widgets/asr_popup_menu.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_item.dart';
import 'package:tuikit_atomic_x/message_list/widgets/forward/forward_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

typedef OnUserClick = void Function(String userID);

/// Callback when user long presses on avatar (for @ mention feature)
/// [userID] is the user ID of the message sender
/// [displayName] is the display name of the message sender
typedef OnUserLongPress = void Function(String userID, String displayName);

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
  final List<MessageCustomAction> customActions;
  /// Multi-select mode change callback
  final OnMultiSelectModeChanged? onMultiSelectModeChanged;
  /// Multi-select state change callback (includes action methods)
  final void Function(MultiSelectState? state)? onMultiSelectStateChanged;

  const MessageList({
    super.key,
    required this.conversationID,
    this.config = const ChatMessageListConfig(),
    this.locateMessage,
    this.onUserClick,
    this.onUserLongPress,
    this.customActions = const [],
    this.onMultiSelectModeChanged,
    this.onMultiSelectStateChanged,
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

  // Multi-select mode state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIDs = {};

  // ASR display manager for voice-to-text feature
  late AsrDisplayManager _asrDisplayManager;

  // Translation display manager for text translation feature
  late TranslationDisplayManager _translationDisplayManager;

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

    _messageListStore =
        MessageListStore.create(conversationID: widget.conversationID, messageListType: MessageListType.history);
    _messageListStore.addListener(_onMessageListStateChanged);
    _messageEventSubscription = _messageListStore.messageEventStream.listen(_onMessageEvent);
    _itemPositionsListener.itemPositions.addListener(_scrollListener);

    if (widget.conversationID.startsWith(groupConversationIDPrefix)) {
      final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
      _groupSettingStore = GroupSettingStore.create(groupID: groupId);
      _groupSettingStore!.addListener(_onGroupSettingStateChanged);
      _loadGroupAttributes();
    }

    _loadInitialMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atomicLocale = AtomicLocalizations.of(context);
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
    _messageListStore.removeListener(_onMessageListStateChanged);
    _messageEventSubscription?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _receiptTimer?.cancel();
    _asrDisplayManager.dispose();
    _translationDisplayManager.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_isLoadingNewer || !hasMoreNewerMessages) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (_highlightedMessageId == null && positions.isNotEmpty && positions.any((pos) => pos.index <= 0)) {
      debugPrint('messageList, _scrollListener->_loadNewerMessages');
      _loadNewerMessages();
    }
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
    setState(() {
      _messages = _messageListStore.messageListState.messageList.reversed.toList();
    });

    if (widget.locateMessage != null && _isInitialLoad) {
      _isInitialLoad = false;
      _scrollToMessageAndHighlight(widget.locateMessage!.msgID!);
      return;
    }
  }

  void _onMessageEvent(MessageEvent event) {
    switch (event) {
      case FetchMessagesEvent():
        _clearUnreadCount();
        if (widget.locateMessage == null && !isLoading) {
          _scrollToBottom();
        }
        // Fetch reactions for loaded messages
        if (widget.config.isSupportReaction) {
          _fetchMessageReactions(event.messageList);
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
    debugPrint('messageList, _loadNewerMessages');

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
                  child: RefreshIndicator(
                    displacement: 10.0,
                    onRefresh: _loadPreviousMessages,
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
              ),
            ),
            if (_callStatusWidget != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _callStatusWidget!,
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
