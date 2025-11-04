import 'package:flutter/cupertino.dart';
import 'package:atomic_x/atomicx.dart';
import 'package:tencent_calls_uikit/src/tui_call_kit_impl.dart';
import 'bridge/bootloader/bootloader.dart';

abstract class TUICallKit {
  static final TUICallKit _instance = TUICallKitImpl.instance;
  static TUICallKit get instance => _instance;
  static NavigatorObserver navigatorObserver = Bootloader.instance;

  /// login TUICallKit
  ///
  /// @param sdkAppId      sdkAppId
  /// @param userId        userId
  /// @param userSig       userSig
  Future<TUIResult> login(int sdkAppId, String userId, String userSig) async {
    // TODO: implement login
    throw UnimplementedError();
  }

  /// logout TUICallKit
  ///
  Future<void> logout() async {
    // TODO: implement logout
    throw UnimplementedError();
  }

  /// Set user profile
  ///
  /// @param nickname User name, which can contain up to 500 bytes
  /// @param avatar   User profile photo URL, which can contain up to 500 bytes
  ///                 For example: https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png
  /// @param callback Set the result callback
  Future<TUIResult> setSelfInfo(String nickname, String avatar) async {
    // TODO: implement setSelfInfo
    throw UnimplementedError();
  }

  /// Make a call
  ///
  /// @param userIdList    List of userId
  /// @param callMediaType Call type
  /// @param params        Call extension parameters
  Future<TUIResult> calls(List<String> userIdList, TUICallMediaType callMediaType,
      [TUICallParams? params]) async {
    // TODO: implement calls
    throw UnimplementedError();
  }

  /// Join a current call
  ///
  /// @param callId        Unique ID for this call
  Future<void> join(String callId) async {
    // TODO: implement join
    throw UnimplementedError();
  }

  /// Set the ringtone (preferably shorter than 30s)
  ///
  /// First introduce the ringtone resource into the project
  /// Then set the resource as a ringtone
  ///
  /// @param filePath Callee ringtone path
  Future<void> setCallingBell(String assetName) async {
    // TODO: implement setCallingBell
    throw UnimplementedError();
  }

  ///Enable the mute mode (the callee doesn't ring)
  Future<void> enableMuteMode(bool enable) async {
    // TODO: implement enableMuteMode
    throw UnimplementedError();
  }

  ///Enable the floating window
  Future<void> enableFloatWindow(bool enable) async {
    // TODO: implement enableFloatWindow
    throw UnimplementedError();
  }

  Future<void> enableVirtualBackground(bool enable) async {
    // TODO: implement enableVirtualBackground
    throw UnimplementedError();
  }

  void enableIncomingBanner(bool enable) ;

  /// Call experimental interface
  ///
  /// @param jsonObject
  Future<void> callExperimentalAPI(String json) async {
    // TODO: implement callExperimentalAPI
    throw UnimplementedError();
  }
}
