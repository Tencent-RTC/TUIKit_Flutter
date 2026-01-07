import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';

enum CallProtocolType {
  unknown,
  send,
  accept,
  reject,
  cancel,
  hangup,
  timeout,
  lineBusy,
  switchToAudio,
  switchToAudioConfirm
}

enum CallStreamMediaType { unknown, audio, video }

enum CallParticipantType { unknown, c2c, group }

enum CallParticipantRole { unknown, caller, callee }

enum CallMessageDirection { incoming, outcoming }

class CallingMessageDataProvider {
  bool _isExcludedFromLastMessage = false;
  bool _isExcludedFromUnreadCount = false;
  Map<String, dynamic> _jsonData = {};
  String _groupID = '';
  List<dynamic> _inviteeList = [];
  int _actionType = 0;

  CallProtocolType _protocolType = CallProtocolType.unknown;
  CallStreamMediaType _streamMediaType = CallStreamMediaType.unknown;
  CallParticipantType _participantType = CallParticipantType.unknown;
  CallParticipantRole _participantRole = CallParticipantRole.unknown;
  CallMessageDirection _direction = CallMessageDirection.outcoming;
  bool _excludeFromHistory = false;
  String _callerId = '';
  String _content = '';
  bool _isCallingSignal = false;

  CallProtocolType get protocolType => _protocolType;

  // 媒体类型
  CallStreamMediaType get streamMediaType => _streamMediaType;

  // 通话类型
  CallParticipantType get participantType => _participantType;

  // 用户角色
  CallParticipantRole get participantRole => _participantRole;

  // 上屏信息的方向信息
  CallMessageDirection get direction => _direction;

  // 是否需要上屏
  bool get excludeFromHistory => _excludeFromHistory;

  // 主角ID
  String get callerId => _callerId;

  // 上屏内容
  String get content => _content;

  // 是否Call信令
  bool get isCallingSignal => _isCallingSignal;

  late MessageInfo messageInfo;
  late AtomicLocalizations atomicLocale;

  CallingMessageDataProvider(this.messageInfo, BuildContext context) {
    atomicLocale = AtomicLocalizations.of(context);
    _isExcludedFromLastMessage = messageInfo.rawMessage?.isExcludedFromLastMessage ?? false;
    _isExcludedFromUnreadCount = messageInfo.rawMessage?.isExcludedFromUnreadCount ?? false;

    final customElem = messageInfo.rawMessage?.customElem;
    try {
      if (customElem?.data != null) {
        final customData = jsonDecode(customElem!.data!);
        _groupID = customData['groupID'];
        _inviteeList = customData['inviteeList'];
        _actionType = customData['actionType'];
        _jsonData = jsonDecode(customData['data']);
      }
    } catch (err) {
      return;
    }

    _setIsCallingSignal();
    _setProtocolType();
    _setStreamMediaType();
    _setParticipantType();
    _setCallerId();
    _setParticipantRole();
    _setDirection();
    _setExcludeFromHistory();
    _setContent();
  }

  _setIsCallingSignal() {
    final businessID = _jsonData['businessID'];
    if (businessID != null && (businessID == 'av_call' || businessID == 'rtc_call')) {
      _isCallingSignal = true;
    } else {
      _isCallingSignal = false;
    }
  }

