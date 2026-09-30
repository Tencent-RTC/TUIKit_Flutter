// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/api/view/camera_view.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/material.dart';

import '../../../../api/view/live/live_core_widget.dart';

// for owner: local render before start live
class LocalPreviewLayer extends StatefulWidget {
  final LiveCoreControllerImpl controller;

  const LocalPreviewLayer({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() {
    return _LocalPreviewLayerState();
  }
}

class _LocalPreviewLayerState extends State<LocalPreviewLayer> {
  int _nativeViewPtr = 0;
  late final String userId;
  late final _cameraStatusListener = _onCameraStatusChanged;
  late final InternalState _internalState;

  @override
  void initState() {
    super.initState();
    userId = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (userId.isNotEmpty) {
      DeviceStore.shared.state.cameraStatus.addListener(_cameraStatusListener);
    }
    _internalState = widget.controller.getInternalState();
  }

  @override
  void dispose() {
    super.dispose();
    if (userId.isNotEmpty) {
      DeviceStore.shared.state.cameraStatus.removeListener(_cameraStatusListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty ||
        _internalState.seatList.value.isNotEmpty ||
        widget.controller.getCoreViewType() != CoreViewType.pushView) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
        listenable: Listenable.merge([
          DeviceStore.shared.state.cameraStatus,
          _internalState.seatList,
        ]),
        builder: (context, _) {
          if (_internalState.seatList.value.isNotEmpty) {
            return const SizedBox.shrink();
          }
          return Visibility(
            visible: DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on,
            child: CameraView(
              key: ValueKey(userId),
              onViewCreated: (id) {
                _onViewCreated(id);
              },
              onViewDisposed: (id) {
                _onViewDisposed();
              },
            ),
          );
        });
  }

  void _onViewCreated(int viewID) {
    _nativeViewPtr = viewID;
    if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on) {
      widget.controller.setVideoView(userId, _nativeViewPtr);
    }
  }

  void _onViewDisposed() {
    _nativeViewPtr = 0;
    widget.controller.setVideoView(userId, 0);
  }

  void _onCameraStatusChanged() {
    if (DeviceStore.shared.state.cameraStatus.value == DeviceStatus.on && _nativeViewPtr != 0) {
      widget.controller.setVideoView(userId, _nativeViewPtr);
    }
  }
}
