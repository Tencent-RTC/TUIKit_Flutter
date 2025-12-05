import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton, AlertDialog;

import 'c2c_chat_setting.dart';

class GroupMemberList extends StatefulWidget {
  final GroupSettingStore settingStore;
  final OnSendMessageClick? onSendMessageClick;

  const GroupMemberList({
    super.key,
    required this.settingStore,
    this.onSendMessageClick,
  });

  @override
  State<GroupMemberList> createState() => _GroupMemberListState();
}

class _GroupMemberListState extends State<GroupMemberList> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    widget.settingStore.addListener(_onSettingStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    widget.settingStore.removeListener(_onSettingStateChanged);
    super.dispose();
  }

  void _onSettingStateChanged() {
    if (mounted) {
      setState(() {
        // Just rebuild the widget
      });
    }
  }

  bool _canDeleteMember(GroupMember member) {
    if (member.role == GroupMemberRole.owner) {
      return false;
    }

    UserProfile? userProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = userProfile?.userID ?? '';
    if (member.userID == currentUserID) {
      return false;
    }

    if (widget.settingStore.groupSettingState.currentUserRole == GroupMemberRole.owner) {
      return true;
    }

    if (widget.settingStore.groupSettingState.currentUserRole == GroupMemberRole.admin &&
        member.role == GroupMemberRole.member) {
      return true;
    }

    return false;
  }

  bool _canSetAdmin(GroupMember member) {
    if (widget.settingStore.groupSettingState.currentUserRole != GroupMemberRole.owner) {
      return false;
    }

    if (member.role == GroupMemberRole.owner) {
      return false;
    }

    UserProfile? userProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = userProfile?.userID ?? '';
    if (member.userID == currentUserID) {
      return false;
    }

    return true;
  }

  void _onMemberTap(GroupMember member) {
    UserProfile? uerProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = uerProfile?.userID ?? '';
    if (member.userID == currentUserID) {
      return;
    }

    _showMemberActionSheet(member);
  }

  void _showMemberActionSheet(GroupMember member) {
    List<ActionSheetItem> actions = [];

    actions.add(
      ActionSheetItem(
        title: atomicLocale.detail,
        onTap: () => _showMemberInfo(member),
      ),
    );

    if (_canSetAdmin(member)) {
      final isAdmin = member.role == GroupMemberRole.admin;
      actions.add(
        ActionSheetItem(
          title: isAdmin ? atomicLocale.cancelAdmin : atomicLocale.setAdmin,
          onTap: () => _setMemberRole(member, isAdmin ? GroupMemberRole.member : GroupMemberRole.admin),
        ),
      );
    }

    if (_canDeleteMember(member)) {
      actions.add(
        ActionSheetItem(
          title: atomicLocale.delete,
          isDestructive: true,
          onTap: () => _showDeleteConfirmDialog(member),
        ),
      );
    }

    ActionSheet.show(
      context,
      actions: actions,
    );
  }

  void _showMemberInfo(GroupMember member) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => C2CChatSetting(
          userID: member.userID,
          onSendMessageClick: widget.onSendMessageClick,
        ),
      ),
    );
  }

  Future<void> _setMemberRole(GroupMember member, GroupMemberRole newRole) async {
    final result = await widget.settingStore.setGroupMemberRole(
      userID: member.userID,
      role: newRole,
    );

    if (result.errorCode == 0) {
      _showToast(atomicLocale.settingSuccess);
    } else {
      debugPrint('setGroupMemberRole failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  Future<void> _deleteMember(GroupMember member) async {
    final result = await widget.settingStore.deleteGroupMember(
      members: [member],
    );

    if (result.errorCode != 0) {
      debugPrint('deleteGroupMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  void _showDeleteConfirmDialog(GroupMember member) {
    AlertDialog.show(
      context,
      title: atomicLocale.delete,
      content: atomicLocale.deleteGroupMemberTip,
      isDestructive: true,
      onConfirm: () => _deleteMember(member),
    );
  }

  void _showToast(String message) {
    if (mounted) {
      Toast.info(context, message);
    }
  }

  Widget _buildNameAccessory(BuildContext context, GroupMember member) {
    if (member.role != GroupMemberRole.owner && member.role != GroupMemberRole.admin) {
      return const SizedBox.shrink();
    }
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorBubbleOwn,
        border: Border.all(color: colorsTheme.buttonColorPrimaryDefault),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        member.role == GroupMemberRole.owner ? atomicLocale.groupOwner : atomicLocale.admin,
        style: TextStyle(
          color: colorsTheme.buttonColorPrimaryHover,
          fontSize: 10,
        ),
      ),
    );
  }

  String _getMemberDisplayName(GroupMember member) {
    if (member.nameCard?.isNotEmpty == true) {
      return member.nameCard!;
    }

    if (member.nickname?.isNotEmpty == true) {
      return member.nickname!;
    }

    if (member.userID.isNotEmpty) {
      return member.userID;
    }

    return atomicLocale.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = widget.settingStore.groupSettingState.allMembers.map((member) {
      return AZOrderedListItem(
        key: member.userID,
        label: _getMemberDisplayName(member),
        avatarURL: member.avatarURL,
        extraData: member,
        nameAccessoryBuilder: (context) => _buildNameAccessory(context, member),
      );
    }).toList();

    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorTopBar,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${atomicLocale.groupMember}(${widget.settingStore.groupSettingState.memberCount})',
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: AZOrderedList(
        dataSource: dataSource,
        config: AZOrderedListConfig(
          onItemClick: (item) {
            final member = widget.settingStore.groupSettingState.allMembers.firstWhere((m) => m.userID == item.key);
            _onMemberTap(member);
          },
        ),
      ),
    );
  }
}
