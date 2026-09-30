import 'dart:convert';

import 'package:atomic_x_core/api/call/call_store.dart';
import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/api/view/camera_view.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:atomic_x_core/impl/view/view_define.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

const String _kApiStartRemoteView = 'CallModule.startRemoteView';
const String _kApiStopRemoteView = 'CallModule.stopRemoteView';
const String _kApiGetCameraZoomMaxRatio = 'CallModule.getCameraZoomMaxRatio';
const String _kApiSetCameraZoomRatio = 'CallModule.setCameraZoomRatio';

class _ZoomConfig {
  static const double defaultZoom = 1.0;
  static const double maxZoomFallback = 5.0;
}

int _selfViewPtr = 0;

class CallParticipantView extends StatefulWidget {
  final String participantId;
  final VideoStreamTypeBridge mediaType;
  final bool enableZoom;

  const CallParticipantView({
    super.key,
    required this.participantId,
    this.mediaType = VideoStreamTypeBridge.cameraStream,
    this.enableZoom = false,
  });

  @override
  State<StatefulWidget> createState() => _CallParticipantViewState();
}

class _CallParticipantViewState extends State<CallParticipantView> {
  double _zoomAtGestureStart = _ZoomConfig.defaultZoom;
  double _maxZoom = _ZoomConfig.maxZoomFallback;

  bool _isSelfCached = false;
  int _nativeViewPtr = 0;
  bool? _lastRemoteCameraOpened;

  @override
  void initState() {
    super.initState();
    _isSelfCached = _isSelfParticipant();
    if (widget.enableZoom) {
      _initializeZoom();
    }
    EngineBridge.setQueryHandler('CallModule.getLocalView', (String jsonData) {
      if (_selfViewPtr == 0) return '{}';
      return jsonEncode({'view': ViewIdCodec.encode(_selfViewPtr)});
    });
    DeviceStore.shared.state.cameraStatus.addListener(_onCameraStatusChanged);
    CallStore.shared.state.selfInfo.addListener(_onSelfInfoChanged);
    CallStore.shared.state.allParticipants.addListener(_onRemoteCameraChanged);
  }

  @override
  void dispose() {
    DeviceStore.shared.state.cameraStatus.removeListener(_onCameraStatusChanged);
    CallStore.shared.state.selfInfo.removeListener(_onSelfInfoChanged);
    CallStore.shared.state.allParticipants.removeListener(_onRemoteCameraChanged);
    if (_isSelfCached && _nativeViewPtr != 0 && _selfViewPtr == _nativeViewPtr) {
      _selfViewPtr = 0;
    }
    super.dispose();
  }

  void _onSelfInfoChanged() {
    final isSelfNow = _isSelfParticipant();
    if (isSelfNow && !_isSelfCached) {
      _isSelfCached = true;
      if (_nativeViewPtr != 0) {
        _selfViewPtr = _nativeViewPtr;
        if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on) {
          _proactiveOpenCamera();
        }
      }
    }
  }

  void _proactiveOpenCamera() {
    if (!mounted || _selfViewPtr == 0) return;
    EngineBridge.invoke('DeviceModule.openLocalCamera', jsonEncode({'isFront': DeviceStore.shared.state.isFrontCamera.value, 'view': ViewIdCodec.encode(_selfViewPtr)}));
  }

  void _onCameraStatusChanged() {
    final cameraOn = DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on;
    if (!cameraOn) return;
    if (_selfViewPtr != 0) {
      _proactiveOpenCamera();
    } else if (_nativeViewPtr != 0 && _isSelfParticipant()) {
      _isSelfCached = true;
      _selfViewPtr = _nativeViewPtr;
      _proactiveOpenCamera();
    }
  }

  @override
  void didUpdateWidget(covariant CallParticipantView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableZoom && !oldWidget.enableZoom) {
      _initializeZoom();
    }
  }

  bool _isSelfParticipant() {
    final selfId = CallStore.shared.state.selfInfo.value.id;
    return selfId.isNotEmpty && selfId == widget.participantId;
  }

  void _initializeZoom() {
    _updateMaxZoomIfNeeded();
  }

  void _updateMaxZoomIfNeeded() {
    final result = EngineBridge.query(_kApiGetCameraZoomMaxRatio, '{}');
    if (result.isEmpty) return;
    try {
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      final maxZoom = (decoded['maxZoomRatio'] as num?)?.toDouble();
      if (maxZoom != null && maxZoom.isFinite && maxZoom > 1.0) {
        _maxZoom = maxZoom;
      }
    } catch (_) {
      // ignore parse errors, keep fallback
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = CallStore.shared.state.zoom.value;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) return;
    _setZoomRatio(_zoomAtGestureStart * details.scale);
  }

  void _setZoomRatio(double ratio) {
    if (!ratio.isFinite || ratio < _ZoomConfig.defaultZoom) return;

    _updateMaxZoomIfNeeded();

    final clampedRatio = ratio.clamp(_ZoomConfig.defaultZoom, _maxZoom);
    if (clampedRatio == CallStore.shared.state.zoom.value) return;

    final param = jsonEncode(<String, Object>{
      'zoomRatio': clampedRatio,
    });
    EngineBridge.invoke(_kApiSetCameraZoomRatio, param);
    CallStore.shared.state.zoom.value = clampedRatio;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableZoom) {
      return _buildVideoView();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: _buildVideoView(),
    );
  }

  Widget _buildVideoView() {
    return IgnorePointer(
      child: CameraView(
        onViewCreated: _onNativeViewCreated,
      ),
    );
  }

  void _onNativeViewCreated(int nativePtr) {
    _nativeViewPtr = nativePtr;
    if (!_isSelfParticipant()) {
      _startRemoteView(widget.participantId, nativePtr);
    } else {
      _isSelfCached = true;
      _selfViewPtr = nativePtr;
      if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on) {
        _proactiveOpenCamera();
      }
    }
  }

  void _startRemoteView(String userId, int nativePtr) {
    final param = jsonEncode(<String, Object>{
      'userId': userId,
      'view': ViewIdCodec.encode(nativePtr),
      'streamType': widget.mediaType.index,
    });
    EngineBridge.invoke(_kApiStartRemoteView, param);
  }

  void _stopRemoteView(String userId) {
    final param = jsonEncode(<String, Object>{
      'userId': userId,
      'streamType': widget.mediaType.index,
    });
    EngineBridge.invoke(_kApiStopRemoteView, param);
  }

  void _onRemoteCameraChanged() {
    if (!mounted || _isSelfParticipant()) return;
    final participants = CallStore.shared.state.allParticipants.value;
    final participant = participants.firstWhereOrNull((p) => p.id == widget.participantId);
    final opened = participant?.isCameraOpened;
    final last = _lastRemoteCameraOpened;
    _lastRemoteCameraOpened = opened;
    if (last == null || opened == null || opened == last) return;
    if (_nativeViewPtr == 0) return;
    if (opened) {
      _startRemoteView(widget.participantId, _nativeViewPtr);
    } else {
      _stopRemoteView(widget.participantId);
    }
  }
}
