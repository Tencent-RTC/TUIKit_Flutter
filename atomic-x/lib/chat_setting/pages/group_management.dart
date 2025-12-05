import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import 'group_add_mute_member.dart';

class GroupManagement extends StatefulWidget {
  final GroupSettingStore settingStore;

  const GroupManagement({
    super.key,
    required this.settingStore,
  });

  @override
  State<GroupManagement> createState() => _GroupManagementState();
}

class _GroupManagementState extends State<GroupManagement> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    widget.settingStore.addListener(_onStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    widget.settingStore.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onMuteAllChanged(bool value) async {
    final result = await widget.settingStore.setMuteAllMembers(isMuted: value);
    if (result.errorCode == 0) {
      Toast.success(context, value ? atomicLocale.groupMuteAllEnabled : atomicLocale.groupMuteAllDisabled);
    } else {
      debugPrint('setMuteAllMembers failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorHover,
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
          atomicLocale.groupManagement,
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
                    title: atomicLocale.muteAll,
                    value: widget.settingStore.groupSettingState.isAllMuted,
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
                        atomicLocale.groupMuteTip,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorsTheme.textColorSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.settingStore.groupSettingState.isAllMuted) ...[
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
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
    final mutedMembers = widget.settingStore.groupSettingState.allMembers.where((member) {
      return member.isMuted;
    }).toList();

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
                  atomicLocale.addMuteMemberTip,
                  style: TextStyle(
                    fontSize: 14,
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
  }

  void _onAddMuteMember() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupAddMuteMember(
          settingStore: widget.settingStore,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                        color: colorsTheme.textColorButton,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMemberDisplayName(member),
              style: TextStyle(
                fontSize: 14,
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
    final result = await widget.settingStore.setGroupMemberMuteTime(
      userID: member.userID,
      time: 0,
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
    return 'Unknown';
  }
}
