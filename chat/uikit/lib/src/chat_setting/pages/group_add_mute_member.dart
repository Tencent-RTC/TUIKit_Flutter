import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart';

import '../../user_picker/user_picker.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupAddMuteMember extends StatefulWidget {
  final GroupMemberStore memberStore;

  const GroupAddMuteMember({
    super.key,
    required this.memberStore,
  });

  @override
  State<GroupAddMuteMember> createState() => _GroupAddMuteMemberState();
}

class _GroupAddMuteMemberState extends State<GroupAddMuteMember> {
  List<UserPickerData> _dataSource = [];

  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    _initMemberList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  void _initMemberList() {
    final selectableMembers = widget.memberStore.state.memberList.value
        .where((member) => member.role != GroupMemberRole.owner && member.role != GroupMemberRole.admin)
        .toList();

    _dataSource = selectableMembers.map((member) {
      return UserPickerData(
        key: member.userID,
        label: UIKitUtil.memberDisplayName(member),
        avatarURL: member.avatarURL,
        isPreSelected: member.isMuted,
      );
    }).toList();
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    final userIDs = selectedItems.map((item) => item.key).toList();

    if (userIDs.isEmpty) {
      return;
    }

    for (final userID in userIDs) {
      final result = await widget.memberStore.muteMember(
        userID: userID,
        time: 60 * 60 * 24 * 7,
      );

      if (result.errorCode != 0) {
        debugPrint('muteMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
        if (mounted) {
          Toast.error(context, chatLocale.addFailed);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserPicker(
      dataSource: _dataSource,
      title: chatLocale.groupMember,
      maxCount: 20,
      onConfirm: _onConfirm,
    );
  }
}
