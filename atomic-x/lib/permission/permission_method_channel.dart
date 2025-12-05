import 'package:flutter/services.dart';

/// Manages the MethodChannel communication for the Permission module.
class PermissionMethodChannel {
  PermissionMethodChannel({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger ?? _getDefaultBinaryMessenger();

  static const String _channelName = 'atomic_x/permission';
  final BinaryMessenger _binaryMessenger;
  late final MethodChannel _methodChannel = MethodChannel(
    _channelName,
    const StandardMethodCodec(),
    _binaryMessenger,
  );

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) {
    return _methodChannel.invokeMethod<T>(method, arguments);
  }

  void dispose() {
    _methodChannel.setMethodCallHandler(null);
  }

  static BinaryMessenger _getDefaultBinaryMessenger() {
    final binding = ServicesBinding.instance;
    return binding.defaultBinaryMessenger;
  }
}
