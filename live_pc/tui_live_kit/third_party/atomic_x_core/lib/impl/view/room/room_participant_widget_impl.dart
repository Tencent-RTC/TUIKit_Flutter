part of 'package:atomic_x_core/api/view/room/room_participant_widget.dart';

class _ViewConstants {
  static const double clickActionMaxMoveDistance = 10.0;
  static const double scaleMaximum = 5.0;
  static const double scaleMinimum = 1.0;
}

class _VideoStreamConstants {
  static const double hdThresholdWidthPx = 960.0;
  static const int maxHdStreamCount = 5;
}

int _selfViewId = 0;

class _RoomParticipantWidgetState extends State<RoomParticipantWidget> {
  Offset? _touchDownPoint;
  bool _isClickAction = false;
  int _pointerCount = 0;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _initialScale = 1.0;
  Offset _initialOffset = Offset.zero;
  bool _isScaleGestureActive = false;
  Matrix4 _transformMatrix = Matrix4.identity();

  int? _viewID;

  double _lastWidth = 0.0;

  RoomParticipantControllerImpl get _controller => widget.controller as RoomParticipantControllerImpl;

  @override
  void initState() {
    super.initState();
    _initializeEngine();
    EngineBridge.setQueryHandler('RoomModule.getLocalView', (String jsonData) {
      if (_selfViewId == 0) return '{}';
      return jsonEncode({'view': ViewIdCodec.encode(_selfViewId)});
    });
    DeviceStore.shared.state.cameraStatus.addListener(_onCameraStatusChanged);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    DeviceStore.shared.state.cameraStatus.removeListener(_onCameraStatusChanged);
    _controller.removeListener(_onControllerUpdate);
    if (_viewID != null && _viewID != 0 && _selfViewId == _viewID) {
      _selfViewId = 0;
    }
    _destroy();
    _viewID = null;
    super.dispose();
  }

  void _proactiveOpenCamera() {
    if (!mounted || _selfViewId == 0) return;
    EngineBridge.invoke('DeviceModule.openLocalCamera',
        jsonEncode({'isFront': DeviceStore.shared.state.isFrontCamera.value, 'view': ViewIdCodec.encode(_selfViewId)}));
  }

