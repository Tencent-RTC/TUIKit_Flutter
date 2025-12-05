import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../user_picker/user_picker.dart';
import 'create_group.dart';

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
    await _contactListStore.fetchFriendList();
  }

  Future<void> _createGroupChat(List<UserPickerData> selectedItems) async {
    List<ContactInfo> selectedMembers = [];
    for (final item in selectedItems) {
      final contactInfo = _contactListStore.contactListState.friendList.firstWhere(
        (contact) => contact.contactID == item.key,
        orElse: () => ContactInfo(
          contactID: item.key,
          type: ContactType.user,
          title: item.label,
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
    return ChangeNotifierProvider.value(
      value: _contactListStore,
      child: Consumer<ContactListStore>(
        builder: (context, store, child) {
          final dataSource = store.contactListState.friendList
              .map((contact) => UserPickerData(
                    key: contact.contactID,
                    label: contact.title ?? contact.contactID,
                    avatarURL: contact.avatarURL,
                  ))
              .toList();

          return UserPicker(
            dataSource: dataSource,
            title: atomicLocale.createGroupChat,
            showSelectedList: true,
            maxCount: 20,
            confirmText: atomicLocale.next,
            onConfirm: _createGroupChat,
          );
        },
      ),
    );
  }
}
