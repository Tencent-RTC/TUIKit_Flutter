// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   Log @ AtomicXCore
// Function: Dart 侧日志封装，通过 EngineBridge 调用 LoginModule.log 写入 TRTC 日志。

import 'dart:convert';

import '../../engine/engine_bridge.dart';

class Log {
  static const String _api = 'LoginModule.log';
  static const String _logKeyLevel = 'level';
  static const String _logKeyMessage = 'message';
  static const String _logKeyFile = 'file';
  static const String _logKeyLine = 'line';
  static const String _logKeyTag = 'tag';

  static const String _moduleAtomicXCoreCommon = 'AtomicXCore-Common';
  static const String _moduleAtomicXCoreCall = 'AtomicXCore-Call';
  static const String _moduleAtomicXCoreChat = 'AtomicXCore-Chat';
  static const String _moduleAtomicXCoreLive = 'AtomicXCore-Live';
  static const String _moduleAtomicXCoreRoom = 'AtomicXCore-Room';

  static const int _logLevelInfo = 0;
  static const int _logLevelWarning = 1;
  static const int _logLevelError = 2;

  final String _moduleName;
  final String _fileName;

  Log._(this._moduleName, this._fileName);

  static Log getCommonLog(String fileName) {
    return Log._(_moduleAtomicXCoreCommon, fileName);
  }

  static Log getCallLog(String fileName) {
    return Log._(_moduleAtomicXCoreCall, fileName);
  }

  static Log getChatLog(String fileName) {
    return Log._(_moduleAtomicXCoreChat, fileName);
  }

  static Log getLiveLog(String fileName) {
    return Log._(_moduleAtomicXCoreLive, fileName);
  }

  static Log getRoomLog(String fileName) {
    return Log._(_moduleAtomicXCoreRoom, fileName);
  }

  void info(String message) {
    _log(_moduleName, _fileName, _logLevelInfo, message);
  }

  void warn(String message) {
    _log(_moduleName, _fileName, _logLevelWarning, message);
  }

  void error(String message) {
    _log(_moduleName, _fileName, _logLevelError, message);
  }

  static void _log(String module, String file, int level, String message) {
    final Map<String, dynamic> params = {
      _logKeyLevel: level,
      _logKeyMessage: message,
      _logKeyFile: file,
      _logKeyLine: 0,
      _logKeyTag: module,
    };
    final jsonString = jsonEncode(params);
    EngineBridge.invoke(_api, jsonString);
  }
}