  void _onCameraStatusChanged() {
    final cameraOn = DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on;
    if (!cameraOn) return;
    if (_selfViewId != 0) {
      _proactiveOpenCamera();
    } else if (_viewID != null && _viewID != 0) {
      final loginUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
      if (_controller._participant.userID == loginUserID) {
        _selfViewId = _viewID!;
        _proactiveOpenCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth != _lastWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onLayoutWidthChanged(constraints.maxWidth, _lastWidth);
            _lastWidth = constraints.maxWidth;
          });
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (PointerDownEvent event) {
            _incrementPointerCount();
            if (_pointerCount == 1) {
              _touchDownPoint = event.position;
              _isClickAction = true;
            } else {
              _isClickAction = false;
            }
          },
          onPointerMove: (PointerMoveEvent event) {
            if (_pointerCount == 1 && _touchDownPoint != null) {
              final distance = (event.position - _touchDownPoint!).distance;
              if (distance >= _ViewConstants.clickActionMaxMoveDistance) {
                _isClickAction = false;
              }
            }
          },
          onPointerUp: (PointerUpEvent event) {
            if (_pointerCount == 1 && _isClickAction) {
              if (_controller._streamType == VideoStreamType.screen && _controller._clickAction != null) {
                _controller._clickAction!();
              }
            }

            _decrementPointerCount();
          },
          onPointerCancel: (PointerCancelEvent event) {
            _decrementPointerCount();
          },
          child: RawGestureDetector(
            gestures: _controller._streamType == VideoStreamType.screen
                ? {
                    _ScreenShareScaleRecognizer: GestureRecognizerFactoryWithHandlers<_ScreenShareScaleRecognizer>(
                      () => _ScreenShareScaleRecognizer(),
                      (_ScreenShareScaleRecognizer instance) {
                        instance
                          ..onStart = _onScaleStart
                          ..onUpdate = _onScaleUpdate
                          ..onEnd = _onScaleEnd;
                      },
                    ),
                  }
                : {
                    ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                      (ScaleGestureRecognizer instance) {
                        instance
                          ..onStart = _onScaleStart
                          ..onUpdate = _onScaleUpdate
                          ..onEnd = _onScaleEnd;
                      },
                    ),
                  },
            behavior: HitTestBehavior.opaque,
            child: Transform(
              transform: _transformMatrix,
              child: _buildVideoView(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoView() {
    return CameraView(
      onViewCreated: (viewID) {
        _viewID = viewID;
        if (_isReady()) {
          _initView(_controller._streamType, _controller._participant);
        }
      },
      onViewDisposed: (id) {
        _onVideoViewDisposed();
      },
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});

      if (!_controller._isActive) {
        _stop();
        return;
      }

      if (_isReady()) {
        _initView(_controller._streamType, _controller._participant);
      }
    }
  }

  Future<void> _initializeEngine() async {
    if (_isReady() && _viewID != null) {
      _initView(_controller._streamType, _controller._participant);
    }
  }

  bool _isReady() {
    return _controller._isActive;
  }

  void _initView(VideoStreamType streamType, RoomParticipant participant) {
    final loginUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';

    if (loginUserID.isEmpty) {
      return;
    }
    if (_controller._fillMode != null) {
      _applyFillMode(streamType, participant, _controller._fillMode!);
    }

    final userID = participant.userID;
    if (userID == loginUserID) {
      if (_viewID != null && _viewID != 0) {
        _selfViewId = _viewID!;
      }
      if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on) {
        _proactiveOpenCamera();
      }
      return;
    }

    switch (streamType) {
      case VideoStreamType.camera:
        _initRemoteCameraView(participant);
        break;
      case VideoStreamType.screen:
        _initRemoteScreenShareView(participant);
        break;
    }
  }

  void _onVideoViewDisposed() {
    final userID = _controller._participant.userID;
    final currentUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (userID == currentUserID || _viewID == null) {
      if (userID == currentUserID && _viewID != null && _selfViewId == _viewID) {
        _selfViewId = 0;
      }
      _viewID = null;
      return;
    }

    final videoManager = VideoStreamManager.shared;
    final viewID = _viewID!;

    switch (_controller._streamType) {
      case VideoStreamType.camera:
        videoManager.stopPlayCameraStream(userID: userID, viewID: viewID);
        break;
      case VideoStreamType.screen:
        videoManager.stopPlayScreenShareStream(userID: userID, viewID: viewID);
        break;
    }

    _viewID = null;
  }

  void _initRemoteCameraView(RoomParticipant participant) {
    if (participant.cameraStatus == DeviceStatus.on && _viewID != null) {
      VideoStreamManager.shared
          .startPlayCameraStream(userID: participant.userID, viewID: _viewID!, viewWidth: _lastWidth);
    } else if (_viewID != null) {
      VideoStreamManager.shared.stopPlayCameraStream(userID: participant.userID, viewID: _viewID!);
    }
  }

  void _initRemoteScreenShareView(RoomParticipant participant) {
    if (participant.screenShareStatus == DeviceStatus.on && _viewID != null) {
      VideoStreamManager.shared.startPlayScreenShareStream(userID: participant.userID, viewID: _viewID!);
    } else if (_viewID != null) {
      VideoStreamManager.shared.stopPlayScreenShareStream(userID: participant.userID, viewID: _viewID!);
    }
  }

  void _applyFillMode(VideoStreamType streamType, RoomParticipant participant, FillMode fillMode) {
    VideoStreamManager.shared.setFillMode(userID: participant.userID, streamType: streamType, fillMode: fillMode);
  }

