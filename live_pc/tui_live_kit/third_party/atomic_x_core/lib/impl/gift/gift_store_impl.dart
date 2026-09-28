// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   GiftStoreImpl @ AtomicXCore
// Function: GiftStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/gift/gift_store.dart';
import '../../engine/engine_bridge.dart';
import '../live/live_audience_store_define.dart';
import '../common/list_modify_type.dart';
import '../common/store_factory.dart';

class _GiftStateImpl implements GiftState {
  @override
  final ValueNotifier<List<GiftCategory>> usableGifts = ValueNotifier<List<GiftCategory>>(const <GiftCategory>[]);

  @override
  final ValueNotifier<bool> isGiftEnabled = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<List<GiftStatisticInfo>> userGiftStatisticsList =
      ValueNotifier<List<GiftStatisticInfo>>(const <GiftStatisticInfo>[]);
}

// API keys
const String _kSetLanguage = 'GiftModule.setLanguage';
const String _kRefreshUsableGifts = 'GiftModule.refreshUsableGifts';
const String _kSendGift = 'GiftModule.sendGift';
const String _kSetGiftEnabled = 'GiftModule.setGiftEnabled';
const String _kCreateModule = 'GiftModule.createModule';
const String _kDestroyModule = 'GiftModule.destroyModule';

const String _eventChannel = 'GiftModule.event';
const String _stateChannel = 'GiftModule.stateChanged';

class GiftStoreImpl extends GiftStore implements IStore {
  GiftStoreImpl(this._liveID);

  final String _liveID;
  SubscriptionToken? _eventToken;
  SubscriptionToken? _stateToken;
  final _GiftStateImpl _state = _GiftStateImpl();
  final Set<GiftListener> _listeners = <GiftListener>{};

  @override
  GiftState get giftState => _state;

  @override
  void setLanguage(String language) {
    final param = jsonEncode(<String, Object>{
      'language': language,
    });
    unawaited(EngineBridge.invoke(_kSetLanguage, param, id: _liveID));
  }

  @override
  Future<CompletionHandler> refreshUsableGifts() {
    return EngineBridge.invoke(_kRefreshUsableGifts, '{}', id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> sendGift({
    required String giftID,
    required int count,
    String receiver = '',
  }) {
    final param = jsonEncode(<String, Object>{
      'giftID': giftID,
      'count': count,
      'receiver': receiver,
    });
    return EngineBridge.invoke(_kSendGift, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> setGiftEnabled(bool enabled) {
    final param = jsonEncode(<String, Object>{
      'enabled': enabled,
    });
    return EngineBridge.invoke(_kSetGiftEnabled, param, id: _liveID).then((r) => r.toCompletionHandler());
  }

  @override
  void addGiftListener(GiftListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeGiftListener(GiftListener listener) {
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
    _state.usableGifts.value = const <GiftCategory>[];
    _state.isGiftEnabled.value = true;
    _state.userGiftStatisticsList.value = const <GiftStatisticInfo>[];
  }

  // MARK: - Passive Event dispatcher (type 判别)

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
      case 'onReceiveGift':
        final gift = _mapToGift(dict['gift']);
        final receiver = LiveUserInfoCodec.fromMap(dict['receiver']);
        for (final l in _listeners) {
          // ignore: deprecated_member_use_from_same_package
          l.onReceiveGift?.call(
            (dict['liveID'] as String?) ?? '',
            gift,
            (dict['count'] as int?) ?? 1,
            LiveUserInfoCodec.fromMap(dict['sender']),
          );
          l.onReceiveGiftWithReceiver?.call(
            (dict['liveID'] as String?) ?? '',
            gift,
            (dict['count'] as int?) ?? 1,
            LiveUserInfoCodec.fromMap(dict['sender']),
            receiver,
          );
        }
        break;
    }
  }

  // MARK: - Passive State dispatcher (property 判别)

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
      case 'usableGifts':
        {
          final rawList = (dict['usableGifts'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToGiftCategory(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.usableGifts.value = _applyListModify(_state.usableGifts.value, modify, items, (e) => e.categoryID);
          break;
        }
      case 'isGiftEnabled':
        {
          _state.isGiftEnabled.value = (dict['isGiftEnabled'] as bool?) ?? true;
          break;
        }
      case 'userGiftStatisticsList':
        {
          final rawList = (dict['userGiftStatisticsList'] as List?) ?? const [];
          final items =
              rawList.map((e) => _mapToGiftStatisticInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.userGiftStatisticsList.value =
              _applyListModify(_state.userGiftStatisticsList.value, modify, items, (e) => e.receiver);
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

  // MARK: - Model mappers

  Gift _mapToGift(Map<String, dynamic>? map) {
    if (map == null) return Gift();
    final extensionInfoRaw = (map['extensionInfo'] as Map?) ?? const <String, String>{};
    final extensionInfo = extensionInfoRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    return Gift(
      giftID: (map['giftID'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      desc: (map['desc'] as String?) ?? '',
      iconURL: (map['iconURL'] as String?) ?? '',
      resourceURL: (map['resourceURL'] as String?) ?? '',
      level: (map['level'] as int?) ?? 0,
      coins: (map['coins'] as int?) ?? 0,
      extensionInfo: extensionInfo,
    );
  }

  GiftCategory _mapToGiftCategory(Map<String, dynamic>? map) {
    if (map == null) return GiftCategory();
    final giftListRaw = (map['giftList'] as List?) ?? const [];
    final giftList = giftListRaw.map((e) => _mapToGift(e is Map ? e.cast<String, dynamic>() : null)).toList();
    final extensionInfoRaw = (map['extensionInfo'] as Map?) ?? const <String, String>{};
    final extensionInfo = extensionInfoRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    return GiftCategory(
      categoryID: (map['categoryID'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      desc: (map['desc'] as String?) ?? '',
      extensionInfo: extensionInfo,
      giftList: giftList,
    );
  }

  GiftStatisticInfo _mapToGiftStatisticInfo(Map<String, dynamic>? map) {
    if (map == null) return GiftStatisticInfo();
    return GiftStatisticInfo(
      receiver: (map['receiver'] as String?) ?? '',
      totalGiftCount: (map['totalGiftCount'] as num?)?.toInt() ?? 0,
      totalGiftCoins: (map['totalGiftCoins'] as num?)?.toInt() ?? 0,
      totalGiftSendersCount: (map['totalGiftSendersCount'] as num?)?.toInt() ?? 0,
    );
  }
}
