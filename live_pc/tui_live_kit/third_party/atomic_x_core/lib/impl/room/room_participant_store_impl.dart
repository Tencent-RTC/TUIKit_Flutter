// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   RoomParticipantStoreImpl @ AtomicXCore
// Function: RoomParticipantStore 主动接口实现 + 被动事件/State 监听。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/device/device_store.dart';
import '../../api/room/room_participant_store.dart';
import '../../api/room/room_store.dart';
import '../../engine/engine_bridge.dart';
import '../../engine/engine_call_result.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _RoomParticipantStateImpl implements RoomParticipantState {
  @override
  final ValueNotifier<List<RoomParticipant>> participantList =
      ValueNotifier<List<RoomParticipant>>(const <RoomParticipant>[]);

  @override
  final ValueNotifier<String> participantListCursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<List<RoomUser>> audienceList = ValueNotifier<List<RoomUser>>(const <RoomUser>[]);

  @override
  final ValueNotifier<String> audienceListCursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<List<RoomUser>> adminList = ValueNotifier<List<RoomUser>>(const <RoomUser>[]);

  @override
  final ValueNotifier<List<RoomUser>> messageDisabledUserList = ValueNotifier<List<RoomUser>>(const <RoomUser>[]);

  @override
  final ValueNotifier<List<RoomParticipant>> participantListWithVideo =
      ValueNotifier<List<RoomParticipant>>(const <RoomParticipant>[]);

  @override
  final ValueNotifier<RoomParticipant?> participantWithScreen = ValueNotifier<RoomParticipant?>(null);

  @override
  final ValueNotifier<List<DeviceRequestInfo>> pendingDeviceApplications =
      ValueNotifier<List<DeviceRequestInfo>>(const <DeviceRequestInfo>[]);

  @override
  final ValueNotifier<List<DeviceRequestInfo>> pendingDeviceInvitations =
      ValueNotifier<List<DeviceRequestInfo>>(const <DeviceRequestInfo>[]);

  @override
  final ValueNotifier<Map<String, int>> speakingUsers = ValueNotifier<Map<String, int>>(const <String, int>{});

  @override
  final ValueNotifier<Map<String, NetworkInfo>> networkQualities =
      ValueNotifier<Map<String, NetworkInfo>>(const <String, NetworkInfo>{});

  @override
  final ValueNotifier<List<RoomParticipant>> pendingParticipantList =
      ValueNotifier<List<RoomParticipant>>(const <RoomParticipant>[]);

  @override
  final ValueNotifier<RoomParticipant?> localParticipant = ValueNotifier<RoomParticipant?>(null);
}

const String _kGetParticipantList = 'RoomModule.getParticipantList';
const String _kGetAudienceList = 'RoomModule.getAudienceList';
const String _kSearchUsers = 'RoomModule.searchUsers';
const String _kPromoteAudienceToParticipant = 'RoomModule.promoteAudienceToParticipant';
const String _kDemoteParticipantToAudience = 'RoomModule.demoteParticipantToAudience';
const String _kTransferOwner = 'RoomModule.transferOwner';
const String _kSetAdmin = 'RoomModule.setAdmin';
const String _kRevokeAdmin = 'RoomModule.revokeAdmin';
const String _kKickUser = 'RoomModule.kickUser';
const String _kUpdateParticipantNameCard = 'RoomModule.updateParticipantNameCard';
const String _kUpdateParticipantMetaData = 'RoomModule.updateParticipantMetaData';
const String _kMuteMicrophone = 'RoomModule.muteMicrophone';
const String _kUnmuteMicrophone = 'RoomModule.unmuteMicrophone';
const String _kCloseParticipantDevice = 'RoomModule.closeParticipantDevice';
const String _kDisableUserMessage = 'RoomModule.disableUserMessage';
const String _kDisableAllDevices = 'RoomModule.disableAllDevices';
const String _kDisableAllMessages = 'RoomModule.disableAllMessages';
const String _kRequestToOpenDevice = 'RoomModule.requestToOpenDevice';
const String _kCancelOpenDeviceRequest = 'RoomModule.cancelOpenDeviceRequest';
const String _kApproveOpenDeviceRequest = 'RoomModule.approveOpenDeviceRequest';
const String _kRejectOpenDeviceRequest = 'RoomModule.rejectOpenDeviceRequest';
const String _kInviteToOpenDevice = 'RoomModule.inviteToOpenDevice';
const String _kCancelOpenDeviceInvitation = 'RoomModule.cancelOpenDeviceInvitation';
const String _kAcceptOpenDeviceInvitation = 'RoomModule.acceptOpenDeviceInvitation';
const String _kDeclineOpenDeviceInvitation = 'RoomModule.declineOpenDeviceInvitation';
const String _kCreateModule = 'RoomModule.createModule';
const String _kDestroyModule = 'RoomModule.destroyModule';

