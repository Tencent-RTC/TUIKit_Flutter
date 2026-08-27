import 'package:atomic_x_core/api/message/message_action_store.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_item.dart';
import 'package:tencent_chat_uikit/src/third_party/scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../common/language/gen/chat_localizations.dart';

/// Merged message detail page
class MergedMessageDetailPage extends StatefulWidget {
  final MessageInfo message;
  final MessageListStore messageListStore;

  const MergedMessageDetailPage({
    super.key,
    required this.message,
    required this.messageListStore,
  });

  @override
  State<MergedMessageDetailPage> createState() => _MergedMessageDetailPageState();
}

class _MergedMessageDetailPageState extends State<MergedMessageDetailPage> {
  List<MessageInfo> _mergedMessages = [];
  bool _isLoading = true;

  /// MessageListStore for merged messages — needed by [MessageItem] for
  /// the same widget contract as the main chat. The store itself is
  /// unused inside the merged-detail flow (messages are loaded via
  /// MessageActionStore.downloadMergedMessageList and held locally
  /// in [_mergedMessages]); it exists only to satisfy MessageItem's
  /// required `messageListStore` parameter.
  late MessageListStore _mergedMessageStore;

  /// In-list scroll controller used by [ScrollablePositionedList] to
  /// jumpTo the index of a tapped quote target.
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  /// msgID of the message currently flashing the highlight animation
  /// (after a quote tap). Cleared by [MessageBubble.onHighlightComplete].
  String? _highlightedMessageId;

  /// Config for merged detail view - disable read receipt
  static const _config = ChatMessageListConfig(
    enableReadReceipt: false,
    isSupportCopy: false,
    isSupportDelete: false,
    isSupportRecall: false,
    isSupportForward: false,
    isSupportMultiSelect: false,
  );

  @override
  void initState() {
    super.initState();
    _mergedMessageStore = MessageListStore.create(conversationID: '');
    _loadMergedMessagePayloads();
  }

  Future<void> _loadMergedMessagePayloads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final actionStore = MessageActionStore.create(widget.message);
      final result = await actionStore.downloadMergedMessageList();
      if (result.isSuccess && mounted) {
        setState(() {
          _mergedMessages = result.messageList;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle tap on a quote preview INSIDE the merged-detail list.
  ///
  /// Merged-detail is a bounded, in-memory list — there is no
  /// "load around an external message" affordance here (unlike the
  /// main chat's `_loadAndNavigateToQuotedMessage`). So the behaviour
  /// is strictly:
  ///   - target msgID present in [_mergedMessages]   → jumpTo (if
  ///     not already visible) + highlight the target.
  ///   - target msgID NOT in [_mergedMessages]       → toast the
  ///     reusable "quoted original unreachable" string. There's no
  ///     equivalent of `_NavToQuotedMessage` reload here because
  ///     merged forwards are immutable: nothing outside the bundle
  ///     is reachable.
  void _onQuotePreviewTap(MessageInfo message) {
    final quoteInfo = message.quoteInfo;
    if (quoteInfo == null || quoteInfo.msgID.isEmpty) return;

    final targetIndex =
        _mergedMessages.indexWhere((m) => m.msgID == quoteInfo.msgID);

    if (targetIndex == -1) {
      // Reuses the same string as the main chat shows when an original
      // quoted message can't be located — keeps the user-facing copy
      // consistent across the two surfaces.
      Toast.info(context, ChatLocalizations.of(context).quotedOriginalMessageUnreachable);
      return;
    }

    // Only scroll when the target is actually off-screen. For short
    // bundles (a few messages, the common case) the target is already
    // fully visible — issuing a jumpTo would needlessly redraw and,
    // worse, force ScrollablePositionedList to honour the requested
    // alignment exactly, which on a list shorter than the viewport
    // leaves a band of blank space above the pinned item. Skipping the
    // jump in that case keeps the layout natural and the user simply
    // sees the flash highlight on the existing position.
    if (!_isTargetFullyVisible(targetIndex)
        && _itemScrollController.isAttached) {
      // alignment 0 (NOT 0.3 like the main chat) because this list is
      // forward-scrolled (`reverse: false`), so 0 means "pin to the
      // top of the viewport". A fractional alignment here would
      // re-introduce the same blank-band issue described above.
      _itemScrollController.jumpTo(index: targetIndex, alignment: 0);
    }
    setState(() {
      _highlightedMessageId = _mergedMessages[targetIndex].msgID;
    });
  }

  /// Whether the item at [index] is wholly inside the current viewport.
  /// `itemLeadingEdge` and `itemTrailingEdge` are expressed as fractions
  /// of the viewport's main axis: leading >= 0 and trailing <= 1 means
  /// the item is fully on-screen.
  bool _isTargetFullyVisible(int index) {
    final positions = _itemPositionsListener.itemPositions.value;
    for (final pos in positions) {
      if (pos.index == index) {
        return pos.itemLeadingEdge >= 0 && pos.itemTrailingEdge <= 1;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final mergedInfo = widget.message.messagePayload as MergedMessagePayload?;
    final title = mergedInfo?.title ?? _getDefaultTitle();

    return Scaffold(
      backgroundColor: colors.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colors.bgColorDefault,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Icon(Icons.arrow_back_ios, color: colors.textColorSecondary),
          ),
        ),
        title: Text(
          title,
          style: FontScheme.body4Medium.copyWith(
            color: colors.textColorPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(SemanticColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mergedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth - 32 - 36 - _config.avatarSpacing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: _mergedMessages.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          final message = _mergedMessages[index];
          final isHighlighted = _highlightedMessageId != null
              && message.msgID == _highlightedMessageId;
          return MessageItem(
            message: message,
            conversationID: '',
            isGroup: false,
            maxWidth: maxWidth,
            messageListStore: _mergedMessageStore,
            isHighlighted: isHighlighted,
            onHighlightComplete: () {
              if (_highlightedMessageId == message.msgID && mounted) {
                setState(() {
                  _highlightedMessageId = null;
                });
              }
            },
            onQuotePreviewTap: _onQuotePreviewTap,
            config: _config,
            isInMergedDetailView: true,
            mergedMediaMessages: _mergedMessages,
          );
        },
      ),
    );
  }

  String _getDefaultTitle() {
    final locale = ChatLocalizations.of(context);
    return locale.chatHistory;
  }
}
