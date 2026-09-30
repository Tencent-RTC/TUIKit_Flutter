// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   CallStoreImpl @ AtomicXCore
// Function: CallStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

part of 'package:atomic_x_core/api/call/call_store.dart';

class _CallStateImpl implements CallState {
  @override
  final ValueNotifier<CallInfo> activeCall = ValueNotifier<CallInfo>(CallInfo._());

  @override
  final ValueNotifier<List<CallInfo>> recentCalls = ValueNotifier<List<CallInfo>>(const <CallInfo>[]);

  @override
  final ValueNotifier<String> cursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<CallParticipantInfo> selfInfo = ValueNotifier<CallParticipantInfo>(CallParticipantInfo._());

  @override
  final ValueNotifier<List<CallParticipantInfo>> allParticipants = ValueNotifier<List<CallParticipantInfo>>([]);

  @override
  final ValueNotifier<Map<String, int>> speakerVolumes = ValueNotifier<Map<String, int>>(const <String, int>{});

  @override
  final ValueNotifier<Map<String, NetworkQuality>> networkQualities = ValueNotifier<Map<String, NetworkQuality>>({});

  @override
  final ValueNotifier<double> zoom = ValueNotifier<double>(1.0);
}

// API keys
const String _kCalls = 'CallModule.calls';
const String _kAccept = 'CallModule.accept';
const String _kReject = 'CallModule.reject';
const String _kHangup = 'CallModule.hangup';
const String _kJoin = 'CallModule.join';
const String _kInvite = 'CallModule.invite';
const String _kQueryRecentCalls = 'CallModule.queryRecentCalls';
const String _kDeleteRecentCalls = 'CallModule.deleteRecentCalls';
const String _kCallExperimentalAPI = 'CallModule.callExperimentalAPI';
const String _kCreateModule = 'CallModule.createModule';

// Event keys
const String _kOnStateChanged = 'CallModule.stateChanged';
const String _kOnCallEvent = 'CallModule.event';

class _CallStoreImpl extends CallStore {
  _CallStoreImpl() {
    EngineBridge.subscribe(_kOnStateChanged, _onStateChanged);
    EngineBridge.subscribe(_kOnCallEvent, _onCallEvent);
    unawaited(EngineBridge.invoke(_kCreateModule, '{}'));
  }

  final _CallStateImpl _state = _CallStateImpl();
  final Set<CallEventListener> _listeners = <CallEventListener>{};

  @override
  CallState get state => _state;

