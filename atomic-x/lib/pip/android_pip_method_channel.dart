import 'dart:async';

import 'package:flutter/services.dart';

enum PictureInPictureState {
  enter,
  leave,
}

class AndroidPipChannel {
  static const String _methodChannelName = 'atomic_x/pip';
  static const String _eventChannelName = 'atomic_x_pip_events';

  static const String _enablePictureInPictureMethod = 'enablePictureInPicture';
  static const String _stateEnterPip = 'state_enter_pip';
  static const String _stateLeavePip = 'state_leave_pip';

  final MethodChannel _methodChannel = const MethodChannel(_methodChannelName);
  final EventChannel _eventChannel = const EventChannel(_eventChannelName);

  Stream<PictureInPictureState>? _pipStateStream;

  Future<bool> enablePictureInPicture(bool enable) async {
    try {
      final params = {
        'params': {
          'enable': enable,
        }
      };
      
      final result = await _methodChannel.invokeMethod<bool>(
        _enablePictureInPictureMethod,
        params,
      );
      
      return result ?? false;
    } on PlatformException catch (e) {
      print('enable pip failed: ${e.message}');
      return false;
    }
  }

  Future<bool> closePictureInPicture() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'closePictureInPicture',
      );
      
      return result ?? false;
    } on PlatformException catch (e) {
      print('close pip failed: ${e.message}');
      return false;
    }
  }

  Stream<PictureInPictureState> get pipStateStream {
    _pipStateStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event == _stateEnterPip) {
        return PictureInPictureState.enter;
      } else if (event == _stateLeavePip) {
        return PictureInPictureState.leave;
      }
      return PictureInPictureState.leave;
    });
    
    return _pipStateStream!;
  }

  StreamSubscription<PictureInPictureState> listen({
    Function()? onEnter,
    Function()? onLeave,
  }) {
    return pipStateStream.listen((state) {
      switch (state) {
        case PictureInPictureState.enter:
          onEnter?.call();
          break;
        case PictureInPictureState.leave:
          onLeave?.call();
          break;
      }
    });
  }

  void dispose() {
    _pipStateStream = null;
  }
}