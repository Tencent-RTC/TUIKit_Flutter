import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import '../../user_picker/user_picker.dart';

class GroupAddMember extends StatefulWidget {
  final GroupSettingStore settingStore;

  const GroupAddMember({
    super.key,
    required this.settingStore,
  });

  @override
  State<GroupAddMember> createState() => _GroupAddMemberState();
}

class _GroupAddMemberState extends State<GroupAddMember> {
  late ContactListStore _contactListStore;
  bool _isLoading = true;
  List<UserPickerData> _dataSource = [];

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _contactListStore = ContactListStore.create();
    _fetchFriendList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    _contactListStore.dispose();
    super.dispose();
  }

  Future<void> _fetchFriendList() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _contactListStore.fetchFriendList();
    if (result.errorCode == 0) {
      _dataSource = _buildDataSource();
    } else {
      debugPrint('fetchFriendList failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserPickerData> _buildDataSource() {
    final existingMemberIds = widget.settingStore.groupSettingState.allMembers.map((m) => m.userID).toSet();

    return _contactListStore.contactListState.friendList
        .map((friend) => UserPickerData(
              key: friend.contactID,
              label: friend.title ?? friend.contactID,
              avatarURL: friend.avatarURL,
              isPreSelected: existingMemberIds.contains(friend.contactID),
            ))
        .toList();
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    final userIDs = selectedItems.map((item) => item.key).toList();
    final result = await widget.settingStore.addGroupMember(userIDList: userIDs);
    if (result.errorCode != 0) {
      debugPrint('addGroupMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      if (mounted) {
        Toast.error(context, atomicLocale.addFailed);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorsTheme.listColorDefault,
        appBar: AppBar(
          backgroundColor: colorsTheme.bgColorTopBar,
          elevation: 0,
          leading: IconButton.buttonContent(
            content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
            type: ButtonType.noBorder,
            size: ButtonSize.l,
            onClick: () => Navigator.of(context).pop(),
          ),
          title: Text(
            atomicLocale.addMembers,
            style: TextStyle(
              color: colorsTheme.textColorPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: colorsTheme.textColorSecondary,
          ),
        ),
      );
    }

    return UserPicker(
      dataSource: _dataSource,
      title: atomicLocale.addMembers,
      maxCount: 20,
      onConfirm: _onConfirm,
    );
  }
}