  void _stop() {
    final selfUserId = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (selfUserId == null || selfUserId.isEmpty) {
      return;
    }

    if (_controller._participant.userID == selfUserId) {
      return;
    }
    if (_viewID == null) return;
    switch (_controller._streamType) {
      case VideoStreamType.camera:
        VideoStreamManager.shared.stopPlayCameraStream(userID: _controller._participant.userID, viewID: _viewID!);
        break;
      case VideoStreamType.screen:
        VideoStreamManager.shared.stopPlayScreenShareStream(userID: _controller._participant.userID, viewID: _viewID!);
        break;
    }
  }

  void _destroy() {
    final userID = _controller._participant.userID;

    if (userID.isEmpty || _viewID == null) {
      return;
    }

    switch (_controller._streamType) {
      case VideoStreamType.camera:
        VideoStreamManager.shared.stopPlayCameraStream(userID: userID, viewID: _viewID!);
        break;
      case VideoStreamType.screen:
        VideoStreamManager.shared.stopPlayScreenShareStream(userID: userID, viewID: _viewID!);
        break;
    }
  }

  void _onLayoutWidthChanged(double width, double oldWidth) {
    if (width != oldWidth && _isReady()) {
      final userID = _controller._participant.userID;
      final needSwitch = VideoStreamManager.shared.needSwitchStreamType(userID: userID, viewWidth: width);
      if (needSwitch && _viewID != null) {
        VideoStreamManager.shared.startPlayCameraStream(userID: userID, viewID: _viewID!, viewWidth: width);
      }
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_controller._streamType != VideoStreamType.screen || _isScaleGestureActive) return;

    _initialScale = _scale;
    _initialOffset = _offset;
    _isScaleGestureActive = true;

    if (details.pointerCount == 1) {
      _isClickAction = true;
      _touchDownPoint = details.focalPoint;
    } else {
      _isClickAction = false;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_controller._streamType != VideoStreamType.screen) return;

    final size = context.size;
    if (size == null) return;

    if (details.pointerCount == 2 && !_isScaleGestureActive) {
      _initialScale = _scale;
      _initialOffset = _offset;
      _isScaleGestureActive = true;
      _isClickAction = false;
    }

    if (details.pointerCount == 1) {
      _handleSingleFingerDrag(details, size);
    } else if (details.pointerCount == 2) {
      _isClickAction = false;
      _handleTwoFingerScaling(details, size);
    } else if (details.pointerCount > 2) {
      _isClickAction = false;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_controller._streamType != VideoStreamType.screen) return;
    _resetTouchState();
  }

  void _handleSingleFingerDrag(ScaleUpdateDetails details, Size size) {
    if (_scale <= 1.0 || _touchDownPoint == null) return;

    final deltaX = details.focalPoint.dx - _touchDownPoint!.dx;
    final deltaY = details.focalPoint.dy - _touchDownPoint!.dy;

    if (deltaX.abs() >= _ViewConstants.clickActionMaxMoveDistance ||
        deltaY.abs() >= _ViewConstants.clickActionMaxMoveDistance) {
      _isClickAction = false;

      setState(() {
        _offset = _clampOffset(
          _initialOffset + Offset(deltaX, deltaY),
          _scale,
          size,
        );
        _updateTransformMatrix(size);
      });
    }
  }

  void _handleTwoFingerScaling(ScaleUpdateDetails details, Size size) {
    setState(() {
      final newScale = (_initialScale * details.scale).clamp(
        _ViewConstants.scaleMinimum,
        _ViewConstants.scaleMaximum,
      );

      // Calculate the focal point relative to the view center
      final focalPointX = details.localFocalPoint.dx - size.width / 2;
      final focalPointY = details.localFocalPoint.dy - size.height / 2;

      if (newScale > 1.0) {
        // Calculate new offset to keep the focal point stationary during scaling
        final scaleDelta = newScale / _initialScale;
        _offset = Offset(
          _initialOffset.dx + focalPointX - focalPointX * scaleDelta,
          _initialOffset.dy + focalPointY - focalPointY * scaleDelta,
        );
        _offset = _clampOffset(_offset, newScale, size);
      } else {
        _offset = Offset.zero;
      }

      _scale = newScale;
      _updateTransformMatrix(size);
    });
  }

