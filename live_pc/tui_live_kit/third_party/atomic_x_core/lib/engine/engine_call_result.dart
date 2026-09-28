// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   AtomicEngine
// Function: engine 层与 impl 层之间流通的内部调用结果结构体。
//
// 本类型不对外导出（不会出现在 lib/atomicxcore.dart barrel 文件中），
// 也不出现在 lib/api/ 目录下的公共签名里。impl 层可按需取出 [data]
// 字段做 JSON 反序列化；对无 data 需求的接口，调用 [toCompletionHandler]
// 将其转换为对外的 [CompletionHandler]。

import '../api/define.dart';

/// engine.call 的统一返回结构体。
///
/// 同时携带 native 返回的 `code` / `message` / `data` 三个字段：
/// * [code]：0 表示成功，其他为 native 错误码或 -1（Dart 侧异常）；
/// * [message]：失败时的错误描述，成功时为 `null`；
/// * [data]：native 层透传的业务 JSON 字符串，默认 `''`。
class EngineCallResult {
  /// 调用错误码，0 表示成功。
  final int code;

  /// 调用失败描述，成功时为 `null`。
  final String? message;

  /// native 层透传的业务 JSON 字符串。
  final String data;

  const EngineCallResult({
    required this.code,
    this.message,
    this.data = '',
  });

  /// 是否成功。
  bool get isSuccess => code == 0;

  /// 只暴露 data 长度：data 可能携带敏感载荷（如窗口标题），不进入日志。
  @override
  String toString() => 'EngineCallResult(code: $code, message: $message, dataLen: ${data.length})';

  /// 将当前结果转换为对外的 [CompletionHandler]。
  ///
  /// 仅供 impl 层使用：对于不关心 [data] 的接口，统一通过该方法把 engine
  /// 返回的内部结果转成对外公共基类，避免在每个 impl 文件里重写转换逻辑。
  CompletionHandler toCompletionHandler() {
    return CompletionHandler()
      ..errorCode = code
      ..errorMessage = message;
  }
}
