import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/services.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/asr_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/call_ui_extension.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_display_manager.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/translation_text_parser.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/asr_popup_menu.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_item.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_tongue_widget.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/forward/forward_service.dart';
import 'package:tencent_chat_uikit/src/third_party/scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tencent_chat_uikit/src/third_party/visibility_detector/visibility_detector.dart';

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
  /// Callback when user taps "Quote" in the long-press menu
  final void Function(MessageInfo message)? onQuoteMessage;
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
    this.onQuoteMessage,
    this.customActions = const [],
    this.onMultiSelectModeChanged,
    this.onMultiSelectStateChanged,
    this.groupAtInfoList,
    this.initialUnreadCount = 0,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

/// What the message list is currently doing, navigation-wise.
///
/// All four "in-flight" states are mutually exclusive: the list can be
/// navigating to the oldest unread message, or to an @ mention, or to a
/// quoted message, or reloading to the latest page — never two at once.
/// Modelling them as a sealed hierarchy instead of as a bag of independent
/// booleans (the previous design) makes that exclusivity a compile-time
/// guarantee, lets the scroll listener short-circuit on the single check
/// `_navigationState is _NavIdle`, and gives the inbound
/// `_onMessageListStateChanged` dispatcher exhaustive pattern matching
/// over each navigation kind.
///
/// `_NavToAtMention.targetSeq` and `_NavToQuotedMessage.targetMsgID` are
/// nullable on purpose: setting them to null after the inbound branch has
/// run is the "processed once" guard that prevents a second
/// notifyListeners (e.g. from a reaction/extension fetch in the same
/// 2-frame settle window) from re-applying the jump/highlight and yanking
/// the user away from where they just landed.
sealed class _NavigationState {
  const _NavigationState();
}

class _NavIdle extends _NavigationState {
  const _NavIdle();
}

class _NavToUnread extends _NavigationState {
  const _NavToUnread();
}

class _NavToAtMention extends _NavigationState {
  final int? targetSeq;
  const _NavToAtMention(this.targetSeq);
}

class _NavToQuotedMessage extends _NavigationState {
  final String? targetMsgID;

  /// Tongue type to commit when the inbound branch lands on the target.
  ///
  /// Forward navigation (tap on quote preview → go to the quoted target)
  /// passes [TongueType.backToQuote] so the user can round-trip back to
  /// the source. The reverse navigation (tap on backToQuote tongue → go
  /// back to the source) passes [TongueType.none] so the scroll listener
  /// can re-derive the "natural" tongue (backToLatest / atMention) after
  /// the round-trip completes — we do not want a second backToQuote
  /// tongue chaining off the back-navigation.
  final TongueType tongueAfter;

  /// Whether to highlight the landed-on message.
  ///
  /// Forward navigation highlights the quoted target so the user can see
  /// what they landed on. Reverse navigation does NOT highlight the
  /// source — the user already knows where they came from, and a re-flash
  /// of the originating message is just visual noise.
  ///
  /// Kept as a separate field from [tongueAfter] on purpose: the two
  /// happen to align for the current forward/back uses, but they are
  /// orthogonal concerns and a future caller (e.g. "navigate to a search
  /// hit") might want one but not the other.
  final bool highlightTarget;

  const _NavToQuotedMessage(
    this.targetMsgID,
    this.tongueAfter,
    this.highlightTarget,
  );
}

class _NavReloadingLatest extends _NavigationState {
  const _NavReloadingLatest();
}

