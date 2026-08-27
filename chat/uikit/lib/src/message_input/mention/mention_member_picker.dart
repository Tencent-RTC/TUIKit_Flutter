import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_chat_uikit/src/common/utils/uikit_util.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/avatar.dart';
import '../../common/language/gen/chat_localizations.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/font.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';
import 'package:tencent_chat_uikit/src/user_picker/user_picker.dart';

import 'mention_info.dart';

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
  late GroupMemberStore _memberStore;
  late SemanticColorScheme _colorsTheme;
  late ChatLocalizations _chatLocale;

  bool _isLoading = false;
  List<UserPickerData> _memberDataSource = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _memberStore = GroupMemberStore.create(groupID: widget.groupID);
    _memberStore.state.memberList.addListener(_onMemberListChanged);
    _loadGroupMembers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memberStore.state.memberList.removeListener(_onMemberListChanged);
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
    _chatLocale = ChatLocalizations.of(context);
  }

  void _onMemberListChanged() {
    if (mounted) _updateMemberDataSource();
  }

  void _updateMemberDataSource() {
    final members = _memberStore.state.memberList.value;
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;

    final dataSource = members
        .where((member) => member.userID != currentUserID)
        .map((member) {
      return UserPickerData(
        key: member.userID,
        label: UIKitUtil.memberDisplayName(member),
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
    await _memberStore.loadMembers();
    if (mounted) {
      _updateMemberDataSource();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreGroupMembers() async {
    if (_isLoading) return;
    if (!_memberStore.state.hasMoreMembers.value) return;

    setState(() => _isLoading = true);
    await _memberStore.loadMoreMembers();
    if (mounted) {
      _updateMemberDataSource();
      setState(() => _isLoading = false);
    }
  }

  void _onAtAllTap() {
    final mentionInfo = MentionInfo(
      userID: MentionInfo.atAllUserID,
      displayName: _chatLocale.messageInputAllMembers,
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
    final allMembersText = _chatLocale.messageInputAllMembers;

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
                style: FontScheme.caption1Medium.copyWith(
                  color: _colorsTheme.textColorPrimary,
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
      title: _chatLocale.selectMentionMember,
      headerWidget: _buildAtAllHeader(),
      onConfirm: _onMembersConfirmed,
      onReachEnd: _loadMoreGroupMembers,
    );
  }
}
