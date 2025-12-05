import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';

class AddFriend extends StatefulWidget {
  final ContactInfo? contactInfo;

  const AddFriend({super.key, this.contactInfo});

  @override
  State<AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  late ContactListStore _contactListStore;
  ContactInfo? _searchResult;
  bool _showAddFriendDetail = false;

  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  @override
  void initState() {
    super.initState();
    _contactListStore = ContactListStore.create();
    if (widget.contactInfo != null) {
      _showAddFriendDetail = true;
    }
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
    _remarkController.dispose();
    _verificationController.dispose();
    _contactListStore.dispose();
    super.dispose();
  }

  void _searchUser() async {
    final userId = _searchController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _searchResult = null;
      _showAddFriendDetail = false;
    });

    final result = await _contactListStore.fetchUserInfo(userID: userId);
    if (result.errorCode == 0) {
      setState(() {
        _searchResult = _contactListStore.contactListState.addFriendInfo;
      });
    } else {
      if (mounted) {
        Toast.error(context, '${result.errorMessage}');
      }
    }
  }

  void _onUserCardTapped() {
    if (_searchResult == null) return;

    if (_searchResult!.isContact == true) {
      Toast.info(context, atomicLocale.alreadyFriend);
    } else {
      setState(() {
        _showAddFriendDetail = true;
        _remarkController.text = _searchResult?.title ?? '';
      });
    }
  }

  void _sendAddFriendRequest() async {
    if (widget.contactInfo == null && _searchResult == null) return;
    final result = await _contactListStore.addFriend(
      userID: widget.contactInfo != null ? widget.contactInfo!.contactID : _searchResult!.contactID,
      addWording: _verificationController.text.trim(),
    );

    if (mounted) {
      if (result.errorCode == 0) {
        Toast.success(context, atomicLocale.contactAddedSuccessfully);
        Navigator.pop(context);
      } else {
        if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_NEED_CONFIRM.value) {
          Toast.info(context, atomicLocale.waitAgreeFriend);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_DENY_ANY.value) {
          Toast.error(context, atomicLocale.forbidAddFriend);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_IN_PEER_BLACKLIST.value) {
          Toast.error(context, atomicLocale.setInBlacklist);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_IN_SELF_BLACKLIST.value) {
          Toast.error(context, atomicLocale.inBlacklist);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_PEER_FRIEND_LIMIT.value) {
          Toast.error(context, atomicLocale.otherFriendLimit);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_COUNT_LIMIT.value) {
          Toast.error(context, atomicLocale.friendLimit);
        } else {
          Toast.error(context, result.errorMessage ?? '');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showAddFriendDetail ? atomicLocale.addFriend : atomicLocale.addFriend),
        backgroundColor: colorsTheme.bgColorOperate,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () {
            if (_showAddFriendDetail && widget.contactInfo == null) {
              setState(() {
                _showAddFriendDetail = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: colorsTheme.bgColorOperate,
      body: _showAddFriendDetail ? _buildAddFriendDetail() : _buildSearchInterface(),
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
                      hintText: atomicLocale.userID,
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
                  onTap: _searchUser,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
          atomicLocale.searchUserID,
          style: TextStyle(
            color: colorsTheme.textColorTertiary,
            fontSize: 16,
          ),
        ),
      );
    }

    return _buildUserCard(_searchResult!);
  }

  Widget _buildUserCard(ContactInfo userInfo) {
    final userID = userInfo.contactID;
    final nickname = userInfo.title ?? '';
    final faceURL = userInfo.avatarURL;

    return InkWell(
      onTap: _onUserCardTapped,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar.image(
              name: nickname,
              url: faceURL,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nickname,
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
                          text: '${atomicLocale.userID}: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorsTheme.textColorSecondary,
                          ),
                        ),
                        TextSpan(
                          text: userID,
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

  Widget _buildAddFriendDetail() {
    if (widget.contactInfo == null && _searchResult == null) return const SizedBox();

    final userID = widget.contactInfo != null ? widget.contactInfo!.contactID : _searchResult!.contactID;
    final nickname = widget.contactInfo != null ? widget.contactInfo!.title ?? '' : _searchResult!.title ?? '';
    final faceURL = widget.contactInfo != null ? widget.contactInfo!.avatarURL : _searchResult!.avatarURL;

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
                  name: nickname,
                  url: faceURL,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorsTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${atomicLocale.userID}：$userID',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorsTheme.textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${atomicLocale.signature}：',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  atomicLocale.profileRemark,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorsTheme.textColorPrimary,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _remarkController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: atomicLocale.profileRemark,
                      hintStyle: TextStyle(color: colorsTheme.textColorTertiary, fontSize: 16),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: colorsTheme.textColorPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: colorsTheme.shadowColor,
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendAddFriendRequest,
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
