// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   BarrageStoreImpl @ AtomicXCore
// Function: BarrageStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/barrage/barrage_store.dart';
import '../../api/define.dart';
import '../../engine/engine_bridge.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';
import '../live/live_audience_store_define.dart';

class _BarrageStateImpl implements BarrageState {
  @override
  final ValueNotifier<List<Barrage>> messageList = ValueNotifier<List<Barrage>>(const <Barrage>[]);

  @override
  final ValueNotifier<bool> isMessageDisable = ValueNotifier<bool>(false);
}

// API keys
const String _kSendTextMessage = 'BarrageModule.sendTextMessage';
const String _kSendCustomMessage = 'BarrageModule.sendCustomMessage';
const String _kSetMessageDisable = 'BarrageModule.setMessageDisable';
const String _kAppendLocalTip = 'BarrageModule.appendLocalTip';
const String _kCreateModule = 'BarrageModule.createModule';
const String _kDestroyModule = 'BarrageModule.destroyModule';

const String _eventChannel = 'BarrageModule.event';
const String _stateChannel = 'BarrageModule.stateChanged';

class BarrageStoreImpl extends BarrageStore implements IStore {
  BarrageStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _BarrageStateImpl _state = _BarrageStateImpl();
  final Set<BarrageListener> _listeners = <BarrageListener>{};

  @override
  BarrageState get barrageState => _state;

  @override
  Future<CompletionHandler> sendTextMessage({
    required String text,
    Map<String, String>? extensionInfo,
  }) {
    final param = jsonEncode(<String, Object>{
      'textContent': text,
      'extensionInfo': extensionInfo ?? const <String, String>{},
    });
    return EngineBridge.invoke(_kSendTextMessage, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> sendCustomMessage({
    required String businessID,
    required String data,
  }) {
    final param = jsonEncode(<String, Object>{
      'businessID': businessID,
      'data': data,
    });
    return EngineBridge.invoke(_kSendCustomMessage, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setMessageDisable(bool disable) {
    final param = jsonEncode(<String, Object>{
      'disable': disable,
    });
    return EngineBridge.invoke(_kSetMessageDisable, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void appendLocalTip(Barrage message) {
    final param = jsonEncode(<String, Object>{
      'message': _barrageToMap(message),
    });
    unawaited(EngineBridge.invoke(_kAppendLocalTip, param, id: _liveID));
  }

  @override
  void addBarrageListener(BarrageListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeBarrageListener(BarrageListener listener) {
    _listeners.remove(listener);
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
    unawaited(EngineBridge.invoke(_kCreateModule, '{}', id: _liveID));
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
    _state.messageList.value = const <Barrage>[];
    _state.isMessageDisable.value = false;
  }

  void _onModuleEvent(String id, String json) {
    if (id != _liveID) return;
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
      case 'onCustomMessageReceived':
        for (final l in _listeners) {
          l.onCustomMessageReceived?.call(_mapToBarrage(dict['barrage']));
        }
        break;
    }
  }

  void _onModuleStateChanged(String id, String json) {
    if (id != _liveID) return;
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
      case 'messageList':
        {
          final rawList = (dict['messageList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToBarrage(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.messageList.value =
              _applyListModify(_state.messageList.value, modify, items, (e) => e.sequence.toString());
          break;
        }
      case 'isMessageDisable':
        _state.isMessageDisable.value = (dict['isMessageDisable'] as bool?) ?? false;
        break;
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
        return <T>[...current, ...payload];
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

  Map<String, Object> _barrageToMap(Barrage message) {
    return <String, Object>{
      'liveID': message.liveID,
      'sender': message.sender.toMap(),
      'sequence': message.sequence,
      'timestampInSecond': message.timestampInSecond,
      'messageType': message.messageType.value,
      'textContent': message.textContent,
      'extensionInfo': message.extensionInfo,
      'businessID': message.businessID,
      'data': message.data,
    };
  }

  Barrage _mapToBarrage(Map<String, dynamic>? map) {
    if (map == null) return Barrage();
    final messageTypeValue = (map['messageType'] as int?) ?? BarrageType.text.value;
    final messageType = BarrageType.values.firstWhere(
      (e) => e.value == messageTypeValue,
      orElse: () => BarrageType.text,
    );
    final extensionInfoRaw = (map['extensionInfo'] as Map?) ?? const <String, String>{};
    final extensionInfo = extensionInfoRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    return Barrage(
      liveID: (map['liveID'] as String?) ?? '',
      sender: LiveUserInfoCodec.fromMap(map['sender'] as Map<String, dynamic>?),
      sequence: (map['sequence'] as int?) ?? 0,
      timestampInSecond: (map['timestampInSecond'] as int?) ?? 0,
      messageType: messageType,
      textContent: (map['textContent'] as String?) ?? '',
      extensionInfo: extensionInfo,
      businessID: (map['businessID'] as String?) ?? '',
      data: (map['data'] as String?) ?? '',
    );
  }
}