const String _eventChannel = 'RoomModule.event';
const String _stateChannel = 'RoomModule.stateChanged';

class RoomParticipantStoreImpl extends RoomParticipantStore implements IStore {
  RoomParticipantStoreImpl(this._roomID);

  final String _roomID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _RoomParticipantStateImpl _state = _RoomParticipantStateImpl();
  final Set<RoomParticipantListener> _listeners = <RoomParticipantListener>{};

  @override
  RoomParticipantState get state => _state;

  @override
  void addRoomParticipantListener(RoomParticipantListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeRoomParticipantListener(RoomParticipantListener listener) {
    _listeners.remove(listener);
  }

  @override
  Future<ListResultCompletionHandler<RoomParticipant>> getParticipantList(String? cursor) async {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'cursor': cursor ?? '',
    });
    final result = await EngineBridge.invoke(_kGetParticipantList, param, id: _roomID);
    return _wrapList<RoomParticipant>(result, _mapToRoomParticipant);
  }

  @override
  Future<ListResultCompletionHandler<RoomUser>> getAudienceList(String? cursor) async {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'cursor': cursor ?? '',
    });
    final result = await EngineBridge.invoke(_kGetAudienceList, param, id: _roomID);
    return _wrapList<RoomUser>(result, _mapToRoomUser);
  }

  @override
  Future<ListResultCompletionHandler<RoomUser>> searchUsers(String keyword) async {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'keyword': keyword,
    });
    final result = await EngineBridge.invoke(_kSearchUsers, param, id: _roomID);
    return _wrapList<RoomUser>(result, _mapToRoomUser);
  }

  @override
  Future<CompletionHandler> promoteAudienceToParticipant(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kPromoteAudienceToParticipant, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> demoteParticipantToAudience(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kDemoteParticipantToAudience, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> transferOwner(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kTransferOwner, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setAdmin(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kSetAdmin, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> revokeAdmin(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kRevokeAdmin, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> kickUser(String userID) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
    });
    return EngineBridge.invoke(_kKickUser, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateParticipantNameCard({
    required String userID,
    required String nameCard,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'nameCard': nameCard,
    });
    return EngineBridge.invoke(_kUpdateParticipantNameCard, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateParticipantMetaData({
    required String userID,
    required Map<String, String> metaData,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'metaData': metaData,
    });
    return EngineBridge.invoke(_kUpdateParticipantMetaData, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  void muteMicrophone() {
    final param = jsonEncode(<String, Object>{'roomID': _roomID});
    unawaited(EngineBridge.invoke(_kMuteMicrophone, param, id: _roomID));
  }

  @override
  Future<CompletionHandler> unmuteMicrophone() {
    final param = jsonEncode(<String, Object>{'roomID': _roomID});
    return EngineBridge.invoke(_kUnmuteMicrophone, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> closeParticipantDevice({
    required String userID,
    required DeviceType device,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'device': device.value,
    });
    return EngineBridge.invoke(_kCloseParticipantDevice, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> disableUserMessage({
    required String userID,
    required bool disable,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'disable': disable,
    });
    return EngineBridge.invoke(_kDisableUserMessage, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> disableAllDevices({
    required DeviceType device,
    required bool disable,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'device': device.value,
      'disable': disable,
    });
    return EngineBridge.invoke(_kDisableAllDevices, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> disableAllMessages(bool disable) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'disable': disable,
    });
    return EngineBridge.invoke(_kDisableAllMessages, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> requestToOpenDevice({
    required DeviceType device,
    int timeout = 0,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'device': device.value,
      'timeout': timeout,
    });
    return EngineBridge.invoke(_kRequestToOpenDevice, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelOpenDeviceRequest(DeviceType device) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'device': device.value,
    });
    return EngineBridge.invoke(_kCancelOpenDeviceRequest, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> approveOpenDeviceRequest({
    required DeviceType device,
    required String userID,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'device': device.value,
      'userID': userID,
    });
    return EngineBridge.invoke(_kApproveOpenDeviceRequest, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> rejectOpenDeviceRequest({
    required DeviceType device,
    required String userID,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'device': device.value,
      'userID': userID,
    });
    return EngineBridge.invoke(_kRejectOpenDeviceRequest, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> inviteToOpenDevice({
    required String userID,
    required DeviceType device,
    int timeout = 0,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'device': device.value,
      'timeout': timeout,
    });
    return EngineBridge.invoke(_kInviteToOpenDevice, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> cancelOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'device': device.value,
    });
    return EngineBridge.invoke(_kCancelOpenDeviceInvitation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> acceptOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'device': device.value,
    });
    return EngineBridge.invoke(_kAcceptOpenDeviceInvitation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> declineOpenDeviceInvitation({
    required String userID,
    required DeviceType device,
  }) {
    final param = jsonEncode(<String, Object>{
      'roomID': _roomID,
      'userID': userID,
      'device': device.value,
    });
    return EngineBridge.invoke(_kDeclineOpenDeviceInvitation, param, id: _roomID).then((r) => r.toCompletionHandler());
  }

  // MARK: - IStore lifecycle

  @override
  void beforeEnterRoom(String roomID) {
    if (_eventToken != null) return;
    _eventToken = EngineBridge.subscribe(_eventChannel, _onModuleEvent);
    _stateToken = EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
  }

  @override
  void afterEnterRoom(dynamic info) {
    unawaited(EngineBridge.invoke(_kCreateModule, '{}', id: _roomID));
  }

  @override
  void didLeaveRoom(String roomID) {
    unawaited(EngineBridge.invoke(_kDestroyModule, '{}', id: roomID));
    final eventToken = _eventToken;
    if (eventToken != null) {
      EngineBridge.unsubscribe(eventToken);
    }
    _eventToken = null;
    final stateToken = _stateToken;
    if (stateToken != null) {
      EngineBridge.unsubscribe(stateToken);
    }
    _stateToken = null;
    _listeners.clear();
  }

  // MARK: - Passive Event dispatcher (type 判别)

  void _onModuleEvent(String id, String json) {
    if (id != _roomID) return;
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
      case 'onParticipantJoined':
        for (final l in _listeners) {
          l.onParticipantJoined?.call(_mapToRoomUser(dict['participant']));
        }
        break;
      case 'onParticipantLeft':
        for (final l in _listeners) {
          l.onParticipantLeft?.call(_mapToRoomUser(dict['participant']));
        }
        break;
      case 'onAudiencePromotedToParticipant':
        for (final l in _listeners) {
          l.onAudiencePromotedToParticipant?.call(_mapToRoomUser(dict['userInfo']));
        }
        break;
      case 'onParticipantDemotedToAudience':
        for (final l in _listeners) {
          l.onParticipantDemotedToAudience?.call(_mapToRoomUser(dict['userInfo']));
        }
        break;
      case 'onOwnerChanged':
        for (final l in _listeners) {
          l.onOwnerChanged?.call(
            _mapToRoomUser(dict['newOwner']),
            _mapToRoomUser(dict['oldOwner']),
          );
        }
        break;
      case 'onAdminSet':
        for (final l in _listeners) {
          l.onAdminSet?.call(_mapToRoomUser(dict['userInfo']));
        }
        break;
      case 'onAdminRevoked':
        for (final l in _listeners) {
          l.onAdminRevoked?.call(_mapToRoomUser(dict['userInfo']));
        }
        break;
      case 'onKickedFromRoom':
        for (final l in _listeners) {
          l.onKickedFromRoom?.call(
            _intToKickedOutOfRoomReason(dict['reason'] as int?),
            (dict['message'] as String?) ?? '',
          );
        }
        final roomId = (dict['roomID'] as String?) ?? '';
        StoreFactory.shared.didLeaveRoom(roomId);
        break;
      case 'onParticipantDeviceClosed':
        for (final l in _listeners) {
          l.onParticipantDeviceClosed?.call(
            _intToDeviceType(dict['device'] as int?),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onUserMessageDisabled':
        for (final l in _listeners) {
          l.onUserMessageDisabled?.call(
            (dict['disable'] as bool?) ?? false,
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onAllDevicesDisabled':
        for (final l in _listeners) {
          l.onAllDevicesDisabled?.call(
            _intToDeviceType(dict['device'] as int?),
            (dict['disable'] as bool?) ?? false,
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onAllMessagesDisabled':
        for (final l in _listeners) {
          l.onAllMessagesDisabled?.call(
            (dict['disable'] as bool?) ?? false,
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onDeviceRequestReceived':
        for (final l in _listeners) {
          l.onDeviceRequestReceived?.call(_mapToDeviceRequestInfo(dict['request']));
        }
        break;
      case 'onDeviceRequestCancelled':
        for (final l in _listeners) {
          l.onDeviceRequestCancelled?.call(_mapToDeviceRequestInfo(dict['request']));
        }
        break;
      case 'onDeviceRequestTimeout':
        for (final l in _listeners) {
          l.onDeviceRequestTimeout?.call(_mapToDeviceRequestInfo(dict['request']));
        }
        break;
      case 'onDeviceRequestApproved':
        for (final l in _listeners) {
          l.onDeviceRequestApproved?.call(
            _mapToDeviceRequestInfo(dict['request']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onDeviceRequestRejected':
        for (final l in _listeners) {
          l.onDeviceRequestRejected?.call(
            _mapToDeviceRequestInfo(dict['request']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onDeviceRequestProcessed':
        for (final l in _listeners) {
          l.onDeviceRequestProcessed?.call(
            _mapToDeviceRequestInfo(dict['request']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onDeviceInvitationReceived':
        for (final l in _listeners) {
          l.onDeviceInvitationReceived?.call(_mapToDeviceRequestInfo(dict['invitation']));
        }
        break;
      case 'onDeviceInvitationCancelled':
        for (final l in _listeners) {
          l.onDeviceInvitationCancelled?.call(_mapToDeviceRequestInfo(dict['invitation']));
        }
        break;
      case 'onDeviceInvitationTimeout':
        for (final l in _listeners) {
          l.onDeviceInvitationTimeout?.call(_mapToDeviceRequestInfo(dict['invitation']));
        }
        break;
      case 'onDeviceInvitationAccepted':
        for (final l in _listeners) {
          l.onDeviceInvitationAccepted?.call(
            _mapToDeviceRequestInfo(dict['invitation']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
      case 'onDeviceInvitationDeclined':
        for (final l in _listeners) {
          l.onDeviceInvitationDeclined?.call(
            _mapToDeviceRequestInfo(dict['invitation']),
            _mapToRoomUser(dict['operator']),
          );
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property 判别)

  void _onModuleStateChanged(String id, String json) {
    if (id != _roomID) return;
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

    final modify = (dict['listModifyType'] as int?) ?? 1;
    switch (property) {
      case 'participantList':
        {
          final rawList = (dict['participantList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomParticipant(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.participantList.value = _applyListModify(_state.participantList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'participantListCursor':
        _state.participantListCursor.value = (dict['participantListCursor'] as String?) ?? '';
        break;
      case 'audienceList':
        {
          final rawList = (dict['audienceList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomUser(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.audienceList.value = _applyListModify(_state.audienceList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'audienceListCursor':
        _state.audienceListCursor.value = (dict['audienceListCursor'] as String?) ?? '';
        break;
      case 'adminList':
        {
          final rawList = (dict['adminList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomUser(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.adminList.value = _applyListModify(_state.adminList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'messageDisabledUserList':
        {
          final rawList = (dict['messageDisabledUserList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomUser(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.messageDisabledUserList.value =
              _applyListModify(_state.messageDisabledUserList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'participantListWithVideo':
        {
          final rawList = (dict['participantListWithVideo'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomParticipant(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.participantListWithVideo.value =
              _applyListModify(_state.participantListWithVideo.value, modify, items, (e) => e.userID);
          break;
        }
      case 'participantWithScreen':
        {
          final raw = dict['participantWithScreen'];
          _state.participantWithScreen.value = raw is Map ? _mapToRoomParticipant(raw.cast<String, dynamic>()) : null;
          break;
        }
      case 'pendingDeviceApplications':
        {
          final rawList = (dict['pendingDeviceApplications'] as List?) ?? const [];
          final items =
              rawList.map((e) => _mapToDeviceRequestInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.pendingDeviceApplications.value = _applyListModify(
            _state.pendingDeviceApplications.value,
            modify,
            items,
            (e) => '${e.senderUserID}:${e.device.value}',
          );
          break;
        }
      case 'pendingDeviceInvitations':
        {
          final rawList = (dict['pendingDeviceInvitations'] as List?) ?? const [];
          final items =
              rawList.map((e) => _mapToDeviceRequestInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.pendingDeviceInvitations.value = _applyListModify(
            _state.pendingDeviceInvitations.value,
            modify,
            items,
            (e) => '${e.senderUserID}:${e.device.value}',
          );
          break;
        }
      case 'speakingUsers':
        {
          final raw = dict['speakingUsers'] as Map<String, dynamic>? ?? const {};
          _state.speakingUsers.value = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
          break;
        }
      case 'networkQualities':
        {
          final raw = dict['networkQualities'] as Map<String, dynamic>? ?? const {};
          _state.networkQualities.value = raw.map(
            (k, v) {
              final m = v as Map<String, dynamic>;
              final qualityValue = (m['quality'] as int?) ?? NetworkQuality.excellent.value;
              return MapEntry(
                k,
                NetworkInfo(
                  userID: (m['userID'] as String?) ?? '',
                  quality: NetworkQuality.values.firstWhere(
                    (e) => e.value == qualityValue,
                    orElse: () => NetworkQuality.excellent,
                  ),
                  upLoss: (m['upLoss'] as int?) ?? 0,
                  downLoss: (m['downLoss'] as int?) ?? 0,
                  delay: (m['delay'] as int?) ?? 0,
                ),
              );
            },
          );
          break;
        }
      case 'pendingParticipantList':
        {
          final rawList = (dict['pendingParticipantList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToRoomParticipant(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.pendingParticipantList.value =
              _applyListModify(_state.pendingParticipantList.value, modify, items, (e) => e.userID);
          break;
        }
      case 'localParticipant':
        {
          final raw = dict['localParticipant'];
          _state.localParticipant.value = raw is Map ? _mapToRoomParticipant(raw.cast<String, dynamic>()) : null;
          break;
        }
    }
  }

  // MARK: - List modify helper

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

extension _RoomParticipantStoreImplHelpers on RoomParticipantStoreImpl {
  RoomUser _mapToRoomUser(Map<String, dynamic>? map) {
    if (map == null) return RoomUser();
    return RoomUser(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
    );
  }

  DeviceType _intToDeviceType(int? value) {
    return DeviceType.values.firstWhere(
      (e) => e.value == (value ?? DeviceType.microphone.value),
      orElse: () => DeviceType.microphone,
    );
  }

  KickedOutOfRoomReason _intToKickedOutOfRoomReason(int? value) {
    return KickedOutOfRoomReason.values.firstWhere(
      (e) => e.value == (value ?? KickedOutOfRoomReason.kickedByAdmin.value),
      orElse: () => KickedOutOfRoomReason.kickedByAdmin,
    );
  }

  DeviceStatus _intToDeviceStatus(int? value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.value == (value ?? DeviceStatus.off.value),
      orElse: () => DeviceStatus.off,
    );
  }

  RoomParticipant _mapToRoomParticipant(Map<String, dynamic>? map) {
    if (map == null) return RoomParticipant();
    final roleValue = (map['role'] as int?) ?? ParticipantRole.generalUser.value;
    final role = ParticipantRole.values.firstWhere(
      (e) => e.value == roleValue,
      orElse: () => ParticipantRole.generalUser,
    );
    final roomStatusValue = (map['roomStatus'] as int?) ?? RoomParticipantStatus.scheduled.value;
    final roomStatus = RoomParticipantStatus.values.firstWhere(
      (e) => e.value == roomStatusValue,
      orElse: () => RoomParticipantStatus.scheduled,
    );
    final metaDataRaw = (map['metaData'] as Map?) ?? const <String, String>{};
    final metaData = metaDataRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    return RoomParticipant(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
      nameCard: (map['nameCard'] as String?) ?? '',
      role: role,
      roomStatus: roomStatus,
      microphoneStatus: _intToDeviceStatus(map['microphoneStatus'] as int?),
      screenShareStatus: _intToDeviceStatus(map['screenShareStatus'] as int?),
      cameraStatus: _intToDeviceStatus(map['cameraStatus'] as int?),
      isMessageDisabled: (map['isMessageDisabled'] as bool?) ?? false,
      metaData: metaData,
    );
  }

  DeviceRequestInfo _mapToDeviceRequestInfo(Map<String, dynamic>? map) {
    if (map == null) return DeviceRequestInfo();
    return DeviceRequestInfo(
      timestamp: (map['timestamp'] as int?) ?? 0,
      senderUserID: (map['senderUserID'] as String?) ?? '',
      senderUserName: (map['senderUserName'] as String?) ?? '',
      senderNameCard: (map['senderNameCard'] as String?) ?? '',
      senderAvatarURL: (map['senderAvatarURL'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      device: _intToDeviceType(map['device'] as int?),
    );
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
        debugPrint('[RoomParticipantStoreImpl] decode list result failed: $e');
      }
    }
    return handler;
  }
}
