import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart' hide AlertDialog;

typedef OnSendMessageClick = void Function({String? userID, String? groupID});

class C2CChatSetting extends StatefulWidget {
  final String userID;

  final VoidCallback? onContactDelete;
  final OnSendMessageClick? onSendMessageClick;

  const C2CChatSetting({
    super.key,
    required this.userID,
    this.onContactDelete,
    this.onSendMessageClick,
  });

  @override
  State<C2CChatSetting> createState() => _C2CChatSettingState();
}

class _C2CChatSettingState extends State<C2CChatSetting> {
  late C2CSettingStore settingStore;
  late ConversationListStore conversationListStore;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;
  late String conversationID;

  @override
  void initState() {
    super.initState();
    conversationID = c2cConversationIDPrefix + widget.userID;
    settingStore = C2CSettingStore.create(userID: widget.userID);
    settingStore.fetchUserInfo();
    settingStore.checkBlacklistStatus();
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
        title: atomicLocale.contactInfo,
      ),
      body: ListenableBuilder(
        listenable: settingStore,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildUserProfile(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
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

  Widget _buildUserProfile() {
    return Column(
      children: [
        Avatar(
          content: AvatarImageContent(
              url: settingStore.c2cSettingState.avatarURL, name: settingStore.c2cSettingState.nickname),
          size: AvatarSize.xl,
        ),
        const SizedBox(height: 16),
        Text(
          settingStore.c2cSettingState.nickname.isNotEmpty
              ? settingStore.c2cSettingState.nickname
              : settingStore.userID,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorsTheme.textColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SettingWidgets.buildActionButton(
            context: context,
            icon: Icons.message,
            label: atomicLocale.sendMessage,
            onTap: () {
              _navigateToMessageList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        _buildRemarkRow(),
        SettingWidgets.buildDivider(context),
        SettingWidgets.buildSettingRow(
          context: context,
          title: atomicLocale.doNotDisturb,
          value: settingStore.c2cSettingState.isNotDisturb,
          onChanged: (value) async {
            final result = await conversationListStore.muteConversation(conversationID: conversationID, mute: value);
            if (result.errorCode != 0) {
              debugPrint(
                  'setChatNotDisturb failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
            }
          },
        ),
        SettingWidgets.buildDivider(context),
        SettingWidgets.buildSettingRow(
          context: context,
          title: atomicLocale.pin,
          value: settingStore.c2cSettingState.isPinned,
          onChanged: (value) async {
            final result = await conversationListStore.pinConversation(conversationID: conversationID, pin: value);
            if (result.errorCode != 0) {
              _showErrorMessage('${result.errorMessage}');
            }
          },
        ),
        SettingWidgets.buildDivider(context),
        SettingWidgets.buildSettingRow(
          context: context,
          title: atomicLocale.profileBlack,
          value: settingStore.c2cSettingState.isInBlacklist,
          onChanged: (value) async {
            if (value) {
              final result = await settingStore.addToBlacklist();
              if (result.errorCode != 0) {
                _showErrorMessage('${result.errorMessage}');
              }
            } else {
              final result = await settingStore.removeFromBlacklist();
              if (result.errorCode != 0) {
                _showErrorMessage('${result.errorMessage}');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildRemarkRow() {
    return GestureDetector(
      onTap: () {
        _showRemarkEditDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              atomicLocale.profileRemark,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorsTheme.textColorPrimary,
              ),
            ),
            Expanded(
              child: Text(
                settingStore.c2cSettingState.remark.isNotEmpty ? settingStore.c2cSettingState.remark : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorsTheme.textColorPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colorsTheme.scrollbarColorHover,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerousActions() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildDangerousActionRow(
          context: context,
          title: atomicLocale.clearMessage,
          onTap: () {
            _showConfirmDialog(
              title: atomicLocale.clearMessage,
              content: atomicLocale.clearMsgTip,
              onConfirm: () async {
                final result = await conversationListStore.clearConversationMessages(conversationID: conversationID);
                if (result.errorCode != 0) {
                  debugPrint(
                      'clearHistoryMessage failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
                }
              },
            );
          },
        ),
        SettingWidgets.buildDivider(context),
        if (!settingStore.c2cSettingState.isInBlacklist)
          SettingWidgets.buildDangerousActionRow(
            context: context,
            title: atomicLocale.deleteFriend,
            onTap: () {
              _showConfirmDialog(
                title: atomicLocale.deleteFriend,
                content: atomicLocale.deleteFriendTip,
                onConfirm: () async {
                  final result = await _deleteFriend();
                  if (result.errorCode == 0) {
                    conversationListStore.deleteConversation(conversationID: conversationID);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }

                    if (widget.onContactDelete != null) {
                      widget.onContactDelete!();
                    }
                  } else {
                    debugPrint(
                        '_deleteFriend failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
                  }
                },
              );
            },
          ),
      ],
    );
  }

  void _showRemarkEditDialog() {
    final TextEditingController controller = TextEditingController(text: settingStore.c2cSettingState.remark);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorsTheme.bgColorDialog,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    atomicLocale.remarkEdit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: colorsTheme.bgColorInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorsTheme.buttonColorSecondaryDefault,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          atomicLocale.cancel,
                          style: TextStyle(
                            color: colorsTheme.textColorPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final newRemark = controller.text.trim();
                          Navigator.of(context).pop();

                          final result = await settingStore.setUserRemark(remark: newRemark);
                          if (result.errorCode != 0) {
                            debugPrint(
                                'setUserRemark failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorsTheme.buttonColorPrimaryDefault,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          atomicLocale.confirm,
                          style: TextStyle(
                            color: colorsTheme.textColorButton,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      Toast.error(context, message);
    }
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

  Future<CompletionHandler> _deleteFriend() async {
    return await settingStore.deleteFriend(userID: widget.userID);
  }

  void _navigateToMessageList() {
    if (widget.onSendMessageClick != null) {
      widget.onSendMessageClick!(userID: widget.userID);
    }
  }
}