  void _updateTransformMatrix(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    _transformMatrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale)
      ..translate(-centerX, -centerY);
  }

  Offset _clampOffset(Offset offset, double scale, Size size) {
    if (scale <= 1.0) return Offset.zero;

    final maxOffsetX = (size.width * (scale - 1.0)) / 2;
    final maxOffsetY = (size.height * (scale - 1.0)) / 2;

    return Offset(
      offset.dx.clamp(-maxOffsetX, maxOffsetX),
      offset.dy.clamp(-maxOffsetY, maxOffsetY),
    );
  }

  void _incrementPointerCount() {
    _pointerCount++;
  }

  void _decrementPointerCount() {
    if (_pointerCount > 0) _pointerCount--;

    if (_pointerCount == 0) {
      _isScaleGestureActive = false;
      _resetTouchState();
    }
  }

  void _resetTouchState() {
    _isClickAction = false;
    _touchDownPoint = null;
  }
}

// API keys (RoomModule active APIs)
const String _kStartRemoteView = 'RoomModule.startRemoteView';
const String _kStopRemoteView = 'RoomModule.stopRemoteView';
const String _kUpdateRemoteView = 'RoomModule.updateRemoteView';
const String _kSetFillMode = 'RoomModule.setFillMode';

class VideoStreamManager {
  static final VideoStreamManager shared = VideoStreamManager._();

  final Set<String> _hdStreamUsers = {};
  final Map<String, _VideoStreamInfo> _playCameraStreams = {};
  _VideoStreamInfo? _playScreenStream;

  VideoStreamManager._();

  String get _currentRoomID => RoomStore.shared.state.currentRoom.value?.roomID ?? '';

  void startPlayCameraStream({required String userID, required int viewID, required double viewWidth}) {
    if (userID.isEmpty) {
      return;
    }

    final streamType = _decideVideoStreamType(viewWidth);
    final streamInfo = _VideoStreamInfo(userID: userID, streamType: streamType, viewID: viewID);
    if (_playCameraStreams[userID] == streamInfo) {
      return;
    }

    final param = jsonEncode(<String, Object>{
      'userId': userID,
      'streamType': streamType,
      'view': ViewIdCodec.encode(viewID),
    });
    unawaited(EngineBridge.invoke(_kStartRemoteView, param, id: _currentRoomID));

    _playCameraStreams[userID] = streamInfo;
    if (streamType == VideoStreamTypeBridge.cameraStream) {
      _hdStreamUsers.add(userID);
    } else {
      _hdStreamUsers.remove(userID);
    }
  }

