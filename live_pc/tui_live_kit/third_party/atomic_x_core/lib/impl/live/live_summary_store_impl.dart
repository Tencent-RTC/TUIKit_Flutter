// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveSummaryStoreImpl @ AtomicXCore
// Function: LiveSummaryStore 纯状态实现，仅承载直播汇总数据与生命周期。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/live/live_summary_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/store_factory.dart';

class _LiveSummaryStateImpl implements LiveSummaryState {
  @override
  final ValueNotifier<LiveSummaryData> summaryData = ValueNotifier<LiveSummaryData>(LiveSummaryData());
}

const String _kCreateModule = 'LiveSummaryModule.createModule';
const String _kDestroyModule = 'LiveSummaryModule.destroyModule';

const String _stateChannel = 'LiveSummaryModule.stateChanged';

class LiveSummaryStoreImpl extends LiveSummaryStore implements IStore {
  LiveSummaryStoreImpl(this._liveID);

  // ignore: unused_field
  final String _liveID;
  SubscriptionToken? _stateToken;
  final _LiveSummaryStateImpl _state = _LiveSummaryStateImpl();

  @override
  LiveSummaryState get liveSummaryState => _state;

  // MARK: - IStore lifecycle

  @override
  void beforeEnterRoom(String roomID) {
    if (_stateToken != null) return;
    _stateToken = EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
  }

  @override
  void afterEnterRoom(dynamic info) {
    unawaited(EngineBridge.invoke(_kCreateModule, '{}', id: _liveID));
  }

  @override
  void didLeaveRoom(String roomID) {
    unawaited(EngineBridge.invoke(_kDestroyModule, '{}', id: roomID));
    final stateToken = _stateToken;
    if (stateToken != null) {
      EngineBridge.unsubscribe(stateToken);
    }
    _stateToken = null;
    _state.summaryData.value = LiveSummaryData();
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

    switch (property) {
      case 'summaryData':
        _state.summaryData.value = _mapToLiveSummaryData(dict['summaryData']);
        break;
    }
  }

  LiveSummaryData _mapToLiveSummaryData(Map<String, dynamic>? map) {
    if (map == null) return LiveSummaryData();
    return LiveSummaryData(
      totalDuration: (map['totalDuration'] as int?) ?? 0,
      totalViewers: (map['totalViewers'] as int?) ?? 0,
      totalGiftsSent: (map['totalGiftsSent'] as int?) ?? 0,
      totalGiftUniqueSenders: (map['totalGiftUniqueSenders'] as int?) ?? 0,
      totalGiftCoins: (map['totalGiftCoins'] as int?) ?? 0,
      totalLikesReceived: (map['totalLikesReceived'] as int?) ?? 0,
      totalMessageSent: (map['totalMessageSent'] as int?) ?? 0,
    );
  }
}
