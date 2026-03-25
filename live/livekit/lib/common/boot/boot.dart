import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

class Boot {
  static final Boot instance = Boot._internal();

  factory Boot() {
    return instance;
  }

  Boot._internal() {
    _recordGlobalError();
  }

  void _recordGlobalError() {
    FlutterExceptionHandler? oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      LiveKitLogger.error("FlutterExceptionHandler: ${details.toString()}");
      oldHandler?.call(details);
    };

    ErrorCallback? oldCallback = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      LiveKitLogger.error("ErrorCallback: error:$error, stack:${stack.toString()}");
      oldCallback?.call(error, stack);
      return true;
    };
  }
}
