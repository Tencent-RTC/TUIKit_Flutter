import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/components/localized_manager.dart';
import 'package:atomic_x_core_example/debug/generate_test_user_sig.dart';
import 'package:atomic_x_core_example/scenes/login/profile_setup_page.dart';
import 'package:atomic_x_core_example/scenes/feature_list/feature_list_page.dart';

/// Business scenario: user login page
///
/// Related APIs:
/// - `LoginStore.shared.login(sdkAppID:userID:userSig:)` -> `Future<CompletionHandler>`: SDK login
/// - `LoginStore.shared.loginState` - Login state (`LoginState`: `loginStatus`, `loginUserInfo`)
/// - `LoginStore` extends `ChangeNotifier` -> use `addListener` / `removeListener` to observe state changes
///
/// Only `User ID` needs to be entered. `UserSig` is generated locally and is used for debugging only.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // MARK: - Constants

  /// Cache key for the local user ID
  static const String _cachedUserIDKey = 'CachedLoginUserID';

  // MARK: - Properties

  final TextEditingController _userIDController = TextEditingController();
  bool _isLoading = false;

  /// Login state listener callback (`LoginStore` extends `ChangeNotifier`)
  late final VoidCallback _onLoginStateChanged;

  /// Previous login state (used to detect state changes)
  LoginStatus _lastLoginStatus = LoginStatus.unlogin;

  // MARK: - Lifecycle

  @override
  void initState() {
    super.initState();
    _setupBindings();
    _restoreCachedUserID();
  }

  @override
  void dispose() {
    LoginStore.shared.removeListener(_onLoginStateChanged);
    _userIDController.dispose();
    super.dispose();
  }

  // MARK: - Setup

  void _setupBindings() {
    // `LoginStore` extends `ChangeNotifier`, so use `addListener` to observe login state changes
    _onLoginStateChanged = () {
      if (!mounted) return;
      final currentStatus = LoginStore.shared.loginState.loginStatus;
      if (currentStatus != _lastLoginStatus) {
        _lastLoginStatus = currentStatus;
        _updateLoginStatus(currentStatus);
      }
    };
    LoginStore.shared.addListener(_onLoginStateChanged);
  }

  // MARK: - Actions

  void _switchLanguage() {
    LocalizedManager.shared.showLanguageSwitchAlert(context);
  }

  void _loginTapped() {
    FocusScope.of(context).unfocus();

    final userID = _userIDController.text.trim();
    if (userID.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _showAlert(title: l10n.commonError, message: l10n.loginErrorEmptyUserID);
      return;
    }

    _performLogin(userID: userID);
  }

  // MARK: - Login Logic

  Future<void> _performLogin({required String userID}) async {
    _setLoading(true);

    // Generate `UserSig` automatically
    final userSig = GenerateTestUserSig.genTestUserSig(identifier: userID);
    print('[Login] Generated UserSig: $userSig');

    final result = await LoginStore.shared.login(sdkAppID: SDKAPPID, userID: userID, userSig: userSig);

    if (!mounted) return;
    if (result.isSuccess) {
      // Login succeeded; cache the user ID for automatic filling on the next cold start
      _cacheUserID(userID);
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _setLoading(false);
        _checkProfileAndNavigate();
      });
    } else {
      _setLoading(false);
      _showToast(result.errorMessage ?? '');
    }
  }

  // MARK: - Status Handling

  void _updateLoginStatus(LoginStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case LoginStatus.unlogin:
        _showToast(l10n.loginStatusNotLoggedIn);
        break;
      case LoginStatus.logined:
        _showToast(l10n.loginStatusLoggedIn);
        break;
    }
  }

  // MARK: - Navigation

  /// After login succeeds, check whether the nickname is empty and decide whether to navigate to the profile setup page or the feature list
  void _checkProfileAndNavigate() {
    final userInfo = LoginStore.shared.loginState.loginUserInfo;
    final nickname = userInfo?.nickname ?? '';

    if (nickname.isEmpty) {
      // Nickname is empty -> navigate to the profile setup page
      Navigator.of(
        context,
      ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const ProfileSetupPage()), (route) => false);
    } else {
      // Nickname is already set -> go directly to the feature list
      _navigateToFeatureList();
    }
  }

  void _navigateToFeatureList() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const FeatureListPage()), (route) => false);
  }

  // MARK: - UI Helpers

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  void _showAlert({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.commonConfirm))],
        );
      },
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Restore the previously logged-in user ID from local cache and fill it into the input field automatically
  /// If no cache exists, generate a random user ID and cache it to avoid multiple devices using the same ID
  Future<void> _restoreCachedUserID() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUserID = prefs.getString(_cachedUserIDKey);

    if (cachedUserID != null && cachedUserID.isNotEmpty) {
      _userIDController.text = cachedUserID;
    } else {
      final randomUserID = _generateRandomUserID();
      _userIDController.text = randomUserID;
      await prefs.setString(_cachedUserIDKey, randomUserID);
    }
  }

  /// Cache the user ID locally
  Future<void> _cacheUserID(String userID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserIDKey, userID);
  }

  /// Generate a random numeric `User ID` (9 random digits)
  /// This ID is also used as the anchor's room ID
  String _generateRandomUserID() {
    final random = Random();
    final randomID = 100000000 + random.nextInt(900000000);
    return randomID.toString();
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          // Language switch button
          IconButton(icon: const Icon(Icons.language), onPressed: _switchLanguage),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Title
                Text(
                  l10n.loginTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  l10n.loginSubtitle,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // `User ID` input field
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _userIDController,
                    autocorrect: false,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: l10n.loginUserIDPlaceholder,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Debug tip
                Text(
                  l10n.loginDebugTip,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginTapped,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                            : Text(l10n.loginButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
