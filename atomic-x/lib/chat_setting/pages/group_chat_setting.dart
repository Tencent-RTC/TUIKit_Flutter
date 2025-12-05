import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter_svg/svg.dart';

import '../widgets/setting_widgets.dart';
import 'c2c_chat_setting.dart';
import 'choose_group_avatar.dart';
import 'group_add_member.dart';
import 'group_management.dart';
import 'group_member_list.dart';
import 'group_notice.dart';
import 'group_permission_manager.dart';
import 'group_transfer_owner.dart';

enum GroupMethodType {
  join,
  invite,
}

class MethodSheetConfig {
  final String forbidText;
  final String authText;
  final String anyText;

  MethodSheetConfig({
    required this.forbidText,
    required this.authText,
    required this.anyText,
  });
}

class GroupChatSetting extends StatefulWidget {
  final String groupID;
  final VoidCallback? onGroupDelete;
  final OnSendMessageClick? onSendMessageClick;

  const GroupChatSetting({
    super.key,
    required this.groupID,
    this.onGroupDelete,
    this.onSendMessageClick,
  });

  @override
  State<GroupChatSetting> createState() => _GroupChatSettingState();
}

class _GroupChatSettingState extends State<GroupChatSetting> {
  late GroupSettingStore settingStore;
  late ConversationListStore conversationListStore;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;
  late String conversationID;

  @override
  void initState() {
    super.initState();
    conversationID = groupConversationIDPrefix + widget.groupID;
    settingStore = GroupSettingStore.create(groupID: widget.groupID);
    settingStore.fetchGroupInfo();
    settingStore.fetchGroupMemberList(role: GroupMemberRole.all);
    settingStore.fetchSelfMemberInfo();
    conversationListStore = ConversationListStore.create();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    settingStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: atomicLocale.groupDetail,
      ),
      body: ListenableBuilder(
        listenable: settingStore,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildGroupProfile(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildBasicSettings(),
                const SizedBox(height: 24),
                _buildGroupSettings(),
                const SizedBox(height: 24),
                _buildGroupRemark(),
                // const SizedBox(height: 24),
                // _buildBackground(),
                const SizedBox(height: 24),
                _buildGroupMembers(),
                const SizedBox(height: 24),
                _buildDangerousActions(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupProfile() {
    return Column(
      children: [
        GestureDetector(
          onTap: _hasPermission(GroupPermission.setGroupAvatar) ? _onAvatarTap : null,
          child: Avatar(
            content: AvatarImageContent(
                url: settingStore.groupSettingState.avatarURL, name: settingStore.groupSettingState.groupName),
            size: AvatarSize.xl,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              settingStore.groupSettingState.groupName.isNotEmpty
                  ? settingStore.groupSettingState.groupName
                  : settingStore.groupID,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorsTheme.textColorPrimary,
              ),
            ),
            if (_hasPermission(GroupPermission.setGroupName)) const SizedBox(width: 8),
            if (_hasPermission(GroupPermission.setGroupName))
              GestureDetector(
                onTap: () {
                  _showGroupNameEditDialog();
                },
                child: SvgPicture.asset(
                  'chat_assets/icon/name_edit.svg',
                  package: 'tuikit_atomic_x',
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ID: ${settingStore.groupID}',
          style: TextStyle(
            fontSize: 12,
            color: colorsTheme.textColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    List<Widget> buttons = [];

    if (_hasPermission(GroupPermission.sendMessage)) {
      buttons.add(_buildActionButton(
        icon: Icons.message,
        label: atomicLocale.sendMessage,
        onTap: () {
          _navigateToMessageList();
        },
      ));
    }

    // buttons.addAll([
    //   _buildActionButton(
    //     icon: Icons.call,
    //     label: 'Audio',
    //     onTap: _onAudioCall,
    //   ),
    //   _buildActionButton(
    //     icon: Icons.videocam,
    //     label: 'Video',
    //     onTap: _onVideoCall,
    //   ),
    // ]);

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colorsTheme.listColorHover,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorsTheme.bgColorOperate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colorsTheme.buttonColorPrimaryDefault,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings() {
    List<Widget> settings = [];

    if (_hasPermission(GroupPermission.setDoNotDisturb)) {
      settings.add(SettingWidgets.buildSettingRow(
        context: context,
        title: atomicLocale.doNotDisturb,
        value: settingStore.groupSettingState.isNotDisturb,
        onChanged: (value) async {
          final result = await conversationListStore.muteConversation(conversationID: conversationID, mute: value);
          if (result.errorCode != 0) {
            print('setDoNotDisturb failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
          }
        },
      ));
    }

    if (_hasPermission(GroupPermission.pinGroup)) {
      if (settings.isNotEmpty) settings.add(SettingWidgets.buildDivider(context));
      settings.add(SettingWidgets.buildSettingRow(
        context: context,
        title: atomicLocale.pin,
        value: settingStore.groupSettingState.isPinned,
        onChanged: (value) async {
          final result = await conversationListStore.pinConversation(conversationID: conversationID, pin: value);
          if (result.errorCode != 0) {
            debugPrint('pin failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
          }
        },
      ));
    }

    if (settings.isEmpty) return const SizedBox.shrink();

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: settings,
    );
  }

  Widget _buildGroupSettings() {
    List<Widget> settings = [];

    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: atomicLocale.groupOfAnnouncement,
      subtitle: settingStore.groupSettingState.notice.isNotEmpty
          ? settingStore.groupSettingState.notice
          : atomicLocale.groupNoticeEmpty,
      onTap: () => _onGroupNotice(),
    ));

    if (_hasPermission(GroupPermission.setGroupManagement)) {
      settings.add(SettingWidgets.buildDivider(context));
      settings.add(SettingWidgets.buildNavigationRow(
        context: context,
        title: atomicLocale.groupManagement,
        onTap: () => _onGroupManagement(),
      ));
    }

    if (_hasPermission(GroupPermission.getGroupType)) {
      settings.add(SettingWidgets.buildDivider(context));
      settings.add(SettingWidgets.buildInfoRow(
        context: context,
        title: atomicLocale.groupType,
        value: GroupPermissionManager.getGroupTypeDescription(settingStore.groupSettingState.groupType, context),
      ));
    }

    settings.add(SettingWidgets.buildDivider(context));
    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: atomicLocale.addGroupWay,
      value: _getJoinOptionText(settingStore.groupSettingState.joinGroupApprovalType),
      onTap: _hasPermission(GroupPermission.setJoinGroupApprovalType) ? () => _onJoinGroupMethod() : null,
    ));

    settings.add(SettingWidgets.buildDivider(context));
    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: atomicLocale.inviteGroupType,
      value: _getInviteOptionText(settingStore.groupSettingState.inviteToGroupApprovalType),
      onTap: _hasPermission(GroupPermission.setInviteToGroupApprovalType) ? () => _onInviteMethod() : null,
    ));

    if (settings.isEmpty) return const SizedBox.shrink();

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: settings,
    );
  }

  Widget _buildGroupRemark() {
    if (!_hasPermission(GroupPermission.setGroupRemark)) {
      return const SizedBox.shrink();
    }

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildNavigationRow(
          context: context,
          title: atomicLocale.myAliasInGroup,
          value: settingStore.groupSettingState.selfNameCard,
          onTap: () => _onGroupRemark(),
        ),
      ],
    );
  }

  Widget _buildGroupMembers() {
    List<Widget> memberWidgets = [];

    memberWidgets.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: '${atomicLocale.groupMember} (${settingStore.groupSettingState.memberCount})',
      onTap: _hasPermission(GroupPermission.getGroupMemberList) ? () => _onGroupMemberList() : null,
    ));

