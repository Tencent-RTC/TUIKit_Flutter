import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_conference_uikit/tencent_conference_uikit.dart';

import '../../l10n/app_localizations.dart';
import '../../common/index.dart';
import '../../debug/generate_test_user_sig.dart';
import '../profile/profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _initServices();
    await _autoLogin();
  }

  Future<void> _initServices() async {
    await StorageService.instance.init();
  }

  Future<void> _autoLogin() async {
    if (UserService.instance.haveLoggedInBefore()) {
      await UserService.instance.loadUserModel();
      final userId = UserService.instance.userModel.value?.userId;
      if (userId != null && userId.isNotEmpty) {
        await _loginRoomAndIm(userId, haveLoggedInBefore: true);
      }
    }
  }

  Future<void> _login() async {
    if (_userIdController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.userIdIsEmpty);
      return;
    }
    await _loginRoomAndIm(_userIdController.text);
  }

  Future<void> _loginRoomAndIm(String userId, {bool haveLoggedInBefore = false}) async {
    setState(() => _isLoading = true);

    try {
      final userSig = GenerateTestUserSig.genTestSig(userId);

      var loginResult = await LoginStore.shared.login(
        sdkAppID: GenerateTestUserSig.sdkAppId,
        userID: userId,
        userSig: userSig,
      );

      if (!loginResult.isSuccess) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        _showSnackBar(
          AppLocalizations.of(context)!.loginError(loginResult.errorCode.toString(), loginResult.errorMessage ?? ''),
        );
        return;
      }

      UserService.instance.userModel.value = UserModel(userId: userId, userName: '', avatarURL: '');

      final shouldSetProfile = !haveLoggedInBefore && await _shouldSetProfile();
      final targetPage = shouldSetProfile ? const ProfilePage() : const RoomHomeWidget();

      setState(() => _isLoading = false);
      _focusNode.unfocus();

      if (!mounted) return;

      Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Login failed: $e');
    }
  }

  Future<bool> _shouldSetProfile() async {
    final loginUserInfo = LoginStore.shared.loginState.loginUserInfo;
    if (loginUserInfo == null) return true;

    if (loginUserInfo.nickname?.isEmpty == true || loginUserInfo.avatarURL?.isEmpty == true) {
      return true;
    }

    await UserService.instance.saveUserModel();
    return false;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMainContent(),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Center(child: Image.asset(AppImages.tencentCloud))),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                TextField(
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.displayMedium,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.userIdInputHint,
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
                  controller: _userIdController,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: Text(AppLocalizations.of(context)!.login, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
