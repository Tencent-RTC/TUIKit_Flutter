import 'package:tuikit_atomic_x/atomicx.dart' hide Badge;
import 'package:atomic_x_chat/contacts_page.dart';
import 'package:atomic_x_chat/conversations_page.dart';
import 'package:flutter/material.dart';
import 'package:uikit_next/pages/settings_page.dart';
import 'package:uikit_next/widgets/tab_icon.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConversationListStore conversationListStore;
  late AtomicLocalizations atomicLocale;
  int _currentIndex = 0;
  late List<_NavItem> _navItems;
  int totalUnreadCount = 0;

  final List<Widget> _pages = [
    const _KeepAlivePage(child: ConversationsPage()),
    const _KeepAlivePage(child: ContactsPage()),
    const _KeepAlivePage(child: SettingsPage()),
  ];

  @override
  void initState() {
    super.initState();
    conversationListStore = ConversationListStore.create();
    conversationListStore.addListener(_onConversationListChanged);
    conversationListStore.getConversationTotalUnreadCount();
  }

  @override
  void dispose() {
    conversationListStore.removeListener(_onConversationListChanged);
    super.dispose();
  }

  void _onConversationListChanged() {
    setState(() {
      totalUnreadCount = conversationListStore.conversationListState.totalUnreadCount;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    _navItems = [
      _NavItem(
        iconType: TabIconType.chats,
        label: atomicLocale.chat,
      ),
      _NavItem(
        iconType: TabIconType.contact,
        label: atomicLocale.contact,
      ),
      _NavItem(
        iconType: TabIconType.settings,
        label: atomicLocale.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final colors = BaseThemeProvider.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgColorBottomBar,
        border: Border(
          top: BorderSide(
            color: colors.strokeColorPrimary,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: colors.bgColorBottomBar,
          selectedItemColor: colors.buttonColorPrimaryDefault,
          unselectedItemColor: colors.textColorSecondary,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 28,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.24,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.24,
          ),
          items: _navItems.map((item) => _buildNavItem(item, totalUnreadCount, colors)).toList(),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(_NavItem item, int unreadCount, SemanticColorScheme colors) {
    final isActive = _navItems.indexOf(item) == _currentIndex;

    if (item.iconType == TabIconType.chats) {
      return BottomNavigationBarItem(
        icon: Padding(
          padding: const EdgeInsets.only(bottom: 2.0, top: 8.0),
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textColorButton,
                height: 1.4,
              ),
            ),
            backgroundColor: colors.textColorError,
            offset: const Offset(10, -5),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            smallSize: 16,
            largeSize: 20,
            child: TabIcon(
              iconType: item.iconType,
              isActive: isActive,
              activeColor: colors.textColorLink,
              inactiveColor: colors.textColorSecondary,
              size: 28,
            ),
          ),
        ),
        label: item.label,
      );
    }

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 2.0, top: 8.0),
        child: TabIcon(
          iconType: item.iconType,
          isActive: isActive,
          activeColor: colors.buttonColorPrimaryDefault,
          inactiveColor: colors.textColorSecondary,
          size: 28,
        ),
      ),
      label: item.label,
    );
  }
}

class _NavItem {
  final TabIconType iconType;
  final String label;

  _NavItem({
    required this.iconType,
    required this.label,
  });
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