  void stopPlayCameraStream({required String userID, required int viewID, bool needClearView = false}) {
    if (userID.isEmpty) {
      return;
    }

    final streamInfo = _playCameraStreams[userID];
    if (streamInfo == null) return;
    if (streamInfo.viewID != viewID) return;

    final roomID = _currentRoomID;
    // Stop both the big and the low camera streams, aligned with other platforms.
    unawaited(EngineBridge.invoke(
      _kStopRemoteView,
      jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.cameraStream.value}),
      id: roomID,
    ));
    unawaited(EngineBridge.invoke(
      _kStopRemoteView,
      jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.cameraStreamLow.value}),
      id: roomID,
    ));
    if (needClearView) {
      unawaited(EngineBridge.invoke(
        _kUpdateRemoteView,
        jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.cameraStream.value, 'view': ''}),
        id: roomID,
      ));
      unawaited(EngineBridge.invoke(
        _kUpdateRemoteView,
        jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.cameraStreamLow.value, 'view': ''}),
        id: roomID,
      ));
    }

    _hdStreamUsers.remove(userID);
    _playCameraStreams.remove(userID);
  }

  void startPlayScreenShareStream({required String userID, required int viewID}) {
    if (userID.isEmpty) {
      return;
    }

    final streamInfo =
        _VideoStreamInfo(userID: userID, streamType: VideoStreamTypeBridge.screenStream.value, viewID: viewID);
    if (_playScreenStream == streamInfo) {
      return;
    }

    final param = jsonEncode(<String, Object>{
      'userId': userID,
      'streamType': VideoStreamTypeBridge.screenStream.value,
      'view': ViewIdCodec.encode(viewID),
    });
    unawaited(EngineBridge.invoke(_kStartRemoteView, param, id: _currentRoomID));

    _playScreenStream = streamInfo;
  }

  void stopPlayScreenShareStream({required String userID, required int viewID, bool needClearView = false}) {
    if (userID.isEmpty) {
      return;
    }

    final streamInfo = _playScreenStream;
    if (streamInfo == null) return;
    if (streamInfo.viewID != viewID) return;

    final roomID = _currentRoomID;
    unawaited(EngineBridge.invoke(
      _kStopRemoteView,
      jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.screenStream.value}),
      id: roomID,
    ));
    if (needClearView) {
      unawaited(EngineBridge.invoke(
        _kUpdateRemoteView,
        jsonEncode(<String, Object>{'userId': userID, 'streamType': VideoStreamTypeBridge.screenStream.value, 'view': ''}),
        id: roomID,
      ));
    }

    _playScreenStream = null;
  }

  bool needSwitchStreamType({required String userID, required double viewWidth}) {
    final streamInfo = _playCameraStreams[userID];
    if (streamInfo == null) return false;

    return _decideVideoStreamType(viewWidth) != streamInfo.streamType;
  }

  void setFillMode({required String userID, required VideoStreamType streamType, required FillMode fillMode}) {
    if (userID.isEmpty) {
      return;
    }

    switch (streamType) {
      case VideoStreamType.camera:
        // Apply to both big and low camera streams; native routes local/remote internally.
        _invokeFillMode(userID: userID, streamType: VideoStreamTypeBridge.cameraStream.value, fillMode: fillMode);
        _invokeFillMode(userID: userID, streamType: VideoStreamTypeBridge.cameraStreamLow.value, fillMode: fillMode);
        break;
      case VideoStreamType.screen:
        _invokeFillMode(userID: userID, streamType: VideoStreamTypeBridge.screenStream.value, fillMode: fillMode);
        break;
    }
  }

  void _invokeFillMode({required String userID, required int streamType, required FillMode fillMode}) {
    final param = jsonEncode(<String, Object>{
      'userId': userID,
      'streamType': streamType,
      'fillMode': fillMode == FillMode.fill ? 0 : 1,
    });
    unawaited(EngineBridge.invoke(_kSetFillMode, param, id: _currentRoomID));
  }

  int _decideVideoStreamType(double viewWidth) {
    if (_hdStreamUsers.length >= _VideoStreamConstants.maxHdStreamCount &&
        viewWidth <= _VideoStreamConstants.hdThresholdWidthPx) {
      return VideoStreamTypeBridge.cameraStreamLow.value;
    }
    return VideoStreamTypeBridge.cameraStream.value;
  }
}

class _VideoStreamInfo {
  final String userID;
  final int streamType;
  final int viewID;

  _VideoStreamInfo({
    required this.userID,
    required this.streamType,
    required this.viewID,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _VideoStreamInfo &&
        other.userID == userID &&
        other.streamType == streamType &&
        other.viewID == viewID;
  }

  @override
  int get hashCode => userID.hashCode ^ streamType.hashCode ^ viewID.hashCode;
}

class _ScreenShareScaleRecognizer extends ScaleGestureRecognizer {
  int _pointerCount = 0;

  @override
  void addPointer(PointerDownEvent event) {
    _pointerCount++;
    super.addPointer(event);

    if (_pointerCount >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointerCount = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}
