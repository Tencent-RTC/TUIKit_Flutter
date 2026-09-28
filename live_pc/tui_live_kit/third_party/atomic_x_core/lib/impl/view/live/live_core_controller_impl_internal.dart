// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

part of 'live_core_controller_impl.dart';

/// Current state of preview:
/// - [idle]    : startPreviewLiveStream has not been called, or stopPreviewLiveStream has been called.
/// - [pending] : startPreviewLiveStream has been called, but viewId is not ready yet.
///               The native SDK has not been called.
/// - [active]  : The native SDK has been called, preview is running.
enum PreviewState { idle, pending, active }

class InternalState {
  final ValueNotifier<List<SeatInfo>> seatList = ValueNotifier<List<SeatInfo>>(const <SeatInfo>[]);
  final ValueNotifier<LiveCanvas> canvas = ValueNotifier<LiveCanvas>(LiveCanvas());
  final ValueNotifier<Set<String>> hasVideoStreamUserList = ValueNotifier({});
  final Map<String, int> userViewMap = {};

  Completer<int> _mixStreamViewIdCompleter = Completer<int>();
  int _mixStreamViewId = 0;
  PreviewState _previewState = PreviewState.idle;
}

/// Work for LiveCoreController and LiveCoreWidget
extension LiveCoreControllerImplInternal on LiveCoreControllerImpl {
  void init() {
    _subscribeDataBeforeEnterRoom();
    EngineBridge.setQueryHandler('CoreViewModule.getLocalView', (String jsonData) {
      final selfUserId = LoginStore.shared.loginState.loginUserInfo?.userID;
      final viewId = _internalState.userViewMap[selfUserId];
      if (viewId == null || viewId == 0) return '{}';
      return jsonEncode({'view': ViewIdCodec.encode(viewId)});
    });
  }

  void unInit() {
    _logger.info("unInit, liveID=${getLiveID()}");
    _unsubscribeDataBeforeEnterRoom();
  }

  String getLiveID() {
    return _liveID;
  }

  CoreViewType getCoreViewType() {
    return _coreViewType;
  }

  InternalState getInternalState() {
    return _internalState;
  }

  void setVideoView(String userId, int viewID) {
    _logger.info("setVideoView, userId=$userId, viewID=$viewID");
    _internalState.userViewMap[userId] = viewID;
    if (userId != LoginStore.shared.loginState.loginUserInfo?.userID) {
      _updateRemoteView(userId, viewID);
    } else if (viewID != 0 && DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on) {
      final isFront = DeviceStore.shared.state.isFrontCamera.value;
      EngineBridge.invoke('DeviceModule.openLocalCamera', jsonEncode({'isFront': isFront, 'view': ViewIdCodec.encode(viewID)}));
    }
  }

  void startPlayVideo(String userId) {
    final viewID = _internalState.userViewMap[userId] ?? 0;
    _logger.info("startPlayVideo, userId=$userId, viewID=$viewID");
    if (userId.isEmpty || viewID == 0) return;
    _startRemoteView(userId, viewID);
  }

  void stopPlayVideo(String userId) {
    _logger.info("stopPlayVideo, userId=$userId");
    if (userId.isEmpty) return;
    _stopRemoteView(userId);
  }

  void onMixStreamViewCreated(int viewId) {
    _logger.info("onMixStreamViewCreated, viewId=$viewId, liveID=${getLiveID()}");
    _internalState._mixStreamViewId = viewId;
    if (!_internalState._mixStreamViewIdCompleter.isCompleted) {
      _internalState._mixStreamViewIdCompleter.complete(viewId);
    }
  }

  void onMixStreamViewDisposed(int viewId) {
    _logger.info("onMixStreamViewDisposed, viewId=$viewId, liveID=${getLiveID()}");
    _internalState._mixStreamViewId = 0;
    _internalState._mixStreamViewIdCompleter = Completer<int>();
  }

  Future<int> getMixStreamViewId() {
    if (_internalState._mixStreamViewId != 0) {
      return Future.value(_internalState._mixStreamViewId);
    }
    return _internalState._mixStreamViewIdCompleter.future;
  }