class _MessageListState extends State<MessageList> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late MessageListStore _messageListStore;
  GroupInfo? _groupInfo;
  late AtomicLocalizations _atomicLocale;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  List<MessageInfo> _messages = [];
  StreamSubscription<MessageEvent>? _messageEventSubscription;
  bool isLoading = false;
  bool _isLoadingNewer = false;

  /// Single source of truth for "what kind of navigation is in flight".
  /// See [_NavigationState] for why this replaces the previous bag of
  /// `_isNavigatingTo* / _isReloadingLatest` booleans.
  _NavigationState _navigationState = const _NavIdle();

  bool _isInitialLoad = true;

  String? _highlightedMessageId;

  /// The source message of an in-progress quote round-trip — i.e. the
  /// message whose quote preview the user just tapped. Stored as the
  /// full [MessageInfo] (not just `msgID`) because when the
  /// quote-target navigation triggered a Store reload and the source
  /// was wholesale-replaced out of the loaded list, we need its
  /// `sequence` / `timestamp` to reload the page around it on the
  /// reverse leg (`_onBackToQuoteTongueTap`). Cleared after the
  /// round-trip completes.
  MessageInfo? _quoteReturnSource;

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
  late final VoidCallback _joinedGroupListChangedListener;

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
    _joinedGroupListChangedListener = _onJoinedGroupListChanged;

    _messageListStore =
        MessageListStore.create(conversationID: widget.conversationID);
    _messageListStore.state.messageList.addListener(_messageListStateChangedListener);
    _messageEventSubscription = _messageListStore.messageEventStream.listen(_onMessageEvent);
    _itemPositionsListener.itemPositions.addListener(_scrollListenerCallback);

    if (widget.conversationID.startsWith(groupConversationIDPrefix)) {
      // Initial pull for call banner; subsequent attribute pushes arrive via
      // GroupStore.joinedGroupList (see _onJoinedGroupListChanged).
      GroupStore.shared.state.joinedGroupList.addListener(_joinedGroupListChangedListener);
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
            style: FontScheme.caption3Regular.copyWith(
              color: colorsTheme.textColorTertiary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageListStore.state.messageList.removeListener(_messageListStateChangedListener);
    _messageEventSubscription?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListenerCallback);
    if (widget.conversationID.startsWith(groupConversationIDPrefix)) {
      GroupStore.shared.state.joinedGroupList.removeListener(_joinedGroupListChangedListener);
    }
    _receiptTimer?.cancel();
    _asrDisplayManager.dispose();
    _translationDisplayManager.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Single-pass: compute minIndex, maxIndex, isAtBottom in one traversal
    int minIndex = positions.first.index;
    int maxIndex = minIndex;
    bool isAtBottom = minIndex <= 1;
    for (final pos in positions) {
      final idx = pos.index;
      if (idx < minIndex) minIndex = idx;
      if (idx > maxIndex) maxIndex = idx;
      if (!isAtBottom && idx <= 1) isAtBottom = true;
    }

    // Don't kick off auto-loads while any user-initiated navigation is in
    // flight. Each of those nav states drives its own scroll/jumpTo and
    // would race with the scroll-listener-driven _loadNewer/_loadPrevious.
    final isNavIdle = _navigationState is _NavIdle;

    // Load newer messages when the user has scrolled to the bottom
    // (reverse:true → "bottom" = newest = index 0 area).
    //
    // Uses `isAtBottom` (minIndex <= 1) rather than the stricter
    // `minIndex <= 0` so this trigger matches the rest of the file's
    // notion of "at bottom" (see `_isUserAtBottom()` and the
    // `isAtBottom` flag above). With reverse:true,
    // ScrollablePositionedList does not always pin index 0 at the
    // leading edge once a scroll reaches its physical limit — index 0
    // may stay fully visible while minIndex sits at 1 — so requiring
    // `<= 0` would silently skip the load even after the user is
    // visibly at the bottom of the loaded page.
    if (!_isLoadingNewer &&
        isNavIdle &&
        _messageListStore.state.hasNewerMessages.value) {
      if (_highlightedMessageId == null && isAtBottom) {
        _loadNewerMessages();
      }
    }

    // Auto-load older messages when scrolled near the oldest message (reverse list: largest index = oldest)
    if (!isLoading &&
        isNavIdle &&
        _messageListStore.state.hasOlderMessages.value) {
      if (maxIndex >= _messages.length - _loadOlderMessagesThreshold) {
        _loadPreviousMessages();
      }
    }

    // Tongue visibility logic
    if (!widget.config.isSupportTongue) return;
    _updateTongueState(minIndex, isAtBottom);
  }

  void _updateTongueState(int minIndex, bool isAtBottom) {
    // Any user-initiated navigation owns the tongue state for the duration
    // of its 2-frame settle window — the corresponding branch in
    // `_onMessageListStateChanged` set tongue/highlight/scroll atomically
    // and any scroll-driven re-derivation here would race with that.
    // Reload-latest needs the tongue's loading spinner kept on too, until
    // the Completer-driven cleanup hides it.
    if (_navigationState is! _NavIdle) return;

    if (isAtBottom) {
      if (_tongueType != TongueType.none || _newMessageCount > 0) {
        setState(() {
          _newMessageCount = 0;
          if (_remainingAtInfoList.isEmpty) {
            // Only hide tongue when truly at the bottom of ALL messages.
            // If there are still newer messages to load, keep backToLatest
            // visible so the user can tap to jump to the latest.
            if (_messageListStore.state.hasNewerMessages.value) {
              _tongueType = TongueType.backToLatest;
            } else {
              _tongueType = TongueType.none;
            }
          }
        });
      }
      return;
    }

    final isScrolledPastThreshold = minIndex > _tongueScrollThreshold;

    if (isScrolledPastThreshold) {
      // Don't override backToQuote tongue — it stays until user taps it or scrolls to bottom
      if (_tongueType != TongueType.backToQuote) {
        final newType = _computeTongueType();
        if (newType != _tongueType) {
          setState(() {
            _tongueType = newType;
          });
        }
      }
    } else {
      // Not scrolled past threshold — only hide tongue types that require
      // the threshold (atMention).  Keep newMessages and backToLatest tongue
      // visible: the user is NOT at bottom (handled above) so they should
      // still see the indicator to jump back to the latest position.
      if (_tongueType != TongueType.none
          && _tongueType != TongueType.newMessages
          && _tongueType != TongueType.backToLatest
          && _tongueType != TongueType.backToQuote
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

    if (_pendingUnreadCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkUnreadTongueVisibility();
        });
      });
    }
  }

  void _onMessageListStateChanged() {
    final state = _messageListStore.state;

    debugPrint('messageList, _onMessageListStateChanged, '
        'msgCount: ${state.messageList.value.length}, '
        'navState: ${_navigationState.runtimeType}');

    // Each navigation kind owns an "atomic-frame" branch: messages +
    // scroll + highlight + tongue are applied in one setState while we
    // still hold the notifyListeners stack, so a stray _scrollListener /
    // _updateTongueState invocation can never observe a half-applied
    // intermediate state (e.g. list already swapped, but jumpTo hasn't
    // run yet, so positions still report index 0 / isAtBottom=true).
    //
    // `_NavToAtMention` and `_NavToQuotedMessage` carry a nullable
    // target; null means "this nav has already been processed once" —
    // the 2-frame settle window may see additional notifyListeners
    // (e.g. reaction/extension fetch) and we don't want to re-fire the
    // jump and yank the user away from where they just landed.
    final navState = _navigationState;
    switch (navState) {
      case _NavToUnread()
          when _oldestUnreadMessageSeq != null && _oldestUnreadMessageSeq! > 0:
        setState(() {
          _messages = state.messageList.value.reversed.toList();
          isLoading = false;
        });
        _scrollToSeq(_oldestUnreadMessageSeq!);
        return;

      case _NavToAtMention(targetSeq: final targetSeq?):
        debugPrint('messageList, _onMessageListStateChanged [AT_MENTION], '
            'targetSeq: $targetSeq, '
            'messageCount: ${state.messageList.value.length}');
        setState(() {
          _messages = state.messageList.value.reversed.toList();
          isLoading = false;
        });
        _scrollToSeq(targetSeq, alignment: 0);
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
        // Mark this nav "processed" without leaving the 2-frame settle
        // window — a subsequent notifyListeners in this window will fall
        // through this switch to the default branch instead of
        // re-jumping back to the @ message.
        _navigationState = const _NavToAtMention(null);
        _activateAtMentionTongueIfNeeded();
        return;

      case _NavToQuotedMessage(
          targetMsgID: final targetMsgID?,
          tongueAfter: final tongueAfter,
          highlightTarget: final highlightTarget,
        ):
        debugPrint('messageList, _onMessageListStateChanged [QUOTE], '
            'targetMsgID: $targetMsgID, '
            'tongueAfter: $tongueAfter, '
            'highlight: $highlightTarget, '
            'messageCount: ${state.messageList.value.length}');
        setState(() {
          _messages = state.messageList.value.reversed.toList();
          isLoading = false;
          if (highlightTarget) {
            _highlightedMessageId = targetMsgID;
          }
          _tongueType = tongueAfter;
          // Same processed-once guard as the at-mention branch.
          _navigationState =
              _NavToQuotedMessage(null, tongueAfter, highlightTarget);
        });
        final targetIndex =
            _messages.indexWhere((msg) => msg.msgID == targetMsgID);
        if (targetIndex != -1 && _itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: targetIndex, alignment: 0.3);
        }
        return;

      case _NavIdle():
      case _NavToUnread():
      case _NavToAtMention():
      case _NavToQuotedMessage():
      case _NavReloadingLatest():
        break;
    }

    final oldLength = _messages.length;
    // Remember the first message's ID to detect head-insertion (new messages)
    // vs tail-append (older history messages).
    final oldFirstMsgID = _messages.isNotEmpty ? _messages.first.msgID : null;

    setState(() {
      _messages = state.messageList.value.reversed.toList();
    });

    // Only compensate when new messages are inserted at the HEAD of the list
    // (index 0 = newest in reverse list).  Detect this by checking whether
    // the first message's ID has changed — if it changed, newer messages were
    // prepended; if it didn't, older messages were appended at the tail and
    // no compensation is needed (existing item indices are unchanged).
    final insertedCount = _messages.length - oldLength;
    final newFirstMsgID = _messages.isNotEmpty ? _messages.first.msgID : null;
    final isHeadInsertion = insertedCount > 0 && oldFirstMsgID != null && newFirstMsgID != oldFirstMsgID;

    // If the new head message is sent by self, auto-scroll to bottom.
    //
    // Must also skip while _loadNewerMessages is in flight: when a page of
    // newer messages happens to include a self-sent tail (e.g. the user
    // earlier sent a quote message and we now scroll-to-load the page
    // containing it), the new _messages.first will be self-sent — but
    // this was not a fresh "user just hit send" event. _loadNewerMessages
    // is already running its own scroll-preserving jumpTo(insertedCount)
    // after the await, and if we also schedule a postFrame jumpTo(0)
    // here, that postFrame fires last and clobbers the scroll-preserve,
    // visibly snapping the user to the very bottom on every second load.
    if (isHeadInsertion &&
        !_isLoadingNewer &&
        _messages.isNotEmpty &&
        _messages.first.isSentBySelf) {
      if (_messageListStore.state.hasNewerMessages.value) {
        // List was loaded around an older position, need to reload latest
        _reloadLatestMessages();
      } else if (_itemScrollController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _itemScrollController.isAttached) {
            _itemScrollController.jumpTo(index: 0);
          }
        });
      }
    }
    // Skip compensation when _loadNewerMessages is in progress — it already
    // does its own jumpTo after the await returns.
    else if (isHeadInsertion && !_isLoadingNewer && !_isUserAtBottom() && _itemScrollController.isAttached) {
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
      case OnReceiveNewMessage(:final message):
        debugPrint('messageList, onReceiveNewMessage: ${message.msgID}');
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
          _fetchMessageReactions([message]);
        }
    }
  }

  Future<void> _fetchMessageReactions(List<MessageInfo> messages) async {
    // Reactions are now auto-fetched by MessageListStore's internal listener
    // when new messages are added to the message list.
  }

  bool _isUserAtBottom() {
    if (!_itemScrollController.isAttached) return true;
    final positions = _itemPositionsListener.itemPositions.value;
    return positions.isNotEmpty && positions.any((pos) => pos.index <= 1);
  }

  Future<void> _loadLatestMessages() async {
    final option = MessageLoadOption()
      ..direction = MessageLoadDirection.older
      ..pageCount = 20;

    await _messageListStore.loadMessages(option: option);
    // No local mirroring of has-more flags — Store resets both to false on
    // loadMessages entry and only flips hasOlderMessages back to true if
    // more older pages exist. Read sites check
    // `_messageListStore.state.hasOlderMessages.value` directly.
  }

  Future<void> _loadMessagesAround(MessageInfo message) async {
    debugPrint('messageList, _loadMessagesAround');
    final option = MessageLoadOption()
      ..cursor = message
      ..direction = MessageLoadDirection.both
      ..pageCount = 20;
    await _messageListStore.loadMessages(option: option);
  }

  Future<void> _loadPreviousMessages() async {
    if (isLoading || !_messageListStore.state.hasOlderMessages.value) return;

    debugPrint('messageList, _loadPreviousMessages');

    setState(() {
      isLoading = true;
    });

    await _messageListStore.loadOlderMessages();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadNewerMessages() async {
    if (_isLoadingNewer || !_messageListStore.state.hasNewerMessages.value) return;

    setState(() {
      _isLoadingNewer = true;
    });

    final oldListLength = _messages.length;
    await _messageListStore.loadNewerMessages();
    final newListLength = _messages.length;
    if (mounted && newListLength > oldListLength) {
      final newIndex = newListLength - oldListLength;
      _itemScrollController.jumpTo(index: newIndex);
    }

    if (mounted) {
      setState(() {
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
            maxWidth: MediaQuery.sizeOf(context).width - 32,
            messageListStore: _messageListStore,
            isHighlighted: _highlightedMessageId == message.msgID,
            onHighlightComplete: () {
              debugPrint('messageList, onHighlightComplete, msgID: ${message.msgID}, sequence:${message.sequence}');
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
            onQuotePreviewTap: _onQuotePreviewTap,
            onQuoteMessage: widget.onQuoteMessage,
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
    if (message.isSentBySelf) return false;

    if (!message.needReadReceipt) return false;

    if (message.messageType == MessageType.tips) return false;

    if (message.status == MessageStatus.revoked) return false;

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
                    isLoading: _navigationState is _NavToUnread,
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
                    isLoading: _navigationState is _NavToAtMention
                        || _navigationState is _NavReloadingLatest,
                  ),
                  onTap: _onTongueTap,
                  backToLatestText: _atomicLocale.backToLatest,
                  newMessageCountText: (count) => _atomicLocale.newMessageCount(count),
                  backToQuoteText: _atomicLocale.backToQuotePosition,
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
  /// Only for group conversations — C2C message seq is not sequential,
  /// so seq-based positioning is not possible.
  void _initUnreadTongue() {
    if (!widget.config.isSupportTongue) return;
    if (widget.initialUnreadCount <= 0) return;
    if (widget.locateMessage != null) return;
    if (!widget.conversationID.startsWith(groupConversationIDPrefix)) return;

    _initialUnreadCount = widget.initialUnreadCount;
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
      case TongueType.backToQuote:
        _onBackToQuoteTongueTap();
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
      _navigationState = const _NavToUnread();
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
        setState(() {
          _navigationState = const _NavIdle();
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
      final cursorMsg = MessageInfo(sequence: _oldestUnreadMessageSeq!);
      final option = MessageLoadOption()
        ..cursor = cursorMsg
        ..direction = MessageLoadDirection.both
        ..pageCount = 20;

      final result = await _messageListStore.loadMessages(option: option);

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

    // Delay clearing _NavToUnread by TWO frames.
    // After _scrollToSeq's jumpTo executes, _itemPositionsListener only
    // fires after layout completes (next frame).  _scrollListener then
    // re-checks `_navigationState is _NavIdle` — if we cleared it
    // immediately and hasNewerMessages is true with index 0 visible
    // (few messages), _loadNewerMessages would be triggered, pulling
    // in the latest messages and causing a second visual change.
    // Frame 1: jumpTo → build + layout, positions update
    // Frame 2: scroll listener has fired; safe to exit nav state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _navigationState is _NavToUnread) {
          setState(() {
            _navigationState = const _NavIdle();
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
    if (_messageListStore.state.hasNewerMessages.value) {
      // Keep the tongue visible with a loading spinner while reloading.
      // The _NavReloadingLatest state is cleared inside
      // _reloadLatestMessages AFTER scrollToBottom + layout settle.
      setState(() {
        _newMessageCount = 0;
        _navigationState = const _NavReloadingLatest();
      });

      _reloadLatestMessages();
    } else {
      setState(() {
        _tongueType = TongueType.none;
        _newMessageCount = 0;
      });
      if (_itemScrollController.isAttached && _messages.isNotEmpty) {
        _itemScrollController.jumpTo(index: 0);
      }
    }
  }

  /// Handle tap on quote preview inside a message bubble — navigate to quoted message
  void _onQuotePreviewTap(MessageInfo message) {
    final quoteInfo = message.quoteInfo;
    if (quoteInfo == null || quoteInfo.msgID.isEmpty) return;

    // Capture the full source MessageInfo (not just msgID) — the reverse
    // leg in `_onBackToQuoteTongueTap` needs seq/timestamp to reload
    // around the source when the forward leg wholesale-replaced the
    // list and the source is no longer in it.
    _quoteReturnSource = message;

    // Search for the quoted message in current loaded list
    final targetMsgID = quoteInfo.msgID;
    final targetIndex = _messages.indexWhere((msg) => msg.msgID == targetMsgID);

    debugPrint('messageList, _onQuotePreviewTap, sourceMsgID: ${message.msgID}, '
        'sourceSequence: ${message.sequence}, targetMsgID: $targetMsgID, '
        'targetMsgSequence: ${quoteInfo.sequence}, '
        'targetIndex: $targetIndex, listSize: ${_messages.length}');

    if (targetIndex != -1) {
      // Found in current list - scroll to it and highlight
      _scrollToIndexAndHighlight(targetIndex, targetMsgID);
    } else {
      // Not in current list - need to reload around the quoted message
      _loadAndNavigateToQuotedMessage(quoteInfo);
    }
  }

  void _scrollToIndexAndHighlight(int index, String msgID) {
    // Check if target is already visible on screen
    bool isVisible = false;
    if (_itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;
      isVisible = positions.any((pos) => pos.index == index);
    }

    if (!isVisible && _itemScrollController.isAttached) {
      // Target not visible - scroll to it and show "back to quote" tongue
      _itemScrollController.jumpTo(index: index, alignment: 0.3);
      setState(() {
        _highlightedMessageId = msgID;
        _tongueType = TongueType.backToQuote;
      });
    } else {
      // Target already visible - just highlight, no scroll, no tongue
      setState(() {
        _highlightedMessageId = msgID;
      });
    }
  }

  /// Forward leg of the quote round-trip: tap on a quote preview when the
  /// quoted target isn't in the currently-loaded list. Loads around the
  /// target (Store's `_fetchTwoSideMessageList`), jumps to it, highlights
  /// it, and commits a `backToQuote` tongue so the user can round-trip
  /// back to the source.
  ///
  /// The cursor is constructed from `quoteInfo`'s msgID/seq/timestamp
  /// (without a rawMessage) — Store falls back to `lastMsgSeq`-based
  /// positioning in that case.
  Future<void> _loadAndNavigateToQuotedMessage(MessageQuoteInfo quoteInfo) {
    final cursorMessage = MessageInfo(
      msgID: quoteInfo.msgID,
      timestamp: quoteInfo.timestamp,
      sequence: quoteInfo.sequence,
    );
    return _loadAndNavigateToMessage(
      cursorMessage: cursorMessage,
      targetMsgID: quoteInfo.msgID,
      tongueAfter: TongueType.backToQuote,
      highlightTarget: true,
      debugLabel: 'quote-forward',
    );
  }

  /// Generic "load around a message and jump to it" routine.
  ///
  /// Both forward navigation (tap on quote preview) and reverse
  /// navigation (tap on backToQuote tongue when the source got
  /// wholesale-replaced out of the list) feed through here. The two
  /// callers differ only in:
  ///   - which message is the navigation target (quoted target vs. the
  ///     source message of the quote round-trip), and
  ///   - what tongue to commit when the landing branch runs in
  ///     `_onMessageListStateChanged`.
  Future<void> _loadAndNavigateToMessage({
    required MessageInfo cursorMessage,
    required String targetMsgID,
    required TongueType tongueAfter,
    required bool highlightTarget,
    String debugLabel = 'message',
  }) async {
    debugPrint('messageList, _loadAndNavigateToMessage [$debugLabel], '
        'targetMsgID: $targetMsgID, '
        'seq: ${cursorMessage.sequence}, '
        'ts: ${cursorMessage.timestamp}, '
        'tongueAfter: $tongueAfter, '
        'highlight: $highlightTarget');

    // Enter "quote navigation in progress" state. The actual
    // setState/jumpTo/tongue work happens inside `_onMessageListStateChanged`
    // (the `_NavToQuotedMessage` case) when the Store fires
    // notifyListeners — same atomic-frame pattern as _NavToAtMention /
    // _NavToUnread.
    setState(() {
      _navigationState =
          _NavToQuotedMessage(targetMsgID, tongueAfter, highlightTarget);
      isLoading = true;
    });

    final option = MessageLoadOption(
      messageListType: MessageListType.history,
      cursor: cursorMessage,
      direction: MessageLoadDirection.both,
    );

    await _messageListStore.loadMessages(option: option);

    // Defer exiting the nav state by two frames so the scroll listener
    // that fires off the back of our synchronous jumpTo has settled
    // before _scrollListener / _updateTongueState are allowed to react
    // again. Mirrors the _NavToAtMention / _NavToUnread tail.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _navigationState is _NavToQuotedMessage) {
          setState(() {
            _navigationState = const _NavIdle();
          });
        }
      });
    });
  }

  /// Handle tap on "back to quote position" tongue.
  ///
  /// Reverse leg of the quote round-trip: jump back to the source
  /// message whose quote preview the user tapped earlier.
  ///
  /// If the forward leg had to wholesale-reload the list around the
  /// quoted target (because the target wasn't in the loaded page),
  /// the source itself has been evicted — the previous implementation
  /// fell through to `_reloadLatestMessages()` here, which is the
  /// reported bug: tapping "back to quote" was silently jumping the
  /// user to the latest page instead of returning them to where they
  /// had tapped. Fix: when the source isn't in the current list,
  /// load around it the same way the forward leg loads around the
  /// quoted target, but pass `tongueAfter: TongueType.none` so we
  /// don't chain a second backToQuote tongue off the back-navigation.
  void _onBackToQuoteTongueTap() {
    final returnSource = _quoteReturnSource;
    _quoteReturnSource = null;
    if (returnSource == null) return;

    final returnMsgID = returnSource.msgID;
    if (returnMsgID == null || returnMsgID.isEmpty) {
      setState(() {
        _tongueType = _computeTongueType();
      });
      return;
    }

    final returnIndex =
        _messages.indexWhere((msg) => msg.msgID == returnMsgID);
    if (returnIndex != -1 && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: returnIndex, alignment: 0.3);
      // No highlight on the reverse leg — the user just left this exact
      // message a moment ago and re-flashing it is visual noise.
      //
      // Tongue decision is split into "position-agnostic" and
      // "position-sensitive":
      //   - atMention / newMessages depend only on app state, so commit
      //     them here.
      //   - backToLatest depends on whether the post-jumpTo position
      //     is at the bottom — info we don't have until the next
      //     layout. Committing backToLatest here when the source
      //     happens to be the latest message would produce a visible
      //     1-frame "回到最新位置" flash before _updateTongueState
      //     (isAtBottom branch) wipes it. So coerce backToLatest → none
      //     and let the listener materialise it next frame if needed.
      setState(() {
        final derived = _computeTongueType();
        _tongueType =
            derived == TongueType.backToLatest ? TongueType.none : derived;
      });
      return;
    }

    // Source not in the current loaded list — reload around it. Reuses
    // the forward-leg's load + atomic jump + tongue machinery via
    // `_loadAndNavigateToMessage`; the reverse leg differs in
    // `tongueAfter: none` (round-trip complete) and
    // `highlightTarget: false` (no need to flash the source).
    _loadAndNavigateToMessage(
      cursorMessage: returnSource,
      targetMsgID: returnMsgID,
      tongueAfter: TongueType.none,
      highlightTarget: false,
      debugLabel: 'quote-back',
    );
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
      // Only then is it safe to exit _NavReloadingLatest and hide the tongue.
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached && _messages.isNotEmpty) {
          _itemScrollController.jumpTo(index: 0);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _navigationState is _NavReloadingLatest) {
            setState(() {
              _navigationState = const _NavIdle();
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
      // Enter _NavToAtMention(targetSeq) so the _onMessageListStateChanged
      // switch handles messages / scroll / highlight atomically.
      debugPrint('messageList, _onAtMentionTongueTap, message NOT in list, will fetchMessageList for seq: $targetSeq');
      setState(() {
        _navigationState = _NavToAtMention(targetSeq);
        isLoading = true;
      });

      final atCursorMsg = MessageInfo(sequence: targetSeq);
      final option = MessageLoadOption()
        ..cursor = atCursorMsg
        ..direction = MessageLoadDirection.both
        ..pageCount = 20;

      await _messageListStore.loadMessages(option: option);
    }

    // Delay exiting the nav state by TWO frames (same pattern as
    // _NavToUnread in _onUnreadTongueTap). After _scrollToSeq's jumpTo
    // executes, _itemPositionsListener only fires after layout completes
    // (next frame). _scrollListener then re-checks `is _NavIdle` — if
    // we exited immediately, it could fire off an unwanted load.
    // Frame 1: jumpTo → build + layout, positions update
    // Frame 2: scroll listener has fired; safe to exit nav state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _navigationState is _NavToAtMention) {
          setState(() {
            _navigationState = const _NavIdle();
          });
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
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        content: _atomicLocale.deleteMessagesConfirmTip,
        cancelConfig: ButtonConfig(text: _atomicLocale.cancel),
        confirmConfig: ButtonConfig(
          text: _atomicLocale.confirm,
          type: TextColorPreset.red,
          onClick: () async {
            final messagesToDelete = selectedMessages;
            await _messageListStore.deleteMessages(messageList: messagesToDelete);
            exitMultiSelectMode();
          },
        ),
      ),
    );
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
    if (message.messageType == MessageType.tips) {
      return true;
    }

    if (message.status == MessageStatus.revoked) {
      return true;
    }

    if (MessageUtil.isSystemStyleCustomMessagePayload(message, context)) {
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
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final DateTime now = DateTime.now();

    final String timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime messageDay = DateTime(date.year, date.month, date.day);
    final int daysDiff = today.difference(messageDay).inDays;

    if (daysDiff == 0) {
      return timeStr;
    }

    if (daysDiff == 1) {
      return "${_atomicLocale.yesterday} $timeStr";
    }

    // Compute Monday-based week start to determine "same week".
    final int nowWeekIndex = (now.weekday + 6) % 7;
    final int dateWeekIndex = (date.weekday + 6) % 7;
    final DateTime nowWeekStart = today.subtract(Duration(days: nowWeekIndex));
    final DateTime dateWeekStart = messageDay.subtract(Duration(days: dateWeekIndex));

    if (now.year == date.year && nowWeekStart == dateWeekStart) {
      final weekdays = [
        _atomicLocale.weekdaySunday,
        _atomicLocale.weekdayMonday,
        _atomicLocale.weekdayTuesday,
        _atomicLocale.weekdayWednesday,
        _atomicLocale.weekdayThursday,
        _atomicLocale.weekdayFriday,
        _atomicLocale.weekdaySaturday,
      ];
      return "${weekdays[date.weekday % 7]} $timeStr";
    }

    if (now.year == date.year) {
      return "${date.month}/${date.day} $timeStr";
    }

    return "${date.year}/${date.month}/${date.day} $timeStr";
  }

  Future<void> _loadGroupAttributes() async {
    final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
    final result = await GroupStore.shared.getGroupInfo(groupID: groupId);
    if (result.isSuccess && result.groupInfo != null && mounted) {
      // Prefer the joinedGroupList entry (same instance attribute pushes mutate)
      // so the call banner stays in sync with subsequent _onGroupAttributeChanged.
      final list = GroupStore.shared.state.joinedGroupList.value;
      GroupInfo? fromList;
      for (final g in list) {
        if (g.groupID == groupId) {
          fromList = g;
          break;
        }
      }
      setState(() {
        _groupInfo = fromList ?? result.groupInfo;
      });
      _updateCallStatusWidget();
    }
  }

  /// Sync call banner when GroupStore pushes group attribute / profile updates
  /// (e.g. in-group call start / end while this chat page is already open).
  void _onJoinedGroupListChanged() {
    if (!mounted) return;
    final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
    final list = GroupStore.shared.state.joinedGroupList.value;
    GroupInfo? updated;
    for (final g in list) {
      if (g.groupID == groupId) {
        updated = g;
        break;
      }
    }
    if (updated == null) return;
    _groupInfo = updated;
    _updateCallStatusWidget();
  }

  void _updateCallStatusWidget() {
    if (_groupInfo == null) return;

    final groupId = widget.conversationID.replaceFirst(groupConversationIDPrefix, '');
    final groupAttributes = _groupInfo!.groupAttributes;

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
    if (message.isSentBySelf) return;

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
    final asrText = (message.messagePayload as AudioMessagePayload?)?.asrText ?? '';
    if (asrText.isEmpty) return;

    showAsrPopupMenu(
      context: context,
      targetKey: asrBubbleKey,
      isSelf: message.isSentBySelf,
      actions: [
        // TODO: 暂时屏蔽"隐藏"入口，后续会重新支持，请勿删除
        // AsrPopupMenuAction(
        //   label: _atomicLocale.hide,
        //   iconAsset: 'chat_assets/icon/hide.svg',
        //   onTap: () => _hideAsrText(message),
        // ),
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

  // TODO: 暂时屏蔽"隐藏"功能，后续会重新支持，请勿删除
  // /// Hide ASR text bubble (only for this session)
  // void _hideAsrText(MessageInfo message) {
  //   final messageID = message.msgID ?? '';
  //   _asrDisplayManager.hide(messageID);
  // }

  /// Forward ASR text as text message
  void _forwardAsrText(MessageInfo message) {
    final asrText = (message.messagePayload as AudioMessagePayload?)?.asrText ?? '';
    if (asrText.isEmpty) return;

    ForwardService.forwardText(
      context: context,
      text: asrText,
      excludeConversationID: widget.conversationID,
    );
  }

  /// Copy ASR text to clipboard
  void _copyAsrText(MessageInfo message) {
    final asrText = (message.messagePayload as AudioMessagePayload?)?.asrText ?? '';
    if (asrText.isEmpty) return;

    Clipboard.setData(ClipboardData(text: asrText));
  }

  // ==================== Translation text bubble menu ====================

  /// Show translation text bubble long press menu (popup above the target)
  void _showTranslationTextMenu(MessageInfo message, GlobalKey translationBubbleKey) {
    final translatedTextMap = (message.messagePayload as TextMessagePayload?)?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    showAsrPopupMenu(
      context: context,
      targetKey: translationBubbleKey,
      isSelf: message.isSentBySelf,
      actions: [
        // TODO: 暂时屏蔽"隐藏"入口，后续会重新支持，请勿删除
        // AsrPopupMenuAction(
        //   label: _atomicLocale.hide,
        //   iconAsset: 'chat_assets/icon/hide.svg',
        //   onTap: () => _hideTranslationText(message),
        // ),
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

  // TODO: 暂时屏蔽"隐藏"功能，后续会重新支持，请勿删除
  // /// Hide translation text bubble (only for this session)
  // void _hideTranslationText(MessageInfo message) {
  //   final messageID = message.msgID ?? '';
  //   _translationDisplayManager.hide(messageID);
  // }

  /// Forward translated text as text message
  void _forwardTranslationText(MessageInfo message) {
    final translatedTextMap = (message.messagePayload as TextMessagePayload?)?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    // Build translated display text with emoji preserved (same as copy logic)
    final originalText = (message.messagePayload as TextMessagePayload?)?.text ?? '';
    final translatedText = TranslationTextParser.buildTranslatedDisplayText(
      originalText,
      translatedTextMap,
      [],
    );
    if (translatedText.isEmpty) return;

    ForwardService.forwardText(
      context: context,
      text: translatedText,
      excludeConversationID: widget.conversationID,
    );
  }

  /// Copy translated text to clipboard
  void _copyTranslationText(MessageInfo message) {
    final translatedTextMap = (message.messagePayload as TextMessagePayload?)?.translatedText;
    if (translatedTextMap == null || translatedTextMap.isEmpty) return;

    // Get the translated display text with emoji preserved (no need to fetch atUserNames)
    final originalText = (message.messagePayload as TextMessagePayload?)?.text ?? '';
    final textToCopy = TranslationTextParser.buildTranslatedDisplayText(
      originalText,
      translatedTextMap,
      [],
    );
    
    Clipboard.setData(ClipboardData(text: textToCopy));
  }
}
