import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/api/group/group_store.dart' as group_api;
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/svg.dart';

import '../../chat_setting/widgets/avatar_selector.dart';
import '../widgets/group_type_selector.dart';
import '../../common/language/gen/chat_localizations.dart';

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
  late ChatLocalizations chatLocale;

  String _selectedAvatarURL = '';
  GroupType _selectedGroupType = GroupType.work;
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
    chatLocale = ChatLocalizations.of(context);
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

  /// Cap default group name length so it doesn't overflow the input field.
  static const int _defaultGroupNameMaxLength = 30;

  void _initGroupName() {
    if (widget.selectedMembers.isEmpty) return;

    final buffer = StringBuffer();
    for (int i = 0; i < widget.selectedMembers.length; i++) {
      final name = _getContactDisplayName(widget.selectedMembers[i]);
      if (name.isEmpty) continue;
      final segment = buffer.isEmpty ? name : '、$name';
      if (buffer.length + segment.length > _defaultGroupNameMaxLength) {
        buffer.write('...');
        break;
      }
      buffer.write(segment);
    }
    if (buffer.isNotEmpty) {
      _groupNameController.text = buffer.toString();
    }
  }

  String _getContactDisplayName(ContactInfo contact) {
    return (contact.nickname?.isNotEmpty == true ? contact.nickname! : contact.userID);
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
        style: FontScheme.caption1Regular.copyWith(
          color: colorsTheme.textColorPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: FontScheme.caption1Regular.copyWith(
            color: colorsTheme.textColorSecondary,
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
        final result = await Navigator.push<GroupType>(
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
              chatLocale.groupType,
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  getGroupTypeName(context, _selectedGroupType),
                  style: FontScheme.caption1Regular.copyWith(
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
            chatLocale.groupFaceUrl,
            style: FontScheme.caption1Medium.copyWith(
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
            '${chatLocale.groupMemberSelected} (${widget.selectedMembers.length})',
            style: FontScheme.caption1Medium.copyWith(
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
                                package: 'tencent_chat_uikit',
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
                          style: FontScheme.caption3Regular.copyWith(
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
      Toast.warning(context, chatLocale.inputGroupName);
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final groupStore = group_api.GroupStore.shared;
    final result = await groupStore.createGroup(
        params: group_api.GroupCreateParams(
      groupType: _selectedGroupType,
      groupName: groupName,
      groupID: _groupIdController.text.trim().isNotEmpty ? _groupIdController.text.trim() : null,
      avatarURL: _selectedAvatarURL,
      memberList: widget.selectedMembers.map((c) => c.userID).toList(),
    ));
    if (result.isSuccess) {
      await Future.delayed(const Duration(milliseconds: 200));

      String loginUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
      int cmdValue = _selectedGroupType == GroupType.community ? 1 : 0;
      Map<String, dynamic> customMessageJson = {
        'version': 4,
        'cmd': cmdValue,
        'businessID': 'group_create',
        'opUser': loginUserID,
        'content': chatLocale.createGroupTips,
      };

      String customData = ChatUtil.dictionary2JsonData(customMessageJson);

      MessageInputStore messageInputStore =
          MessageInputStore.create(conversationID: 'group_${result.groupID}');
      final sendMessageResult = await messageInputStore.sendMessage(
        payload: CustomSendMessagePayload(customData: customData),
      );
      if (!sendMessageResult.isSuccess) {
        debugPrint(
            "send create group custom message, errorCode:${sendMessageResult.errorCode}, errorMessage:${sendMessageResult.errorMessage}");
      }
      if (widget.onGroupCreated != null) {
        widget.onGroupCreated!(result.groupID, groupName, _selectedAvatarURL);
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
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          chatLocale.createGroupChat,
          style: FontScheme.caption1Medium.copyWith(
            color: colorsTheme.textColorPrimary,
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
                    chatLocale.create,
                    style: FontScheme.caption1Medium.copyWith(
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
              hintText: chatLocale.groupName,
            ),
            _buildTextField(
              controller: _groupIdController,
              hintText: chatLocale.groupIDOption,
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
