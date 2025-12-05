import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'android_pip_method_channel.dart';

class AndroidPipFeature {
  final AndroidPipChannel _channel = AndroidPipChannel();
  StreamSubscription<PictureInPictureState>? _subscription;
  
  bool _isEnabled = false;
  bool _isInPipMode = false;
  
  VoidCallback? onEnterPip;
  VoidCallback? onLeavePip;
  
  bool get isEnabled => _isEnabled;
  
  bool get isInPipMode => _isInPipMode;

  Future<bool> enable({bool autoEnterPip = true}) async {
    if (!Platform.isAndroid) {
      return false;
    }

    final success = await _channel.enablePictureInPicture(true);
    if (success) {
      _isEnabled = true;
      
      if (autoEnterPip) {
        _startListening();
      }
    }
    
    return success;
  }
  
  Future<bool> disable() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final success = await _channel.enablePictureInPicture(false);
    if (success) {
      _isEnabled = false;
      _stopListening();
    }
    
    return success;
  }

  Future<bool> closePictureInPicture() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final success = await _channel.closePictureInPicture();
    if (success) {
      _isInPipMode = false;
    }
    
    return success;
  }
  
  void _startListening() {
    if (!Platform.isAndroid) return;
    if (_subscription != null) return;
    
    _subscription = _channel.listen(
      onEnter: () {
        if(_isInPipMode) return;
        _isInPipMode = true;
        onEnterPip?.call();
      },
      onLeave: () {
        if (!_isInPipMode) return;
        _isInPipMode = false;
        onLeavePip?.call();
      },
    );
  }
  
  void _stopListening() {
    if (!Platform.isAndroid) return;

    _subscription?.cancel();
    _subscription = null;
    _isInPipMode = false;
  }

  void dispose() {
    _stopListening();
    _channel.dispose();
  }
}