  @override
  Future<CompletionHandler> calls(
    List<String> participantIds,
    CallMediaType mediaType,
    CallParams? params,
  ) {
    final paramsMap = <String, Object>{
      'roomId': params?.roomId ?? '',
      'timeout': params?.timeout ?? 30,
      'userData': params?.userData ?? '',
      'chatGroupId': params?.chatGroupId ?? '',
      'isEphemeralCall': params?.isEphemeralCall ?? false,
      'cloudRecordPolicy': (params?.cloudRecordPolicy ?? CloudRecordPolicy.followConsoleConfig).index,
      'offlinePushTitle': _resolveOfflinePushTitle(params),
      'offlinePushDesc': _resolveOfflinePushDesc(params),
    };
    final param = jsonEncode(<String, Object>{
      'participantIds': participantIds,
      'mediaType': mediaType.value,
      'params': paramsMap,
    });
    return EngineBridge.invoke(_kCalls, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> accept() {
    return EngineBridge.invoke(_kAccept, '{}').then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> reject() {
    return EngineBridge.invoke(_kReject, '{}').then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> hangup() {
    return EngineBridge.invoke(_kHangup, '{}').then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> join(String callId) {
    StoreFactory.shared.beforeEnterRoom(callId, SceneType.call);
    final param = jsonEncode(<String, Object>{'callId': callId});
    return EngineBridge.invoke(_kJoin, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> invite(List<String> participantIds, CallParams? params) {
    final paramsMap = <String, Object>{
      'roomId': params?.roomId ?? '',
      'timeout': params?.timeout ?? 30,
      'userData': params?.userData ?? '',
      'chatGroupId': params?.chatGroupId ?? '',
      'isEphemeralCall': params?.isEphemeralCall ?? false,
      'cloudRecordPolicy': (params?.cloudRecordPolicy ?? CloudRecordPolicy.followConsoleConfig).index,
      'offlinePushTitle': _resolveOfflinePushTitle(params),
      'offlinePushDesc': _resolveOfflinePushDesc(params),
    };
    final param = jsonEncode(<String, Object>{
      'participantIds': participantIds,
      'params': paramsMap,
    });
    return EngineBridge.invoke(_kInvite, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> queryRecentCalls(String cursor, int count) {
    final resultType = cursor.isEmpty ? 0 : (int.tryParse(cursor) ?? 0);
    final param = jsonEncode(<String, Object>{
      'resultType': resultType,
      'count': count,
    });
    return EngineBridge.invoke(_kQueryRecentCalls, param).then((r) {
      if (r.code == 0) {
        final records = _decodeRecentCalls(r.data);
        _state.recentCalls.value = records;
      }
      return r.toCompletionHandler();
    });
  }

  @override
  Future<CompletionHandler> deleteRecentCalls(List<String> callIdList) {
    final param = jsonEncode(<String, Object>{'callIdList': callIdList});
    return EngineBridge.invoke(_kDeleteRecentCalls, param).then((r) {
      if (r.code == 0) {
        if (callIdList.isEmpty) {
          _state.recentCalls.value = const <CallInfo>[];
        } else {
          _state.recentCalls.value = _state.recentCalls.value.where((c) => !callIdList.contains(c.callId)).toList();
        }
      }
      return r.toCompletionHandler();
    });
  }

  @override
  void addListener(CallEventListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(CallEventListener listener) {
    _listeners.remove(listener);
  }

  @override
  Future<void> callExperimentalAPI(Map<String, dynamic> jsonMap, {ExperimentalAPICallback? callback}) async {
    final String eventName;
    final String param;
    final api = jsonMap['api'];
    if (jsonMap.length == 2 && jsonMap.containsKey('api') && jsonMap.containsKey('params') && api is String) {
      eventName = api;
      final params = jsonMap['params'];
      param = params == null ? '{}' : (params is String ? params : jsonEncode(params));
    } else {
      eventName = _kCallExperimentalAPI;
      param = jsonEncode(jsonMap);
    }
    final result = await EngineBridge.invoke(eventName, param);
    callback?.call(result.code, result.message ?? '', result.data);
  }

  @override
  SubscriptionToken subscribeExperimentalEvent(String event, ExperimentalEventCallback callback) {
    return EngineBridge.subscribe(event, (id, json) => callback(id, json));
  }

  @override
  void unsubscribeExperimentalEvent(SubscriptionToken token) {
    EngineBridge.unsubscribe(token);
  }

  // MARK: - Passive event handlers

  void _onStateChanged(String id, String jsonData) {
    final dynamic parsed = jsonDecode(jsonData);
    if (parsed is! Map<String, dynamic>) return;

    final callInfo = parsed['callInfo'];
    if (callInfo is Map<String, dynamic>) {
      _state.activeCall.value = _decodeCallInfo(callInfo);
    }

    final selfInfo = parsed['selfInfo'];
    if (selfInfo is Map<String, dynamic>) {
      _state.selfInfo.value = _decodeParticipantInfo(selfInfo);
    }

    final participants = parsed['allParticipants'];
    if (participants is List) {
      _state.allParticipants.value =
          participants.whereType<Map<String, dynamic>>().map(_decodeParticipantInfo).toList();
    }

    final volumes = parsed['speakerVolumes'];
    if (volumes is Map<String, dynamic>) {
      final Map<String, int> result = <String, int>{};
      for (final entry in volumes.entries) {
        final v = _decodeInt(entry.value);
        if (v != 0 || entry.value is int) {
          result[entry.key] = v;
        }
      }
      _state.speakerVolumes.value = result;
    }

    final qualities = parsed['networkQualities'];
    if (qualities is Map<String, dynamic>) {
      final Map<String, NetworkQuality> result = <String, NetworkQuality>{};
      for (final entry in qualities.entries) {
        final raw = _decodeInt(entry.value);
        if (raw != 0 || entry.value is int) {
          result[entry.key] = NetworkQuality.values.firstWhere(
            (q) => q.value == raw,
            orElse: () => NetworkQuality.unknown,
          );
        }
      }
      _state.networkQualities.value = result;
    }
  }

  void _onCallEvent(String id, String jsonData) {
    final dynamic parsed = jsonDecode(jsonData);
    if (parsed is! Map<String, dynamic>) return;
    final type = parsed['type'] as String?;
    if (type == null) return;

    final callId = parsed['callId'] as String? ?? '';
    final rawMediaType = _decodeInt(parsed['mediaType']);
    final mediaType = _decodeMediaTypeFromRaw(rawMediaType) ?? CallMediaType.audio;
    final userData = parsed['userData'] as String? ?? '';
    final userId = parsed['userId'] as String? ?? '';
    final rawReason = _decodeInt(parsed['reason']);
    final reason = CallEndReason.values.firstWhere(
      (r) => r.value == rawReason,
      orElse: () => CallEndReason.unknown,
    );

    switch (type) {
      case 'onCallStarted':
        StoreFactory.shared.beforeEnterRoom(callId, SceneType.call);
        for (final listener in _listeners) {
          listener.onCallStarted?.call(callId, mediaType);
        }
        break;
      case 'onCallReceived':
        StoreFactory.shared.beforeEnterRoom(callId, SceneType.call);
        for (final listener in _listeners) {
          listener.onCallReceived?.call(callId, mediaType, userData);
        }
        break;
      case 'onCallEnded':
        StoreFactory.shared.didLeaveRoom(callId);
        for (final listener in _listeners) {
          listener.onCallEnded?.call(callId, mediaType, reason, userId);
        }
        break;
    }
  }

  // MARK: - Offline push helpers

  String _resolveOfflinePushTitle(CallParams? params) {
    final explicit = params?.offlinePushTitle ?? '';
    if (explicit.isNotEmpty) return explicit;
    final userInfo = LoginStore.shared.loginState.loginUserInfo;
    return userInfo?.nickname ?? userInfo?.userID ?? '';
  }

  String _resolveOfflinePushDesc(CallParams? params) {
    final explicit = params?.offlinePushDescription ?? '';
    if (explicit.isNotEmpty) return explicit;
    final isChinese = PlatformDispatcher.instance.locale.languageCode.startsWith('zh');
    return isChinese ? '您有新的来电' : 'You have a new call.';
  }

  // MARK: - JSON decode helpers

  CallInfo _decodeCallInfo(Map<String, dynamic> map) {
    final roomDict = map['roomId'] as Map<String, dynamic>?;
    return CallInfo._(
      callId: map['callId'] as String? ?? '',
      inviterId: map['inviter'] as String? ?? '',
      inviteeIds: (map['inviteeList'] as List?)?.whereType<String>().toList() ?? const <String>[],
      mediaType: _decodeMediaTypeFromRaw(_decodeInt(map['mediaType'])),
      roomId: roomDict?['strRoomId'] as String? ?? '',
      chatGroupId: map['groupId'] as String? ?? '',
      startTime: _decodeInt(map['startTime']),
      duration: _decodeInt(map['duration']),
    );
  }

  CallParticipantInfo _decodeParticipantInfo(Map<String, dynamic> map) {
    final rawStatus = _decodeInt(map['status']);
    final status = CallParticipantStatus.values.firstWhere(
      (s) => s.value == rawStatus,
      orElse: () => CallParticipantStatus.none,
    );
    return CallParticipantInfo._(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      avatarURL: map['avatarUrl'] as String? ?? '',
      status: status,
      isMicrophoneOpened: map['isMicrophoneOpened'] as bool? ?? false,
      isCameraOpened: map['isCameraOpened'] as bool? ?? false,
    );
  }

  // MARK: - Call record decode helpers

  List<CallInfo> _decodeRecentCalls(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return const <CallInfo>[];
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) return const <CallInfo>[];
    return decoded.whereType<Map<String, dynamic>>().map(_decodeRecordRow).toList();
  }

  CallInfo _decodeRecordRow(Map<String, dynamic> map) {
    final inviteeJson = map['invitee_list'] as String?;
    List<String> inviteeIds = const <String>[];
    if (inviteeJson != null && inviteeJson.isNotEmpty) {
      final dynamic inviteeDecoded = jsonDecode(inviteeJson);
      if (inviteeDecoded is List) {
        inviteeIds = inviteeDecoded.whereType<String>().toList();
      }
    }

    final startTime = _decodeInt(map['start_time']);
    final endTime = _decodeInt(map['end_time']);
    final duration = (endTime > 0 && startTime > 0 && endTime > startTime) ? (endTime - startTime) ~/ 1000 : 0;

    final roomId = (map['room_id'] as String?) ?? (map['room_id'] as num?)?.toString() ?? '';

    final rawResult = _decodeInt(map['call_result']);
    final result = CallDirection.values.firstWhere(
      (d) => d.value == rawResult,
      orElse: () => CallDirection.unknown,
    );

    final mediaType = _decodeMediaTypeFromRaw(_decodeInt(map['media_type']));

    return CallInfo._(
      callId: map['call_id'] as String? ?? '',
      roomId: roomId,
      inviterId: map['inviter'] as String? ?? '',
      inviteeIds: inviteeIds,
      chatGroupId: map['chat_group_id'] as String? ?? '',
      mediaType: mediaType,
      result: result,
      startTime: startTime,
      duration: duration,
    );
  }

  int _decodeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  CallMediaType? _decodeMediaTypeFromRaw(int rawValue) {
    switch (rawValue) {
      case 1:
        return CallMediaType.audio;
      case 2:
        return CallMediaType.video;
      default:
        return null;
    }
  }
}
