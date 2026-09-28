// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveListStoreImpl @ AtomicXCore
// Function: LiveListStore 主动接口实现，通过 AtomicEngine 桥接到 native 层。

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/define.dart';
import '../../api/live/live_list_store.dart';
import '../../engine/engine_bridge.dart';
import '../common/data_report.dart';
import '../common/list_modify_type.dart';
import '../common/log.dart';
import '../common/store_factory.dart';
import 'live_audience_store_define.dart';
import 'live_list_store_define.dart';

class TriggerableValueNotifier<T> extends ValueNotifier<T> {
  TriggerableValueNotifier(super.value);

  void notify() {
    notifyListeners();
  }
}

class _LiveListStateImpl implements LiveListState {
  @override
  final ValueNotifier<List<LiveInfo>> liveList = ValueNotifier<List<LiveInfo>>(const <LiveInfo>[]);

  @override
  final ValueNotifier<String> liveListCursor = ValueNotifier<String>('');

  @override
  final ValueNotifier<LiveInfo> currentLive = TriggerableValueNotifier<LiveInfo>(LiveInfo());
}

// API keys
const String _kFetchLiveList = 'LiveListModule.fetchLiveList';
const String _kFetchLiveInfo = 'LiveListModule.fetchLiveInfo';
const String _kStartLive = 'LiveListModule.startLive';
const String _kJoinLive = 'LiveListModule.joinLive';
const String _kLeaveLive = 'LiveListModule.leaveLive';
const String _kEndLive = 'LiveListModule.endLive';
const String _kUpdateLiveInfo = 'LiveModule.updateLiveInfo';
const String _kQueryMetaData = 'LiveModule.queryMetaData';
const String _kUpdateLiveMetaData = 'LiveModule.updateLiveMetaData';

const String _eventChannel = 'LiveModule.event';
const String _listEventChannel = 'LiveListModule.event';
const String _listStateChannel = 'LiveListModule.stateChanged';

class LiveListStoreImpl extends LiveListStore implements IStore {
  LiveListStoreImpl._() {
    EngineBridge.subscribe(_eventChannel, (String id, String json) {
      if (id == _state.currentLive.value.liveID) _onModuleEvent(id, json);
    });
    EngineBridge.subscribe(_listEventChannel, _onModuleEvent);
    EngineBridge.subscribe(_listStateChannel, _onModuleStateChanged);
  }
  static int componentFramework = 26;
  static final LiveListStoreImpl shared = LiveListStoreImpl._();

  final _LiveListStateImpl _state = _LiveListStateImpl();
  final Set<LiveListListener> _listeners = <LiveListListener>{};
  final Log _logger = Log.getLiveLog("LiveListStore");

  @override
  LiveListState get liveState => _state;

  // MARK: - Simple active APIs