    if (_hasPermission(GroupPermission.addGroupMember) &&
        settingStore.groupSettingState.inviteToGroupApprovalType != GroupJoinOption.forbid) {
      memberWidgets.add(SettingWidgets.buildDivider(context));
      memberWidgets.add(SettingWidgets.buildActionRow(
        context: context,
        icon: Icons.add,
        title: atomicLocale.addMembers,
        onTap: () => _onAddMembers(),
      ));
    }

    final displayMembers = settingStore.groupSettingState.allMembers.take(3).toList();
    for (int i = 0; i < displayMembers.length; i++) {
      memberWidgets.add(SettingWidgets.buildDivider(context));
      memberWidgets.add(_buildMemberRow(displayMembers[i]));
    }

    if (memberWidgets.isEmpty) return const SizedBox.shrink();

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: memberWidgets,
    );
  }

  Widget _buildDangerousActions() {
    List<Widget> actions = [];

    if (_hasPermission(GroupPermission.clearHistoryMessages)) {
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: atomicLocale.clearMessage,
        onTap: () => _onClearHistory(),
      ));
    }

    if (_hasPermission(GroupPermission.deleteAndQuit)) {
      if (actions.isNotEmpty) actions.add(SettingWidgets.buildDivider(context));
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: atomicLocale.quitGroup,
        onTap: () => _onDeleteAndQuit(),
      ));
    }

    if (_hasPermission(GroupPermission.transferOwner)) {
      if (actions.isNotEmpty) actions.add(SettingWidgets.buildDivider(context));
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: atomicLocale.transferGroupOwner,
        onTap: () => _onTransferOwner(),
      ));
    }

    if (_hasPermission(GroupPermission.dismissGroup)) {
      if (actions.isNotEmpty) actions.add(SettingWidgets.buildDivider(context));
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: atomicLocale.dismissGroup,
        onTap: () => _onDismissGroup(),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: actions,
    );
  }

  Widget _buildMemberRow(GroupMember member) {
    return GestureDetector(
      onTap: _hasPermission(GroupPermission.getGroupMemberInfo) ? () => _onMemberInfo(member) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                image: member.avatarURL?.isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(member.avatarURL!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: member.avatarURL?.isEmpty != false ? colorsTheme.listColorHover : null,
              ),
              child: member.avatarURL?.isEmpty != false
                  ? Center(
                      child: Text(
                        _getMemberDisplayName(member).isNotEmpty ? _getMemberDisplayName(member)[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorsTheme.textColorPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMemberDisplayName(member),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (member.role != GroupMemberRole.member)
              Text(
                GroupPermissionManager.getMemberRoleDescription(member.role, context),
                style: TextStyle(
                  fontSize: 16,
                  color: colorsTheme.textColorSecondary,
                ),
              ),
            if (_hasPermission(GroupPermission.getGroupMemberInfo)) const SizedBox(width: 8),
            if (_hasPermission(GroupPermission.getGroupMemberInfo))
              SvgPicture.asset(
                'chat_assets/icon/chevron_right.svg',
                package: 'tuikit_atomic_x',
                width: 12,
                height: 24,
                colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasPermission(GroupPermission permission) {
    return GroupPermissionManager.hasPermission(
      groupType: settingStore.groupSettingState.groupType,
      memberRole: settingStore.groupSettingState.currentUserRole,
      permission: permission,
    );
  }

  void _onAvatarTap() {
    _pickAvatar();
  }

  void _pickAvatar() async {
    final result = await Navigator.push<String>(
        context,
        MaterialPageRoute<String>(
            builder: (context) => ChooseGroupAvatar(
                groupID: widget.groupID,
                groupType: settingStore.groupSettingState.groupType.toString(),
                selectedAvatarURL: settingStore.groupSettingState.avatarURL)));
    if (result != null && result.isNotEmpty) {
      final updateResult = await settingStore.updateGroupProfile(avatar: result);
      if (updateResult.errorCode != 0) {
        print(
            'updateGroupProfile failed, errorCode:${updateResult.errorCode}, errorMessage:${updateResult.errorMessage}');
      }
    }
  }

  void _onGroupNotice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupNotice(
          settingStore: settingStore,
        ),
      ),
    );
  }

  void _onGroupManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupManagement(
          settingStore: settingStore,
        ),
      ),
    );
  }

  void _onJoinGroupMethod() {
    _showGroupMethodSheet(
      type: GroupMethodType.join,
      onSelected: (option) => _setJoinGroupMethod(option),
    );
  }

  void _onInviteMethod() {
    _showGroupMethodSheet(
      type: GroupMethodType.invite,
      onSelected: (option) => _setInviteMethod(option),
    );
  }

  void _onGroupRemark() {
    _showGroupRemarkEditDialog();
  }

  void _showGroupMethodSheet({
    required GroupMethodType type,
    required void Function(GroupJoinOption) onSelected,
  }) {
    final config = _getMethodSheetConfig(type);

    ActionSheet.show(
      context,
      actions: [
        ActionSheetItem(
          title: config.forbidText,
          onTap: () => onSelected(GroupJoinOption.forbid),
        ),
        ActionSheetItem(
          title: config.authText,
          onTap: () => onSelected(GroupJoinOption.auth),
        ),
        ActionSheetItem(
          title: config.anyText,
          onTap: () => onSelected(GroupJoinOption.any),
        ),
      ],
    );
  }

  MethodSheetConfig _getMethodSheetConfig(GroupMethodType type) {
    switch (type) {
      case GroupMethodType.join:
        return MethodSheetConfig(
          forbidText: atomicLocale.groupAddForbid,
          authText: atomicLocale.groupAddAuth,
          anyText: atomicLocale.groupAddAny,
        );
      case GroupMethodType.invite:
        return MethodSheetConfig(
          forbidText: atomicLocale.groupInviteForbid,
          authText: atomicLocale.groupAddAuth,
          anyText: atomicLocale.groupAddAny,
        );
    }
  }

  void _setJoinGroupMethod(GroupJoinOption option) {
    settingStore.setGroupJoinOption(option: option).then((result) {
      if (result.errorCode != 0) {
        debugPrint('_setJoinGroupMethod failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      }
    });
  }

  void _setInviteMethod(GroupJoinOption option) {
    settingStore.setGroupInviteOption(option: option).then((result) {
      if (result.errorCode != 0) {
        debugPrint('_setInviteMethod failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      }
    });
  }

  void _showGroupRemarkEditDialog() async {
    final result = await BottomInputSheet.show(
      context,
      title: atomicLocale.modifyGroupNickname,
      hintText: '',
      initialText: settingStore.groupSettingState.selfNameCard,
    );

    if (result != null) {
      final updateResult = await settingStore.setSelfGroupNameCard(nameCard: result);
      if (updateResult.errorCode != 0) {
        debugPrint(
            'setSelfGroupNameCard failed, errorCode:${updateResult.errorCode}, errorMessage:${updateResult.errorMessage}');
      }
    }
  }

  void _onGroupMemberList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupMemberList(
          settingStore: settingStore,
          onSendMessageClick: widget.onSendMessageClick,
        ),
      ),
    );
  }

  void _onAddMembers() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupAddMember(
          settingStore: settingStore,
        ),
      ),
    );
  }

  void _onMemberInfo(GroupMember member) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => C2CChatSetting(
          userID: member.userID,
          onSendMessageClick: widget.onSendMessageClick,
        ),
      ),
    );
  }

  void _onClearHistory() {
    _showConfirmDialog(
      title: atomicLocale.clearMessage,
      content: atomicLocale.clearMsgTip,
      onConfirm: () async {
        final result = await conversationListStore.clearConversationMessages(conversationID: conversationID);
        if (result.errorCode != 0) {
          debugPrint('clearHistoryMessage failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
        }
      },
    );
  }

  void _onDeleteAndQuit() {
    _showConfirmDialog(
      title: atomicLocale.quitGroup,
      content: atomicLocale.quitGroupTip,
      onConfirm: () async {
        final result = await settingStore.quitGroup();
        if (result.errorCode == 0) {
          conversationListStore.deleteConversation(conversationID: conversationID);
          if (mounted) {
            Navigator.of(context).pop();
          }

          if (widget.onGroupDelete != null) {
            widget.onGroupDelete!();
          }
        } else {
          debugPrint('quitGroup failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
        }
      },
    );
  }

  void _onTransferOwner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupTransferOwner(
          settingStore: settingStore,
        ),
      ),
    );
  }

  void _onDismissGroup() {
    _showConfirmDialog(
      title: atomicLocale.dismissGroup,
      content: atomicLocale.dismissGroupTip,
      onConfirm: () async {
        final result = await settingStore.dismissGroup();
        if (result.errorCode == 0) {
          conversationListStore.deleteConversation(conversationID: conversationID);
          if (mounted) {
            Navigator.of(context).pop();
          }

          if (widget.onGroupDelete != null) {
            widget.onGroupDelete!();
          }
        } else {
          debugPrint('dismissGroup failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
        }
      },
    );
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    AlertDialog.show(
      context,
      title: title,
      content: content,
      isDestructive: true,
      onConfirm: onConfirm,
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

  String _getJoinOptionText(GroupJoinOption joinOption) {
    switch (joinOption) {
      case GroupJoinOption.forbid:
        return atomicLocale.groupAddForbid;
      case GroupJoinOption.auth:
        return atomicLocale.groupAddAuth;
      case GroupJoinOption.any:
        return atomicLocale.groupAddAny;
    }
  }

  String _getInviteOptionText(GroupJoinOption inviteOption) {
    switch (inviteOption) {
      case GroupJoinOption.forbid:
        return atomicLocale.groupInviteForbid;
      case GroupJoinOption.auth:
        return atomicLocale.groupAddAuth;
      case GroupJoinOption.any:
        return atomicLocale.groupAddAny;
    }
  }

  String _buildGroupConversationID(String groupID) {
    return 'group_$groupID';
  }

  void _showGroupNameEditDialog() async {
    final result = await BottomInputSheet.show(
      context,
      title: atomicLocale.modifyGroupName,
      hintText: '',
      initialText: settingStore.groupSettingState.groupName,
    );

    if (result != null) {
      final updateResult = await settingStore.updateGroupProfile(name: result);
      if (updateResult.errorCode != 0) {
        debugPrint(
            'updateGroupProfile failed, errorCode:${updateResult.errorCode}, errorMessage:${updateResult.errorMessage}');
      }
    }
  }

  void _navigateToMessageList() {
    if (widget.onSendMessageClick != null) {
      widget.onSendMessageClick!(groupID: widget.groupID);
    }
  }
}
