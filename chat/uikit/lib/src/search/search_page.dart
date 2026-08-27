import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

import 'search_bar.dart';
import 'search_result_widget.dart';
import '../common/language/gen/chat_localizations.dart';

class SearchPage extends StatefulWidget {
  final OnContactSelect? onContactSelect;
  final OnGroupSelect? onGroupSelect;
  final OnConversationSelect? onConversationSelect;
  final OnMessageSelect? onMessageSelect;

  const SearchPage({
    super.key,
    this.onContactSelect,
    this.onGroupSelect,
    this.onConversationSelect,
    this.onMessageSelect,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late SearchStore _searchStore;
  late SemanticColorScheme _colorScheme;
  late ChatLocalizations _chatLocale;
  String _keyword = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchStore = SearchStore.create();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = BaseThemeProvider.colorsOf(context);
    _chatLocale = ChatLocalizations.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    setState(() {
      _keyword = keyword;
    });
    if (keyword.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      _searchStore.search(keywordList: [keyword]).then((_) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    } else {
      _searchStore = SearchStore.create();
      setState(() {});
    }
  }

  Widget _buildInitialBody() {
    return Container();
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: _colorScheme.textColorSecondary),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      colorFilter: ColorFilter.mode(_colorScheme.textColorSecondary, BlendMode.srcIn),
                      package: 'tencent_chat_uikit',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
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
                  _controller.clear();
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_keyword.isEmpty) {
      return _buildInitialBody();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = _searchStore.state;
    final hasResults =
        state.friendList.value.isNotEmpty || state.groupList.value.isNotEmpty || state.messageResults.value.isNotEmpty;

    if (!hasResults && !_isSearching) {
      return _buildNoResults();
    }

    return SearchResultWidget(
      searchStore: _searchStore,
      keyword: _keyword,
      onContactSelect: widget.onContactSelect,
      onGroupSelect: widget.onGroupSelect,
      onConversationSelect: widget.onConversationSelect,
      onMessageSelect: widget.onMessageSelect,
    );
  }
}
