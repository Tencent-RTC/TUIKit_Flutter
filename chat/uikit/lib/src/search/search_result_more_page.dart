import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/search/utils/text_highlighter.dart';

import 'search_bar.dart';
import 'search_message_in_conversation_page.dart';
import '../common/language/gen/chat_localizations.dart';

class SearchResultMorePage extends StatefulWidget {
  final SearchType searchType;
  final String keyword;
  final OnContactSelect? onContactSelect;
  final OnGroupSelect? onGroupSelect;
  final OnConversationSelect? onConversationSelect;
  final OnMessageSelect? onMessageSelect;

  const SearchResultMorePage({
    super.key,
    required this.searchType,
    required this.keyword,
    this.onContactSelect,
    this.onGroupSelect,
    this.onConversationSelect,
    this.onMessageSelect,
  });

  @override
  State<SearchResultMorePage> createState() => _SearchResultMorePageState();
}

class _SearchResultMorePageState extends State<SearchResultMorePage> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _textEditingController;
  final FocusNode _focusNode = FocusNode();
  late SearchStore _searchStore;
  late SemanticColorScheme _colorScheme;
  late ChatLocalizations _chatLocale;
  bool _isSearching = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.keyword);
    _searchStore = SearchStore.create();
    _onSearch(widget.keyword);

    if (widget.searchType == SearchType.message) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = BaseThemeProvider.colorsOf(context);
    _chatLocale = ChatLocalizations.of(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    _focusNode.unfocus();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      if (!_searchStore.state.hasMoreMessageResults.value) return;
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
      _searchStore = SearchStore.create();
      setState(() {});
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final option = SearchOption(searchScope: [widget.searchType]);
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
    final state = _searchStore.state;

    List<dynamic> results = [];
    if (widget.searchType == SearchType.friend) {
      results = state.friendList.value;
    } else if (widget.searchType == SearchType.group) {
      results = state.groupList.value;
    } else if (widget.searchType == SearchType.message) {
      results = state.messageResults.value;
    }

    Widget body;
    if (_isSearching && results.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView.builder(
        controller: _scrollController,
        itemCount: results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == results.length && _isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildResultItem(context, results[index]);
        },
      );
    }

    return Scaffold(
      backgroundColor: _colorScheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: _colorScheme.bgColorOperate,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _colorScheme.bgColorInput,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'chat_assets/icon/search.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(_colorScheme.textColorTertiary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        onChanged: _onSearch,
                        textAlignVertical: TextAlignVertical.center,
                        style: FontScheme.caption2Regular.copyWith(
                          color: _colorScheme.textColorPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _chatLocale.search,
                          hintStyle: FontScheme.caption2Regular.copyWith(
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
              padding: const EdgeInsets.only(left: 14),
              child: GestureDetector(
                onTap: () {
                  _textEditingController.clear();
                  _onSearch('');
                  Navigator.of(context).pop();
                },
                child: Text(
                  _chatLocale.cancel,
                  style: TextStyle(
                    color: _colorScheme.textColorSecondary,
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

  Widget _buildResultItem(BuildContext context, dynamic item) {
    if (item is FriendSearchInfo) {
      return _buildFriendItem(context, item);
    } else if (item is GroupSearchInfo) {
      return _buildGroupItem(context, item);
    } else if (item is MessageSearchResultItem) {
      return _buildMessageResultItem(context, item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFriendItem(BuildContext context, FriendSearchInfo friend) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;
    final keyword = _textEditingController.text;
    final titleStyle = TextStyle(color: _colorScheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: _colorScheme.textColorSecondary);

    final displayName = friend.friendRemark?.isNotEmpty == true
        ? friend.friendRemark!
        : (friend.userInfo?.nickname?.isNotEmpty == true ? friend.userInfo!.nickname! : friend.userID);
    final avatar = friend.userInfo?.avatarURL ?? '';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, _colorScheme.textColorLink),
          subtitle: TextHighlighter.buildHighlightedText(
              'ID:${friend.userID}', keyword, subtitleStyle, _colorScheme.textColorLink),
          onTap: () {
            if (widget.onContactSelect != null) {
              widget.onContactSelect!(friend);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: _colorScheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItem(BuildContext context, GroupSearchInfo group) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;
    final keyword = _textEditingController.text;
    final titleStyle = TextStyle(color: _colorScheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: _colorScheme.textColorSecondary);

    final displayName = (group.groupName?.isNotEmpty == true) ? group.groupName! : group.groupID;
    final avatar = group.groupAvatarURL ?? '';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, _colorScheme.textColorLink),
          subtitle: TextHighlighter.buildHighlightedText(
              'groupID: ${group.groupID}', keyword, subtitleStyle, _colorScheme.textColorLink),
          onTap: () {
            if (widget.onGroupSelect != null) {
              widget.onGroupSelect!(group);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: _colorScheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageResultItem(BuildContext context, MessageSearchResultItem messageResult) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;
    final keyword = _textEditingController.text;
    final titleStyle = TextStyle(color: _colorScheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: _colorScheme.textColorSecondary);

    final displayName = messageResult.conversationShowName;
    final avatar = messageResult.conversationAvatarURL ?? '';

    String subtitle;
    if (messageResult.messageCount > 1) {
      subtitle = _chatLocale.chatRecords(messageResult.messageCount);
    } else if (messageResult.messageList.isNotEmpty) {
      subtitle = MessageUtil.getMessageAbstract(messageResult.messageList.first, context);
    } else {
      subtitle = '';
    }

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, _colorScheme.textColorLink),
          subtitle: subtitle.isNotEmpty
              ? TextHighlighter.buildHighlightedText(subtitle, keyword, subtitleStyle, _colorScheme.textColorLink)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchMessageInConversationPage(
                  conversationID: messageResult.conversationID,
                  conversationName: messageResult.conversationShowName,
                  conversationAvatar: messageResult.conversationAvatarURL ?? '',
                  keyword: _textEditingController.text,
                  onConversationSelect: widget.onConversationSelect,
                  onMessageSelect: widget.onMessageSelect,
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: _colorScheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }
}
