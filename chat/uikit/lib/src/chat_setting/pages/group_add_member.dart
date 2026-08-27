import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import '../../user_picker/user_picker.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupAddMember extends StatefulWidget {
  final String groupID;
  final GroupMemberStore memberStore;

  const GroupAddMember({
    super.key,
    required this.groupID,
    required this.memberStore,
  });

  @override
  State<GroupAddMember> createState() => _GroupAddMemberState();
}

class _GroupAddMemberState extends State<GroupAddMember> {
  final ContactStore _contactStore = ContactStore.shared;
  bool _isLoading = true;
  List<UserPickerData> _dataSource = [];

  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    _fetchFriendList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  Future<void> _fetchFriendList() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _contactStore.loadFriends();
    if (result.errorCode == 0) {
      _dataSource = _buildDataSource();
    } else {
      debugPrint('loadFriends failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserPickerData> _buildDataSource() {
    final existingMemberIds = widget.memberStore.state.memberList.value.map((m) => m.userID).toSet();

    return _contactStore.state.friendList.value
        .map((friend) => UserPickerData(
              key: friend.userID,
              label: (friend.nickname?.isNotEmpty == true ? friend.nickname! : friend.userID),
              avatarURL: friend.avatarURL,
              isPreSelected: existingMemberIds.contains(friend.userID),
            ))
        .toList();
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    final userIDs = selectedItems.map((item) => item.key).toList();
    final result = await widget.memberStore.addMember(userIDList: userIDs);
    if (result.errorCode != 0) {
      debugPrint('addMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      if (mounted) {
        Toast.error(context, chatLocale.addFailed);
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
            content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
            type: ButtonType.noBorder,
            size: ButtonSize.l,
            onClick: () => Navigator.of(context).pop(),
          ),
          title: Text(
            chatLocale.addMembers,
            style: FontScheme.caption1Medium.copyWith(
              color: colorsTheme.textColorPrimary,
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
      title: chatLocale.addMembers,
      maxCount: 20,
      onConfirm: _onConfirm,
    );
  }
}
