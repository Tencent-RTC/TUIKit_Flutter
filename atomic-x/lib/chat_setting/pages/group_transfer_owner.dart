import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../user_picker/user_picker.dart';

class GroupTransferOwner extends StatefulWidget {
  final GroupSettingStore settingStore;

  const GroupTransferOwner({
    super.key,
    required this.settingStore,
  });

  @override
  State<GroupTransferOwner> createState() => _GroupTransferOwnerState();
}

class _GroupTransferOwnerState extends State<GroupTransferOwner> {
  List<UserPickerData> _dataSource = [];
  late AtomicLocalizations atomicLocal;

  @override
  void initState() {
    super.initState();
    _initMemberList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocal = AtomicLocalizations.of(context);
  }

  void _initMemberList() {
    final selectableMembers = widget.settingStore.groupSettingState.allMembers
        .where((member) => member.role != GroupMemberRole.owner)
        .toList();

    _dataSource = selectableMembers.map((member) {
      return UserPickerData(
        key: member.userID,
        label: _getDisplayName(member),
        avatarURL: member.avatarURL,
      );
    }).toList();
  }

  String _getDisplayName(GroupMember member) {
    if (member.nameCard?.isNotEmpty == true) {
      return member.nameCard!;
    }
    if (member.nickname?.isNotEmpty == true) {
      return member.nickname!;
    }
    if (member.userID.isNotEmpty) {
      return member.userID;
    }
    return atomicLocal.unknown;
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    if (selectedItems.isEmpty) {
      return;
    }

    final selectedMember = selectedItems.first;

    final result = await widget.settingStore.changeGroupOwner(
      newOwnerID: selectedMember.key,
    );

    if (result.errorCode != 0) {
      debugPrint('changeGroupOwner failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserPicker(
      dataSource: _dataSource,
      title: atomicLocal.transferGroupOwner,
      maxCount: 1,
      onConfirm: _onConfirm,
    );
  }
}
