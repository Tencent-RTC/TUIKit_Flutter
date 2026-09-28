// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   RoomStoreImpl @ AtomicXCore
// Function: RoomStore 主动接口实现 + 被动事件/State 监听。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/room/room_store.dart';
import '../../engine/engine_bridge.dart';
import '../../engine/engine_call_result.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _RoomStateImpl implements RoomState {
  @override
  final ValueNotifier<List<RoomInfo>> scheduledRoomList = ValueNotifier<List<RoomInfo>>(const <RoomInfo>[]);

  @override
  final ValueNotifier<String> scheduledRoomListCursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<RoomInfo?> currentRoom = ValueNotifier<RoomInfo?>(null);
}

const String _kGetScheduledRoomList = 'RoomListModule.getScheduledRoomList';
const String _kGetScheduledAttendees = 'RoomListModule.getScheduledAttendees';
const String _kScheduleRoom = 'RoomListModule.scheduleRoom';
const String _kUpdateScheduledRoom = 'RoomListModule.updateScheduledRoom';
const String _kAddScheduledAttendees = 'RoomListModule.addScheduledAttendees';
const String _kRemoveScheduledAttendees = 'RoomListModule.removeScheduledAttendees';
const String _kCancelScheduledRoom = 'RoomListModule.cancelScheduledRoom';
const String _kGetRoomInfo = 'RoomListModule.getRoomInfo';

const String _kCreateAndJoinRoom = 'RoomModule.createAndJoinRoom';
const String _kJoinRoom = 'RoomModule.joinRoom';
const String _kLeaveRoom = 'RoomModule.leaveRoom';
const String _kEndRoom = 'RoomModule.endRoom';
const String _kUpdateRoomInfo = 'RoomModule.updateRoomInfo';
const String _kGetPendingCalls = 'RoomModule.getPendingCalls';
const String _kCallUserToRoom = 'RoomModule.callUserToRoom';
const String _kCancelCall = 'RoomModule.cancelCall';
const String _kAcceptCall = 'RoomModule.acceptCall';
const String _kRejectCall = 'RoomModule.rejectCall';
const String _kStartRecording = 'RoomModule.startRecording';
const String _kStopRecording = 'RoomModule.stopRecording';
const String _kReset = 'RoomModule.reset';

const String _eventChannel = 'RoomModule.event';
const String _stateChannel = 'RoomModule.stateChanged';
const String _listEventChannel = 'RoomListModule.event';
const String _listStateChannel = 'RoomListModule.stateChanged';

class RoomStoreImpl extends RoomStore {
  RoomStoreImpl() {
    _subscribePassiveChannels();
  }

  static final RoomStoreImpl shared = RoomStoreImpl();

  final _RoomStateImpl _state = _RoomStateImpl();
  final Set<RoomListener> _listeners = <RoomListener>{};

  @override
  RoomState get state => _state;

