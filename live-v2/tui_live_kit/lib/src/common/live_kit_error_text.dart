library;

import 'package:atomic_x_core/atomicxcore.dart';

class LiveKitErrorText {
  LiveKitErrorText._();

  /// AtomicXCore 的异步接口统一返回 [CompletionHandler]，失败时用错误码与描述展示。
  static String message(CompletionHandler handler) {
    final String detail = (handler.errorMessage ?? '').trim();
    return detail.isEmpty ? 'AtomicXCore error (${handler.errorCode})' : detail;
  }
}
