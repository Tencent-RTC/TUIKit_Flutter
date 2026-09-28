// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/common/log.dart';
import 'package:atomic_x_core/impl/common/store_factory.dart';
import 'package:flutter/cupertino.dart';

import '../../../engine/engine_bridge.dart';
import '../../common/atomic_platform.dart';
import '../../common/list_modify_type.dart';
import '../../common/live_json_util.dart';
import '../../live/live_list_store_impl.dart';
import '../../live/live_seat_store_impl.dart';

part 'live_core_controller_impl_internal.dart';

const String _kApiStartPreview = 'CoreViewModule.startPreview';
const String _kApiStopPreview = 'CoreViewModule.stopPreview';
const String _kApiUpdateRemoteView = 'CoreViewModule.updateRemoteView';
const String _kApiStartRemoteView = 'CoreViewModule.startRemoteView';
const String _kApiStopRemoteView = 'CoreViewModule.stopRemoteView';
const String _kApiMuteRemoteAudio = 'CoreViewModule.muteRemoteAudio';
const String _kApiQueryUsersHasVideo = "CoreViewModule.queryUsersHasVideo";

const String _kOnUserVideoStateChanged = "CoreViewModule.onUserVideoStateChanged";
const String _kOnUserAudioStateChanged = "CoreViewModule.onUserAudioStateChanged";
const String _kOnError = "CoreViewModule.onError";
const String _kOnNetworkQualityChanged = "CoreViewModule.onNetworkQualityChanged";
const String _kOnUserVideoSizeChanged = "CoreViewModule.onUserVideoSizeChanged";

const String _stateChannel = 'CoreViewModule.stateChanged';

class LiveCoreControllerImpl implements LiveCoreController {
  String _liveID = "";
  final InternalState _internalState = InternalState();
  late final CoreViewType _coreViewType;
  late final VoidCallback _onCurrentLiveListener;
  late final VoidCallback _cameraStatusListener;
  static final viewIdTimeout = Duration(seconds: 3);

  SubscriptionToken? _onUserVideoStateChangedToken;
  SubscriptionToken? _stateToken;
  LiveListListener? _liveListListener;
  final Log _logger = Log.getLiveLog("LiveCoreController");

  LiveCoreControllerImpl(CoreViewType type) {
    _coreViewType = type;
    _onCurrentLiveListener = _onCurrentLiveInfoChanged;
    _cameraStatusListener = _onCameraStatusChanged;
  }

  @override
  void setLiveID(String liveID) {
    _liveID = liveID;
    _logger.info("setLiveID:$liveID");
  }

  @override
  void startPreviewLiveStream(String liveID, bool isMuteAudio, PlayCallback? playCallback) {
    _logger.info("startPreviewLiveStream, liveID=$liveID, isMuteAudio=$isMuteAudio");
    DataReport.reportComponent(LiveListStoreImpl.componentFramework);
    _internalState._previewState = PreviewState.pending;
    getMixStreamViewId().then((viewId) {
      if (_internalState._previewState != PreviewState.pending) {
        return;
      }
      // The view may have been disposed (or replaced by a new view) while waiting.
      // Do not pass a stale viewId to the native SDK.
      if (_internalState._mixStreamViewId != viewId) {
        _internalState._previewState = PreviewState.idle;
        return;
      }
      _internalState._previewState = PreviewState.active;
      final param = jsonEncode(<String, Object>{
        'view': ViewIdCodec.encode(viewId),
        'isMuteAudio': isMuteAudio,
      });
      EngineBridge.invoke(_kApiStartPreview, param, id: liveID).then((r) {
        _logger.info(
            "startPreview, liveID=$liveID, viewId=$viewId, isMuteAudio=$isMuteAudio, code=${r.code}, data=${r.data}");
        if (r.isSuccess) {
          debugPrint("startPreview, data=${r.data}");
        }
      });
    }).timeout(viewIdTimeout, onTimeout: () {});
  }

  @override
  void stopPreviewLiveStream(String liveID) {
    _logger.info("stopPreviewLiveStream, liveID=$liveID, previewState=${_internalState._previewState}");
    switch (_internalState._previewState) {
      case PreviewState.idle:
        return;
      case PreviewState.pending:
        _internalState._previewState = PreviewState.idle;
        return;
      case PreviewState.active:
        _internalState._previewState = PreviewState.idle;
        EngineBridge.invoke(_kApiStopPreview, '{}', id: liveID);
    }
  }

  static void callExperimentalAPI(String jsonStr) {
    try {
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;

      if (jsonMap['api'] == 'setFramework' && jsonMap['params'] is Map<String, dynamic>) {
        final params = jsonMap['params'] as Map<String, dynamic>;

        if (params.containsKey('component') && params['component'] is int) {
          LiveListStoreImpl.componentFramework = params['component'] as int;
        }
      }
    } catch (e) {
      // Ignore JSON parsing errors
    } finally {}
  }
}
