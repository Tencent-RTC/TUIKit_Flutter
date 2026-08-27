import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart';

import '../../user_picker/user_picker.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupTransferOwner extends StatefulWidget {
  final String groupID;
  final GroupMemberStore memberStore;

  const GroupTransferOwner({
    super.key,
    required this.groupID,
    required this.memberStore,
  });

  @override
  State<GroupTransferOwner> createState() => _GroupTransferOwnerState();
}

class _GroupTransferOwnerState extends State<GroupTransferOwner> {
  List<UserPickerData> _dataSource = [];
  late ChatLocalizations chatLocal;

  @override
  void initState() {
    super.initState();
    _initMemberList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocal = ChatLocalizations.of(context);
  }

  void _initMemberList() {
    final selectableMembers = widget.memberStore.state.memberList.value
        .where((member) => member.role != GroupMemberRole.owner)
        .toList();

    _dataSource = selectableMembers.map((member) {
      return UserPickerData(
        key: member.userID,
        label: UIKitUtil.memberDisplayName(member),
        avatarURL: member.avatarURL,
      );
    }).toList();
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    if (selectedItems.isEmpty) {
      return;
    }

    final selectedMember = selectedItems.first;

    final result = await GroupStore.shared.changeOwner(
      groupID: widget.groupID,
      newOwnerID: selectedMember.key,
    );

    if (!mounted) return;

    if (result.errorCode == 0) {
      Toast.success(context, chatLocal.settingSuccess, useRootOverlay: true);
    } else {
      debugPrint(
          'changeOwner failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      final errMsg = result.errorMessage?.trim();
      final fullMsg = (errMsg == null || errMsg.isEmpty)
          ? chatLocal.settingFail
          : '${chatLocal.settingFail} $errMsg';
      Toast.error(context, fullMsg, useRootOverlay: true);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return UserPicker(
      dataSource: _dataSource,
      title: chatLocal.transferGroupOwner,
      maxCount: 1,
      onConfirm: _onConfirm,
    );
  }
}
