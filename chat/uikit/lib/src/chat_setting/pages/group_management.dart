import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart' hide IconButton;

import 'group_add_mute_member.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupManagement extends StatefulWidget {
  final String groupID;
  final GroupMemberStore memberStore;

  const GroupManagement({
    super.key,
    required this.groupID,
    required this.memberStore,
  });

  @override
  State<GroupManagement> createState() => _GroupManagementState();
}

class _GroupManagementState extends State<GroupManagement> {
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;
  GroupInfo? _groupInfo;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  Future<void> _loadGroupInfo() async {
    final result = await GroupStore.shared.getGroupInfo(groupID: widget.groupID);
    if (result.isSuccess && result.groupInfo != null && mounted) {
      setState(() {
        _groupInfo = result.groupInfo;
      });
    }
  }

  Future<void> _onMuteAllChanged(bool value) async {
    final result = await GroupStore.shared.muteAllMembers(groupID: widget.groupID, isMuted: value);
    if (result.errorCode == 0) {
      if (mounted) {
        Toast.success(context, value ? chatLocale.groupMuteAllEnabled : chatLocale.groupMuteAllDisabled);
        _loadGroupInfo();
      }
    } else {
      debugPrint('setMuteAllMembers failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAllMuted = _groupInfo?.isAllMuted ?? false;

    return Scaffold(
      backgroundColor: colorsTheme.listColorHover,
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
          chatLocale.groupManagement,
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
      body: SafeArea(
        left: false,
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorsTheme.bgColorOperate,
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    title: chatLocale.muteAll,
                    value: isAllMuted,
                    onChanged: _onMuteAllChanged,
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: colorsTheme.buttonColorSecondaryHover,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        chatLocale.groupMuteTip,
                        style: FontScheme.caption3Regular.copyWith(
                          color: colorsTheme.textColorSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isAllMuted) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorsTheme.listColorHover,
                  ),
                  child: _buildMutedMembersList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              return colorsTheme.textColorButton;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return colorsTheme.switchColorOn;
              }
              return colorsTheme.switchColorOff;
            }),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
              return colorsTheme.clearColor;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedMembersList() {
    return ValueListenableBuilder<List<GroupMember>>(
      valueListenable: widget.memberStore.state.memberList,
      builder: (context, members, child) {
        final mutedMembers = members.where((member) => member.isMuted).toList();
        return Column(
          children: [
            GestureDetector(
              onTap: _onAddMuteMember,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: colorsTheme.bgColorOperate,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: colorsTheme.buttonColorPrimaryDefault,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chatLocale.addMuteMemberTip,
                      style: FontScheme.caption2Regular.copyWith(
                        color: colorsTheme.buttonColorPrimaryDefault,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: mutedMembers.isEmpty
                  ? Container()
                  : ListView.builder(
                      itemCount: mutedMembers.length,
                      itemBuilder: (context, index) {
                        final member = mutedMembers[index];
                        return _buildMutedMemberItem(member);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _onAddMuteMember() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupAddMuteMember(
          memberStore: widget.memberStore,
        ),
      ),
    );
  }

  Widget _buildMutedMemberItem(GroupMember member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      color: colorsTheme.bgColorOperate,
      child: Row(
        children: [
          Avatar.image(
            url: member.avatarURL,
            name: UIKitUtil.memberDisplayName(member),
            size: AvatarSize.m,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              UIKitUtil.memberDisplayName(member),
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _onUnmuteMember(member),
            child: Icon(
              Icons.remove_circle,
              color: colorsTheme.textColorError,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onUnmuteMember(GroupMember member) async {
    await widget.memberStore.muteMember(userID: member.userID, time: 0);
  }
}
