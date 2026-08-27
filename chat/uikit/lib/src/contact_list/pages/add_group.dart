import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/api/group/group_store.dart' as group_api;
import 'package:flutter/material.dart' hide IconButton;
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import '../../common/language/gen/chat_localizations.dart';

class AddGroup extends StatefulWidget {
  const AddGroup({super.key});

  @override
  State<AddGroup> createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  final group_api.GroupStore _groupStore = group_api.GroupStore.shared;
  group_api.GroupInfo? _searchResult;
  bool _showJoinGroupDetail = false;

  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  void _searchGroup() async {
    final groupId = _searchController.text.trim();
    if (groupId.isEmpty) return;

    setState(() {
      _searchResult = null;
      _showJoinGroupDetail = false;
    });

    final result = await _groupStore.getGroupInfo(groupID: groupId);
    if (result.errorCode == 0 && result.groupInfo != null) {
      setState(() {
        _searchResult = result.groupInfo;
      });
    } else {
      if (!mounted) {
        return;
      }

      if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_INVALID_GROUPID.value) {
        Toast.error(context, chatLocale.groupIDInvalid);
      } else {
        debugPrint('getGroupInfo failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      }
    }
  }

  void _onGroupCardTapped() {
    if (_searchResult == null) return;

    // Note: isInGroup check is handled via getGroupInfo result
    // For now, we always show join detail since GroupInfo doesn't have isInGroup
    setState(() {
      _showJoinGroupDetail = true;
    });
  }

  void _sendJoinGroupRequest() async {
    if (_searchResult == null) return;

    try {
      final result = await _groupStore.joinGroup(
        groupID: _searchResult!.groupID,
        message: _verificationController.text.trim(),
      );

      if (mounted) {
        if (result.errorCode == 0) {
          Toast.success(context, chatLocale.joinedGroupSuccessfully);
          Navigator.pop(context);
        } else {
          if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_PERMISSION_DENY.value) {
            Toast.error(context, chatLocale.addGroupPermissionDeny);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_ALLREADY_MEMBER.value) {
            Toast.error(context, chatLocale.addGroupAlreadyMember);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_NOT_FOUND.value) {
            Toast.error(context, chatLocale.addGroupNotFound);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_FULL_MEMBER_COUNT.value) {
            Toast.error(context, chatLocale.addGroupFullMember);
          } else {
            Toast.error(context, result.errorMessage ?? '');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, chatLocale.joinGroupFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          chatLocale.joinGroup,
          style: FontScheme.caption1Medium.copyWith(color: colorsTheme.textColorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorsTheme.bgColorOperate,
        elevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () {
            if (_showJoinGroupDetail) {
              setState(() {
                _showJoinGroupDetail = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: colorsTheme.bgColorOperate,
      body: _showJoinGroupDetail ? _buildJoinGroupDetail() : _buildSearchInterface(),
    );
  }

  Widget _buildSearchInterface() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: colorsTheme.bgColorInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: colorsTheme.textColorPrimary),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: chatLocale.searchGroupID,
                      hintStyle: FontScheme.caption1Regular.copyWith(
                        color: colorsTheme.textColorTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _searchGroup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      chatLocale.search,
                      style: FontScheme.caption1Medium.copyWith(
                        color: colorsTheme.textColorLink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildSearchResult(),
        ),
      ],
    );
  }

  Widget _buildSearchResult() {
    if (_searchResult == null) {
      return Center(
        child: Text(
          chatLocale.searchGroupIDHint,
          style: FontScheme.caption1Regular.copyWith(
            color: colorsTheme.textColorTertiary,
          ),
        ),
      );
    }

    return _buildGroupCard(_searchResult!);
  }

  Widget _buildGroupCard(group_api.GroupInfo groupInfo) {
    final groupID = groupInfo.groupID;
    final groupName = groupInfo.groupName ?? '';
    final faceURL = groupInfo.avatarURL;

    return InkWell(
      onTap: _onGroupCardTapped,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar.image(
              name: groupName,
              url: faceURL,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    groupName,
                    style: FontScheme.caption1Medium.copyWith(
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ID: ',
                          style: FontScheme.caption2Regular.copyWith(
                            color: colorsTheme.textColorSecondary,
                          ),
                        ),
                        TextSpan(
                          text: groupID,
                          style: FontScheme.caption2Regular.copyWith(
                            color: colorsTheme.textColorLink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinGroupDetail() {
    if (_searchResult == null) return const SizedBox();

    final groupID = _searchResult!.groupID;
    final groupName = _searchResult!.groupName ?? '';
    final faceURL = _searchResult!.avatarURL;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Avatar.image(
                  name: groupName,
                  url: faceURL,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: FontScheme.body4Medium.copyWith(
                          color: colorsTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID：$groupID',
                        style: FontScheme.caption3Regular.copyWith(
                          color: colorsTheme.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              chatLocale.fillInTheVerificationInformation,
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 123,
            decoration: BoxDecoration(
              color: colorsTheme.bgColorInput,
            ),
            child: TextField(
              controller: _verificationController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '',
                hintStyle: TextStyle(color: colorsTheme.textColorTertiary),
                contentPadding: EdgeInsets.all(12),
              ),
              style: FontScheme.caption1Regular.copyWith(
                color: colorsTheme.textColorTertiary,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendJoinGroupRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorsTheme.bgColorInput,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                chatLocale.send,
                style: FontScheme.caption1Medium.copyWith(color: colorsTheme.textColorLink),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
