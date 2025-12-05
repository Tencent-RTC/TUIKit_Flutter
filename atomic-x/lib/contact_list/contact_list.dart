import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/contact_list/pages/group_application_list.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/blacklist.dart';
import 'pages/friend_application_list.dart';
import 'pages/group_list.dart';

typedef OnGroupClick = void Function(ContactInfo contactInfo);
typedef OnContactClick = void Function(ContactInfo contactInfo);

class ContactList extends StatefulWidget {
  final Function(ContactInfo contactInfo)? onGroupClick;
  final Function(ContactInfo contactInfo)? onContactClick;

  const ContactList({
    super.key,
    this.onGroupClick,
    this.onContactClick,
  });

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  late ContactListStore _contactListStore;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _contactListStore = ContactListStore.create();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    _contactListStore.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _contactListStore.fetchFriendList(),
      _contactListStore.fetchFriendApplicationList(),
      _contactListStore.fetchGroupApplicationList(),
    ]);
  }

  Widget _buildMenuTile({
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      color: colorsTheme.bgColorInput,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: colorsTheme.textColorPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorsTheme.textColorError,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: colorsTheme.textColorButton,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: colorsTheme.scrollbarColorHover),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget buildDivider(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      height: 1,
      color: colorsTheme.listColorDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _contactListStore,
      child: Consumer<ContactListStore>(
        builder: (context, store, child) {
          final dataSource = store.contactListState.friendList
              .map((contact) => AZOrderedListItem(
                    key: contact.contactID,
                    label: contact.title ?? contact.contactID,
                    avatarURL: contact.avatarURL,
                  ))
              .toList();

          final header = Column(
            children: [
              _buildMenuTile(
                title: atomicLocale.newFriend,
                badge: store.contactListState.friendApplicationUnreadCount > 0
                    ? store.contactListState.friendApplicationUnreadCount.toString()
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _contactListStore,
                        child: const FriendApplicationList(),
                      ),
                    ),
                  );
                },
              ),
              buildDivider(context),
              _buildMenuTile(
                title: atomicLocale.groupChatNotifications,
                badge: store.contactListState.groupApplicationUnreadCount > 0
                    ? store.contactListState.groupApplicationUnreadCount.toString()
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _contactListStore,
                        child: const GroupApplicationList(),
                      ),
                    ),
                  );
                },
              ),
              buildDivider(context),
              _buildMenuTile(
                title: atomicLocale.myGroups,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _contactListStore,
                        child: GroupList(
                          onGroupClick: widget.onGroupClick,
                        ),
                      ),
                    ),
                  );
                },
              ),
              buildDivider(context),
              _buildMenuTile(
                title: atomicLocale.blackList,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _contactListStore,
                        child: Blacklist(
                          onContactClick: widget.onContactClick,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );

          return AZOrderedList(
            dataSource: dataSource,
            header: header,
            config: AZOrderedListConfig(
              showIndexBar: true,
              emptyText: '',
              onItemClick: (item) {
                if (widget.onContactClick != null) {
                  ContactInfo contactInfo = ContactInfo(
                    contactID: item.key,
                    type: ContactType.user,
                    title: item.label,
                    avatarURL: item.avatarURL,
                  );

                  widget.onContactClick!(contactInfo);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
