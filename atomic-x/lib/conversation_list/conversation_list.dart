import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'conversation_list_config.dart';
import 'widgets/conversation_item.dart';

export 'widgets/conversation_item.dart';

class ConversationCustomAction {
  final String title;
  final void Function(ConversationInfo) action;

  const ConversationCustomAction({
    required this.title,
    required this.action,
  });
}

class ConversationList extends StatefulWidget {
  final Function(ConversationInfo)? onConversationClick;
  final List<ConversationCustomAction> customActions;
  final ConversationActionConfigProtocol config;

  const ConversationList({
    super.key,
    this.onConversationClick,
    this.customActions = const [],
    this.config = const ChatConversationActionConfig(),
  });

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  late ConversationListStore conversationListStore;
  final ScrollController _scrollController = ScrollController();
  List<ConversationInfo> conversations = [];
  bool isLoading = false;
  bool hasMoreConversations = true;

  @override
  void initState() {
    super.initState();
    conversationListStore = ConversationListStore.create();

    conversationListStore.addListener(_onConversationListChanged);

    _scrollController.addListener(_scrollListener);

    _loadConversations();
  }

  @override
  void dispose() {
    conversationListStore.removeListener(_onConversationListChanged);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onConversationListChanged() {
    setState(() {
      conversations = conversationListStore.conversationListState.conversationList;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMoreConversations) {
        _loadMoreConversations();
      }
    }
  }

  Future<void> _loadConversations() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    final option = ConversationFetchOption();

    final result = await conversationListStore.fetchConversationList(option: option);
    setState(() {
      hasMoreConversations = result.isSuccess && conversationListStore.conversationListState.hasMoreConversation;
      isLoading = false;
    });
  }

  Future<void> _loadMoreConversations() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    final result = await conversationListStore.fetchMoreConversationList();
    setState(() {
      hasMoreConversations = result.isSuccess && conversationListStore.conversationListState.hasMoreConversation;
      isLoading = false;
    });
  }

  void _handlePinConversation(ConversationInfo conversationInfo) async {
    if (conversationInfo.isPinned) {
      conversationListStore.pinConversation(conversationID: conversationInfo.conversationID, pin: false);
    } else {
      conversationListStore.pinConversation(conversationID: conversationInfo.conversationID, pin: true);
    }
  }

  void _handleClearHistoryMessage(ConversationInfo conversationInfo) async {
    conversationListStore.clearConversationMessages(conversationID: conversationInfo.conversationID);
  }

  void _handleDeleteConversation(ConversationInfo conversationInfo) async {
    conversationListStore.deleteConversation(conversationID: conversationInfo.conversationID);
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      color: colorsTheme.bgColorOperate,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length + (isLoading && hasMoreConversations ? 1 : 0),
            itemBuilder: (context, index) {
              if (isLoading && hasMoreConversations && index == conversations.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.buttonColorPrimaryDefault),
                    ),
                  ),
                );
              }

              final conversation = conversations[index];

              return ConversationItem(
                conversation: conversation,
                onPinToggle: () {
                  _handlePinConversation(conversation);
                },
                onDelete: () {
                  _handleDeleteConversation(conversation);
                },
                onClearHistory: () {
                  _handleClearHistoryMessage(conversation);
                },
                onTap: () {
                  if (widget.onConversationClick != null) {
                    widget.onConversationClick!(conversation);
                  }
                },
                customActions: widget.customActions,
                config: widget.config,
              );
            },
          ),
          if (isLoading && conversations.isEmpty)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.buttonColorPrimaryDefault),
              ),
            ),
        ],
      ),
    );
  }
}
