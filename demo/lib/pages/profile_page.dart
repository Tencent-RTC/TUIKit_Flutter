import 'package:tuikit_atomic_x/atomicx.dart' hide AlertDialog;
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

  void showNicknameEditDialog(BuildContext context, AtomicLocalizations atomicLocale, String? currentNickname) async {
    final result = await BottomInputSheet.show(
      context,
      title: atomicLocale.setNickname,
      hintText: '',
      initialText: currentNickname ?? '',
    );

    if (result != null) {
      _updateUserInfo(nickname: result);
    }
  }

  void showSignatureEditDialog(BuildContext context, AtomicLocalizations atomicLocale, String? currentSignature) async {
    final result = await BottomInputSheet.show(
      context,
      title: atomicLocale.setSignature,
      hintText: '',
      initialText: currentSignature ?? '',
    );

    if (result != null) {
      _updateUserInfo(selfSignature: result);
    }
  }

  void showGenderSelector(BuildContext context, AtomicLocalizations atomicLocale, Gender? currentGender) {
    final List<Map<String, dynamic>> options = [
      {"label": atomicLocale.male, "value": Gender.male},
      {"label": atomicLocale.female, "value": Gender.female},
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
      // 不需要手动调用 setState，Consumer 会自动重建 UI
    }
  }

  String getGenderName(AtomicLocalizations atomicLocale, Gender? gender) {
    switch (gender) {
      case Gender.male:
        return atomicLocale.male;
      case Gender.female:
        return atomicLocale.female;
      default:
        return atomicLocale.unknown;
    }
  }

  String getBirthdayString(AtomicLocalizations atomicLocale, int? birthday) {
    if (birthday == null) return atomicLocale.unknown;

    // Convert YYYYMMDD format (e.g., 20241101) to date string
    String birthdayStr = birthday.toString();
    if (birthdayStr.length != 8) return atomicLocale.unknown;

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
          title: Text(AtomicLocalizations.of(context).contactInfo),
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
    AtomicLocalizations atomicLocale = AtomicLocalizations.of(context);
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
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: currentUser?.avatarURL != null && currentUser!.avatarURL!.isNotEmpty
                      ? NetworkImage(currentUser.avatarURL!)
                      : null,
                  child: currentUser?.avatarURL == null || currentUser!.avatarURL!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showNicknameEditDialog(context, atomicLocale, currentUser?.nickname);
                },
                child: Text(
                  currentUser?.nickname ?? currentUser?.userID ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                      title: atomicLocale.userID,
                      value: currentUser?.userID ?? "",
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.signature,
                      value: currentUser?.selfSignature ?? "",
                      onTap: () {
                        showSignatureEditDialog(context, atomicLocale, currentUser?.selfSignature);
                      },
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.gender,
                      value: getGenderName(atomicLocale, currentUser?.gender),
                      onTap: () {
                        showGenderSelector(context, atomicLocale, currentUser?.gender);
                      },
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.birthday,
                      value: getBirthdayString(atomicLocale, currentUser?.birthday),
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
