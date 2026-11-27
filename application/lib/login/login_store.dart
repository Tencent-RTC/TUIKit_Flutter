import 'dart:async';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../debug/generate_test_user_sig.dart';

/// Only request orchestration and login preferences live here; the SDK owns the profile and login state.
class AppLoginStore extends ChangeNotifier {
  bool busy = false;
  bool sessionReady = false;
  bool pusherVisible = false;
  StreamSubscription<LoginEvent>? _accountEvents;
  String _expectedUser = '';
  bool autoLogin = false;
  String cachedUser = '';
  String? error;
  int _request = 0;
  bool _disposed = false;
  final _sdk = LoginStore.shared;
  Timer? _profileTimeout;
  final ready = Completer<void>();
  AppLoginStore() {
    _sdk.addListener(_changed);
    _accountEvents = _sdk.loginEventStream.listen((event) {
      if (_disposed) return;
      ++_request;
      _profileTimeout?.cancel();
      busy = false;
      sessionReady = false;
      if (event == LoginEvent.loginExpired) pusherVisible = false;
      notifyListeners();
    });
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    autoLogin = prefs.getBool('app.autoLogin') ?? false;
    cachedUser = prefs.getString('app.userId') ?? '';
    ready.complete();
    notifyListeners();
    if (autoLogin && cachedUser.isNotEmpty) unawaited(login(cachedUser));
  }

  void _changed() {
    if (_disposed) return;
    if (_sdk.loginState.loginStatus == LoginStatus.unlogin) sessionReady = false;
    if (busy &&
        _sdk.loginState.loginStatus == LoginStatus.logined &&
        _sdk.loginState.loginUserInfo?.userID == _expectedUser) {
      sessionReady = true;
      busy = false;
      _profileTimeout?.cancel();
    }
    notifyListeners();
  }

  Future<void> setAutomatic(bool value) async {
    autoLogin = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app.autoLogin', value);
  }

  Future<void> login(String input) async {
    if (busy || _disposed) return;
    final user = input.trim();
    if (user.isEmpty) {
      error = 'emptyUser';
      notifyListeners();
      return;
    }
    const appId = GenerateTestUserSig.sdkAppId;
    final sig = GenerateTestUserSig.genTestUserSig(identifier: user);
    if (appId <= 0 || sig.isEmpty) {
      error = 'missingConfig';
      notifyListeners();
      return;
    }
    busy = true;
    sessionReady = false;
    _expectedUser = user;
    error = null;
    final token = ++_request;
    notifyListeners();
    try {
      final result = await _sdk.login(sdkAppID: appId, userID: user, userSig: sig);
      if (_disposed || token != _request) return;
      if (!result.isSuccess) {
        busy = false;
        error = result.errorMessage ?? '${result.errorCode}';
        notifyListeners();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || token != _request) return;
      cachedUser = user;
      await prefs.setString('app.userId', user);
      if (_disposed || token != _request) return;
      if (_sdk.loginState.loginUserInfo?.userID == _expectedUser) {
        _changed();
      } else {
        _profileTimeout = Timer(const Duration(seconds: 5), () {
          if (!_disposed && token == _request) {
            ++_request;
            busy = false;
            error = 'profileTimeout';
            notifyListeners();
          }
        });
      }
    } catch (e) {
      if (!_disposed && token == _request) {
        busy = false;
        error = e.toString();
        notifyListeners();
      }
    }
  }

  void setPusherVisible(bool visible) {
    if (_disposed || pusherVisible == visible) return;
    pusherVisible = visible;
    notifyListeners();
  }

  Future<void> logout() async {
    ++_request;
    _profileTimeout?.cancel();
    busy = false;
    sessionReady = false;
    autoLogin = false;
    cachedUser = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app.autoLogin', false);
    await prefs.remove('app.userId');
    try {
      await _sdk.logout();
    } catch (failure) {
      if (!_disposed) {
        error = '$failure';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    _profileTimeout?.cancel();
    _sdk.removeListener(_changed);
    unawaited(_accountEvents?.cancel());
    super.dispose();
  }
}
