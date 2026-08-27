import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide Badge;
import 'package:flutter/material.dart';
import 'package:application/src/chat/settings_page.dart';
import 'package:application/src/chat/tab_widget.dart';
import 'package:application/src/chat/welcome_message_sender.dart';

class ChatMainWidget extends StatefulWidget {
  const ChatMainWidget({Key? key}) : super(key: key);

  @override
  State<ChatMainWidget> createState() => _ChatMainWidgetState();
}

class _ChatMainWidgetState extends State<ChatMainWidget> {
  late ConversationListStore conversationListStore;
  late ChatLocalizations chatLocale;
  int _currentIndex = 0;
  late List<_NavItem> _navItems;
  int totalUnreadCount = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    conversationListStore = ConversationListStore.create();
    conversationListStore.state.totalUnreadCount.addListener(_onConversationListChanged);
    WelcomeMessageSender.scheduleWelcomeMessage();

    _pages = [
      _KeepAlivePage(child: ConversationsPage(onBackPressed: _onBackPressed)),
      _KeepAlivePage(child: ContactsPage(onBackPressed: _onBackPressed)),
      _KeepAlivePage(child: SettingsPage(onBackPressed: _onBackPressed)),
    ];
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    conversationListStore.state.totalUnreadCount.removeListener(_onConversationListChanged);
    super.dispose();
  }

  void _onConversationListChanged() {
    setState(() {
      totalUnreadCount = conversationListStore.state.totalUnreadCount.value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    _navItems = [
      _NavItem(
        iconType: TabIconType.chats,
        label: chatLocale.chat,
      ),
      _NavItem(
        iconType: TabIconType.contact,
        label: chatLocale.contact,
      ),
      _NavItem(
        iconType: TabIconType.settings,
        label: chatLocale.me,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
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
            child: TabWidget(
              iconType: item.iconType,
              isActive: isActive,
              activeColor: colors.textColorLink,
              inactiveColor: colors.textColorTertiary,
              size: 24,
            ),
          ),
        ),
        label: item.label,
      );
    }

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 2.0, top: 8.0),
        child: TabWidget(
          iconType: item.iconType,
          isActive: isActive,
          activeColor: colors.buttonColorPrimaryDefault,
          inactiveColor: colors.textColorTertiary,
          size: 24,
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
