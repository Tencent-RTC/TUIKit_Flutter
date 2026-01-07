import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/svg.dart';

import '../../chat_setting/widgets/avatar_selector.dart';
import '../widgets/group_type_selector.dart';

class CreateGroup extends StatefulWidget {
  final List<ContactInfo> selectedMembers;
  final Function(String groupID, String groupName, String? avatar)? onGroupCreated;

  const CreateGroup({
    super.key,
    required this.selectedMembers,
    this.onGroupCreated,
  });

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  String _selectedAvatarURL = '';
  String _selectedGroupType = GroupType.work.value;
  bool _isCreating = false;

  final String _groupFaceURL = "https://im.sdk.qcloud.com/download/tuikit-resource/group-avatar/group_avatar_%s.png";
  final int _groupFaceCount = 24;
  late List<String> _groupAvatars;

  @override
  void initState() {
    super.initState();
    _initGroupAvatars();
    _initGroupName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  void _initGroupAvatars() {
    _groupAvatars = [];
    for (int i = 0; i < _groupFaceCount; i++) {
      _groupAvatars.add(_groupFaceURL.replaceAll('%s', (i + 1).toString()));
    }
    _selectedAvatarURL = _groupAvatars.first;
  }

  void _initGroupName() {
    if (widget.selectedMembers.isNotEmpty) {
      final firstMember = widget.selectedMembers.first;
      final displayName = firstMember.title ?? firstMember.contactID;
      _groupNameController.text = '$displayName...';
    }
  }

  String _getContactDisplayName(ContactInfo contact) {
    return contact.title ?? contact.contactID;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          color: colorsTheme.textColorPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorsTheme.textColorSecondary,
            fontSize: 16,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: colorsTheme.strokeColorPrimary,
              width: 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: colorsTheme.buttonColorPrimaryDefault,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTypeSelector() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => GroupTypeSelector(
              selectedGroupType: _selectedGroupType,
            ),
          ),
        );

        if (result != null && result != _selectedGroupType) {
          setState(() {
            _selectedGroupType = result;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              atomicLocale.groupType,
              style: TextStyle(
                fontSize: 16,
                color: colorsTheme.textColorPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  getGroupTypeName(context, _selectedGroupType),
                  style: TextStyle(
                    fontSize: 16,
                    color: colorsTheme.textColorPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorsTheme.textColorSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            atomicLocale.groupFaceUrl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorsTheme.textColorPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AvatarSelector(
            avatarURLs: _groupAvatars,
            selectedAvatarURL: _selectedAvatarURL,
            onAvatarSelected: (url) {
              setState(() {
                _selectedAvatarURL = url;
              });
            },
            config: const AvatarSelectorConfig(
              scrollDirection: Axis.horizontal,
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: EdgeInsets.symmetric(horizontal: 4),
              height: 120,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMemberList() {
    if (widget.selectedMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${atomicLocale.groupMemberSelected} (${widget.selectedMembers.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorsTheme.textColorPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedMembers.length,
              itemBuilder: (context, index) {
                final member = widget.selectedMembers[index];
                final displayName = _getContactDisplayName(member);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Avatar.image(
                            name: displayName,
                            url: member.avatarURL,
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.selectedMembers.removeAt(index);
                                });
                              },
                              child: SvgPicture.asset(
                                'chat_assets/icon/close.svg',
                                width: 18,
                                height: 18,
                                package: 'tuikit_atomic_x',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 50,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorsTheme.textColorSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_isCreating) return;

    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      Toast.warning(context, atomicLocale.inputGroupName);
      return;
    }

    setState(() {
      _isCreating = true;
    });

    ContactListStore contactListStore = ContactListStore.create();
    final result = await contactListStore.createGroup(
        groupType: _selectedGroupType,
        groupName: groupName,
        groupID: _groupIdController.text.trim(),
        avatarURL: _selectedAvatarURL,
        memberList: widget.selectedMembers);
    if (result.isSuccess) {
      await Future.delayed(const Duration(milliseconds: 200));

      String loginUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
      int cmdValue = _selectedGroupType == GroupType.community.value ? 1 : 0;
      Map<String, dynamic> customMessageJson = {
        'version': 4,
        'cmd': cmdValue,
        'businessID': 'group_create',
        'opUser': loginUserID,
        'content': atomicLocale.createGroupTips,
      };

      String customData = ChatUtil.dictionary2JsonData(customMessageJson);

      final messageInfo = MessageInfo();
      messageInfo.messageType = MessageType.custom;
      MessageBody messageBody = MessageBody();
      messageBody.customMessage = CustomMessageInfo(data: customData);
      messageInfo.messageBody = messageBody;
      MessageInputStore messageInputStore =
          MessageInputStore.create(conversationID: 'group_${contactListStore.contactListState.createdGroupID}');
      final sendMessageResult = await messageInputStore.sendMessage(message: messageInfo);
      if (!sendMessageResult.isSuccess) {
        debugPrint(
            "send create group custom message, errorCode:${sendMessageResult.errorCode}, errorMessage:${sendMessageResult.errorMessage}");
      }
      if (widget.onGroupCreated != null) {
        widget.onGroupCreated!(contactListStore.contactListState.createdGroupID, groupName, _selectedAvatarURL);
      }
    } else {
      if (mounted) {
        Toast.error(context, 'Failed, errorCode: ${result.errorCode}, errorMessage:${result.errorMessage}');
        debugPrint('createGroup failed, errorCode: ${result.errorCode}, errorMessage:${result.errorMessage}');
      }
    }

    if (mounted) {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.bgColorOperate,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorOperate,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          atomicLocale.createGroupChat,
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorsTheme.buttonColorPrimaryDefault,
                      ),
                    ),
                  )
                : Text(
                    atomicLocale.create,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorsTheme.buttonColorPrimaryDefault,
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _groupNameController,
              hintText: atomicLocale.groupName,
            ),
            _buildTextField(
              controller: _groupIdController,
              hintText: atomicLocale.groupIDOption,
            ),
            _buildGroupTypeSelector(),
            Container(
              height: 1,
              color: colorsTheme.strokeColorPrimary,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _buildAvatarSection(),
            Container(
              height: 1,
              color: colorsTheme.strokeColorPrimary,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _buildSelectedMemberList(),
          ],
        ),
      ),
    );
  }
}
