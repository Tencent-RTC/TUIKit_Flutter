import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../user_picker/user_picker.dart';

class GroupAddMuteMember extends StatefulWidget {
  final GroupSettingStore settingStore;

  const GroupAddMuteMember({
    super.key,
    required this.settingStore,
  });

  @override
  State<GroupAddMuteMember> createState() => _GroupAddMuteMemberState();
}

class _GroupAddMuteMemberState extends State<GroupAddMuteMember> {
  List<UserPickerData> _dataSource = [];

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _initMemberList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  void _initMemberList() {
    final selectableMembers = widget.settingStore.groupSettingState.allMembers
        .where((member) => member.role != GroupMemberRole.owner && member.role != GroupMemberRole.admin)
        .toList();

    _dataSource = selectableMembers.map((member) {
      return UserPickerData(
        key: member.userID,
        label: _getMemberDisplayName(member),
        avatarURL: member.avatarURL,
        isPreSelected: member.isMuted,
      );
    }).toList();
  }

  String _getMemberDisplayName(GroupMember member) {
    if (member.nameCard?.isNotEmpty == true) {
      return member.nameCard!;
    }
    if (member.nickname?.isNotEmpty == true) {
      return member.nickname!;
    }
    return member.userID;
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    final userIDs = selectedItems.map((item) => item.key).toList();

    if (userIDs.isEmpty) {
      return;
    }

    for (final userID in userIDs) {
      final result = await widget.settingStore.setGroupMemberMuteTime(
        userID: userID,
        time: 60 * 60 * 24 * 7,
      );

      if (result.errorCode != 0) {
        debugPrint('setGroupMemberMuteTime failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
        if (mounted) {
          Toast.error(context, atomicLocale.addFailed);
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
      title: atomicLocale.groupMember,
      maxCount: 20,
      onConfirm: _onConfirm,
    );
  }
}
