// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LoginStoreImpl @ AtomicXCore
// Function: LoginStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../api/define.dart';
import '../../api/device/device_store.dart';
import '../../api/login/login_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/atomic_platform.dart';

// API keys
const String _kLogin = 'LoginModule.login';
const String _kLogout = 'LoginModule.logout';
const String _kSetSelfInfo = 'LoginModule.setSelfInfo';
const String _kSetCertificateID = 'PushModule.setCertificateID';

// Event keys (engine → Dart)
const String _kOnLoginStateChanged = 'LoginModule.onLoginStateChanged';
const String _kOnKickedOffline = 'LoginModule.onKickedOffline';
const String _kOnUserSigExpired = 'LoginModule.onUserSigExpired';

class LoginStoreImpl extends LoginStore {
  LoginStoreImpl._() {
    _registerEventHandlers();
  }

  static final LoginStoreImpl _instance = LoginStoreImpl._();

  static LoginStoreImpl get instance => _instance;

  LoginState _state = const LoginState();
  final StreamController<LoginEvent> _eventController = StreamController<LoginEvent>.broadcast();

  int _sdkAppID = 0;

  @override
  int get sdkAppID => _sdkAppID;

  @override
  LoginState get loginState => _state;

  @override
  Stream<LoginEvent> get loginEventStream => _eventController.stream;

  @override
  Future<CompletionHandler> login({
    required int sdkAppID,
    required String userID,
    required String userSig,
  }) async {
    _sdkAppID = sdkAppID;
    await TencentImSDKPlugin.v2TIMManager.initSDK(sdkAppID: sdkAppID, loglevel: LogLevelEnum.V2TIM_LOG_INFO);
    final paths = await _resolveIMPaths();
    final param = jsonEncode(<String, Object>{
      'sdkAppID': sdkAppID,
      'userID': userID,
      'userSig': userSig,
      'imInitPath': paths.initPath,
      'imLogPath': paths.logPath,
    });
    final r = await EngineBridge.invoke(_kLogin, param);
    if (AtomicPlatform.isOhos) {
      await const MethodChannel('atomic_engine').invokeMethod<void>('ensureNativeReady');
    }
    return r.toCompletionHandler();
  }

  Future<({String initPath, String logPath})> _resolveIMPaths() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    final String initPath = supportDir.path;

    String logPath = '$initPath/log/tencent/imsdk/';
    try {
      final Directory? externalDir = Platform.isAndroid ? await getExternalStorageDirectory() : null;
      if (externalDir != null) {
        logPath = '${externalDir.path}/log/tencent/imsdk/';
      }
    } catch (_) {}
    return (initPath: initPath, logPath: logPath);
  }

  @override
  Future<CompletionHandler> logout() {
    return EngineBridge.invoke(_kLogout, '{}').then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setSelfInfo({required UserProfile userInfo}) {
    final Map<String, Object> paramMap = <String, Object>{};
    if (userInfo.nickname != null) {
      paramMap['nickname'] = userInfo.nickname!;
    }
    if (userInfo.avatarURL != null) {
      paramMap['avatarURL'] = userInfo.avatarURL!;
    }
    if (userInfo.selfSignature != null) {
      paramMap['selfSignature'] = userInfo.selfSignature!;
    }
    if (userInfo.gender != null) {
      paramMap['gender'] = userInfo.gender!.index;
    }
    if (userInfo.role != null) {
      paramMap['role'] = userInfo.role!;
    }
    if (userInfo.level != null) {
      paramMap['level'] = userInfo.level!;
    }
    if (userInfo.birthday != null) {
      paramMap['birthday'] = userInfo.birthday!;
    }
    if (userInfo.allowType != null) {
      paramMap['allowType'] = userInfo.allowType!.index;
    }
    if (userInfo.customInfo != null) {
      final Map<String, String> encoded = <String, String>{};
      userInfo.customInfo!.forEach((String key, String value) {
        encoded[key] = base64Encode(utf8.encode(value));
      });
      paramMap['customInfo'] = encoded;
    }
    final param = jsonEncode(paramMap);
    return EngineBridge.invoke(_kSetSelfInfo, param).then((r) => r.toCompletionHandler());
  }

  @override
  void setCertificateID(Map<String, String> config) {
    final param = jsonEncode(config);
    unawaited(EngineBridge.invoke(_kSetCertificateID, param));
  }

  // MARK: - Event handlers (engine → Dart)

  void _registerEventHandlers() {
    EngineBridge.subscribe(_kOnLoginStateChanged, _handleLoginStateChanged);
    EngineBridge.subscribe(_kOnKickedOffline, (_, __) => _handleKickedOffline());
    EngineBridge.subscribe(_kOnUserSigExpired, (_, __) => _handleUserSigExpired());
  }

  void _handleLoginStateChanged(String id, String json) {
    final dict = _parseJSON(json);
    if (dict == null) return;

    final statusRaw = dict['loginStatus'];
    final status = statusRaw is int ? LoginStatus.fromValue(statusRaw) : LoginStatus.unlogin;

    UserProfile? userInfo;
    final userInfoJson = dict['loginUserInfo'];
    if (userInfoJson is Map<String, dynamic>) {
      userInfo = _decodeUserProfile(userInfoJson);
    }

    if (_state.loginStatus != status || userInfo != null) {
      _state = LoginState(
        loginStatus: status,
        loginUserInfo: userInfo ?? _state.loginUserInfo,
      );
      notifyListeners();
    }
  }

  void _handleKickedOffline() {
    _cleanupOnLogout();
    if (_state.loginStatus != LoginStatus.unlogin) {
      _state = const LoginState(loginStatus: LoginStatus.unlogin);
      notifyListeners();
    }
    _eventController.add(LoginEvent.kickedOffline);
  }

  void _handleUserSigExpired() {
    _cleanupOnLogout();
    if (_state.loginStatus != LoginStatus.unlogin) {
      _state = const LoginState(loginStatus: LoginStatus.unlogin);
      notifyListeners();
    }
    _eventController.add(LoginEvent.loginExpired);
  }

  void _cleanupOnLogout() {
    // Aligns with HarmonyOS: reset DeviceStore state after logout / kicked / expired.
    // CallStore state is pushed empty by native after logout, no explicit reset needed.
    DeviceStore.shared.reset();
  }

  // MARK: - JSON helpers

  static Map<String, dynamic>? _parseJSON(String json) {
    if (json.isEmpty) return null;
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }

  static UserProfile _decodeUserProfile(Map<String, dynamic> dict) {
    return UserProfile(
      userID: (dict['userID'] as String?) ?? '',
      nickname: dict['nickname'] as String?,
      avatarURL: dict['avatarURL'] as String?,
      selfSignature: dict['selfSignature'] as String?,
      gender: dict['gender'] is int
          ? (dict['gender'] as int == 1
              ? Gender.male
              : dict['gender'] as int == 2
                  ? Gender.female
                  : Gender.unknown)
          : null,
      role: dict['role'] as int?,
      level: dict['level'] as int?,
      birthday: dict['birthday'] as int?,
      allowType: dict['allowType'] is int
          ? (dict['allowType'] as int == 0 ? AllowType.allowAny : AllowType.needConfirm)
          : null,
      customInfo: (dict['customInfo'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
    );
  }
}
