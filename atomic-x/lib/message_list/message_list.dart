import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/utils/call_ui_extension.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_item.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

export 'message_list_config.dart';
export 'widgets/message_bubble.dart';
export 'widgets/message_item.dart';
export 'widgets/message_types/custom_message_widget.dart';
export 'widgets/message_types/system_message_widget.dart';

typedef OnUserClick = void Function(String userID);

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
  final List<MessageCustomAction> customActions;

  const MessageList({
    super.key,
    required this.conversationID,
    this.config = const ChatMessageListConfig(),
    this.locateMessage,
    this.onUserClick,
    this.customActions = const [],
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
  MessageListChangeReason _messageListChangeReason = MessageListChangeReason.unknown;
  bool isLoading = false;
  bool _isLoadingNewer = false;

  bool hasMoreOlderMessages = true;
  bool hasMoreNewerMessages = false;
  bool _isInitialLoad = true;

  String? _highlightedMessageId;

  Widget? _callStatusWidget;

  static const int _messageAggregationTime = 300;

  // AutomaticKeepAliveClientMixin requires this method to be implemented
  // Returning true indicates that the state is maintained even if the Widget is not in the view.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _messageListStore =
        MessageListStore.create(conversationID: widget.conversationID, messageListType: MessageListType.history);
    _messageListStore.addListener(_onMessageListStateChanged);
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
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
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
    _messageListChangeReason = _messageListStore.messageListState.messageListChangeSource;

    _clearUnreadCountIfNeeded();

    setState(() {
      _messages = _messageListStore.messageListState.messageList.reversed.toList();
    });

    if (widget.locateMessage != null && _isInitialLoad) {
      _isInitialLoad = false;
      _scrollToMessageAndHighlight(widget.locateMessage!.msgID!);
      return;
    }

    if (isLoading) return;

    // scrollable_positioned_list can keep position
    if (_messageListChangeReason == MessageListChangeReason.loadMoreMessages) {
      return;
    }

    if (widget.locateMessage == null &&
        (_isInitialLoad ||
            _messageListChangeReason == MessageListChangeReason.sendMessage ||
            (_isUserAtBottom() && _messageListChangeReason == MessageListChangeReason.recvMessage))) {
      _scrollToBottom();
    }
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
    return RepaintBoundary(
      child: MessageItem(
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
        customActions: widget.customActions,
        config: widget.config,
      ),
    );
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

  void _clearUnreadCountIfNeeded() {
    ConversationListStore conversationListStore = ConversationListStore.create();
    ConversationInfo conversationInfo = ConversationInfo(conversationID: widget.conversationID);
    if (_messageListChangeReason == MessageListChangeReason.fetchMessages) {
      conversationListStore.clearConversationUnreadCount(conversationID: conversationInfo.conversationID);
      return;
    }

    if (_messageListChangeReason == MessageListChangeReason.recvMessage) {
      conversationListStore.clearConversationUnreadCount(conversationID: conversationInfo.conversationID);
      return;
    }
  }

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
}
