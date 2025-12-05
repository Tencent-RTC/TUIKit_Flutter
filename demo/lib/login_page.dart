import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_cloud_chat_push/tencent_cloud_chat_push.dart';
import 'package:uikit_next/pages/home_page.dart';
import 'package:uikit_next/signature/GenerateUserSig.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

const int SDKAPPID = 0;
const String SECRETKEY = "";
const int EXPIRE_TIME = 604800; // 7 day = 7 x 24 x 60 x 60 = 604800

class LoginInfoState extends ChangeNotifier {
  bool isLoggedIn = false;
  bool isLoggingIn = false;
  String currentUserID = "";
  String? loginError;
  bool isTestEnvironment = false;

  static final LoginInfoState _instance = LoginInfoState._internal();

  factory LoginInfoState() => _instance;

  LoginInfoState._internal() {
    _loadTestEnvironmentConfig();
    isLoggedIn = LoginStore.shared.loginState.loginStatus == LoginStatus.logined;
    if (isLoggedIn && LoginStore.shared.loginState.loginUserInfo != null) {
      currentUserID = LoginStore.shared.loginState.loginUserInfo!.userID;
    }
  }

  Future<void> _loadTestEnvironmentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    isTestEnvironment = prefs.getBool("testEnvironment") ?? false;
    notifyListeners();
  }

  Future<bool> login(String userID) async {
    isLoggingIn = true;
    loginError = null;
    notifyListeners();

    final userSig = GenerateDevUsersigForTest(
      sdkappid: SDKAPPID,
      key: SECRETKEY,
    ).genSig(
      userID: userID,
      expireTime: EXPIRE_TIME,
    );

    TUICallKit.instance.login(SDKAPPID, userID, userSig);
    final result = await LoginStore.shared.login(
      sdkAppID: SDKAPPID,
      userID: userID,
      userSig: userSig,
    );
    if (result.errorCode == 0) {
      _saveLoginToken(userID, userSig);
      _initPush();
      TUICallKit.instance.enableFloatWindow(true);
      isLoggedIn = true;
      currentUserID = userID;
      isLoggingIn = false;
      notifyListeners();
      return true;
    } else {
      loginError = "login failed: ${result.errorCode}, ${result.errorMessage}";
      isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    if (CallParticipantStore.shared.state.selfInfo.value.status == CallParticipantStatus.accept) {
      await CallStore.shared.hangup();
    }
    final result = await LoginStore.shared.logout();
    TUICallKit.instance.logout();
    if (result.errorCode == 0) {
      _removeLoginToken();
      isLoggedIn = false;
      currentUserID = "";
      notifyListeners();
      return true;
    } else {
      debugPrint("logout failed: ${result.errorCode}, ${result.errorMessage}");
      return false;
    }
  }

  Future<void> _saveLoginToken(String userID, String userSig) async {
    Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
    SharedPreferences prefs = await prefs0;
    prefs.setString(LoginScreen.DEV_LOGIN_USER_ID, userID);
    prefs.setString(LoginScreen.DEV_LOGIN_USER_SIG, userSig);
    prefs.setInt("sdkAppId", SDKAPPID);
  }

  Future<void> _removeLoginToken() async {
    Future<SharedPreferences> prefs0 = SharedPreferences.getInstance();
    SharedPreferences prefs = await prefs0;
    prefs.remove(LoginScreen.DEV_LOGIN_USER_ID);
    prefs.remove(LoginScreen.DEV_LOGIN_USER_SIG);
    return;
  }

  void _initPush() async {
    final TencentCloudChatPush tencentCloudChatPush = TencentCloudChatPush();
    int apnsCertificateID =  29064;
    if (kReleaseMode) {
      apnsCertificateID =  32321;
    }

    tencentCloudChatPush.registerPush(
      onNotificationClicked: _onNotificationClicked,
      apnsCertificateID: apnsCertificateID,
    );
  }

  void _onNotificationClicked({required String ext, String? userID, String? groupID}) {
    debugPrint("_onNotificationClicked: $ext, userID: $userID, groupID: $groupID");
  }
}

class LoginScreen extends StatefulWidget {
  static const String DEV_LOGIN_USER_ID = "devLoginUserID";
  static const String DEV_LOGIN_USER_SIG = "devUserSig";

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIDController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userIDController.dispose();

    super.dispose();
  }

  void _login(BuildContext context) {
    final loginState = Provider.of<LoginInfoState>(context, listen: false);

    if (_userIDController.text.isEmpty) {
      return;
    }

    loginState.login(_userIDController.text).then((success) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AtomicLocalizations atomicLocale = AtomicLocalizations.of(context);
    final loginState = Provider.of<LoginInfoState>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "UIKit Next",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _userIDController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "User ID",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (loginState.loginError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      loginState.loginError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loginState.isLoggingIn ? null : () => _login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loginState.isLoggingIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              atomicLocale.login,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "SDKAPPID: $SDKAPPID",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
