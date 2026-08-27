import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import '../../common/language/gen/chat_localizations.dart';

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
  final ContactStore _contactStore = ContactStore.shared;
  ContactInfo? _searchResult;
  bool _showAddFriendDetail = false;

  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  @override
  void initState() {
    super.initState();
    if (widget.contactInfo != null) {
      _showAddFriendDetail = true;
    }
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
    _remarkController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  void _searchUser() async {
    final userId = _searchController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _searchResult = null;
      _showAddFriendDetail = false;
    });

    final handler = await _contactStore.getContactInfo(userIDList: [userId]);
    if (handler.isSuccess && handler.contactInfoList.isNotEmpty) {
      setState(() {
        _searchResult = handler.contactInfoList.first;
      });
    } else {
      if (mounted) {
        Toast.error(context, '${handler.errorMessage}');
      }
    }
  }

  void _onUserCardTapped() {
    if (_searchResult == null) return;

    if (_searchResult!.isFriend == true) {
      Toast.info(context, chatLocale.alreadyFriend);
    } else {
      setState(() {
        _showAddFriendDetail = true;
        _remarkController.text = _searchResult?.nickname ?? '';
      });
    }
  }

  void _sendAddFriendRequest() async {
    if (widget.contactInfo == null && _searchResult == null) return;
    final result = await _contactStore.addFriend(
      userID: widget.contactInfo != null ? widget.contactInfo!.userID : _searchResult!.userID,
      addWording: _verificationController.text.trim(),
    );

    if (mounted) {
      if (result.errorCode == 0) {
        Toast.success(context, chatLocale.contactAddedSuccessfully);
        Navigator.pop(context);
      } else {
        if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_NEED_CONFIRM.value) {
          Toast.info(context, chatLocale.waitAgreeFriend);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_ALLOW_TYPE_DENY_ANY.value) {
          Toast.error(context, chatLocale.forbidAddFriend);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_IN_PEER_BLACKLIST.value) {
          Toast.error(context, chatLocale.setInBlacklist);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_IN_SELF_BLACKLIST.value) {
          Toast.error(context, chatLocale.inBlacklist);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_PEER_FRIEND_LIMIT.value) {
          Toast.error(context, chatLocale.otherFriendLimit);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_COUNT_LIMIT.value) {
          Toast.error(context, chatLocale.friendLimit);
        } else if (result.errorCode == TIMErrCode.ERR_SVR_FRIENDSHIP_INVALID_SDKAPPID.value) {
          Toast.error(context, chatLocale.userNotExist);
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
        title: Text(
          chatLocale.addContact,
          style: FontScheme.caption1Medium.copyWith(color: colorsTheme.textColorPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorsTheme.bgColorOperate,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
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
                      hintText: chatLocale.userID,
                      hintStyle: FontScheme.caption1Regular.copyWith(
                        color: colorsTheme.textColorTertiary,
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
          chatLocale.searchUserID,
          style: FontScheme.caption1Regular.copyWith(
            color: colorsTheme.textColorTertiary,
          ),
        ),
      );
    }

    return _buildUserCard(_searchResult!);
  }

  Widget _buildUserCard(ContactInfo userInfo) {
    final userID = userInfo.userID;
    final nickname = userInfo.nickname ?? '';
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
                    style: FontScheme.caption1Medium.copyWith(
                      color: colorsTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${chatLocale.userID}: ',
                          style: FontScheme.caption2Regular.copyWith(
                            color: colorsTheme.textColorSecondary,
                          ),
                        ),
                        TextSpan(
                          text: userID,
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

  Widget _buildAddFriendDetail() {
    if (widget.contactInfo == null && _searchResult == null) return const SizedBox();

    final userID = widget.contactInfo != null ? widget.contactInfo!.userID : _searchResult!.userID;
    final nickname = widget.contactInfo != null ? widget.contactInfo!.nickname ?? '' : _searchResult!.nickname ?? '';
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
                        style: FontScheme.body4Medium.copyWith(
                          color: colorsTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${chatLocale.userID}：$userID',
                        style: FontScheme.caption3Regular.copyWith(
                          color: colorsTheme.textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${chatLocale.signature}：',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  chatLocale.profileRemark,
                  style: FontScheme.caption1Regular.copyWith(
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
                      hintText: chatLocale.profileRemark,
                      hintStyle: FontScheme.caption1Regular.copyWith(color: colorsTheme.textColorTertiary),
                    ),
                    style: FontScheme.caption1Regular.copyWith(
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