  @override
  Future<CompletionHandler> fetchLiveList({
    required String cursor,
    required int count,
  }) {
    final param = jsonEncode(<String, Object>{
      'cursor': cursor,
      'count': count,
    });
    return EngineBridge.invoke(_kFetchLiveList, param).then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> leaveLive() async {
    final liveID = _state.currentLive.value.liveID;
    final result = await EngineBridge.invoke(_kLeaveLive, '{}', id: liveID);
    _logger.info("leaveLive, liveID=$liveID, code=${result.code}");
    if (result.isSuccess) StoreFactory.shared.didLeaveRoom(liveID);
    return result.toCompletionHandler();
  }

  @override
  Future<CompletionHandler> updateLiveInfo({
    required LiveInfo liveInfo,
    required List<ModifyFlag> modifyFlagList,
  }) {
    final modifyFlag = modifyFlagList.fold<int>(0, (acc, e) => acc | e.rawValue);
    final param = jsonEncode(<String, Object>{
      'liveInfo': _liveInfoToMap(liveInfo),
      'modifyFlag': modifyFlag,
    });
    return EngineBridge.invoke(_kUpdateLiveInfo, param, id: liveInfo.liveID)
        .then((r) => r.toCompletionHandler());
  }

  @override
  Future<CompletionHandler> updateLiveMetaData(Map<String, String> metaData) {
    final param = jsonEncode(<String, Object>{'metaData': metaData});
    return EngineBridge.invoke(_kUpdateLiveMetaData, param, id: _state.currentLive.value.liveID)
        .then((r) => r.toCompletionHandler());
  }

  // MARK: - APIs with extended CompletionHandler

  @override
  Future<LiveInfoCompletionHandler> fetchLiveInfo(String liveID) {
    final param = jsonEncode(<String, Object>{'liveID': liveID});
    return _callAsLiveInfoHandler(_kFetchLiveInfo, param);
  }

  @override
  Future<LiveInfoCompletionHandler> startLive(LiveInfo liveInfo) async {
    DataReport.reportComponent(componentFramework);
    StoreFactory.shared.beforeEnterRoom(liveInfo.liveID, SceneType.live);
    final param = jsonEncode(<String, Object>{
      'liveInfo': _liveInfoToMap(liveInfo),
    });
    final handler = await _callAsLiveInfoHandler(_kStartLive, param, liveID: liveInfo.liveID);
    _logger.info("startLive, liveID=${liveInfo.liveID}, code=${handler.errorCode}");
    if (handler.isSuccess) StoreFactory.shared.afterEnterRoom(liveInfo.liveID, handler.liveInfo);
    return handler;
  }

  @override
  Future<LiveInfoCompletionHandler> joinLive(String liveID) async {
    DataReport.reportComponent(componentFramework);
    StoreFactory.shared.beforeEnterRoom(liveID, SceneType.live);
    final param = jsonEncode(<String, Object>{'liveID': liveID});
    final handler = await _callAsLiveInfoHandler(_kJoinLive, param, liveID: liveID);
    _logger.info("joinLive, liveID=$liveID, code=${handler.errorCode}");
    if (handler.isSuccess) StoreFactory.shared.afterEnterRoom(liveID, handler.liveInfo);
    return handler;
  }

  @override
  Future<StopLiveCompletionHandler> endLive() async {
    final liveID = _state.currentLive.value.liveID;
    final handler = await _callAsStopLiveHandler(_kEndLive, '{}', liveID: liveID);
    _logger.info("endLive, liveID=$liveID, code=${handler.errorCode}");
    if (handler.isSuccess) StoreFactory.shared.didLeaveRoom(liveID);
    return handler;
  }

  @override
  Future<MetaDataCompletionHandler> queryMetaData(List<String> keys) {
    final param = jsonEncode(<String, Object>{'keys': keys});
    return _callAsMetaDataHandler(_kQueryMetaData, param, liveID: _state.currentLive.value.liveID);
  }

  @override
  Future<void> callExperimentalAPI(Map<String, dynamic> jsonMap, {ExperimentalAPICallback? callback}) async {
    final api = jsonMap['api'];
    if (api is! String) return;
    final params = jsonMap['params'];
    final param = params == null ? '{}' : (params is String ? params : jsonEncode(params));
    final result = await EngineBridge.invoke(api, param, id: _state.currentLive.value.liveID);
    callback?.call(result.code, result.message ?? '', result.data);
  }

  @override
  SubscriptionToken subscribeExperimentalEvent(String event, ExperimentalEventCallback callback) {
    _logger.info("subscribeExperimentalEvent:$event");
    return EngineBridge.subscribe(event, (id, json) => callback(id, json));
  }

  @override
  void unsubscribeExperimentalEvent(SubscriptionToken token) {
    EngineBridge.unsubscribe(token);
  }

  // MARK: - Listener & lifecycle

  @override
  void addLiveListListener(LiveListListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeLiveListListener(LiveListListener listener) {
    _listeners.remove(listener);
  }

  @override
  void reset() {
    _logger.info("reset");
    _state.liveList.value = const <LiveInfo>[];
    _state.liveListCursor.value = '';
    _state.currentLive.value = LiveInfo();
    _listeners.clear();
  }

  @override
  void beforeEnterRoom(String roomID) {}

  @override
  void afterEnterRoom(dynamic info) {}

  @override
  void didLeaveRoom(String roomID) {
    _state.currentLive.value = LiveInfo();
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
      case 'onLiveEnded':
        _logger.info("onModuleEvent:id=$id, $json");
        for (final l in _listeners) {
          final liveId = dict['liveID'] as String?;
          l.onLiveEnded?.call(
            liveId ?? '',
            _intToLiveEndedReason(dict['reason'] as int?),
            (dict['message'] as String?) ?? '',
          );
          StoreFactory.shared.didLeaveRoom(liveId ?? "");
        }
        break;
      case 'onKickedOutOfLive':
        _logger.info("onModuleEvent:id=$id, $json");
        final liveId = dict['liveID'] as String?;
        for (final l in _listeners) {
          l.onKickedOutOfLive?.call(
            liveId ?? '',
            _intToLiveKickedOutReason(dict['reason'] as int?),
            (dict['message'] as String?) ?? '',
          );
          StoreFactory.shared.didLeaveRoom(liveId ?? "");
        }
        break;
    }
  }

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

    final modify = (dict['listModifyType'] as int?) ?? 1;
    switch (property) {
      case 'liveList':
        {
          final rawList = (dict['liveList'] as List?) ?? const [];
          final items = rawList.map((e) => _mapToLiveInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _state.liveList.value = _applyListModify(_state.liveList.value, modify, items, (e) => e.liveID);
          _state.liveListCursor.value = (dict['liveListCursor'] as String?) ?? '';
          break;
        }
      case 'currentLive':
        _state.currentLive.value = _mapToLiveInfo(dict['currentLive']);
        _logger.info("currentLive:liveID=${_state.currentLive.value.liveID}");
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

extension _LiveListStoreImplHelpers on LiveListStoreImpl {
  LiveEndedReason _intToLiveEndedReason(int? value) {
    return LiveEndedReason.values.firstWhere(
      (e) => e.value == (value ?? LiveEndedReason.endedByHost.value),
      orElse: () => LiveEndedReason.endedByHost,
    );
  }

  LiveKickedOutReason _intToLiveKickedOutReason(int? value) {
    return LiveKickedOutReason.values.firstWhere(
      (e) => e.value == (value ?? LiveKickedOutReason.byAdmin.value),
      orElse: () => LiveKickedOutReason.byAdmin,
    );
  }

  SeatLayoutTemplate _mapToSeatLayoutTemplate(int? seatLayoutTemplateID, int? maxSeatCount) {
    final seatCount = maxSeatCount ?? 0;
    switch (seatLayoutTemplateID) {
      case 600:
        return const VideoDynamicGrid9Seats();
      case 601:
        return const VideoDynamicFloat7Seats();
      case 602:
        return const VideoLeftFocus9Seats();
      case 603:
        return const VideoUniformGrid9Seats();
      case 800:
        return const VideoFixedGrid9Seats();
      case 801:
        return const VideoFixedFloat7Seats();
      case 200:
        return const VideoLandscape4Seats();
      case 201:
        return const VideoLandscape10Seats();
      case 604:
        return const VideoPortrait10Seats();
      case 50:
        return Karaoke(seatCount);
      case 70:
        return AudioSalon(seatCount);
      default:
        return const VideoDynamicGrid9Seats();
    }
  }

  Map<String, Object> _liveInfoToMap(LiveInfo info) {
    final seatConfig = LiveInfoExtension.getSeatConfiguration(info.seatTemplate);
    return <String, Object>{
      'liveID': info.liveID,
      'liveName': info.liveName,
      'status': info.status.value,
      'notice': info.notice,
      'isMessageDisable': info.isMessageDisable,
      'isPublicVisible': info.isPublicVisible,
      // ignore: deprecated_member_use_from_same_package
      'isSeatEnabled': info.isSeatEnabled,
      'keepOwnerOnSeat': info.keepOwnerOnSeat,
      // ignore: deprecated_member_use_from_same_package
      'maxSeatCount': seatConfig.maxSeatCount ?? -1,
      'seatMode': info.seatMode.value,
      // ignore: deprecated_member_use_from_same_package
      'seatLayoutTemplateID': seatConfig.seatLayoutTemplateID,
      'coverURL': info.coverURL,
      'backgroundURL': info.backgroundURL,
      'categoryList': info.categoryList,
      'activityStatus': info.activityStatus,
      'liveOwner': info.liveOwner.toMap(),
      'createTime': info.createTime,
      'totalViewerCount': info.totalViewerCount,
      'isGiftEnabled': info.isGiftEnabled,
      'metaData': info.metaData,
    };
  }

  LiveInfo _mapToLiveInfo(Map<String, dynamic>? map) {
    if (map == null) return LiveInfo();
    final seatModeValue = (map['seatMode'] as int?) ?? TakeSeatMode.apply.value;
    final seatMode = TakeSeatMode.values.firstWhere(
      (e) => e.value == seatModeValue,
      orElse: () => TakeSeatMode.apply,
    );
    final seatTemplate = _mapToSeatLayoutTemplate(
      map['seatLayoutTemplateID'] as int?,
      map['maxSeatCount'] as int?,
    );
    final statusValue = (map['status'] as int?) ?? LiveStatus.running.value;
    final status = LiveStatus.values.firstWhere(
      (e) => e.value == statusValue,
      orElse: () => LiveStatus.running,
    );
    final categoryList = (map['categoryList'] as List?)?.cast<int>() ?? <int>[];
    final metaDataRaw = (map['metaData'] as Map?) ?? <String, String>{};
    final metaData = metaDataRaw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    return LiveInfo(
      liveID: (map['liveID'] as String?) ?? '',
      liveName: (map['liveName'] as String?) ?? '',
      status: status,
      notice: (map['notice'] as String?) ?? '',
      isMessageDisable: (map['isMessageDisable'] as bool?) ?? false,
      isPublicVisible: (map['isPublicVisible'] as bool?) ?? true,
      isSeatEnabled: map['isSeatEnabled'] as bool?,
      keepOwnerOnSeat: map['keepOwnerOnSeat'] as bool?,
      maxSeatCount: map['maxSeatCount'] as int?,
      seatMode: seatMode,
      seatTemplate: seatTemplate,
      seatLayoutTemplateID: map['seatLayoutTemplateID'] as int?,
      coverURL: (map['coverURL'] as String?) ?? '',
      backgroundURL: (map['backgroundURL'] as String?) ?? '',
      categoryList: categoryList,
      activityStatus: (map['activityStatus'] as int?) ?? 0,
      liveOwner: LiveUserInfoCodec.fromMap(map['liveOwner'] as Map<String, dynamic>?),
      createTime: (map['createTime'] as int?) ?? 0,
      totalViewerCount: (map['totalViewerCount'] as int?) ?? 0,
      isGiftEnabled: (map['isGiftEnabled'] as bool?) ?? true,
      metaData: metaData,
    );
  }

  LiveStatisticsData _mapToLiveStatisticsData(Map<String, dynamic> map) {
    final data = LiveStatisticsData();
    data.totalViewers = (map['totalViewers'] as int?) ?? 0;
    data.totalGiftsSent = (map['totalGiftsSent'] as int?) ?? 0;
    data.totalGiftCoins = (map['totalGiftCoins'] as int?) ?? 0;
    data.totalUniqueGiftSenders = (map['totalUniqueGiftSenders'] as int?) ?? 0;
    data.totalLikesReceived = (map['totalLikesReceived'] as int?) ?? 0;
    data.totalMessageCount = (map['totalMessageCount'] as int?) ?? 0;
    data.liveDuration = (map['liveDuration'] as int?) ?? 0;
    return data;
  }

  Future<LiveInfoCompletionHandler> _callAsLiveInfoHandler(
    String api,
    String param, {
    String? liveID,
  }) async {
    final base = await EngineBridge.invoke(api, param, id: liveID ?? '');
    final handler = LiveInfoCompletionHandler();
    handler.errorCode = base.code;
    handler.errorMessage = base.message;
    if (base.isSuccess && base.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(base.data);
        if (decoded is Map<String, dynamic>) {
          handler.liveInfo = _mapToLiveInfo(decoded);
        }
      } catch (e) {
        debugPrint('[LiveListStoreImpl] decode liveInfo failed: $e');
      }
    }
    return handler;
  }

  Future<StopLiveCompletionHandler> _callAsStopLiveHandler(
    String api,
    String param, {
    required String liveID,
  }) async {
    final base = await EngineBridge.invoke(api, param, id: liveID);
    final handler = StopLiveCompletionHandler();
    handler.errorCode = base.code;
    handler.errorMessage = base.message;
    if (base.isSuccess && base.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(base.data);
        if (decoded is Map<String, dynamic>) {
          handler.statisticsData = _mapToLiveStatisticsData(decoded);
        }
      } catch (e) {
        debugPrint('[LiveListStoreImpl] decode stopLive statistics failed: $e');
      }
    }
    return handler;
  }

  Future<MetaDataCompletionHandler> _callAsMetaDataHandler(
    String api,
    String param, {
    required String liveID,
  }) async {
    final base = await EngineBridge.invoke(api, param, id: liveID);
    final handler = MetaDataCompletionHandler();
    handler.errorCode = base.code;
    handler.errorMessage = base.message;
    if (base.isSuccess && base.data.isNotEmpty) {
      try {
        final decoded = jsonDecode(base.data);
        if (decoded is Map) {
          handler.metaData = decoded.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          );
        }
      } catch (e) {
        debugPrint('[LiveListStoreImpl] decode metaData failed: $e');
      }
    }
    return handler;
  }
}
