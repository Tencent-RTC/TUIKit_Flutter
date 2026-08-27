import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import '../../common/language/gen/chat_localizations.dart';

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
  final ContactStore _contactStore = ContactStore.shared;
  late ConversationListStore _conversationListStore;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;
  late String conversationID;

  ContactInfo? _contactInfo;
  bool _isNotDisturb = false;
  bool _isPinned = false;
  bool _isInBlacklist = false;
  String? _chatBackgroundImageUri;

  @override
  void initState() {
    super.initState();
    conversationID = c2cConversationIDPrefix + widget.userID;
    _conversationListStore = ConversationListStore.create();
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

  Future<void> _loadData() async {
    await Future.wait([
      _loadContactInfo(),
      _loadConversationInfo(),
      _loadBlacklistStatus(),
    ]);
  }

  Future<void> _loadContactInfo() async {
    final handler = await _contactStore.getContactInfo(userIDList: [widget.userID]);
    if (handler.isSuccess && handler.contactInfoList.isNotEmpty && mounted) {
      setState(() {
        _contactInfo = handler.contactInfoList.first;
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

  Future<void> _loadBlacklistStatus() async {
    await _contactStore.loadBlackList();
    if (mounted) {
      final blackList = _contactStore.state.blackList.value;
      setState(() {
        _isInBlacklist = blackList.any((c) => c.userID == widget.userID);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorInput,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: chatLocale.contactInfo,
      ),
      body: _contactInfo == null
          ? Center(child: CircularProgressIndicator(color: colorsTheme.textColorSecondary))
          : SingleChildScrollView(
              child: Column(
                children: _withSectionGaps([
                  _buildUserProfile(),
                  _buildRemarkSection(),
                  _buildSettingsSection(),
                  _buildChatBackground(),
                  _buildBlacklistSection(),
                  _buildBottomActions(),
                ]),
              ),
            ),
    );
  }

  /// See [_GroupChatSettingState._withSectionGaps]: the first card sits right
  /// under the AppBar with a 1px seam, later cards are separated by 10px of the
  /// gray page background.
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

  Widget _buildUserProfile() {
    final nickname = _contactInfo?.nickname ?? '';
    final avatarURL = _contactInfo?.avatarURL ?? '';
    return Container(
      color: colorsTheme.bgColorOperate,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Avatar(
            content: AvatarImageContent(url: avatarURL, name: nickname),
            size: AvatarSize.l,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nickname.isNotEmpty ? nickname : widget.userID,
                  style: FontScheme.body4Medium.copyWith(
                    color: colorsTheme.textColorPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${chatLocale.userIDLabel}: ${widget.userID}',
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

  Widget _buildRemarkSection() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildNavigationRow(
          context: context,
          title: chatLocale.profileRemark,
          value: _contactInfo?.friendRemark ?? '',
          useEditIcon: true,
          onTap: _showRemarkEditDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildSettingRow(
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
        ),
        SettingWidgets.buildSettingRow(
          context: context,
          title: chatLocale.pin,
          value: _isPinned,
          onChanged: (value) async {
            final result = await _conversationListStore.pinConversation(conversationID: conversationID, pin: value);
            if (result.errorCode == 0) {
              setState(() { _isPinned = value; });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBlacklistSection() {
    return SettingWidgets.buildSettingGroup(
      context: context,
      children: [
        SettingWidgets.buildSettingRow(
          context: context,
          title: chatLocale.profileBlack,
          value: _isInBlacklist,
          onChanged: (value) async {
            CompletionHandler result;
            if (value) {
              result = await _contactStore.addToBlacklist(userID: widget.userID);
            } else {
              result = await _contactStore.removeFromBlacklist(userID: widget.userID);
            }
            if (result.errorCode == 0) {
              setState(() { _isInBlacklist = value; });
            }
          },
        ),
      ],
    );
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

  /// Bottom stack: send message (blue) then the destructive actions (red),
  /// centered in a single card — matching the group setting page.
  Widget _buildBottomActions() {
    final actions = <Widget>[
      SettingWidgets.buildCenteredActionRow(
        context: context,
        title: chatLocale.sendMessage,
        onTap: _navigateToMessageList,
      ),
      SettingWidgets.buildDangerousActionRow(
        context: context,
        title: chatLocale.clearMessage,
        onTap: () {
          _showConfirmDialog(
            content: chatLocale.clearMsgTip,
            onConfirm: () async {
              await _conversationListStore.clearConversationMessages(conversationID: conversationID);
            },
          );
        },
      ),
      if (!_isInBlacklist)
        SettingWidgets.buildDangerousActionRow(
          context: context,
          title: chatLocale.deleteFriend,
          onTap: () {
            _showConfirmDialog(
              content: chatLocale.deleteFriendTip,
              onConfirm: () async {
                final result = await _contactStore.deleteFriend(userID: widget.userID);
                if (result.errorCode == 0) {
                  _conversationListStore.deleteConversation(conversationID: conversationID);
                  if (mounted) Navigator.of(context).pop();
                  widget.onContactDelete?.call();
                }
              },
            );
          },
        ),
    ];

    return SettingWidgets.buildSettingGroup(context: context, children: actions);
  }

  void _showRemarkEditDialog() {
    final TextEditingController controller = TextEditingController(text: _contactInfo?.friendRemark ?? '');

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
                    chatLocale.remarkEdit,
                    style: FontScheme.caption1Medium.copyWith(
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          chatLocale.cancel,
                          style: FontScheme.caption1Regular.copyWith(color: colorsTheme.textColorPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final newRemark = controller.text.trim();
                          Navigator.of(context).pop();

                          final result = await _contactStore.setFriendRemark(
                            userID: widget.userID,
                            remark: newRemark,
                          );
                          if (result.errorCode == 0) {
                            _loadContactInfo();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorsTheme.buttonColorPrimaryDefault,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          chatLocale.confirm,
                          style: FontScheme.caption1Medium.copyWith(
                            color: colorsTheme.textColorButton,
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

  void _navigateToMessageList() {
    widget.onSendMessageClick?.call(userID: widget.userID);
  }
}
