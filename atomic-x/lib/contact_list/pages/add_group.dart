import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';

class AddGroup extends StatefulWidget {
  const AddGroup({super.key});

  @override
  State<AddGroup> createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  late ContactListStore _contactListStore;
  ContactInfo? _searchResult;
  bool _showJoinGroupDetail = false;

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _contactListStore = ContactListStore.create();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    atomicLocale = AtomicLocalizations.of(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verificationController.dispose();
    _contactListStore.dispose();
    super.dispose();
  }

  void _searchGroup() async {
    final groupId = _searchController.text.trim();
    if (groupId.isEmpty) return;

    setState(() {
      _searchResult = null;
      _showJoinGroupDetail = false;
    });

    final result = await _contactListStore.fetchGroupInfo(groupID: groupId);
    if (result.errorCode == 0) {
      setState(() {
        _searchResult = _contactListStore.contactListState.joinGroupInfo;
      });
    } else {
      if (!mounted) {
        return;
      }

      if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_INVALID_GROUPID.value) {
        Toast.error(context, atomicLocale.groupIDInvalid);
      } else {
        debugPrint('fetchGroupInfo failed, errorCode:${result.errorCode}, errorMessage:${result.errorMessage}');
      }
    }
  }

  void _onGroupCardTapped() {
    if (_searchResult == null) return;

    if (_searchResult!.isInGroup == true) {
      Toast.info(context, atomicLocale.alreadyInGroup);
    } else {
      setState(() {
        _showJoinGroupDetail = true;
      });
    }
  }

  void _sendJoinGroupRequest() async {
    if (_searchResult == null) return;

    try {
      final result = await _contactListStore.joinGroup(
        groupID: _searchResult!.contactID,
        message: _verificationController.text.trim(),
      );

      if (mounted) {
        if (result.errorCode == 0) {
          Toast.success(context, atomicLocale.joinedGroupSuccessfully);
          Navigator.pop(context);
        } else {
          if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_PERMISSION_DENY.value) {
            Toast.error(context, atomicLocale.addGroupPermissionDeny);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_ALLREADY_MEMBER.value) {
            Toast.error(context, atomicLocale.addGroupAlreadyMember);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_NOT_FOUND.value) {
            Toast.error(context, atomicLocale.addGroupNotFound);
          } else if (result.errorCode == TIMErrCode.ERR_SVR_GROUP_FULL_MEMBER_COUNT.value) {
            Toast.error(context, atomicLocale.addGroupFullMember);
          } else {
            Toast.error(context, result.errorMessage ?? '');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, atomicLocale.joinGroupFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showJoinGroupDetail ? atomicLocale.addGroup : atomicLocale.addGroup),
        backgroundColor: colorsTheme.bgColorOperate,
        elevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
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
                      hintText: atomicLocale.searchGroupID,
                      hintStyle: TextStyle(
                        color: colorsTheme.textColorTertiary,
                        fontSize: 16,
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
                      atomicLocale.search,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
          atomicLocale.searchGroupIDHint,
          style: TextStyle(
            color: colorsTheme.textColorTertiary,
            fontSize: 16,
          ),
        ),
      );
    }

    return _buildGroupCard(_searchResult!);
  }

  Widget _buildGroupCard(ContactInfo groupInfo) {
    final groupID = groupInfo.contactID;
    final groupName = groupInfo.title ?? '';
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ID: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorsTheme.textColorSecondary,
                          ),
                        ),
                        TextSpan(
                          text: groupID,
                          style: TextStyle(
                            fontSize: 14,
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

    final groupID = _searchResult!.contactID;
    final groupName = _searchResult!.title ?? '';
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorsTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID：$groupID',
                        style: TextStyle(
                          fontSize: 12,
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
              atomicLocale.fillInTheVerificationInformation,
              style: TextStyle(
                fontSize: 16,
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
              style: TextStyle(
                fontSize: 16,
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
                atomicLocale.send,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorsTheme.textColorLink),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
