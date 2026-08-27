import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import 'group_permission_manager.dart';
import '../../common/language/gen/chat_localizations.dart';

class GroupNotice extends StatefulWidget {
  final String groupID;
  final GroupInfo groupInfo;
  final GroupMemberRole currentUserRole;

  const GroupNotice({
    super.key,
    required this.groupID,
    required this.groupInfo,
    required this.currentUserRole,
  });

  @override
  State<GroupNotice> createState() => _GroupNoticeState();
}

class _GroupNoticeState extends State<GroupNotice> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  late String _currentNotice;

  @override
  void initState() {
    super.initState();
    _currentNotice = widget.groupInfo.notification ?? '';
    _controller = TextEditingController(text: _currentNotice);
    GroupStore.shared.state.joinedGroupList.addListener(_onJoinedGroupListChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatLocale = ChatLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    GroupStore.shared.state.joinedGroupList.removeListener(_onJoinedGroupListChanged);
    _controller.dispose();
    super.dispose();
  }

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
      Navigator.of(context).maybePop();
      return;
    }
    final newNotice = updated.notification ?? '';
    if (newNotice == _currentNotice) return;
    setState(() {
      _currentNotice = newNotice;
    });
    if (!_isEditing) {
      _controller.text = newNotice;
    }
  }

  bool get _canEditNotice {
    return GroupPermissionManager.hasPermission(
      groupType: widget.groupInfo.groupType ?? GroupType.work,
      memberRole: widget.currentUserRole,
      permission: GroupPermission.setGroupNotice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // SizedBox.expand provides the bounded height that
        // `_buildEditingView`'s TextField(expands: true) requires; the
        // display view doesn't need it but it's harmless there.
        child: SizedBox.expand(
          child: _isEditing ? _buildEditingView() : _buildDisplayView(_currentNotice),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: colorsTheme.bgColorTopBar,
      elevation: 0,
      leading: IconButton.buttonContent(
        content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
        type: ButtonType.noBorder,
        size: ButtonSize.l,
        onClick: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text(
        chatLocale.groupOfAnnouncement,
        style: FontScheme.caption1Medium.copyWith(
          color: colorsTheme.textColorPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_canEditNotice)
          IconButton.buttonContent(
            content: TextOnlyContent(
              _isEditing ? chatLocale.confirm : chatLocale.groupEdit,
            ),
            type: ButtonType.noBorder,
            size: ButtonSize.l,
            onClick: _onRightButtonTap,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: colorsTheme.strokeColorPrimary,
        ),
      ),
    );
  }

  Widget _buildDisplayView(String notice) {
    return SingleChildScrollView(
      child: Text(
        notice.isNotEmpty ? notice : chatLocale.groupNoticeEmpty,
        style: FontScheme.caption1Regular.copyWith(
          color: colorsTheme.textColorSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildEditingView() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorInput,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintStyle: FontScheme.caption1Regular.copyWith(
            color: colorsTheme.textColorDisable,
          ),
          border: InputBorder.none,
        ),
        style: FontScheme.caption1Regular.copyWith(
          color: colorsTheme.textColorPrimary,
          height: 1.4,
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  void _onRightButtonTap() {
    if (_isEditing) {
      _saveNotice();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _saveNotice() async {
    final newNotice = _controller.text.trim();
    final updatedGroupInfo = GroupInfo(groupID: widget.groupID, notification: newNotice);
    final result = await GroupStore.shared.updateProfile(groupInfo: updatedGroupInfo);

    if (!mounted) return;

    if (result.errorCode == 0) {
      setState(() {
        _currentNotice = newNotice;
        _isEditing = false;
      });
    } else {
      debugPrint('modify notice failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }
}
