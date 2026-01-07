import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/search/utils/text_highlighter.dart';

import 'search_bar.dart';

class SearchMessageInConversationPage extends StatefulWidget {
  final String conversationID;
  final String conversationName;
  final String conversationAvatar;
  final String keyword;
  final OnConversationSelect? onConversationSelect;
  final OnMessageSelect? onMessageSelect;

  const SearchMessageInConversationPage({
    super.key,
    required this.conversationID,
    required this.conversationName,
    required this.conversationAvatar,
    required this.keyword,
    this.onConversationSelect,
    this.onMessageSelect,
  });

  @override
  State<SearchMessageInConversationPage> createState() => _SearchMessageInConversationPageState();
}

class _SearchMessageInConversationPageState extends State<SearchMessageInConversationPage> {
  late SearchStore _searchStore;
  late final TextEditingController _textEditingController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late SemanticColorScheme _colorScheme;
  late AtomicLocalizations _atomicLocale;
  bool _isSearching = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.keyword);
    _searchStore = SearchStore.create();
    _searchStore.addListener(_onSearchStateChanged);
    _scrollController.addListener(_onScroll);

    _onSearch(widget.keyword);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = BaseThemeProvider.colorsOf(context);
    _atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    _searchStore.removeListener(_onSearchStateChanged);
    _searchStore.dispose();
    _scrollController.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      final searchState = _searchStore.searchState;
      if (!searchState.hasMoreMessageResults) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
      _searchStore.searchMore(searchType: SearchType.message).then((_) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _onSearch(String keyword) {
    if (keyword.isEmpty) {
      // Clear search results by re-creating SearchStore
      _searchStore.removeListener(_onSearchStateChanged);
      _searchStore.dispose();
      _searchStore = SearchStore.create();
      _searchStore.addListener(_onSearchStateChanged);
      setState(() {});
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Search messages in one conversation using new API
    final messageFilter = MessageSearchFilter(conversationID: widget.conversationID);
    final option = SearchOption(
      searchType: SearchType.message,
      messageFilter: messageFilter,
    );
    _searchStore.search(keywordList: [keyword], option: option).then((_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = _searchStore.searchState;

    // Get messages from the first message result item (since we're searching in one conversation)
    List<MessageInfo> messages = [];
    if (searchState.messageResults.isNotEmpty) {
      messages = searchState.messageResults.first.messageList;
    }

    Widget body;
    // Show loading indicator only on initial search when results are empty
    if (_isSearching && messages.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          _buildConversationHeader(),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: _colorScheme.strokeColorPrimary,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  return _buildMessageItem(messages[index]);
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _colorScheme.bgColorOperate,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: _colorScheme.bgColorInput,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(Icons.search, size: 20, color: _colorScheme.textColorSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        onChanged: _onSearch,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: _colorScheme.textColorPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _atomicLocale.search,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: _colorScheme.textColorSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () {
                  _textEditingController.clear();
                  _focusNode.unfocus();
                  _onSearch('');
                  Navigator.of(context).pop();
                },
                child: Text(
                  _atomicLocale.cancel,
                  style: TextStyle(
                    color: _colorScheme.buttonColorPrimaryDefault,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildConversationHeader() {
    return ListTile(
      leading: Avatar.image(
        name: widget.conversationName.isNotEmpty ? widget.conversationName[0].toUpperCase() : '?',
        url: widget.conversationAvatar,
        size: AvatarSize.m,
      ),
      title: Text(
        widget.conversationName,
        style: TextStyle(color: _colorScheme.textColorPrimary, fontWeight: FontWeight.bold),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: _colorScheme.textColorSecondary,
      ),
      onTap: () {
        if (widget.onConversationSelect != null) {
          final messageSearchResultItem = MessageSearchResultItem(
            conversationID: widget.conversationID,
            conversationShowName: widget.conversationName,
            conversationAvatarURL: widget.conversationAvatar,
            messageCount: 0,
            messageList: [],
          );
          widget.onConversationSelect!(messageSearchResultItem);
        }
      },
    );
  }

  Widget _buildMessageItem(MessageInfo message) {
    final keyword = _textEditingController.text;
    final titleStyle = TextStyle(color: _colorScheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: _colorScheme.textColorSecondary);

    final senderName = ChatUtil.getMessageSenderName(message);
    final senderAvatar = message.sender.avatarURL ?? '';

    return ListTile(
      leading: Avatar.image(
        name: senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
        url: senderAvatar,
        size: AvatarSize.m,
      ),
      title: TextHighlighter.buildHighlightedText(senderName, keyword, titleStyle, _colorScheme.textColorLink),
      subtitle: TextHighlighter.buildHighlightedText(
          MessageUtil.getMessageAbstract(message, context), keyword, subtitleStyle, _colorScheme.textColorLink),
      onTap: () {
        if (widget.onMessageSelect != null) {
          widget.onMessageSelect!(message);
        }
      },
    );
  }
}
