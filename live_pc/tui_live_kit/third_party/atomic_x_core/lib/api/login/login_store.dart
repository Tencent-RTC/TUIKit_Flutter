// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LoginStore @ AtomicXCore
// Function: Login related interfaces, managing user login, logout, user information settings and other operations.

// <docgen-keep-start>
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
// <docgen-keep-end>

/// Login status.
enum LoginStatus {
  /// Not logged in.
  unlogin(3),

  /// Logged in.
  logined(1);

  final int value;
  const LoginStatus(this.value);

  static LoginStatus fromValue(int value) {
    switch (value) {
      case 1:
        return LoginStatus.logined;
      case 3:
        return LoginStatus.unlogin;
      default:
        return LoginStatus.unlogin;
    }
  }
}

/// Friend verification type.
enum AllowType {
  /// Allow anyone.
  allowAny,

  /// Need confirmation.
  needConfirm,

  /// Deny anyone.
  denyAny,
}

/// Gender.
enum Gender {
  /// Unknown.
  unknown,

  /// Male.
  male,

  /// Female.
  female,
}

/// User profile.
///
/// User profile data structure, containing user ID, nickname, avatar, gender and other personal information.
///
/// ### User Profile Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [userID] | `String` | User ID |
/// | [nickname] | `String?` | Nickname |
/// | [avatarURL] | `String?` | Avatar URL |
/// | [selfSignature] | `String?` | Personal signature |
/// | [gender] | `Gender?` | Gender |
/// | [role] | `int?` | Role. This field has no business restrictions, so you can safely use any valid integer value. |
/// | [level] | `int?` | Level. This field has no business restrictions, so you can safely use any valid integer value. |
/// | [birthday] | `int?` | Birthday. This field has no business restrictions, so you can safely use any valid integer value. |
/// | [allowType] | `AllowType?` | Friend verification type |
/// | [customInfo] | `Map<String, String>?` | Custom information |
class UserProfile {
  /// User ID.
  final String userID;

  /// Nickname.
  final String? nickname;

  /// Avatar URL.
  final String? avatarURL;

  /// Personal signature.
  final String? selfSignature;

  /// Gender.
  final Gender? gender;

  /// Role. This field has no business restrictions, so you can safely use any valid integer value.
  final int? role;

  /// Level. This field has no business restrictions, so you can safely use any valid integer value.
  final int? level;

  /// Birthday. This field has no business restrictions, so you can safely use any valid integer value.
  final int? birthday;

  /// Friend verification type.
  final AllowType? allowType;

  /// Custom information.
  final Map<String, String>? customInfo;

  const UserProfile({
    this.userID = '',
    this.nickname,
    this.avatarURL,
    this.selfSignature,
    this.gender,
    this.role,
    this.level,
    this.birthday,
    this.allowType,
    this.customInfo,
  });
}

/// Login state.
///
/// Login state data structure, containing current login status and logged-in user information.
///
/// ### State Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [loginStatus] | `LoginStatus` | Login status |
/// | [loginUserInfo] | `UserProfile?` | Logged-in user information |
class LoginState {
  /// Login status.
  final LoginStatus loginStatus;

  /// Logged-in user information.
  final UserProfile? loginUserInfo;

  const LoginState({
    this.loginStatus = LoginStatus.unlogin,
    this.loginUserInfo,
  });
}

/// Login event.
enum LoginEvent {
  /// Current user kicked offline.
  kickedOffline,

  /// Login ticket expired.
  loginExpired,
}

/// Login related interfaces, managing user login, logout, user information settings and other operations.
///
/// `LoginStore` Login management class for handling user login, logout and user information management business logic.
/// `LoginStore` provides a complete set of login management APIs, including user login, logout, and personal information settings.
/// Through this class, you can manage user login status and user profiles.
///
/// ### Key Features
///
/// - **User Login**：Supports login using SDK application ID, user ID and user signature.
/// - **User Logout**：Supports user logout operation.
/// - **Personal Information Settings**：Supports setting user nickname, avatar, gender and other personal information.
///
/// > **Important**: Use [shared] singleton object to access the `LoginStore` instance.
///
/// > **Note**: Login status updates are delivered through [loginState] publisher. Subscribe to it to receive real-time updates about login status.
///
/// ### Login Operations Overview
///
/// | Operation | Method | Description |
/// |---------|------|-----------|
/// | Login | [login] | Login using SDK application ID user ID and user signature |
/// | Logout | [logout] | User logout |
/// | Set Info | [setSelfInfo] | Set user personal information |
/// | Push Config | [setCertificateID] | Set offline push certificate IDs |
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Singleton object.
///
/// ### Observing State
/// - [state] : Login state.
///
/// ### Events Handling
/// - [loginEventStream] : Login event stream
///
/// ### Login Operations
/// - [login] : Login.
/// - [logout] : Logout.
/// - [setSelfInfo] : Set personal information.
///
/// ### Push Configuration
/// - [setCertificateID] : Set offline push certificate IDs.
///
/// ## See Also
///
/// - [LoginState]
/// - [UserProfile]
/// - [LoginStatus]
/// - [Gender]
/// - [AllowType]
/// - [LoginEvent]
abstract class LoginStore extends ChangeNotifier {
  /// SDK application ID.
  int get sdkAppID;

