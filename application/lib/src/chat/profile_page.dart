import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide AlertDialog;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'choose_avatar_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late LoginStore _loginStore;

  @override
  void initState() {
    super.initState();
    _loginStore = LoginStore.shared;
  }

  void showNicknameEditDialog(BuildContext context, ChatLocalizations chatLocale, String? currentNickname) async {
    final result = await BottomInputSheet.show(
      context,
      title: chatLocale.setNickname,
      hintText: '',
      initialText: currentNickname ?? '',
    );

    if (result != null) {
      _updateUserInfo(nickname: result);
    }
  }

  void showSignatureEditDialog(BuildContext context, ChatLocalizations chatLocale, String? currentSignature) async {
    final result = await BottomInputSheet.show(
      context,
      title: chatLocale.setSignature,
      hintText: '',
      initialText: currentSignature ?? '',
    );

    if (result != null) {
      _updateUserInfo(selfSignature: result);
    }
  }

  void showGenderSelector(BuildContext context, ChatLocalizations chatLocale, Gender? currentGender) {
    final List<Map<String, dynamic>> options = [
      {"label": chatLocale.male, "value": Gender.male},
      {"label": chatLocale.female, "value": Gender.female},
    ];

    ActionSheet.show(
      context,
      actions: options
          .map((option) => ActionSheetItem(
                title: option["label"],
                isDestructive: currentGender == option["value"],
                onTap: () => _updateUserInfo(gender: option["value"]),
              ))
          .toList(),
    );
  }

  void showBirthdayPicker(BuildContext context, int? currentBirthday) {
    DateTime initialDate = DateTime.now();
    if (currentBirthday != null) {
      // Convert YYYYMMDD format to DateTime
      String birthdayStr = currentBirthday.toString();
      if (birthdayStr.length == 8) {
        try {
          int year = int.parse(birthdayStr.substring(0, 4));
          int month = int.parse(birthdayStr.substring(4, 6));
          int day = int.parse(birthdayStr.substring(6, 8));
          initialDate = DateTime(year, month, day);
        } catch (e) {
          // If parsing fails, use current date
          initialDate = DateTime.now();
        }
      }
    }

    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        // Convert to YYYYMMDD format
        String year = selectedDate.year.toString();
        String month = selectedDate.month.toString().padLeft(2, '0');
        String day = selectedDate.day.toString().padLeft(2, '0');
        int birthdayInt = int.parse("$year$month$day");
        _updateUserInfo(birthday: birthdayInt);
      }
    });
  }

  Future<void> _updateUserInfo({
    String? nickname,
    String? avatarURL,
    String? selfSignature,
    Gender? gender,
    int? birthday,
  }) async {
    final currentUser = _loginStore.loginState.loginUserInfo;

    if (currentUser != null) {
      final updatedProfile = UserProfile(
        userID: currentUser.userID,
        nickname: nickname,
        avatarURL: avatarURL,
        selfSignature: selfSignature,
        gender: gender,
        birthday: birthday ?? currentUser.birthday,
      );

      await _loginStore.setSelfInfo(userInfo: updatedProfile);
    }
  }

  String getGenderName(ChatLocalizations chatLocale, Gender? gender) {
    switch (gender) {
      case Gender.male:
        return chatLocale.male;
      case Gender.female:
        return chatLocale.female;
      default:
        return chatLocale.unknown;
    }
  }

  String getBirthdayString(ChatLocalizations chatLocale, int? birthday) {
    if (birthday == null) return chatLocale.unknown;

    // Convert YYYYMMDD format (e.g., 20241101) to date string
    String birthdayStr = birthday.toString();
    if (birthdayStr.length != 8) return chatLocale.unknown;

    String year = birthdayStr.substring(0, 4);
    String month = birthdayStr.substring(4, 6);
    String day = birthdayStr.substring(6, 8);

    return "$year-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _loginStore,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ChatLocalizations.of(context).contactInfo),
          centerTitle: false,
        ),
        body: Consumer<LoginStore>(
          builder: (context, loginStore, child) {
            return _buildBody(context, loginStore);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LoginStore loginStore) {
    ChatLocalizations chatLocale = ChatLocalizations.of(context);
    final currentUser = loginStore.loginState.loginUserInfo;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChooseAvatarPage(
                        currentAvatarUrl: currentUser?.avatarURL ?? '',
                      ),
                    ),
                  ).then((selectedAvatar) {
                    if (selectedAvatar != null) {
                      _updateUserInfo(avatarURL: selectedAvatar);
                    }
                  });
                },
                child: Avatar.image(
                  url: currentUser?.avatarURL,
                  name: currentUser?.nickname ?? currentUser?.userID,
                  size: AvatarSize.xxl,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showNicknameEditDialog(context, chatLocale, currentUser?.nickname);
                },
                child: Text(
                  currentUser?.nickname ?? currentUser?.userID ?? '',
                  style: FontScheme.body4Regular.copyWith(
                    color: BaseThemeProvider.colorsOf(context).textColorPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                SettingWidgets.buildSettingGroup(
                  context: context,
                  children: [
                    SettingWidgets.buildInfoRow(
                      context: context,
                      title: chatLocale.userID,
                      value: currentUser?.userID ?? "",
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.signature,
                      value: currentUser?.selfSignature ?? "",
                      onTap: () {
                        showSignatureEditDialog(context, chatLocale, currentUser?.selfSignature);
                      },
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.gender,
                      value: getGenderName(chatLocale, currentUser?.gender),
                      onTap: () {
                        showGenderSelector(context, chatLocale, currentUser?.gender);
                      },
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.birthday,
                      value: getBirthdayString(chatLocale, currentUser?.birthday),
                      onTap: () {
                        showBirthdayPicker(context, currentUser?.birthday);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
