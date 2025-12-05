import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import '../../user_picker/user_picker.dart';

class GroupMemberPicker extends StatefulWidget {
  final String groupID;
  final Function(List<UserPickerData>)? onConfirm;

  const GroupMemberPicker({
    super.key,
    required this.groupID,
    this.onConfirm,
  });

  @override
  State<GroupMemberPicker> createState() => _GroupMemberPickerState();
}

class _GroupMemberPickerState extends State<GroupMemberPicker> {
  late GroupSettingStore _groupSettingStore;
  bool _isLoading = true;
  List<UserPickerData> _dataSource = [];

  late SemanticColorScheme colorsTheme;

  @override
  void initState() {
    super.initState();
    _groupSettingStore = GroupSettingStore.create(groupID: widget.groupID);
    _fetchGroupMemberList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    _groupSettingStore.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupMemberList() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _groupSettingStore.fetchGroupMemberList(role: GroupMemberRole.all);
    if (result.errorCode == 0) {
      _dataSource = _buildDataSource();
    } else {
      debugPrint('fetchGroupMemberList failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserPickerData> _buildDataSource() {
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;

    return _groupSettingStore.groupSettingState.allMembers
        .where((member) => member.userID != currentUserID)
        .map((member) => UserPickerData(
              key: member.userID,
              label: _getShowName(member),
              avatarURL: member.avatarURL,
            ))
        .toList();
  }

  String _getShowName(GroupMember groupMember) {
    if (groupMember.nameCard?.isNotEmpty == true) {
      return groupMember.nameCard!;
    }

    if (groupMember.nickname?.isNotEmpty == true) {
      return groupMember.nickname!;
    }

    return groupMember.userID;
  }

  void _onConfirm(List<UserPickerData> selectedItems) async {
    if (widget.onConfirm != null) {
      widget.onConfirm!(selectedItems);
    } else {
      if (mounted) {
        Navigator.of(context).pop(selectedItems);
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
      onConfirm: _onConfirm,
    );
  }
}