  /// Login state.
  LoginState get loginState;

  /// Login event stream. It is recommended to listen to this stream before calling [login], so that you can receive login-related events in a timely manner.
  ///
  /// ### Usage Example
  ///
  /// ```dart
  /// import 'dart:async';
  ///
  /// StreamSubscription<LoginEvent>? subscription;
  ///
  /// subscription = LoginStore.shared.loginEventStream.listen((event) {
  ///   switch (event) {
  ///     case LoginEvent.kickedOffline:
  ///       // Current user has been kicked offline, you can prompt the user and navigate to the login page
  ///       break;
  ///     case LoginEvent.loginExpired:
  ///       // Login ticket has expired, you need to generate a new userSig and re-login
  ///       break;
  ///   }
  /// });
  ///
  /// // Remember to cancel the subscription when it is no longer needed
  /// // subscription?.cancel();
  /// ```
  Stream<LoginEvent> get loginEventStream;

  /// Singleton object
  static LoginStore get shared => LoginStoreImpl.instance;

  /// Login
  ///
  /// - [sdkAppID] : SDK application ID. Get this from [TRTC console](https://console.trtc.io/app).
  /// - [userID] : User ID. The recommended length limit is 32 bytes, and only uppercase and lowercase English letters (a-zA-Z), digits (0-9), underscores, and hyphens are allowed.
  /// - [userSig] : User signature. For the generation of userSig, please refer to the [Secure authentication with userSig](https://trtc.io/document/35166).
  Future<CompletionHandler> login({
    required int sdkAppID,
    required String userID,
    required String userSig,
  });

  /// Logout
  ///
  Future<CompletionHandler> logout();

  /// Set personal information
  ///
  /// - [userProfile] : User profile.
  Future<CompletionHandler> setSelfInfo({required UserProfile userInfo});

  /// Set offline push certificate IDs
  ///
  /// Pass each vendor's push certificate configuration as a `Map<String, String>`. The SDK will detect the current device brand, request the device token from the corresponding vendor and report it to the IM backend automatically.
  ///
  /// Can be called at any time. If invoked before login, the SDK caches the configuration and starts push registration automatically once login succeeds.
  ///
  /// Certificate IDs are obtained from the [IM Console](https://console.cloud.tencent.com/im) after uploading push certificates. The map keys must follow the strings in the table below; unknown keys are ignored, and a channel is not enabled when its value is missing.
  ///
  /// **Supported keys**
  ///
  /// | Key | Description |
  /// | --- | --- |
  /// | `huaweiCertificateId` | Huawei push certificate ID |
  /// | `xiaomiCertificateId` | Xiaomi push certificate ID |
  /// | `xiaomiAppId` | Xiaomi open platform AppId |
  /// | `xiaomiAppKey` | Xiaomi open platform AppKey |
  /// | `oppoCertificateId` | OPPO push certificate ID |
  /// | `oppoAppKey` | OPPO open platform AppKey |
  /// | `oppoAppSecret` | OPPO open platform AppSecret |
  /// | `vivoCertificateId` | vivo push certificate ID |
  /// | `honorCertificateId` | Honor push certificate ID |
  /// | `meizuCertificateId` | Meizu push certificate ID |
  /// | `meizuAppId` | Meizu open platform AppId |
  /// | `meizuAppKey` | Meizu open platform AppKey |
  /// | `fcmCertificateId` | FCM (Firebase) push certificate ID |
  ///
  /// - [config] : Vendor push certificate configuration. The keys are predefined strings (see the "Supported keys" table above); unknown keys are ignored, and a channel is not enabled when its value is missing.
  void setCertificateID(Map<String, String> config);
}
