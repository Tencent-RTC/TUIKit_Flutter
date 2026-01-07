import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_item.dart';

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

  /// MessageListStore for merged messages
  late MessageListStore _mergedMessageStore;

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
    // Create a store for merged messages (same as Swift)
    _mergedMessageStore = MessageListStore.create(
      conversationID: '',
      messageListType: MessageListType.merged,
    );
    _mergedMessageStore.addListener(_onMessageListStateChanged);
    _loadMergedMessages();
  }

  @override
  void dispose() {
    _mergedMessageStore.removeListener(_onMessageListStateChanged);
    super.dispose();
  }

  void _onMessageListStateChanged() {
    if (mounted) {
      setState(() {
        _mergedMessages = _mergedMessageStore.messageListState.messageList.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMergedMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use MessageListStore.fetchMessageList (same as Swift)
      final option = MessageFetchOption()
        ..message = widget.message
        ..direction = MessageFetchDirection.older
        ..pageCount = 100;

      final result = await _mergedMessageStore.fetchMessageList(option: option);
      // Result is handled by _onMessageListStateChanged
      
      // Fetch reactions for loaded messages (display original reactions)
      if (result.isSuccess) {
        final messages = _mergedMessageStore.messageListState.messageList;
        if (messages.isNotEmpty) {
          await _fetchMessageReactions(messages);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch message reactions for displaying emoji responses
  Future<void> _fetchMessageReactions(List<MessageInfo> messages) async {
    if (messages.isEmpty) return;
    await _mergedMessageStore.fetchMessageReactions(
      messageList: messages,
      maxUserCountPerReaction: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final mergedInfo = widget.message.messageBody?.mergedMessage;
    final title = mergedInfo?.title ?? _getDefaultTitle();

    return Scaffold(
      backgroundColor: colors.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colors.bgColorDefault,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Icon(Icons.arrow_back_ios, color: colors.textColorPrimary),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.textColorPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _mergedMessages.length,
      itemBuilder: (context, index) {
        final message = _mergedMessages[index];
        // Use MessageItem for consistent layout with message_list
        return MessageItem(
          message: message,
          conversationID: '',
          isGroup: false,
          maxWidth: maxWidth,
          messageListStore: _mergedMessageStore,
          isHighlighted: false,
          config: _config,
          isInMergedDetailView: true,
        );
      },
    );
  }

  String _getDefaultTitle() {
    final locale = AtomicLocalizations.of(context);
    return locale.chatHistory;
  }
}
