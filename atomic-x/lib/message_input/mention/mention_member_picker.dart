import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/avatar.dart';
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';
import 'package:tuikit_atomic_x/user_picker/user_picker.dart';

import 'mention_info.dart';

/// Extension to get display name from GroupMember
extension GroupMemberDisplayName on GroupMember {
  String get displayName {
    if (nameCard != null && nameCard!.isNotEmpty) return nameCard!;
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    return userID;
  }
}

/// MentionMemberPicker allows users to select group members to mention.
/// It uses UserPicker with a headerWidget for the @All option.
class MentionMemberPicker extends StatefulWidget {
  final String groupID;
  final Function(List<MentionInfo>) onMembersSelected;
  final VoidCallback? onCancel;

  const MentionMemberPicker({
    super.key,
    required this.groupID,
    required this.onMembersSelected,
    this.onCancel,
  });

  @override
  State<MentionMemberPicker> createState() => _MentionMemberPickerState();
}

class _MentionMemberPickerState extends State<MentionMemberPicker> with WidgetsBindingObserver {
  late GroupSettingStore _groupSettingStore;
  late SemanticColorScheme _colorsTheme;
  late AtomicLocalizations _atomicLocale;

  bool _isLoading = false;
  List<UserPickerData> _memberDataSource = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _groupSettingStore = GroupSettingStore.create(groupID: widget.groupID);
    _groupSettingStore.addListener(_onGroupSettingChanged);
    _loadGroupMembers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _groupSettingStore.removeListener(_onGroupSettingChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorsTheme = BaseThemeProvider.colorsOf(context);
    _atomicLocale = AtomicLocalizations.of(context);
  }

  void _onGroupSettingChanged() {
    if (mounted) _updateMemberDataSource();
  }

  void _updateMemberDataSource() {
    final members = _groupSettingStore.groupSettingState.allMembers;
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    
    // Filter out the current user from the member list
    final dataSource = members
        .where((member) => member.userID != currentUserID)
        .map((member) {
      return UserPickerData(
        key: member.userID,
        label: member.displayName,
        avatarURL: member.avatarURL,
        extraData: member,
      );
    }).toList();

    setState(() {
      _memberDataSource = dataSource;
    });
  }

  Future<void> _loadGroupMembers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _groupSettingStore.fetchGroupMemberList(role: GroupMemberRole.all);
    if (mounted) {
      _updateMemberDataSource();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreGroupMembers() async {
    if (_isLoading) return;
    if (!_groupSettingStore.groupSettingState.hasMoreGroupMembers) return;

    setState(() => _isLoading = true);
    await _groupSettingStore.fetchMoreGroupMemberList();
    if (mounted) {
      _updateMemberDataSource();
      setState(() => _isLoading = false);
    }
  }

  void _onAtAllTap() {
    final mentionInfo = MentionInfo(
      userID: MentionInfo.atAllUserID,
      displayName: _atomicLocale.messageInputAllMembers,
      startIndex: 0,
    );
    widget.onMembersSelected([mentionInfo]);
  }

  void _onMembersConfirmed(List<UserPickerData> selectedItems) {
    final mentionInfos = selectedItems.map((item) {
      return MentionInfo(
        userID: item.key,
        displayName: item.label,
        startIndex: 0,
      );
    }).toList();

    widget.onMembersSelected(mentionInfos);
  }

  Widget _buildAtAllHeader() {
    final allMembersText = _atomicLocale.messageInputAllMembers;
    
    return InkWell(
      onTap: _onAtAllTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _colorsTheme.bgColorOperate,
        child: Row(
          children: [
            Avatar.image(name: allMembersText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                allMembersText,
                style: TextStyle(
                  color: _colorsTheme.textColorPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _colorsTheme.textColorTertiary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _memberDataSource.isEmpty) {
      return Scaffold(
        backgroundColor: _colorsTheme.bgColorOperate,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_colorsTheme.buttonColorPrimaryDefault),
          ),
        ),
      );
    }

    return UserPicker(
      dataSource: _memberDataSource,
      title: _atomicLocale.selectMentionMember,
      headerWidget: _buildAtAllHeader(),
      onConfirm: _onMembersConfirmed,
      onReachEnd: _loadMoreGroupMembers,
    );
  }
}