  _setProtocolType() {
    switch (_actionType) {
      case 1:
        final data = _jsonData['data'];
        if (data != null) {
          final cmd = data['cmd'];
          if (cmd != null) {
            if (cmd == 'switchToAudio') {
              _protocolType = CallProtocolType.switchToAudio;
            } else if (cmd == 'hangup') {
              _protocolType = CallProtocolType.hangup;
            } else if (cmd == 'videoCall') {
              _protocolType = CallProtocolType.send;
            } else if (cmd == 'audioCall') {
              _protocolType = CallProtocolType.send;
            } else {
              _protocolType = CallProtocolType.unknown;
            }
          } else {
            _protocolType = CallProtocolType.unknown;
          }
        } else {
          final callEnd = _jsonData!['call_end'];
          if (callEnd != null) {
            _protocolType = CallProtocolType.hangup;
          } else {
            _protocolType = CallProtocolType.send;
          }
        }
        break;
      case 2:
        _protocolType = CallProtocolType.cancel;
        break;
      case 3:
        final data = _jsonData!['data'];
        if (data != null) {
          final cmd = data['cmd'];
          if (cmd != null) {
            if (cmd == 'switchToAudio') {
              _protocolType = CallProtocolType.switchToAudioConfirm;
            } else {
              _protocolType = CallProtocolType.accept;
            }
          } else {
            _protocolType = CallProtocolType.accept;
          }
        } else {
          _protocolType = CallProtocolType.accept;
        }
        break;
      case 4:
        if (_jsonData!['line_busy'] != null) {
          _protocolType = CallProtocolType.lineBusy;
        } else {
          _protocolType = CallProtocolType.reject;
        }
        break;
      case 5:
        _protocolType = CallProtocolType.timeout;
        break;
      default:
        _protocolType = CallProtocolType.unknown;
        break;
    }
  }

  _setStreamMediaType() {
    _streamMediaType = CallStreamMediaType.unknown;
    if (_protocolType == CallProtocolType.unknown) {
      _streamMediaType = CallStreamMediaType.unknown;
      return;
    }

    final callType = _jsonData!['call_type'];
    if (callType != null) {
      if (callType == 1) {
        _streamMediaType = CallStreamMediaType.audio;
      } else if (callType == 2) {
        _streamMediaType = CallStreamMediaType.video;
      }
    }

    if (_protocolType == CallProtocolType.send) {
      final data = _jsonData!['data'];
      if (data != null) {
        final cmd = data['cmd'];
        if (cmd != null) {
          if (cmd == 'audioCall') {
            _streamMediaType = CallStreamMediaType.audio;
          } else if (cmd == 'videoCall') {
            _streamMediaType = CallStreamMediaType.video;
          }
        }
      }
    } else if (_protocolType == CallProtocolType.switchToAudio ||
        _protocolType == CallProtocolType.switchToAudioConfirm) {
      _streamMediaType = CallStreamMediaType.video;
    }
  }

  _setParticipantType() {
    if (_protocolType == CallProtocolType.unknown) {
      _participantType = CallParticipantType.unknown;
      return;
    }

    if (_groupID.isNotEmpty) {
      _participantType = CallParticipantType.group;
    } else {
      _participantType = CallParticipantType.c2c;
    }
  }

  _setCallerId() async {
    if (_protocolType == CallProtocolType.unknown) {
      return;
    }

    final data = _jsonData!['data'];
    if (data != null) {
      final inviter = data['inviter'];
      if (inviter != null) {
        _callerId = inviter as String;
      }
    }

    if (_callerId.isEmpty) {
      _callerId = LoginStore.shared.loginState.loginUserInfo!.userID;
    }
  }

  _setParticipantRole() async {
    final loginUserId = LoginStore.shared.loginState.loginUserInfo?.userID;

    if (_callerId == loginUserId) {
      _participantRole = CallParticipantRole.caller;
    } else {
      _participantRole = CallParticipantRole.callee;
    }
  }

  _setDirection() {
    if (_participantRole == CallParticipantRole.caller) {
      _direction = CallMessageDirection.outcoming;
    } else {
      _direction = CallMessageDirection.incoming;
    }
  }

  _setExcludeFromHistory() {
    _excludeFromHistory =
        _protocolType != CallProtocolType.unknown && _isExcludedFromLastMessage && _isExcludedFromUnreadCount;
  }

