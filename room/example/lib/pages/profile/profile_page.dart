import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';

import '../../l10n/app_localizations.dart';
import '../../common/index.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _userNameController = TextEditingController();
  String _avatarURL = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  void _initData() {
    _userNameController.text = _getRandomUserName();
    _avatarURL = _getRandomAvatarURL();
    setState(() {});
  }

  String _getRandomUserName() {
    var index = Random().nextInt(Constants.userNameArray.length);
    var nameKey = Constants.userNameArray.elementAt(index);
    final localizations = AppLocalizations.of(context);
    switch (nameKey) {
      case 'custom_name_1':
        return localizations?.custom_name_1 ?? nameKey;
      case 'custom_name_2':
        return localizations?.custom_name_2 ?? nameKey;
      case 'custom_name_3':
        return localizations?.custom_name_3 ?? nameKey;
      case 'custom_name_4':
        return localizations?.custom_name_4 ?? nameKey;
      case 'custom_name_5':
        return localizations?.custom_name_5 ?? nameKey;
      case 'custom_name_6':
        return localizations?.custom_name_6 ?? nameKey;
      case 'custom_name_7':
        return localizations?.custom_name_7 ?? nameKey;
      case 'custom_name_8':
        return localizations?.custom_name_8 ?? nameKey;
      case 'custom_name_9':
        return localizations?.custom_name_9 ?? nameKey;
      case 'custom_name_10':
        return localizations?.custom_name_10 ?? nameKey;
      case 'custom_name_11':
        return localizations?.custom_name_11 ?? nameKey;
      case 'custom_name_12':
        return localizations?.custom_name_12 ?? nameKey;
      default:
        return nameKey;
    }
  }

  String _getRandomAvatarURL() {
    var index = Random().nextInt(Constants.userAvatarURLArray.length);
    return Constants.userAvatarURLArray.elementAt(index);
  }

  Future<void> _register() async {
    if (_userNameController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.userNameIsEmpty);
      return;
    }

    // Update user model
    final currentUser = UserService.instance.userModel.value;
    if (currentUser == null) {
      _showSnackBar('User session expired');
      return;
    }

    UserService.instance.userModel.value = UserModel(
      userId: currentUser.userId,
      userName: _userNameController.text,
      avatarURL: _avatarURL,
    );
    await UserService.instance.saveUserModel();

    // Set self info in TUIRoomEngine
    await TUIRoomEngine.setSelfInfo(_userNameController.text, _avatarURL);

    if (!mounted) return;

    // Navigate to home
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RoomHomeWidget()));
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            children: [
              const SizedBox(height: 68),
              SizedBox(width: 100, height: 100, child: CircleAvatar(backgroundImage: NetworkImage(_avatarURL))),
              const SizedBox(height: 30),
              TextField(
                style: Theme.of(context).textTheme.displayMedium,
                controller: _userNameController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.userNameInputHint,
                  hintStyle: const TextStyle(color: AppColors.textHintGrey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.btnBackgroundBlue),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.btnBackgroundBlue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.userNameTips)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  child: Text(AppLocalizations.of(context)!.register, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
