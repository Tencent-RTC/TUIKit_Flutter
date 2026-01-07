import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

import 'search_bar.dart';
import 'search_result_widget.dart';

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
  late AtomicLocalizations _atomicLocale;
  String _keyword = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchStore = SearchStore.create();
    _searchStore.addListener(_onSearchStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = BaseThemeProvider.colorsOf(context);
    _atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _searchStore.removeListener(_onSearchStateChanged);
    _searchStore.dispose();
    super.dispose();
  }

  void _onSearchStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearch(String keyword) {
    setState(() {
      _keyword = keyword;
    });
    if (keyword.isNotEmpty) {
      // Trigger search using new API
      setState(() {
        _isSearching = true;
      });
      final option = SearchOption();
      _searchStore.search(keywordList: [keyword], option: option).then((_) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    } else {
      // Clear search results by re-creating SearchStore
      _searchStore.removeListener(_onSearchStateChanged);
      _searchStore.dispose();
      _searchStore = SearchStore.create();
      _searchStore.addListener(_onSearchStateChanged);
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
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
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
              padding: const EdgeInsets.only(left: 14),
              child: GestureDetector(
                onTap: () {
                  _controller.clear();
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

    final searchState = _searchStore.searchState;
    final hasResults =
        searchState.friendList.isNotEmpty || searchState.groupList.isNotEmpty || searchState.messageResults.isNotEmpty;

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