  _setContent() {
    if (_excludeFromHistory) {
      _content = '';
      return;
    }

    bool isCaller = _participantRole == CallParticipantRole.caller;
    final showName = _getShowName();

    if (_participantType == CallParticipantType.c2c) {
      if (_protocolType == CallProtocolType.reject) {
        _content = isCaller ? atomicLocale.callRejectCaller : atomicLocale.callRejectCallee;
      } else if (_protocolType == CallProtocolType.cancel) {
        _content = isCaller ? atomicLocale.callCancelCaller : atomicLocale.callCancelCallee;
      } else if (_protocolType == CallProtocolType.hangup) {
        final time = _getShowTime(_jsonData['call_end']);
        _content = '${atomicLocale.stopCallTip}:$time';
      } else if (_protocolType == CallProtocolType.timeout) {
        _content = isCaller ? atomicLocale.callTimeoutCaller : atomicLocale.callTimeoutCallee;
      } else if (_protocolType == CallProtocolType.lineBusy) {
        _content = isCaller ? atomicLocale.callLineBusyCaller : atomicLocale.callLineBusyCallee;
      } else if (_protocolType == CallProtocolType.send) {
        _content = atomicLocale.startCall;
      } else if (_protocolType == CallProtocolType.accept) {
        _content = atomicLocale.acceptCall;
      } else if (_protocolType == CallProtocolType.switchToAudio) {
        _content = atomicLocale.callingSwitchToAudio;
      } else if (_protocolType == CallProtocolType.switchToAudioConfirm) {
        _content = atomicLocale.callingSwitchToAudioAccept;
      } else {
        _content = atomicLocale.unknownCall;
      }
    } else if (_participantType == CallParticipantType.group) {
      if (_protocolType == CallProtocolType.send) {
        _content = '"$showName" ${atomicLocale.groupCallSend}';
      } else if (_protocolType == CallProtocolType.cancel) {
        _content = atomicLocale.groupCallEnd;
      } else if (_protocolType == CallProtocolType.hangup) {
        _content = atomicLocale.groupCallEnd;
      } else if (_protocolType == CallProtocolType.timeout || _protocolType == CallProtocolType.lineBusy) {
        String inviteeNames = '';
        if (_participantType == CallParticipantType.group) {
          for (String invitee in _inviteeList) {
            inviteeNames = '$inviteeNames$invitee、';
          }
        }
        if (_protocolType == CallProtocolType.lineBusy) {
          _content = inviteeNames.substring(0, inviteeNames.length - 1) + atomicLocale.callLineBusyCallee;
        } else {
          _content = inviteeNames.substring(0, inviteeNames.length - 1) + atomicLocale.groupCallNoAnswer;
        }
      } else if (_protocolType == CallProtocolType.reject) {
        _content = '"$showName" ${atomicLocale.groupCallReject}';
      } else if (_protocolType == CallProtocolType.accept) {
        _content = '"$showName" ${atomicLocale.groupCallAccept}';
      } else if (_protocolType == CallProtocolType.switchToAudio) {
        _content = '"$showName" ${atomicLocale.callingSwitchToAudio}';
      } else if (_protocolType == CallProtocolType.switchToAudioConfirm) {
        _content = '"$showName" ${atomicLocale.groupCallConfirmSwitchToAudio}';
      } else {
        _content = atomicLocale.unknownCall;
      }
    } else {
      _content = atomicLocale.unknownCall;
    }
  }

  _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  _getShowTime(int seconds) {
    int secondsShow = seconds % 60;
    int minutesShow = seconds ~/ 60;
    return "${_twoDigits(minutesShow)}:${_twoDigits(secondsShow)}";
  }

  _getShowName() {
    if (messageInfo.rawMessage == null) {
      return '';
    }

    if (messageInfo.rawMessage!.nameCard?.isNotEmpty == true) {
      return messageInfo.rawMessage!.nameCard!;
    } else if (messageInfo.rawMessage!.friendRemark?.isNotEmpty == true) {
      return messageInfo.rawMessage!.friendRemark!;
    } else if (messageInfo.rawMessage!.nickName?.isNotEmpty == true) {
      return messageInfo.rawMessage!.nickName!;
    } else {
      return messageInfo.sender;
    }
  }
}
