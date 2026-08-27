import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter_svg/svg.dart';

import '../widgets/chat_background_picker.dart';
import '../widgets/setting_widgets.dart';
import '../../common/utils/chat_background_store.dart';
import 'c2c_chat_setting.dart';
import 'choose_group_avatar.dart';
import 'group_add_member.dart';
import 'group_management.dart';
import 'group_member_list.dart';
import 'group_member_picker.dart';
import 'group_notice.dart';
import 'group_permission_manager.dart';
import 'group_transfer_owner.dart';
import '../../user_picker/user_picker.dart';
import '../../common/language/gen/chat_localizations.dart';

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
  late GroupMemberStore _memberStore;
  late ConversationListStore _conversationListStore;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;
  late String conversationID;

  GroupInfo? _groupInfo;
  bool _isNotDisturb = false;
  bool _isPinned = false;
  String _selfNameCard = '';
  GroupMemberRole _currentUserRole = GroupMemberRole.member;
  String? _chatBackgroundImageUri;

  /// True while we're driving an explicit quit / dismiss flow from this page.
  ///
  /// `quitGroup` / `dismissGroup` succeed synchronously and the SDK
  /// immediately mutates `joinedGroupList`, which fires
  /// `_onJoinedGroupListChanged` while `await` is still bouncing back
  /// to `_onDeleteAndQuit` / `_onDismissGroup`. Both code paths then
  /// race to pop ChatSettingPage + ChatPage, ending up popping 4
  /// routes off a 3-route stack and emptying the navigator (black
  /// screen). Set this true before `await`, clear it on failure, and
  /// let the listener short-circuit when it's true — the explicit
  /// flow owns the navigation. External "kicked out / group
  /// dismissed elsewhere" still goes through the listener as before.
  bool _isHandlingPopExplicitly = false;

  @override
  void initState() {
    super.initState();
    conversationID = groupConversationIDPrefix + widget.groupID;
    _memberStore = GroupMemberStore.create(groupID: widget.groupID);
    _conversationListStore = ConversationListStore.create();
    GroupStore.shared.state.joinedGroupList.addListener(_onJoinedGroupListChanged);
    _loadData();
    _loadChatBackground();
  }

  Future<void> _loadChatBackground() async {
    final imageUri = await ChatBackgroundStore.shared.load(conversationID);
    if (!mounted) return;
    setState(() => _chatBackgroundImageUri = imageUri);
  }

  Future<void> _onChatBackgroundTap() async {
    final changed = await ChatBackgroundPicker.show(context, conversationID: conversationID);
    if (!changed || !mounted) return;
    setState(() => _chatBackgroundImageUri = ChatBackgroundStore.shared.peek(conversationID));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);
  }

  @override
  void dispose() {
    GroupStore.shared.state.joinedGroupList.removeListener(_onJoinedGroupListChanged);
    super.dispose();
  }

  /// React to changes in the global joinedGroupList. Two cases:
  ///   1. Group still present → sync _groupInfo + _currentUserRole so that
  ///      _hasPermission() recomputes against the latest selfRole.
  ///   2. Group removed (only after we've already loaded once) → it has been
  ///      dismissed / we were kicked / we quit elsewhere. Pop this page.
  void _onJoinedGroupListChanged() {
    if (!mounted) return;
    final list = GroupStore.shared.state.joinedGroupList.value;
    GroupInfo? updated;
    for (final g in list) {
      if (g.groupID == widget.groupID) {
        updated = g;
        break;
      }
    }
    if (updated == null) {
      // Skip the auto-pop when our own quit/dismiss handler is already
      // unwinding the stack — see `_isHandlingPopExplicitly`. Without
      // this guard the explicit flow and this listener both pop twice
      // and we drain the navigator empty.
      if (_groupInfo != null && !_isHandlingPopExplicitly) {
        widget.onGroupDelete?.call();
        Navigator.of(context).maybePop();
      }
      return;
    }
    setState(() {
      _groupInfo = updated;
      if (updated?.selfRole != null) {
        _currentUserRole = updated!.selfRole!;
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadGroupInfo(),
      _loadMembers(),
      _loadSelfMemberInfo(),
      _loadConversationInfo(),
    ]);
  }

  Future<void> _loadGroupInfo() async {
    final result = await GroupStore.shared.getGroupInfo(groupID: widget.groupID);
    if (result.isSuccess && result.groupInfo != null && mounted) {
      setState(() {
        _groupInfo = result.groupInfo;
      });
    }
  }

  Future<void> _loadMembers() async {
    await _memberStore.loadMembers();
  }

  Future<void> _loadSelfMemberInfo() async {
    final result = await _memberStore.getMemberInfo(
      userIDList: [LoginStore.shared.loginState.loginUserInfo?.userID ?? ''],
    );
    if (result.isSuccess && result.memberInfoList.isNotEmpty && mounted) {
      final selfMember = result.memberInfoList.first;
      setState(() {
        _selfNameCard = selfMember.nameCard ?? '';
        _currentUserRole = selfMember.role;
      });
    }
  }

  Future<void> _loadConversationInfo() async {
    final result = await _conversationListStore.getConversationInfo(conversationID: conversationID);
    if (result.isSuccess && result.conversationInfo != null && mounted) {
      final conv = result.conversationInfo!;
      setState(() {
        _isPinned = conv.isPinned;
        _isNotDisturb = conv.receiveOption != ReceiveMessageOption.receive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorInput,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: chatLocale.groupDetail,
      ),
      body: _groupInfo == null
          ? Center(child: CircularProgressIndicator(color: colorsTheme.textColorSecondary))
          : SingleChildScrollView(
              child: Column(
                children: _withSectionGaps([
                  _buildGroupProfile(),
                  _buildGroupMembers(),
                  _buildGroupSettings(),
                  _buildGroupRemark(),
                  _buildBasicSettings(),
                  _buildChatBackground(),
                  _buildBottomActions(),
                ]),
              ),
            ),
    );
  }

  /// Turns a list of (nullable) setting cards into a scrollable column where
  /// every card is a white block separated from its neighbours by a gray gap
  /// (the page background showing through). The first card sits right under the
  /// AppBar with only a 1px seam; the remaining cards are separated by 10px.
  /// Null cards (hidden by permissions) are skipped so no double gaps appear.
  List<Widget> _withSectionGaps(List<Widget?> sections) {
    final visible = sections.whereType<Widget>().toList();
    final result = <Widget>[const SizedBox(height: 1)];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0) result.add(const SizedBox(height: 10));
      result.add(visible[i]);
    }
    result.add(const SizedBox(height: 28));
    return result;
  }

  Widget _buildGroupProfile() {
    final groupInfo = _groupInfo!;
    final canEditName = _hasPermission(GroupPermission.setGroupName);
    return Container(
      color: colorsTheme.bgColorOperate,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _hasPermission(GroupPermission.setGroupAvatar) ? _onAvatarTap : null,
            child: Avatar(
              content: AvatarImageContent(
                  url: groupInfo.avatarURL ?? '', name: groupInfo.groupName ?? ''),
              size: AvatarSize.l,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        (groupInfo.groupName?.isNotEmpty == true)
                            ? groupInfo.groupName!
                            : widget.groupID,
                        style: FontScheme.body4Medium.copyWith(
                          color: colorsTheme.textColorPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canEditName) const SizedBox(width: 8),
                    if (canEditName)
                      GestureDetector(
                        onTap: _showGroupNameEditDialog,
                        child: SvgPicture.asset(
                          'chat_assets/icon/name_edit.svg',
                          package: 'tencent_chat_uikit',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${chatLocale.groupIDLabel}: ${widget.groupID}',
                  style: FontScheme.caption3Regular.copyWith(
                    color: colorsTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBasicSettings() {
    List<Widget> settings = [];

    if (_hasPermission(GroupPermission.setDoNotDisturb)) {
      settings.add(SettingWidgets.buildSettingRow(
        context: context,
        title: chatLocale.doNotDisturb,
        value: _isNotDisturb,
        onChanged: (value) async {
          final result = await _conversationListStore.setReceiveMessageOpt(
            conversationID: conversationID,
            opt: value ? ReceiveMessageOption.notNotify : ReceiveMessageOption.receive,
          );
          if (result.errorCode == 0) {
            setState(() { _isNotDisturb = value; });
          }
        },
      ));
    }

    if (_hasPermission(GroupPermission.pinGroup)) {
      settings.add(SettingWidgets.buildSettingRow(
        context: context,
        title: chatLocale.pin,
        value: _isPinned,
        onChanged: (value) async {
          final result = await _conversationListStore.pinConversation(conversationID: conversationID, pin: value);
          if (result.errorCode == 0) {
            setState(() { _isPinned = value; });
          }
        },
      ));
    }

    if (settings.isEmpty) return null;

    return SettingWidgets.buildSettingGroup(context: context, children: settings);
  }

  Widget _buildChatBackground() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildNavigationRow(
          context: context,
          title: chatLocale.chatBackground,
          value: _chatBackgroundImageUri == null
              ? chatLocale.chatBackgroundDefault
              : chatLocale.chatBackgroundCustom,
          onTap: _onChatBackgroundTap,
        ),
      ],
    );
  }

  Widget _buildGroupSettings() {
    final groupInfo = _groupInfo!;
    List<Widget> settings = [];

    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: chatLocale.groupOfAnnouncement,
      value: (groupInfo.notification?.isNotEmpty == true)
          ? groupInfo.notification!
          : chatLocale.groupNoticeEmpty,
      useEditIcon: true,
      onTap: () => _onGroupNotice(),
    ));

    if (_hasPermission(GroupPermission.setGroupManagement)) {
      settings.add(SettingWidgets.buildNavigationRow(
        context: context,
        title: chatLocale.groupManagement,
        onTap: () => _onGroupManagement(),
      ));
    }

    if (_hasPermission(GroupPermission.getGroupType)) {
      settings.add(SettingWidgets.buildInfoRow(
        context: context,
        title: chatLocale.groupType,
        value: GroupPermissionManager.getGroupTypeDescription(groupInfo.groupType ?? GroupType.work, context),
      ));
    }

    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: chatLocale.addGroupWay,
      value: _getJoinOptionText(groupInfo.joinOption ?? GroupJoinOption.forbid),
      onTap: _hasPermission(GroupPermission.setJoinGroupApprovalType) ? () => _onJoinGroupMethod() : null,
    ));

    settings.add(SettingWidgets.buildNavigationRow(
      context: context,
      title: chatLocale.inviteGroupType,
      value: _getInviteOptionText(groupInfo.inviteOption ?? GroupInviteOption.forbid),
      onTap: _hasPermission(GroupPermission.setInviteToGroupApprovalType) ? () => _onInviteMethod() : null,
    ));

    return SettingWidgets.buildSettingGroup(context: context, children: settings);
  }

  Widget? _buildGroupRemark() {
    if (!_hasPermission(GroupPermission.setGroupRemark)) {
      return null;
    }

    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildNavigationRow(
          context: context,
          title: chatLocale.myAliasInGroup,
          value: _selfNameCard,
          useEditIcon: true,
          onTap: () => _onGroupRemark(),
        ),
      ],
    );
  }

  Widget _buildGroupMembers() {
    final groupInfo = _groupInfo!;
    final canAdd = _hasPermission(GroupPermission.addGroupMember) &&
        (groupInfo.inviteOption ?? GroupInviteOption.forbid) != GroupInviteOption.forbid;
    final canRemove = _hasPermission(GroupPermission.removeGroupMember);

    return ValueListenableBuilder<List<GroupMember>>(
      valueListenable: _memberStore.state.memberList,
      builder: (context, members, child) {
        return Container(
          color: colorsTheme.bgColorOperate,
          child: Column(
            children: [
              SettingWidgets.buildNavigationRow(
                context: context,
                title: chatLocale.groupMember,
                value: '${groupInfo.memberCount ?? 0}',
                onTap: _hasPermission(GroupPermission.getGroupMemberList) ? () => _onGroupMemberList() : null,
              ),
              _buildMemberGrid(members, canAdd: canAdd, canRemove: canRemove),
            ],
          ),
        );
      },
    );
  }

  /// A 5-column, up-to-2-row preview of members with trailing add (+) and
  /// remove (−) tiles — mirroring the Android group setting layout. Empty
  /// columns are filled with blank slots so tiles stay left-aligned on an even
  /// grid.
  Widget _buildMemberGrid(
    List<GroupMember> members, {
    required bool canAdd,
    required bool canRemove,
  }) {
    const columns = 5;
    const maxSlots = columns * 2;
    final reserved = (canAdd ? 1 : 0) + (canRemove ? 1 : 0);
    final maxMemberSlots = (maxSlots - reserved).clamp(0, maxSlots);

    final cells = <Widget>[
      for (final member in members.take(maxMemberSlots)) _buildMemberCell(member),
      if (canAdd) _buildMemberActionCell(isAdd: true),
      if (canRemove) _buildMemberActionCell(isAdd: false),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += columns) {
      final end = (i + columns < cells.length) ? i + columns : cells.length;
      final rowCells = cells.sublist(i, end);
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            columns,
            (col) => Expanded(
              child: col < rowCells.length ? rowCells[col] : const SizedBox.shrink(),
            ),
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 4,
        bottom: 16,
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildMemberCell(GroupMember member) {
    final name = UIKitUtil.memberDisplayName(member);
    return GestureDetector(
      onTap: _hasPermission(GroupPermission.getGroupMemberInfo) ? () => _onMemberInfo(member) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar.image(
            url: member.avatarURL,
            name: name,
            size: AvatarSize.m,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: FontScheme.caption3Regular.copyWith(color: colorsTheme.textColorPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActionCell({required bool isAdd}) {
    return GestureDetector(
      onTap: isAdd ? _onAddMembers : _onRemoveMembers,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorsTheme.bgColorInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isAdd ? Icons.add : Icons.remove,
              size: 22,
              color: colorsTheme.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom stack: the normal "send message" action (blue) followed by the
  /// destructive ones (red), all centered in a single card — matching the
  /// contact page.
  Widget? _buildBottomActions() {
    List<Widget> actions = [];

    if (_hasPermission(GroupPermission.sendMessage)) {
      actions.add(SettingWidgets.buildCenteredActionRow(
        context: context,
        title: chatLocale.sendMessage,
        onTap: _navigateToMessageList,
      ));
    }

    if (_hasPermission(GroupPermission.clearHistoryMessages)) {
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: chatLocale.clearMessage,
        onTap: () => _onClearHistory(),
      ));
    }

    if (_hasPermission(GroupPermission.deleteAndQuit)) {
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: chatLocale.quitGroup,
        onTap: () => _onDeleteAndQuit(),
      ));
    }

    if (_hasPermission(GroupPermission.transferOwner)) {
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: chatLocale.transferGroupOwner,
        onTap: () => _onTransferOwner(),
      ));
    }

    if (_hasPermission(GroupPermission.dismissGroup)) {
      actions.add(SettingWidgets.buildDangerousActionRow(
        context: context,
        title: chatLocale.dismissGroup,
        onTap: () => _onDismissGroup(),
      ));
    }

    if (actions.isEmpty) return null;

    return SettingWidgets.buildSettingGroup(context: context, children: actions);
  }

  bool _hasPermission(GroupPermission permission) {
    return GroupPermissionManager.hasPermission(
      groupType: _groupInfo?.groupType ?? GroupType.work,
      memberRole: _currentUserRole,
      permission: permission,
    );
  }

  void _onAvatarTap() async {
    final result = await Navigator.push<String>(
        context,
        MaterialPageRoute<String>(
            builder: (context) => ChooseGroupAvatar(
                groupID: widget.groupID,
                groupType: (_groupInfo?.groupType ?? GroupType.work).toString(),
                selectedAvatarURL: _groupInfo?.avatarURL ?? '')));
    if (result != null && result.isNotEmpty) {
      final updatedGroupInfo = GroupInfo(groupID: widget.groupID, avatarURL: result);
      // UI refresh is driven by GroupStore.joinedGroupList listener
      // (see _onJoinedGroupListChanged); no manual reload needed here.
      await GroupStore.shared.updateProfile(groupInfo: updatedGroupInfo);
    }
  }

  void _onGroupNotice() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupNotice(
          groupID: widget.groupID,
          groupInfo: _groupInfo!,
          currentUserRole: _currentUserRole,
        ),
      ),
    );
  }

  void _onGroupManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupManagement(
          groupID: widget.groupID,
          memberStore: _memberStore,
        ),
      ),
    );
  }

  void _onJoinGroupMethod() {
    _showGroupMethodSheet(
      type: GroupMethodType.join,
      onSelected: (option) async {
        // UI refresh is driven by GroupStore.joinedGroupList listener.
        await GroupStore.shared.setJoinOption(groupID: widget.groupID, option: option);
      },
    );
  }

  void _onInviteMethod() {
    final config = _getMethodSheetConfig(GroupMethodType.invite);
    // UI refresh after each setInviteOption is driven by
    // GroupStore.joinedGroupList listener (_onJoinedGroupListChanged).
    ActionSheet.show(
      context,
      actions: [
        ActionSheetItem(
          title: config.forbidText,
          onTap: () => GroupStore.shared.setInviteOption(
            groupID: widget.groupID,
            option: GroupInviteOption.forbid,
          ),
        ),
        ActionSheetItem(
          title: config.authText,
          onTap: () => GroupStore.shared.setInviteOption(
            groupID: widget.groupID,
            option: GroupInviteOption.auth,
          ),
        ),
        ActionSheetItem(
          title: config.anyText,
          onTap: () => GroupStore.shared.setInviteOption(
            groupID: widget.groupID,
            option: GroupInviteOption.any,
          ),
        ),
      ],
    );
  }

  void _onGroupRemark() async {
    final result = await BottomInputSheet.show(
      context,
      title: chatLocale.modifyGroupNickname,
      hintText: '',
      initialText: _selfNameCard,
    );

    if (result != null) {
      final updateResult = await _memberStore.setSelfNameCard(nameCard: result);
      if (updateResult.errorCode == 0) {
        setState(() { _selfNameCard = result; });
      }
    }
  }

  void _showGroupMethodSheet({
    required GroupMethodType type,
    required void Function(GroupJoinOption) onSelected,
  }) {
    final config = _getMethodSheetConfig(type);

    ActionSheet.show(
      context,
      actions: [
        ActionSheetItem(title: config.forbidText, onTap: () => onSelected(GroupJoinOption.forbid)),
        ActionSheetItem(title: config.authText, onTap: () => onSelected(GroupJoinOption.auth)),
        ActionSheetItem(title: config.anyText, onTap: () => onSelected(GroupJoinOption.any)),
      ],
    );
  }

  MethodSheetConfig _getMethodSheetConfig(GroupMethodType type) {
    switch (type) {
      case GroupMethodType.join:
        return MethodSheetConfig(
          forbidText: chatLocale.groupAddForbid,
          authText: chatLocale.groupAddAuth,
          anyText: chatLocale.groupAddAny,
        );
      case GroupMethodType.invite:
        return MethodSheetConfig(
          forbidText: chatLocale.groupInviteForbid,
          authText: chatLocale.groupAddAuth,
          anyText: chatLocale.groupAddAny,
        );
    }
  }

  void _onGroupMemberList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupMemberList(
          groupID: widget.groupID,
          memberStore: _memberStore,
          groupInfo: _groupInfo!,
          currentUserRole: _currentUserRole,
          onSendMessageClick: widget.onSendMessageClick,
        ),
      ),
    );
  }

  void _onAddMembers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupAddMember(
          groupID: widget.groupID,
          memberStore: _memberStore,
        ),
      ),
    );
    await _refreshMembers();
  }

  void _onRemoveMembers() async {
    final selected = await Navigator.of(context).push<List<UserPickerData>>(
      MaterialPageRoute<List<UserPickerData>>(
        builder: (context) => GroupMemberPicker(groupID: widget.groupID),
      ),
    );
    if (selected == null || selected.isEmpty) return;

    final userIDs = selected.map((item) => item.key).toList();
    final result = await _memberStore.deleteMember(userIDList: userIDs);
    if (result.errorCode != 0) {
      debugPrint('deleteMember failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      return;
    }
    await _refreshMembers();
  }

  /// Reload the member list + group info so the grid preview and member count
  /// reflect additions / removals.
  Future<void> _refreshMembers() async {
    await Future.wait([
      _loadMembers(),
      _loadGroupInfo(),
    ]);
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
      content: chatLocale.clearMsgTip,
      onConfirm: () async {
        await _conversationListStore.clearConversationMessages(conversationID: conversationID);
      },
    );
  }

  void _onDeleteAndQuit() {
    _showConfirmDialog(
      content: chatLocale.quitGroupTip,
      onConfirm: () async {
        _isHandlingPopExplicitly = true;
        final result = await GroupStore.shared.quitGroup(groupID: widget.groupID);
        if (result.errorCode == 0) {
          _conversationListStore.deleteConversation(conversationID: conversationID);
          if (mounted) Navigator.of(context).pop();
          widget.onGroupDelete?.call();
        } else {
          _isHandlingPopExplicitly = false;
        }
      },
    );
  }

  void _onTransferOwner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupTransferOwner(
          groupID: widget.groupID,
          memberStore: _memberStore,
        ),
      ),
    );
  }

  void _onDismissGroup() {
    _showConfirmDialog(
      content: chatLocale.dismissGroupTip,
      onConfirm: () async {
        _isHandlingPopExplicitly = true;
        final result = await GroupStore.shared.dismissGroup(groupID: widget.groupID);
        if (result.errorCode == 0) {
          _conversationListStore.deleteConversation(conversationID: conversationID);
          if (mounted) Navigator.of(context).pop();
          widget.onGroupDelete?.call();
        } else {
          _isHandlingPopExplicitly = false;
        }
      },
    );
  }

  void _showConfirmDialog({
    required String content,
    required VoidCallback onConfirm,
  }) {
    final locale = ChatLocalizations.of(context);
    AtomicAlertDialog.showWithConfig(
      context,
      config: AlertDialogConfig(
        content: content,
        cancelConfig: ButtonConfig(text: locale.cancel),
        confirmConfig: ButtonConfig(
          text: locale.confirm,
          type: TextColorPreset.red,
          onClick: onConfirm,
        ),
      ),
    );
  }

  void _showGroupNameEditDialog() async {
    final result = await BottomInputSheet.show(
      context,
      title: chatLocale.modifyGroupName,
      hintText: '',
      initialText: _groupInfo?.groupName ?? '',
    );

    if (result != null) {
      final updatedGroupInfo = GroupInfo(groupID: widget.groupID, groupName: result);
      // UI refresh is driven by GroupStore.joinedGroupList listener.
      await GroupStore.shared.updateProfile(groupInfo: updatedGroupInfo);
    }
  }

  void _navigateToMessageList() {
    widget.onSendMessageClick?.call(groupID: widget.groupID);
  }

  String _getJoinOptionText(GroupJoinOption option) {
    switch (option) {
      case GroupJoinOption.forbid: return chatLocale.groupAddForbid;
      case GroupJoinOption.auth: return chatLocale.groupAddAuth;
      case GroupJoinOption.any: return chatLocale.groupAddAny;
    }
  }

  String _getInviteOptionText(GroupInviteOption option) {
    switch (option) {
      case GroupInviteOption.forbid: return chatLocale.groupInviteForbid;
      case GroupInviteOption.auth: return chatLocale.groupAddAuth;
      case GroupInviteOption.any: return chatLocale.groupAddAny;
    }
  }
}