  @override
  void addRoomListener(RoomListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeRoomListener(RoomListener listener) {
    _listeners.remove(listener);
  }

  // ─── RoomListModule: pre-room APIs (no id scope) ───

  @override
  Future<ListResultCompletionHandler<RoomInfo>> getScheduledRoomList(String? cursor) async {
    final param = jsonEncode(<String, Object>{'cursor': cursor ?? ''});
    final result = await EngineBridge.invoke(_kGetScheduledRoomList, param);
    return _wrapList<RoomInfo>(result, _mapToRoomInfo);
  }

  @override
  Future<ListResultCompletionHandler<RoomUser>> getScheduledAttendees({
    required String roomID,
    required String? cursor,
  }) async {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'cursor': cursor ?? '',
    });
    final result = await EngineBridge.invoke(_kGetScheduledAttendees, param);
    return _wrapList<RoomUser>(result, _mapToRoomUser);
  }

  @override
  Future<CompletionHandler> scheduleRoom({
    required String roomID,
    required ScheduleRoomOptions options,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'options': _scheduleRoomOptionsToMap(options),
    });
    return EngineBridge.invoke(_kScheduleRoom, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateScheduledRoom({
    required String roomID,
    required ScheduleRoomOptions options,
    required List<ScheduleRoomOptionsModifyFlag> modifyFlagList,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'options': _scheduleRoomOptionsToMap(options),
      'modifyFlagList': modifyFlagList.map((e) => e.value).toList(),
    });
    return EngineBridge.invoke(_kUpdateScheduledRoom, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> addScheduledAttendees({
    required String roomID,
    required List<String> userIDList,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'userIDList': userIDList,
    });
    return EngineBridge.invoke(_kAddScheduledAttendees, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> removeScheduledAttendees({
    required String roomID,
    required List<String> userIDList,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'userIDList': userIDList,
    });
    return EngineBridge.invoke(_kRemoveScheduledAttendees, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelScheduledRoom(String roomID) {
    final param = jsonEncode(<String, Object>{'roomID': roomID});
    return EngineBridge.invoke(_kCancelScheduledRoom, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<GetRoomInfoCompletionHandler> getRoomInfo(String roomID) async {
    final param = jsonEncode(<String, Object>{'roomID': roomID});
    final result = await EngineBridge.invoke(_kGetRoomInfo, param);
    final handler = GetRoomInfoCompletionHandler();
    handler.errorCode = result.code;
    handler.errorMessage = result.message;
    if (result.isSuccess && result.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(result.data);
        if (decoded is Map<String, dynamic>) {
          handler.roomInfo = _mapToRoomInfo(decoded);
        }
      } catch (e) {
        debugPrint('[RoomStoreImpl] decode roomInfo failed: $e');
      }
    }
    return handler;
  }

  // ─── RoomModule: in-room APIs (with roomID scope) ───

  @override
  Future<CompletionHandler> createAndJoinRoom({
    required String roomID,
    required RoomType roomType,
    required CreateRoomOptions options,
  }) {
    StoreFactory.shared.beforeEnterRoom(roomID, SceneType.room);
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'roomType': roomType.value,
      'options': <String, Object>{
        'roomName': options.roomName,
        'password': options.password,
        'isAllMicrophoneDisabled': options.isAllMicrophoneDisabled,
        'isAllCameraDisabled': options.isAllCameraDisabled,
        'isAllScreenShareDisabled': options.isAllScreenShareDisabled,
        'isAllMessageDisabled': options.isAllMessageDisabled,
      },
    });
    return EngineBridge.invoke(_kCreateAndJoinRoom, param, id: roomID).then((r) {
      if (r.isSuccess) {
        StoreFactory.shared.afterEnterRoom(roomID, RoomInfo(roomID: roomID));
      }
      return r.toCompletionHandler();
    });
  }

  @override
  Future<CompletionHandler> joinRoom({
    required String roomID,
    required RoomType roomType,
    String? password = '',
  }) {
    StoreFactory.shared.beforeEnterRoom(roomID, SceneType.room);
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'roomType': roomType.value,
      'password': password ?? '',
    });
    return EngineBridge.invoke(_kJoinRoom, param, id: roomID).then((r) {
      if (r.isSuccess) {
        StoreFactory.shared.afterEnterRoom(roomID, RoomInfo(roomID: roomID));
      }
      return r.toCompletionHandler();
    });
  }

  @override
  Future<CompletionHandler> leaveRoom() async {
    final roomID = _state.currentRoom.value?.roomID ?? '';
    final result = await EngineBridge.invoke(_kLeaveRoom, '{}', id: roomID);
    if (result.isSuccess) StoreFactory.shared.didLeaveRoom(roomID);
    return result.toCompletionHandler();
  }

  @override
  Future<CompletionHandler> endRoom() async {
    final roomID = _state.currentRoom.value?.roomID ?? '';
    final result = await EngineBridge.invoke(_kEndRoom, '{}', id: roomID);
    if (result.isSuccess) StoreFactory.shared.didLeaveRoom(roomID);
    return result.toCompletionHandler();
  }

  @override
  Future<CompletionHandler> updateRoomInfo({
    required String roomID,
    required UpdateRoomOptions options,
    required List<UpdateRoomOptionsModifyFlag> modifyFlagList,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'options': <String, Object>{
        'roomName': options.roomName,
        'password': options.password,
      },
      'modifyFlagList': modifyFlagList.map((e) => e.value).toList(),
    });
    return EngineBridge.invoke(_kUpdateRoomInfo, param, id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<ListResultCompletionHandler<RoomCall>> getPendingCalls({
    required String roomID,
    required String? cursor,
  }) async {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'cursor': cursor ?? '',
    });
    final result = await EngineBridge.invoke(_kGetPendingCalls, param, id: roomID);
    return _wrapList<RoomCall>(result, _mapToRoomCall);
  }

  @override
  Future<CallUserToRoomCompletionHandler> callUserToRoom({
    required String roomID,
    required List<String> userIDList,
    int timeout = 0,
    String? extensionInfo,
  }) async {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'userIDList': userIDList,
      'timeout': timeout,
      'extensionInfo': extensionInfo ?? '',
    });
    final result = await EngineBridge.invoke(_kCallUserToRoom, param, id: roomID);
    final handler = CallUserToRoomCompletionHandler();
    handler.errorCode = result.code;
    handler.errorMessage = result.message;
    if (result.isSuccess && result.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(result.data);
        if (decoded is Map) {
          handler.data = decoded.map((key, value) {
            final intValue = value is int ? value : int.tryParse('$value') ?? 0;
            return MapEntry(key.toString(), _intToRoomCallResult(intValue));
          });
        }
      } catch (e) {
        debugPrint('[RoomStoreImpl] decode callUserToRoom result failed: $e');
      }
    }
    return handler;
  }

  @override
  Future<CompletionHandler> cancelCall({
    required String roomID,
    required List<String> userIDList,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'userIDList': userIDList,
    });
    return EngineBridge.invoke(_kCancelCall, param, id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptCall(String roomID) {
    final param = jsonEncode(<String, Object>{'roomID': roomID});
    return EngineBridge.invoke(_kAcceptCall, param, id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectCall({
    required String roomID,
    required CallRejectionReason reason,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': roomID,
      'reason': reason.value,
    });
    return EngineBridge.invoke(_kRejectCall, param, id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> startRecording({StartRecordingOptions? options}) {
    final roomID = _state.currentRoom.value?.roomID ?? '';
    return EngineBridge.invoke(_kStartRecording, '{}', id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> stopRecording() {
    final roomID = _state.currentRoom.value?.roomID ?? '';
    return EngineBridge.invoke(_kStopRecording, '{}', id: roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<void> callExperimentalAPI(Map<String, dynamic> jsonMap, {ExperimentalAPICallback? callback}) async {
    final api = jsonMap['api'];
    if (api is! String) return;
    final params = jsonMap['params'];
    final param = params == null ? '{}' : (params is String ? params : jsonEncode(params));
    final result = await EngineBridge.invoke(api, param, id: _state.currentRoom.value?.roomID ?? "");
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

  @override
  void reset() {
    unawaited(EngineBridge.invoke(_kReset, '{}'));
  }

  // MARK: - Passive channel subscriptions

  void _subscribePassiveChannels() {
    EngineBridge.subscribe(_eventChannel, (String id, String json) {
      if (id == _state.currentRoom.value?.roomID) _onModuleEvent(id, json);
    });
    EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
    EngineBridge.subscribe(_listEventChannel, _onModuleEvent);
    EngineBridge.subscribe(_listStateChannel, _onModuleStateChanged);
  }

  void _onModuleEvent(String id, String json) {
    Map<String, dynamic>? dict;
    try {
      final parsed = jsonDecode(json);
      if (parsed is! Map<String, dynamic>) return;
      dict = parsed;
    } catch (_) {
      return;
    }
    final type = dict['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'onAddedToScheduledRoom':
        for (final l in _listeners) {
          l.onAddedToScheduledRoom?.call(_mapToRoomInfo(dict['roomInfo']));
        }
        break;
      case 'onRemovedFromScheduledRoom':
        for (final l in _listeners) {
          l.onRemovedFromScheduledRoom?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onScheduledRoomCancelled':
        for (final l in _listeners) {
          l.onScheduledRoomCancelled?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onScheduledRoomStartingSoon':
        for (final l in _listeners) {
          l.onScheduledRoomStartingSoon?.call(_mapToRoomInfo(dict['roomInfo']));
        }
        break;
      case 'onRoomEnded':
        final roomInfo = _mapToRoomInfo(dict['roomInfo']);
        for (final l in _listeners) {
          l.onRoomEnded?.call(roomInfo);
        }
        StoreFactory.shared.didLeaveRoom(roomInfo.roomID);
        break;
      case 'onCallReceived':
        for (final l in _listeners) {
          l.onCallReceived?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
            (dict['extensionInfo'] as String?) ?? '',
          );
        }
        break;
      case 'onCallCancelled':
        for (final l in _listeners) {
          l.onCallCancelled?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
          );
        }
        break;
      case 'onCallTimeout':
        for (final l in _listeners) {
          l.onCallTimeout?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
          );
        }
        break;
      case 'onCallAccepted':
        for (final l in _listeners) {
          l.onCallAccepted?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
          );
        }
        break;
      case 'onCallRejected':
        for (final l in _listeners) {
          l.onCallRejected?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
            _intToCallRejectionReason(dict['reason'] as int?),
          );
        }
        break;
      case 'onCallHandledByOtherDevice':
        for (final l in _listeners) {
          l.onCallHandledByOtherDevice?.call(
            _mapToRoomInfo(dict['roomInfo']),
            (dict['isAccepted'] as bool?) ?? false,
          );
        }
        break;
      case 'onCallRevokedByAdmin':
        for (final l in _listeners) {
          l.onCallRevokedByAdmin?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomCall(dict['call']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onRecordingStarted':
        for (final l in _listeners) {
          l.onRecordingStarted?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onRecordingStopped':
        for (final l in _listeners) {
          l.onRecordingStopped?.call(
            _mapToRoomInfo(dict['roomInfo']),
            _mapToRoomUser(dict['operator']),
            _intToRecordingStopReason(dict['reason'] as int?),
          );
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property 判别)

  void _onModuleStateChanged(String id, String json) {
    Map<String, dynamic>? dict;
    try {
      final parsed = jsonDecode(json);
      if (parsed is! Map<String, dynamic>) return;
      dict = parsed;
    } catch (_) {
      return;
    }
    final property = dict['property'] as String?;
    if (property == null) return;

    switch (property) {
      case 'currentRoom':
        _state.currentRoom.value = _mapToRoomInfo(dict['currentRoom']);
        break;
      case 'scheduledRoomListCursor':
        _state.scheduledRoomListCursor.value = (dict['scheduledRoomListCursor'] as String?) ?? '';
        break;
      case 'scheduledRoomList':
        {
          final modify = (dict['listModifyType'] as int?) ?? 1;
          final rawList = (dict['scheduledRoomList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.scheduledRoomList.value = _applyListModify(
            _state.scheduledRoomList.value,
            modify,
            items,
            (e) => e.roomID,
          );
          break;
        }
    }
  }

  List<T> _applyListModify<T>(
    List<T> current,
    int modifyType,
    List<T> payload,
    String Function(T) keyOf,
  ) {
    final type = ListModifyType.fromValue(modifyType);
    switch (type) {
      case ListModifyType.full:
        return payload;
      case ListModifyType.add:
        final map = <String, T>{};
        for (final e in current) {
          map[keyOf(e)] = e;
        }
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return map.values.toList();
      case ListModifyType.remove:
        final removing = payload.map(keyOf).toSet();
        return current.where((e) => !removing.contains(keyOf(e))).toList();
      case ListModifyType.replace:
        final map = <String, T>{};
        for (final e in payload) {
          map[keyOf(e)] = e;
        }
        return current.map((e) => map[keyOf(e)] ?? e).toList();
      case ListModifyType.none:
        return current;
    }
  }
}

// MARK: - Private helpers (extension)

extension _RoomStoreImplHelpers on RoomStoreImpl {
  RoomUser _mapToRoomUser(Map<String, dynamic>? map) {
    if (map == null) return RoomUser();
    return RoomUser(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
    );
  }

  RoomInfo _mapToRoomInfo(Map<String, dynamic>? map) {
    if (map == null) return RoomInfo();
    final roomTypeValue = (map['roomType'] as int?) ?? RoomType.standard.value;
    final roomType = RoomType.values.firstWhere(
      (e) => e.value == roomTypeValue,
      orElse: () => RoomType.standard,
    );
    final roomStatusValue = (map['roomStatus'] as int?) ?? RoomStatus.scheduled.value;
    final roomStatus = RoomStatus.values.firstWhere(
      (e) => e.value == roomStatusValue,
      orElse: () => RoomStatus.scheduled,
    );
    final scheduleAttendeesRaw = (map['scheduleAttendees'] as List?) ?? const [];
    final scheduleAttendees =
        scheduleAttendeesRaw.map((e) => _mapToRoomUser(e is Map ? e.cast<String, dynamic>() : null)).toList();
    return RoomInfo(
      roomID: (map['roomID'] as String?) ?? '',
      roomName: (map['roomName'] as String?) ?? '',
      roomOwner: _mapToRoomUser(map['roomOwner'] as Map<String, dynamic>?),
      roomType: roomType,
      participantCount: (map['participantCount'] as int?) ?? 0,
      audienceCount: (map['audienceCount'] as int?) ?? 0,
      createTime: (map['createTime'] as int?) ?? 0,
      roomStatus: roomStatus,
      scheduledStartTime: (map['scheduledStartTime'] as int?) ?? 0,
      scheduledEndTime: (map['scheduledEndTime'] as int?) ?? 0,
      startReminderInSeconds: (map['startReminderInSeconds'] as int?) ?? 0,
      scheduleAttendees: scheduleAttendees,
      password: map['password'] as String?,
      isAllMicrophoneDisabled: (map['isAllMicrophoneDisabled'] as bool?) ?? false,
      isAllCameraDisabled: (map['isAllCameraDisabled'] as bool?) ?? false,
      isAllMessageDisabled: (map['isAllMessageDisabled'] as bool?) ?? false,
      isAllScreenShareDisabled: (map['isAllScreenShareDisabled'] as bool?) ?? false,
      recordingInfo: _mapToRecordingInfo(map['recordingInfo'] as Map<String, dynamic>?),
    );
  }

  RecordingInfo _mapToRecordingInfo(Map<String, dynamic>? map) {
    if (map == null) return RecordingInfo();
    return RecordingInfo(
      status: _intToRecordingStatus(map['status'] as int?),
      operatorUser: _mapToRoomUser(map['operatorUser'] as Map<String, dynamic>?),
      startTime: (map['startTime'] as int?) ?? 0,
    );
  }

  RoomCall _mapToRoomCall(Map<String, dynamic>? map) {
    if (map == null) return RoomCall();
    final statusValue = (map['status'] as int?) ?? RoomCallStatus.none.value;
    final status = RoomCallStatus.values.firstWhere(
      (e) => e.value == statusValue,
      orElse: () => RoomCallStatus.none,
    );
    return RoomCall(
      caller: _mapToRoomUser(map['caller'] as Map<String, dynamic>?),
      callee: _mapToRoomUser(map['callee'] as Map<String, dynamic>?),
      status: status,
    );
  }

  RoomCallResult _intToRoomCallResult(int value) {
    return RoomCallResult.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RoomCallResult.success,
    );
  }

  CallRejectionReason _intToCallRejectionReason(int? value) {
    return CallRejectionReason.values.firstWhere(
      (e) => e.value == (value ?? CallRejectionReason.rejected.value),
      orElse: () => CallRejectionReason.rejected,
    );
  }

  RecordingStopReason _intToRecordingStopReason(int? value) {
    return RecordingStopReason.values.firstWhere(
      (e) => e.value == (value ?? RecordingStopReason.stoppedByUser.value),
      orElse: () => RecordingStopReason.stoppedByUser,
    );
  }

  RecordingStatus _intToRecordingStatus(int? value) {
    return RecordingStatus.values.firstWhere(
      (e) => e.value == (value ?? RecordingStatus.none.value),
      orElse: () => RecordingStatus.none,
    );
  }

  Map<String, Object> _scheduleRoomOptionsToMap(ScheduleRoomOptions options) {
    return <String, Object>{
      'roomName': options.roomName,
      'password': options.password,
      'scheduleStartTime': options.scheduleStartTime,
      'scheduleEndTime': options.scheduleEndTime,
      'reminderSecondsBeforeStart': options.reminderSecondsBeforeStart,
      'scheduleAttendees': options.scheduleAttendees,
      'isAllMicrophoneDisabled': options.isAllMicrophoneDisabled,
      'isAllCameraDisabled': options.isAllCameraDisabled,
      'isAllScreenShareDisabled': options.isAllScreenShareDisabled,
      'isAllMessageDisabled': options.isAllMessageDisabled,
    };
  }

  ListResultCompletionHandler<T> _wrapList<T>(
    EngineCallResult source,
    T Function(Map<String, dynamic>?) itemMapper,
  ) {
    final handler = ListResultCompletionHandler<T>();
    handler.errorCode = source.code;
    handler.errorMessage = source.message;
    if (source.isSuccess && source.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(source.data);
        if (decoded is Map<String, dynamic>) {
          final listRaw = (decoded['list'] as List?) ?? const [];
          handler.data = listRaw.map((e) => itemMapper(e is Map ? e.cast<String, dynamic>() : null)).toList();
          handler.cursor = decoded['cursor'] as String?;
        }
      } catch (e) {
        debugPrint('[RoomStoreImpl] decode list result failed: $e');
      }
    }
    return handler;
  }
}
