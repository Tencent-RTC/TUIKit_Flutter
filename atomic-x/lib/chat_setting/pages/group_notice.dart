import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;

import 'group_permission_manager.dart';

class GroupNotice extends StatefulWidget {
  final GroupSettingStore settingStore;

  const GroupNotice({
    super.key,
    required this.settingStore,
  });

  @override
  State<GroupNotice> createState() => _GroupNoticeState();
}

class _GroupNoticeState extends State<GroupNotice> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.settingStore.groupSettingState.notice);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canEditNotice {
    return GroupPermissionManager.hasPermission(
      groupType: widget.settingStore.groupSettingState.groupType,
      memberRole: widget.settingStore.groupSettingState.currentUserRole,
      permission: GroupPermission.setGroupNotice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: widget.settingStore,
        builder: (context, child) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                '${atomicLocale.groupOfAnnouncement}:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorsTheme.textColorSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isEditing ? _buildEditingView() : _buildDisplayView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: colorsTheme.bgColorTopBar,
      elevation: 0,
      leading: IconButton.buttonContent(
        content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
        type: ButtonType.noBorder,
        size: ButtonSize.l,
        onClick: () {
          Navigator.of(context).pop();
        },
      ),
      title: Text(
        atomicLocale.groupOfAnnouncement,
        style: TextStyle(
          color: colorsTheme.textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_canEditNotice)
          IconButton.buttonContent(
            content: TextOnlyContent(
              _isEditing ? atomicLocale.confirm : atomicLocale.groupEdit,
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

  Widget _buildDisplayView() {
    return SingleChildScrollView(
      child: Text(
        widget.settingStore.groupSettingState.notice.isNotEmpty
            ? widget.settingStore.groupSettingState.notice
            : atomicLocale.groupNoticeEmpty,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
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
          hintStyle: TextStyle(
            color: colorsTheme.textColorDisable,
            fontSize: 16,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
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
    final result = await widget.settingStore.updateGroupProfile(
      notification: newNotice,
    );

    if (result.errorCode == 0) {
      setState(() {
        _isEditing = false;
      });
    } else {
      debugPrint('modify notice failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
    }
  }
}
