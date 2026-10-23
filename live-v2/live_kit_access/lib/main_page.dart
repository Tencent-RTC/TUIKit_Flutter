/// 对应 iOS `LiveKitAccess/LiveKitAccessCoordinator.swift`。
///
/// 负责登录调度：先展示登录页，登录成功后展示直播列表页；
/// 同时监听被踢下线和票据过期事件，回到登录页并提示。不持有任何直播业务状态。
library;

import 'dart:async';
import 'dart:math';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import 'generate_test_user_sig.dart';
import 'effect_license.dart';
import 'water_fall_page.dart';
import 'login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() =>
      _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const String _cachedUserIDKey = 'livekit.access.loginUserID';

  static const Duration _profileWaitTimeout = Duration(seconds: 5);

  static const int _demoLoginSuccess = 1302;
  static const int _demoClickLive = 1119;

  static const List<String> _avatarURLs = <String>[
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar2.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar3.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar4.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar5.png',
  ];

  static const List<String> _nicknamesZh = <String>[
    '马丁',
    '伊尔凡',
    '罗莎娜',
    '富兰克林',
    '玛琳',
  ];

  static const List<String> _nicknamesEn = <String>[
    'Martijn',
    'irfan',
    'Rosanna',
    'Franklyn',
    'Maren',
  ];

  /// 登录页默认用户 ID：优先取本地缓存，无缓存时生成 7 位随机值。
  String _loginUserID = '';
  bool _isUserIDReady = false;

  bool _isLogined = false;
  bool _isLoading = false;
  String? _toastMessage;
  int _toastToken = 0;
  int _loginOperationID = 0;
  StreamSubscription<LoginEvent>? _loginEventSubscription;

  @override
  void initState() {
    super.initState();
    _observeLoginEvents();
    final LoginStore loginStore = LoginStore.shared;
    if (loginStore.loginState.loginStatus == LoginStatus.logined) {
      _loginUserID =
          loginStore.loginState.loginUserInfo?.userID ?? _loginUserID;
      _isUserIDReady = true;
      _isLogined = true;
      if (_loginUserID.isNotEmpty) {
        unawaited(_saveUserID(_loginUserID));
      }
    } else {
      _loadUserID();
    }
  }

  Future<void> _loadUserID() async {
    String userID = _generateUserID();
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String? cached = preferences.getString(_cachedUserIDKey);
      if (cached != null && cached.isNotEmpty) {
        userID = cached;
      } else {
        await preferences.setString(_cachedUserIDKey, userID);
      }
    } on Object {
      // 本地缓存不可用时仍允许使用本次生成值登录，不扩大为登录阻断。
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _loginUserID = userID;
      _isUserIDReady = true;
    });
  }

  String _generateUserID() {
    final Random random = Random();
    return (1000000 + random.nextInt(9000000)).toString();
  }

  Future<void> _saveUserID(String userID) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      await preferences.setString(_cachedUserIDKey, userID);
    } on Object {
      // 持久化失败不改变 iOS 入口既有的登录与错误提示语义。
    }
  }

  @override
  void dispose() {
    _loginEventSubscription?.cancel();
    super.dispose();
  }

  void _observeLoginEvents() {
    _loginEventSubscription =
        LoginStore.shared.loginEventStream.listen((LoginEvent event) {
      switch (event) {
        case LoginEvent.kickedOffline:
          _showLogin('当前账号已在其他设备登录');
        case LoginEvent.loginExpired:
          _showLogin('登录票据已过期，请更新代码中的 UserSig');
      }
    });
  }

  Future<void> _login(String userID) async {
    final int operationID = ++_loginOperationID;
    setState(() {
      _loginUserID = userID;
    });
    await _saveUserID(userID);
    if (!mounted || operationID != _loginOperationID) {
      return;
    }

    final String userSig = GenerateTestUserSig.genTestUserSig(userID);
    if (GenerateTestUserSig.sdkAppID <= 0 ||
        userID.isEmpty ||
        userSig.isEmpty) {
      _showToast('请先填写 generate_test_user_sig.dart 中的 SDKAppID 和 SECRETKEY');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    LiveListStore.shared;
    final CompletionHandler handler = await LoginStore.shared.login(
      sdkAppID: GenerateTestUserSig.sdkAppID,
      userID: userID,
      userSig: userSig,
    );
    if (!mounted || operationID != _loginOperationID) {
      return;
    }
    if (!handler.isSuccess) {
      setState(() {
        _isLoading = false;
      });
      _showToast(
          'Login failed: ${handler.errorCode} ${handler.errorMessage ?? ''}');
      return;
    }
    // 首次启动可能尚未获得联网许可；登录成功后重新提交特效授权。
    unawaited(initializeEffectLicense());
    reportAtomicMetrics(_demoLoginSuccess);
    await _ensureSelfInfo(userID, operationID);
  }

  /// 引擎在登录成功后才异步补拉 IM 资料，登录回调里读不到，因此先等 `loginUserInfo`，
  /// 再决定是否补全，与 Android/iOS 入口保持一致。
  Future<void> _ensureSelfInfo(String userID, int operationID) async {
    final UserProfile? loginUserInfo = await _waitForLoginUserInfo();
    if (!mounted || operationID != _loginOperationID) {
      return;
    }
    final String nickname = loginUserInfo?.nickname ?? '';
    final String avatarURL = loginUserInfo?.avatarURL ?? '';
    if (nickname.isEmpty || avatarURL.isEmpty) {
      await _setSelfInfo(
        userID,
        operationID,
        needsNickname: nickname.isEmpty,
        needsAvatarURL: avatarURL.isEmpty,
      );
      return;
    }
    reportAtomicMetrics(_demoClickLive);
    setState(() {
      _isLoading = false;
      _isLogined = true;
    });
  }

  /// 等待有界：资料迟迟不到时不能把用户卡在 loading 上，超时按“资料未知”返回当前值，
  /// 由调用方走补全分支。
  Future<UserProfile?> _waitForLoginUserInfo() async {
    final LoginStore loginStore = LoginStore.shared;
    bool isReady(UserProfile? profile) =>
        profile != null && profile.userID.isNotEmpty;
    if (isReady(loginStore.loginState.loginUserInfo)) {
      return loginStore.loginState.loginUserInfo;
    }
    final Completer<UserProfile?> completer = Completer<UserProfile?>();
    void onStateChanged() {
      if (isReady(loginStore.loginState.loginUserInfo) &&
          !completer.isCompleted) {
        completer.complete(loginStore.loginState.loginUserInfo);
      }
    }

    loginStore.addListener(onStateChanged);
    try {
      return await completer.future.timeout(
        _profileWaitTimeout,
        onTimeout: () => loginStore.loginState.loginUserInfo,
      );
    } finally {
      loginStore.removeListener(onStateChanged);
    }
  }

  Future<void> _setSelfInfo(
    String userID,
    int operationID, {
    required bool needsNickname,
    required bool needsAvatarURL,
  }) async {
    final Random random = Random();
    final List<String> nicknames =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'zh'
            ? _nicknamesZh
            : _nicknamesEn;
    await LoginStore.shared.setSelfInfo(
      userInfo: UserProfile(
        userID: userID,
        nickname:
            needsNickname ? nicknames[random.nextInt(nicknames.length)] : null,
        avatarURL: needsAvatarURL
            ? _avatarURLs[random.nextInt(_avatarURLs.length)]
            : null,
      ),
    );
    if (!mounted || operationID != _loginOperationID) {
      return;
    }
    reportAtomicMetrics(_demoClickLive);
    setState(() {
      _isLoading = false;
      _isLogined = true;
    });
  }

  /// 对应 iOS `showLogin(message:)`：回到登录页并提示原因。
  void _showLogin(String message) {
    if (!mounted) {
      return;
    }
    _loginOperationID++;
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    setState(() {
      _isLogined = false;
      _isLoading = false;
    });
    _showToast(message);
  }

  void _showToast(String message) {
    setState(() {
      _toastMessage = message;
      _toastToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLogined) {
      return const WaterfallPage();
    }
    if (!_isUserIDReady) {
      return const Scaffold(backgroundColor: Color(0xFFEAF1FB));
    }
    return LoginPage(
      initialUserID: _loginUserID,
      isLoading: _isLoading,
      toastMessage: _toastMessage,
      toastToken: _toastToken,
      onLogin: (String userID) => _login(userID).ignore(),
    );
  }
}
