import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tencent_chat_uikit/src/contact_list/pages/group_application_list.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/api/group/group_store.dart' as group_api;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'pages/blacklist.dart';
import 'pages/friend_application_list.dart';
import 'pages/group_list.dart';
import 'package:tencent_chat_uikit/src/widgets/az_ordered_list.dart';
import '../common/language/gen/chat_localizations.dart';

typedef OnGroupClick = void Function(ContactInfo contactInfo);
typedef OnContactClick = void Function(ContactInfo contactInfo);

/// Entry icons match the contact avatar footprint so labels and dividers line up.
const AvatarSize _menuIconSize = azItemAvatarSize;

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
  final ContactStore _contactStore = ContactStore.shared;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);
  }

  final group_api.GroupStore _groupStore = group_api.GroupStore.shared;

  Future<void> _loadData() async {
    await Future.wait([
      _contactStore.loadFriends(),
      _contactStore.loadFriendApplications(),
      _groupStore.loadApplications(),
    ]);
  }

  Widget _buildMenuTile({
    required String assetName,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: colorsTheme.bgColorOperate,
        padding: const EdgeInsets.symmetric(
          horizontal: azItemHorizontalPadding,
          vertical: 12,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'chat_assets/icon/$assetName',
              width: _menuIconSize.value,
              height: _menuIconSize.value,
              package: 'tencent_chat_uikit',
            ),
            const SizedBox(width: azItemAvatarSpacing),
            Expanded(
              child: Text(
                title,
                style: FontScheme.body4Regular.copyWith(
                  color: colorsTheme.textColorPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorsTheme.textColorError,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: FontScheme.caption3Medium.copyWith(
                    color: colorsTheme.textColorButton,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildDivider(BuildContext context) {
    return buildAZItemDivider(BaseThemeProvider.colorsOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ContactInfo>>(
      valueListenable: _contactStore.state.friendList,
      builder: (context, friendList, _) {
        return ValueListenableBuilder<int>(
          valueListenable: _contactStore.state.friendApplicationUnreadCount,
          builder: (context, friendAppUnread, _) {
            return ValueListenableBuilder<int>(
              valueListenable: _groupStore.state.unreadApplicationCount,
              builder: (context, groupAppUnread, _) {
                final dataSource = friendList
                    .map((contact) => AZOrderedListItem(
                          key: contact.userID,
                          label: (contact.nickname?.isNotEmpty == true ? contact.nickname! : contact.userID),
                          avatarURL: contact.avatarURL,
                        ))
                    .toList();

                final header = Container(
                  color: colorsTheme.bgColorOperate,
                  child: Column(
                    children: [
                      _buildMenuTile(
                        assetName: 'new_contact.svg',
                        title: chatLocale.newFriend,
                        badge: friendAppUnread > 0 ? friendAppUnread.toString() : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FriendApplicationList(),
                            ),
                          );
                        },
                      ),
                      buildDivider(context),
                      _buildMenuTile(
                        assetName: 'group_notification.svg',
                        title: chatLocale.groupChatNotifications,
                        badge: groupAppUnread > 0 ? groupAppUnread.toString() : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GroupApplicationList(),
                            ),
                          );
                        },
                      ),
                      buildDivider(context),
                      _buildMenuTile(
                        assetName: 'joined_group.svg',
                        title: chatLocale.myGroups,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupList(
                                onGroupClick: widget.onGroupClick,
                              ),
                            ),
                          );
                        },
                      ),
                      buildDivider(context),
                      _buildMenuTile(
                        assetName: 'blacklist.svg',
                        title: chatLocale.blackList,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Blacklist(
                                onContactClick: widget.onContactClick,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
                          userID: item.key,
                          nickname: item.label,
                          avatarURL: item.avatarURL,
                        );

                        widget.onContactClick!(contactInfo);
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
