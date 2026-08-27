import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../user_picker/user_picker.dart';
import 'create_group.dart';
import '../../common/language/gen/chat_localizations.dart';

class StartGroupChat extends StatefulWidget {
  final Function(String groupID, String groupName, String? avatar)? onGroupCreated;

  const StartGroupChat({
    super.key,
    this.onGroupCreated,
  });

  @override
  State<StartGroupChat> createState() => _StartGroupChatState();
}

class _StartGroupChatState extends State<StartGroupChat> {
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

  Future<void> _loadData() async {
    await _contactStore.loadFriends();
  }

  Future<void> _createGroupChat(List<UserPickerData> selectedItems) async {
    List<ContactInfo> selectedMembers = [];
    for (final item in selectedItems) {
      final contactInfo = _contactStore.state.friendList.value.firstWhere(
        (contact) => contact.userID == item.key,
        orElse: () => ContactInfo(
          userID: item.key,
          nickname: item.label,
          avatarURL: item.avatarURL,
        ),
      );
      selectedMembers.add(contactInfo);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroup(
          selectedMembers: selectedMembers,
          onGroupCreated: (groupID, groupName, avatar) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();

            if (widget.onGroupCreated != null) {
              widget.onGroupCreated!(groupID, groupName, avatar);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ContactInfo>>(
      valueListenable: _contactStore.state.friendList,
      builder: (context, friendList, child) {
        final dataSource = friendList
            .map((contact) => UserPickerData(
                  key: contact.userID,
                  label: (contact.nickname?.isNotEmpty == true ? contact.nickname! : contact.userID),
                  avatarURL: contact.avatarURL,
                ))
            .toList();

        return UserPicker(
          dataSource: dataSource,
          title: chatLocale.createGroupChat,
          showSelectedList: true,
          maxCount: 20,
          confirmText: chatLocale.next,
          onConfirm: _createGroupChat,
        );
      },
    );
  }
}
