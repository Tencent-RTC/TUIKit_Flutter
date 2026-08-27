import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart' hide IconButton, AlertDialog;

import 'c2c_chat_setting.dart';
import 'package:tencent_chat_uikit/src/widgets/az_ordered_list.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupMemberList extends StatefulWidget {
  final String groupID;
  final GroupMemberStore memberStore;
  final GroupInfo groupInfo;
  final GroupMemberRole currentUserRole;
  final OnSendMessageClick? onSendMessageClick;

  const GroupMemberList({
    super.key,
    required this.groupID,
    required this.memberStore,
    required this.groupInfo,
    required this.currentUserRole,
    this.onSendMessageClick,
  });

  @override
  State<GroupMemberList> createState() => _GroupMemberListState();
}

class _GroupMemberListState extends State<GroupMemberList> {
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  bool _canDeleteMember(GroupMember member) {
    if (member.role == GroupMemberRole.owner) return false;

    UserProfile? userProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = userProfile?.userID ?? '';
    if (member.userID == currentUserID) return false;

    if (widget.currentUserRole == GroupMemberRole.owner) return true;

    if (widget.currentUserRole == GroupMemberRole.admin &&
        member.role == GroupMemberRole.member) {
      return true;
    }

    return false;
  }

  bool _canSetAdmin(GroupMember member) {
    final groupType = widget.groupInfo.groupType ?? GroupType.work;
    if (groupType == GroupType.work) return false;

    if (widget.currentUserRole != GroupMemberRole.owner) return false;

    if (member.role == GroupMemberRole.owner) return false;

    UserProfile? userProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = userProfile?.userID ?? '';
    if (member.userID == currentUserID) return false;

    return true;
  }

  void _onMemberTap(GroupMember member) {
    UserProfile? userProfile = LoginStore.shared.loginState.loginUserInfo;
    String currentUserID = userProfile?.userID ?? '';
    if (member.userID == currentUserID) return;

    _showMemberActionSheet(member);
  }

  void _showMemberActionSheet(GroupMember member) {
    List<ActionSheetItem> actions = [];

    actions.add(
      ActionSheetItem(
        title: chatLocale.detail,
        onTap: () => _showMemberInfo(member),
      ),
    );

    if (_canSetAdmin(member)) {
      final isAdmin = member.role == GroupMemberRole.admin;
      actions.add(
        ActionSheetItem(
          title: isAdmin ? chatLocale.cancelAdmin : chatLocale.setAdmin,
          onTap: () => _setMemberRole(member, isAdmin ? GroupMemberRole.member : GroupMemberRole.admin),
        ),
      );
    }

    if (_canDeleteMember(member)) {
      actions.add(
        ActionSheetItem(
          title: chatLocale.delete,
          isDestructive: true,
          onTap: () => _showDeleteConfirmDialog(member),
        ),
      );
    }

    ActionSheet.show(context, actions: actions);
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
    final result = await widget.memberStore.setMemberRole(
      userID: member.userID,
      role: newRole,
    );

    if (result.errorCode == 0) {
      _showToast(chatLocale.settingSuccess);
    } else {
      debugPrint('setMemberRole failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  Future<void> _deleteMember(GroupMember member) async {
    final result = await widget.memberStore.deleteMember(userIDList: [member.userID]);

    if (result.errorCode != 0) {
      debugPrint('deleteMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  void _showDeleteConfirmDialog(GroupMember member) {
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        title: chatLocale.delete,
        content: chatLocale.deleteGroupMemberTip,
        cancelConfig: ButtonConfig(text: chatLocale.cancel),
        confirmConfig: ButtonConfig(
          text: chatLocale.confirm,
          type: TextColorPreset.red,
          onClick: () => _deleteMember(member),
        ),
      ),
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
        member.role == GroupMemberRole.owner ? chatLocale.groupOwner : chatLocale.admin,
        style: FontScheme.caption4Regular.copyWith(
          color: colorsTheme.buttonColorPrimaryHover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorTopBar,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${chatLocale.groupMember}(${widget.groupInfo.memberCount ?? 0})',
          style: FontScheme.caption1Medium.copyWith(
            color: colorsTheme.textColorPrimary,
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
      body: ValueListenableBuilder<List<GroupMember>>(
        valueListenable: widget.memberStore.state.memberList,
        builder: (context, members, child) {
          final dataSource = members.map((member) {
            return AZOrderedListItem(
              key: member.userID,
              label: UIKitUtil.memberDisplayName(member),
              avatarURL: member.avatarURL,
              extraData: member,
              nameAccessoryBuilder: (context) => _buildNameAccessory(context, member),
            );
          }).toList();

          return AZOrderedList(
            dataSource: dataSource,
            config: AZOrderedListConfig(
              onItemClick: (item) {
                final member = members.firstWhere((m) => m.userID == item.key);
                _onMemberTap(member);
              },
            ),
          );
        },
      ),
    );
  }
}
