import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide Badge;
import 'package:flutter/material.dart';
import 'package:uikit_next/common/language/gen/demo_localizations.dart';
import 'package:uikit_next/custom_messages/custom_link_message.dart';
import 'package:uikit_next/pages/settings_page.dart';
import 'package:uikit_next/widgets/tab_icon.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConversationListStore conversationListStore;
  late ChatLocalizations chatLocale;
  int _currentIndex = 0;
  late List<_NavItem> _navItems;
  int totalUnreadCount = 0;

  // Rebuilt in didChangeDependencies so the custom more-panel entry picks up
  // the current language when the user switches it.
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    conversationListStore = ConversationListStore.create();
    conversationListStore.state.totalUnreadCount.addListener(_onConversationListChanged);
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
    // Both chat entry points get the same configs, so the custom message
    // renders and can be sent however the user reached the conversation.
    final messageListConfig = CustomLinkMessageManager.messageListConfig;
    final messageInputConfig = CustomLinkMessageManager.messageInputConfig(DemoLocalizations.of(context)).copyWith(
      isShowAudioCall: true,
      isShowVideoCall: true,
    );
    _pages = [
      _KeepAlivePage(
        child: ConversationsPage(
          messageListConfig: messageListConfig,
          messageInputConfig: messageInputConfig,
        ),
      ),
      _KeepAlivePage(
        child: ContactsPage(
          messageListConfig: messageListConfig,
          messageInputConfig: messageInputConfig,
        ),
      ),
      const _KeepAlivePage(child: SettingsPage()),
    ];
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
      canPop: false,
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

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.bgColorOperate,
      selectedItemColor: colors.buttonColorPrimaryDefault,
      unselectedItemColor: colors.textColorSecondary,
      selectedFontSize: FontScheme.caption3Medium.fontSize!,
      unselectedFontSize: FontScheme.caption3Medium.fontSize!,
      iconSize: 28,
      elevation: 0,
      selectedLabelStyle: FontScheme.caption3Medium.copyWith(
        height: 1.4,
        letterSpacing: -0.24,
      ),
      unselectedLabelStyle: FontScheme.caption3Medium.copyWith(
        height: 1.4,
        letterSpacing: -0.24,
      ),
      items: _navItems.map((item) => _buildNavItem(item, totalUnreadCount, colors)).toList(),
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
              style: FontScheme.caption4Medium.copyWith(
                color: colors.textColorButton,
              ),
            ),
            backgroundColor: colors.textColorError,
            offset: const Offset(10, -5),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            largeSize: 20,
            child: TabIcon(
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
        child: TabIcon(
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
