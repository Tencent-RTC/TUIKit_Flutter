import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/widgets/message_checkbox.dart';

/// Forward target selection result
class ForwardTargetSelectResult {
  final List<String> conversationIDs;
  final List<ConversationInfo> conversations;

  ForwardTargetSelectResult({
    required this.conversationIDs,
    required this.conversations,
  });
}

/// Forward target selector page
class ForwardTargetSelectorPage extends StatefulWidget {
  final bool allowMultiSelect;
  final int maxSelectCount;
  final String? excludeConversationID;

  const ForwardTargetSelectorPage({
    super.key,
    this.allowMultiSelect = true,
    this.maxSelectCount = 9,
    this.excludeConversationID,
  });

  @override
  State<ForwardTargetSelectorPage> createState() => _ForwardTargetSelectorPageState();

  /// Show forward target selector
  static Future<ForwardTargetSelectResult?> show(
    BuildContext context, {
    bool allowMultiSelect = true,
    int maxSelectCount = 9,
    String? excludeConversationID,
  }) async {
    return Navigator.of(context).push<ForwardTargetSelectResult>(
      MaterialPageRoute(
        builder: (context) => ForwardTargetSelectorPage(
          allowMultiSelect: allowMultiSelect,
          maxSelectCount: maxSelectCount,
          excludeConversationID: excludeConversationID,
        ),
      ),
    );
  }
}

class _ForwardTargetSelectorPageState extends State<ForwardTargetSelectorPage> {
  final ConversationListStore _conversationListStore = ConversationListStore.create();
  final Set<String> _selectedConversationIDs = {};
  List<ConversationInfo> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _conversationListStore.addListener(_onConversationListChanged);
    _loadConversations();
  }

  @override
  void dispose() {
    _conversationListStore.removeListener(_onConversationListChanged);
    super.dispose();
  }

  void _onConversationListChanged() {
    setState(() {
      _conversations = _conversationListStore.conversationListState.conversationList
          .where((conv) => conv.conversationID != widget.excludeConversationID)
          .toList();
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    await _conversationListStore.fetchConversationList(
      option: ConversationFetchOption(count: 100),
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleSelection(ConversationInfo conversation) {
    setState(() {
      final id = conversation.conversationID;
      if (_selectedConversationIDs.contains(id)) {
        _selectedConversationIDs.remove(id);
      } else {
        if (_selectedConversationIDs.length < widget.maxSelectCount) {
          _selectedConversationIDs.add(id);
        }
      }
    });
  }

  void _confirmSelection() {
    final selectedConversations = _conversations
        .where((conv) => _selectedConversationIDs.contains(conv.conversationID))
        .toList();

    Navigator.of(context).pop(ForwardTargetSelectResult(
      conversationIDs: _selectedConversationIDs.toList(),
      conversations: selectedConversations,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = AtomicLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colors.bgColorOperate,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Icon(Icons.close, color: colors.textColorPrimary),
          ),
        ),
        title: Text(
          _getTitle(locale),
          style: TextStyle(
            color: colors.textColorPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.allowMultiSelect && _selectedConversationIDs.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                '${locale.confirm}(${_selectedConversationIDs.length})',
                style: TextStyle(
                  color: colors.buttonColorPrimaryDefault,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Text(
                    _getEmptyText(locale),
                    style: TextStyle(
                      color: colors.textColorSecondary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final isSelected = _selectedConversationIDs.contains(conversation.conversationID);

                    return _buildConversationItem(
                      conversation: conversation,
                      isSelected: isSelected,
                      colors: colors,
                    );
                  },
                ),
    );
  }

  Widget _buildConversationItem({
    required ConversationInfo conversation,
    required bool isSelected,
    required SemanticColorScheme colors,
  }) {
    return InkWell(
      onTap: () {
        if (widget.allowMultiSelect) {
          _toggleSelection(conversation);
        } else {
          // Single select mode, return directly
          Navigator.of(context).pop(ForwardTargetSelectResult(
            conversationIDs: [conversation.conversationID],
            conversations: [conversation],
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            if (widget.allowMultiSelect)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MessageCheckbox(
                  isSelected: isSelected,
                  isEnabled: true,
                ),
              ),
            // Avatar
            Avatar(
              content: AvatarImageContent(
                url: conversation.avatarURL,
                name: conversation.title ?? '',
              ),
              size: AvatarSize.l,
            ),
            const SizedBox(width: 12),
            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title ?? conversation.conversationID,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textColorPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(AtomicLocalizations locale) {
    return locale.selectChat;
  }

  String _getEmptyText(AtomicLocalizations locale) {
    final languageCode = locale.localeName;
    if (languageCode.startsWith('zh')) {
      return '暂无会话';
    } else {
      return 'No conversations';
    }
  }
}