  void _subscribeDataBeforeEnterRoom() {
    if (getLiveID().isEmpty) return;
    if (_liveListListener != null) return;
    LiveListStore listListStore = LiveListStore.shared;
    listListStore.liveState.currentLive.addListener(_onCurrentLiveListener);
    _liveListListener = LiveListListener(
      onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
        _unsubscribeDataAfterEnterRoom();
      },
      onKickedOutOfLive: (String liveID, LiveKickedOutReason reason, String message) {
        _unsubscribeDataAfterEnterRoom();
      },
    );
    listListStore.addLiveListListener(_liveListListener!);
    _stateToken = EngineBridge.subscribe(_stateChannel, _onModuleStateChanged);
    DeviceStore.shared.state.cameraStatus.addListener(_cameraStatusListener);
  }

  void _unsubscribeDataBeforeEnterRoom() {
    if (getLiveID().isEmpty) return;
    LiveListStore listListStore = LiveListStore.shared;
    listListStore.liveState.currentLive.removeListener(_onCurrentLiveListener);
    listListStore.removeLiveListListener(_liveListListener!);
    final stateToken = _stateToken;
    if (stateToken != null) {
      EngineBridge.unsubscribe(stateToken);
    }
    _stateToken = null;
    DeviceStore.shared.state.cameraStatus.removeListener(_cameraStatusListener);
  }

  void _subscribeDataAfterEnterRoom() {
    if (_onUserVideoStateChangedToken != null) return;
    final list = _queryUsersHasVideo();
    _internalState.hasVideoStreamUserList.value = {...list};
    for (var userID in _internalState.hasVideoStreamUserList.value) {
      _onUserVideoStateChanged(getLiveID(), userID, true);
    }

    _onUserVideoStateChangedToken = EngineBridge.subscribe(_kOnUserVideoStateChanged, (String liveID, String jsonData) {
      if (liveID != getLiveID()) return;
      try {
        final map = jsonDecode(jsonData);
        bool hasVideo = map['hasVideo'] ?? false;
        String userId = map['userId'] ?? '';
        _onUserVideoStateChanged(getLiveID(), userId, hasVideo);
      } catch (e) {

      }
    });
  }

  void _unsubscribeDataAfterEnterRoom() {
    if (_onUserVideoStateChangedToken != null) {
      EngineBridge.unsubscribe(_onUserVideoStateChangedToken!);
      _onUserVideoStateChangedToken = null;
    }
  }

  void _onCurrentLiveInfoChanged() {
    if (getLiveID().isEmpty) return;
    LiveListStore listListStore = LiveListStore.shared;
    LiveInfo liveInfo = listListStore.liveState.currentLive.value;
    _logger.info("CurrentLive:${liveInfo.liveID}");
    if (liveInfo.liveID == getLiveID()) {
      _subscribeDataAfterEnterRoom();
    } else if (liveInfo.liveID.isEmpty) {
      _unsubscribeDataAfterEnterRoom();
    }
  }

  void _onCameraStatusChanged() {
    final currentLiveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (currentLiveID != getLiveID()) return;
    final selfID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    final cameraStatus = DeviceStore.shared.state.cameraStatus.value;
    _logger.info("onCameraStatusChanged, cameraStatus=$cameraStatus");
    if (cameraStatus == DeviceStatus.on && selfID.isNotEmpty) {
      final viewID = _internalState.userViewMap[selfID] ?? 0;
      if (viewID != 0) {
        setVideoView(selfID, viewID);
      }
    }
  }

  void _onUserVideoStateChanged(String liveId, String userId, bool hasVideo) {
    _logger.info("onUserVideoStateChanged, liveId=$liveId, userId=$userId, hasVideo=$hasVideo");
    final list = {..._internalState.hasVideoStreamUserList.value};
    final isRemoteUser = userId != LoginStore.shared.loginState.loginUserInfo?.userID;
    if (hasVideo) {
      if (isRemoteUser) {
        final isMixUser = userId.contains('_feedback_');
        if (isMixUser) {
          getMixStreamViewId().then((viewId) {
            if (viewId != 0) {
              setVideoView(userId, viewId);
              startPlayVideo(userId);
              _muteRemoteAudio(userId, false);
            }
          });
        } else {
          startPlayVideo(userId);
        }
      }
      list.add(userId);
    } else {
      if (isRemoteUser) stopPlayVideo(userId);
      list.remove(userId);
    }
    _internalState.hasVideoStreamUserList.value = list;
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
      case 'seatList':
        {
          final rawList = (dict['seatList'] as Map?) ?? const {};
          _internalState.canvas.value = LiveJsonUtil.mapToLiveCanvas(rawList['canvas']);
          final seatList = (rawList['seatList'] as List?) ?? const [];
          final items =
          seatList.map((e) => LiveJsonUtil.mapToSeatInfo(e is Map ? e.cast<String, dynamic>() : null)).toList();
          _internalState.seatList.value =
              _applyListModify(_internalState.seatList.value, modify, items, (e) => e.index.toString());
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

  void _updateRemoteView(String userId, int nativePtr) {
    final param = jsonEncode(<String, Object>{
      'userID': userId,
      'view': ViewIdCodec.encode(nativePtr),
    });
    EngineBridge.invoke(_kApiUpdateRemoteView, param, id: getLiveID());
  }

  void _startRemoteView(String userId, int nativePtr) {
    final param = jsonEncode(<String, Object>{
      'userID': userId,
      'view': ViewIdCodec.encode(nativePtr),
    });
    EngineBridge.invoke(_kApiStartRemoteView, param, id: getLiveID());
  }

  void _stopRemoteView(String userId) {
    final param = jsonEncode(<String, Object>{
      'userID': userId,
    });
    EngineBridge.invoke(_kApiStopRemoteView, param, id: getLiveID());
  }

  void _muteRemoteAudio(String userId, bool mute) {
    final param = jsonEncode(<String, Object>{
      'userID': userId,
      'mute': mute,
    });
    EngineBridge.invoke(_kApiMuteRemoteAudio, param, id: getLiveID());
  }

  List<String> _queryUsersHasVideo() {
    final result = EngineBridge.query(_kApiQueryUsersHasVideo, '{}', id: getLiveID());
    try {
      final list = jsonDecode(result);
      if (list is List) {
        return List<String>.from(list);
      }
    } catch (e) {}
    return [];
  }
}
