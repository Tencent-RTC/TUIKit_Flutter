// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   AtomicEngineFfi
// Function: dart:ffi bindings to libatomicengine C ABI.
//
// 本文件只做"符号绑定 + 原始类型封装"，不包含业务语义 / 错误处理 / 日志等
// 上层关注。上层入口见 engine/engine_bridge.dart。

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'package:atomic_x_core/impl/common/atomic_platform.dart';

import 'engine_call_result.dart';

// ============================================================================
// 1. C ABI typedef（与 atomic_engine_c_api.h 一一对应）
// ============================================================================

// --- Lifecycle ---

typedef _AtomicEngineCreateNative = Pointer<Void> Function();
typedef _AtomicEngineCreateDart = Pointer<Void> Function();

typedef _AtomicEngineDestroyNative = Void Function(Pointer<Void> handle);
typedef _AtomicEngineDestroyDart = void Function(Pointer<Void> handle);

typedef _AtomicEngineInitNative = Void Function(Pointer<Void> handle);
typedef _AtomicEngineInitDart = void Function(Pointer<Void> handle);

typedef _AtomicEngineUninitNative = Void Function(Pointer<Void> handle);
typedef _AtomicEngineUninitDart = void Function(Pointer<Void> handle);

// --- Port-based init ---

typedef _AtomicEngineInitDartApiDLNative = IntPtr Function(Pointer<Void> data);
typedef _AtomicEngineInitDartApiDLDart = int Function(Pointer<Void> data);

typedef _AtomicEngineRegisterSendPortNative = Void Function(Int64 sendPort);
typedef _AtomicEngineRegisterSendPortDart = void Function(int sendPort);

typedef _AtomicEngineRegisterEventPortNative = Void Function(Int64 sendPort);
typedef _AtomicEngineRegisterEventPortDart = void Function(int sendPort);

// --- Call / Query ---

typedef _AtomicEngineCallNative = Void Function(
  Pointer<Void> handle,
  Pointer<Utf8> apiName,
  Pointer<Utf8> id,
  Pointer<Utf8> jsonParam,
  Pointer<Utf8> token,
);
typedef _AtomicEngineCallDart = void Function(
  Pointer<Void> handle,
  Pointer<Utf8> apiName,
  Pointer<Utf8> id,
  Pointer<Utf8> jsonParam,
  Pointer<Utf8> token,
);

typedef _AtomicEngineQueryNative = Pointer<Utf8> Function(
  Pointer<Void> handle,
  Pointer<Utf8> apiName,
  Pointer<Utf8> id,
  Pointer<Utf8> jsonParam,
);
typedef _AtomicEngineQueryDart = Pointer<Utf8> Function(
  Pointer<Void> handle,
  Pointer<Utf8> apiName,
  Pointer<Utf8> id,
  Pointer<Utf8> jsonParam,
);

// --- Reverse dispatch: C→Dart event (port-based) ---

// ============================================================================
// 2. DynamicLibrary 加载
// ============================================================================

DynamicLibrary _openLibrary() {
  if (Platform.isAndroid) {
    // AtomicEnginePlugin.kt companion init already calls
    // System.loadLibrary("atomicengine"), which triggers ART's JNI_OnLoad
    // and sets g_jvm. When DynamicLibrary.open is called here, the .so is
    // already loaded and g_jvm is already initialized.
    return DynamicLibrary.open('libatomicengine.so');
  }
  if (Platform.isIOS || Platform.isMacOS) {
    // iOS xcframework 合并进主 App 进程空间，macOS 调试用 .dylib 也通常走
    // process-wide 查找；符号已在主进程中。
    return DynamicLibrary.process();
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('AtomicXCore_Win.dll');
  }
  if (AtomicPlatform.isOhos) {
    return DynamicLibrary.open('libatomicengine.so');
  }
  throw UnsupportedError(
    'AtomicEngine ffi: unsupported platform ${Platform.operatingSystem}',
  );
}

// ============================================================================
// 3. FFI 绑定类
// ============================================================================

/// dart:ffi 绑定层：加载 libatomicengine 并暴露面向 Dart 的调用接口。
///
/// 线程模型：
/// - 所有 ffi 方法在 Dart 调用线程上执行，native 侧 `AtomicEngine_Call` 本身
///   只做任务分发即返回；
/// - 异步 call 响应通过 native 侧 `Dart_PostCObject_DL` 投递到本 isolate 的
///   常驻 [ReceivePort]，以事件形式到达事件循环，从而避开 isolate 之间的内存
///   可见性问题，也不存在 per-call trampoline 的 use-after-free。
///
/// 内存模型：
/// - 每次 `call` 分配的 `Pointer<Utf8>` 参数在 native 同步返回后立即 free
///   （native 侧已 dup / 拷贝，不持有指针）；
/// - call 响应经 token 路由到 `Map<String, Completer>`，complete 后移除；重复
///   投递的同一 token 查不到直接忽略，天然幂等；
/// - `query` 返回的字符串指针由 native 侧 thread_local 缓冲管理，本类
///   通过 `toDartString()` 立即 copy，不 free。
class AtomicEngineFfi {
  AtomicEngineFfi._(this._lib) {
    _createFn = _lib
        .lookup<NativeFunction<_AtomicEngineCreateNative>>('AtomicEngine_Create')
        .asFunction<_AtomicEngineCreateDart>();
    _destroyFn = _lib
        .lookup<NativeFunction<_AtomicEngineDestroyNative>>('AtomicEngine_Destroy')
        .asFunction<_AtomicEngineDestroyDart>();
    _initFn =
        _lib.lookup<NativeFunction<_AtomicEngineInitNative>>('AtomicEngine_Init').asFunction<_AtomicEngineInitDart>();
    _uninitFn = _lib
        .lookup<NativeFunction<_AtomicEngineUninitNative>>('AtomicEngine_Uninit')
        .asFunction<_AtomicEngineUninitDart>();
    _initDartApiDLFn = _lib
        .lookup<NativeFunction<_AtomicEngineInitDartApiDLNative>>('AtomicEngine_InitDartApiDL')
        .asFunction<_AtomicEngineInitDartApiDLDart>();
    _registerSendPortFn = _lib
        .lookup<NativeFunction<_AtomicEngineRegisterSendPortNative>>('AtomicEngine_RegisterSendPort')
        .asFunction<_AtomicEngineRegisterSendPortDart>();
    _registerEventPortFn = _lib
        .lookup<NativeFunction<_AtomicEngineRegisterEventPortNative>>('AtomicEngine_RegisterEventPort')
        .asFunction<_AtomicEngineRegisterEventPortDart>();
    _callFn =
        _lib.lookup<NativeFunction<_AtomicEngineCallNative>>('AtomicEngine_Call').asFunction<_AtomicEngineCallDart>();
    _queryFn = _lib
        .lookup<NativeFunction<_AtomicEngineQueryNative>>('AtomicEngine_Query')
        .asFunction<_AtomicEngineQueryDart>();
  }

  /// 构造绑定并加载 libatomicengine。平台不支持时抛 [UnsupportedError]。
  factory AtomicEngineFfi.load() => AtomicEngineFfi._(_openLibrary());

  final DynamicLibrary _lib;

  late final _AtomicEngineCreateDart _createFn;
  late final _AtomicEngineDestroyDart _destroyFn;
  late final _AtomicEngineInitDart _initFn;
  late final _AtomicEngineUninitDart _uninitFn;
  late final _AtomicEngineInitDartApiDLDart _initDartApiDLFn;
  late final _AtomicEngineRegisterSendPortDart _registerSendPortFn;
  late final _AtomicEngineRegisterEventPortDart _registerEventPortFn;
  late final _AtomicEngineCallDart _callFn;
  late final _AtomicEngineQueryDart _queryFn;

  /// 常驻 call 响应端口：native 侧通过 `Dart_PostCObject_DL` 投递
  /// `[token, code, message, data]`。进程内一次性注册（[_ensureCallPortRegistered]）。
  final ReceivePort _callResponsePort = ReceivePort();

  /// 常驻 OnCall 事件端口：native 侧通过 `Dart_PostCObject_DL` 投递
  /// `[eventName, id, jsonData]`。由 [installEventHandler] 注册。
  final ReceivePort _eventPort = ReceivePort();

  /// 引擎 → Dart 被动事件分发回调。由上层（EngineBridge）设置。
  void Function(String eventName, String id, String jsonData)? onEvent;

  /// 引擎 → Dart 二进制载荷事件分发回调（如屏幕采集源图像）。由上层（EngineBridge）设置。
  void Function(String eventName, String id, String jsonData, Uint8List binaryData)? onBinaryEvent;

  /// token → 未决 call 的 completer。收到响应后按 token complete 并移除。
  final Map<String, Completer<EngineCallResult>> _pendingCalls = {};

  /// `Dart_InitializeApiDL` 进程内只需执行一次，两个端口共用此 guard。
  bool _apiDlInitialized = false;
  bool _callPortRegistered = false;
  bool _eventPortRegistered = false;
  int _tokenSeq = 0;

  // --- Lifecycle ---

  Pointer<Void> create() => _createFn();

  void destroy(Pointer<Void> handle) {
    if (handle == nullptr) return;
    _destroyFn(handle);
  }

  void init(Pointer<Void> handle) {
    if (handle == nullptr) return;
    _initFn(handle);
  }

  void uninit(Pointer<Void> handle) {
    if (handle == nullptr) return;
    _uninitFn(handle);
  }

  // --- Query ---

  /// 同步查询。返回值已是 Dart 侧的 String（native 缓冲内容已 copy 走）。
  String query(Pointer<Void> handle, String apiName, String id, String jsonParam) {
    if (handle == nullptr) return '';
    final namePtr = apiName.toNativeUtf8();
    final idPtr = id.toNativeUtf8();
    final paramPtr = jsonParam.toNativeUtf8();
    try {
      final resultPtr = _queryFn(handle, namePtr, idPtr, paramPtr);
      if (resultPtr == nullptr) return '';
      // native 侧返回的是 thread_local 缓冲，立即 copy。
      return resultPtr.toDartString();
    } finally {
      calloc.free(namePtr);
      calloc.free(idPtr);
      calloc.free(paramPtr);
    }
  }

  // --- Reverse dispatch (port-based) ---

  /// 安装引擎 → Dart 的被动事件分发（port-based）。进程内幂等：
  /// 惰性执行 `Dart_InitializeApiDL`，注册事件 send_port 并 `listen`。
  /// 事件消息经 [_onEventMessage] 解析后回调 [onEvent]。
  void installEventHandler() {
    if (_eventPortRegistered) return;
    _ensureApiDlInitialized();
    _registerEventPortFn(_eventPort.sendPort.nativePort);
    _eventPort.listen(_onEventMessage);
    _eventPortRegistered = true;
  }

  /// 处理 native 投递的 OnCall 事件。约定 payload 为
  /// `[eventName:String, id:String, jsonData:String]`；
  /// 二进制载荷事件为 `[eventName:String, id:String, jsonData:String, bytes:Uint8List]`。
  void _onEventMessage(dynamic message) {
    if (message is! List || message.length < 3) {
      developer.log('AtomicEngineFfi malformed event: $message', name: 'AtomicEngineFfi', level: 900);
      return;
    }
    if (message.length >= 4 && message[3] is Uint8List) {
      onBinaryEvent?.call(
        message[0] as String? ?? '',
        message[1] as String? ?? '',
        message[2] as String? ?? '',
        message[3] as Uint8List,
      );
      return;
    }
    final handler = onEvent;
    if (handler == null) return;
    handler(
      message[0] as String? ?? '',
      message[1] as String? ?? '',
      message[2] as String? ?? '',
    );
  }

  // --- Call ---

  /// 异步调用。返回 [Future] 在 native 通过 send_port 投递响应时 complete。
  ///
  /// 机制（port-based，替代 per-call `NativeCallable.listener`）：
  /// 1. 首次调用惰性注册常驻 [_callResponsePort]（`Dart_InitializeApiDL` +
  ///    `AtomicEngine_RegisterSendPort` + `listen`）；
  /// 2. 生成进程内唯一 token，把 completer 存入 [_pendingCalls]；
  /// 3. 把 token 随 `AtomicEngine_Call` 传给 native，响应经 send_port 携带
  ///    token 回到 [_onCallResponse]，按 token complete 并移除。
  ///
  /// 底层即便对同一 token 多次触发响应，第二次查表已无对应 completer，直接
  /// 忽略——从机制上消除一次性 trampoline 的 use-after-free。
  Future<EngineCallResult> call(
    Pointer<Void> handle,
    String apiName,
    String id,
    String jsonParam,
  ) {
    final completer = Completer<EngineCallResult>();

    if (handle == nullptr) {
      // 与 C ABI 在 null handle 时的响应语义保持一致。
      completer.complete(
        const EngineCallResult(
          code: -3, // kSdkNotInitialized
          message: 'engine handle is null',
          data: '',
        ),
      );
      return completer.future;
    }

    _ensureCallPortRegistered();

    final token = _generateToken(apiName);
    _pendingCalls[token] = completer;

    final namePtr = apiName.toNativeUtf8();
    final idPtr = id.toNativeUtf8();
    final paramPtr = jsonParam.toNativeUtf8();
    final tokenPtr = token.toNativeUtf8();
    try {
      _callFn(handle, namePtr, idPtr, paramPtr, tokenPtr);
    } catch (e, st) {
      // 同步抛异常（不应发生）：撤销登记并兜底完成。
      _pendingCalls.remove(token);
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(idPtr);
      calloc.free(paramPtr);
      calloc.free(tokenPtr);
    }

    return completer.future;
  }

  /// `Dart_InitializeApiDL` 进程内一次；call / event 两个端口注册前共用。
  void _ensureApiDlInitialized() {
    if (_apiDlInitialized) return;
    _initDartApiDLFn(NativeApi.initializeApiDLData);
    _apiDlInitialized = true;
  }

  /// 惰性注册 call 响应 send_port（进程内一次）。
  void _ensureCallPortRegistered() {
    if (_callPortRegistered) return;
    _ensureApiDlInitialized();
    _registerSendPortFn(_callResponsePort.sendPort.nativePort);
    _callResponsePort.listen(_onCallResponse);
    _callPortRegistered = true;
  }

  /// 处理 native 投递的 call 响应。约定 payload 为
  /// `[token:String, code:int, message:String, data:String]`。
  void _onCallResponse(dynamic message) {
    if (message is! List || message.length < 4) {
      developer.log('AtomicEngineFfi malformed call response: $message', name: 'AtomicEngineFfi', level: 900);
      return;
    }
    final token = message[0] as String;
    final completer = _pendingCalls.remove(token);
    if (completer == null) {
      // 未知 / 重复 token：幂等忽略（重复投递或已 dispose）。
      developer.log('AtomicEngineFfi unknown call token: $token', name: 'AtomicEngineFfi', level: 800);
      return;
    }
    if (completer.isCompleted) return;
    completer.complete(
      EngineCallResult(
        code: message[1] as int,
        message: message[2] as String? ?? '',
        data: message[3] as String? ?? '',
      ),
    );
  }

  /// 进程内唯一 token：`api_序号_微秒`，避免高并发碰撞且便于日志定位。
  String _generateToken(String apiName) => '${apiName}_${_tokenSeq++}_${DateTime.now().microsecondsSinceEpoch}';

  /// 关闭 OnCall 事件通道：注销事件 send_port、清空分发回调并关闭端口。
  /// 由 [EngineBridge.dispose] 在 `Uninit` 之前调用，让引擎在拆卸期间不再向
  /// 本 isolate 投递事件。
  void shutdownEventChannel() {
    if (_eventPortRegistered) {
      _registerEventPortFn(0);
    }
    onEvent = null;
    onBinaryEvent = null;
    _eventPort.close();
    _eventPortRegistered = false;
  }

  /// 关闭 call 响应通道：以错误完成全部未决 completer、注销 send_port 并关闭
  /// 端口。由 [EngineBridge.dispose] 调用；本实例随单例一起释放、不再复用。
  void shutdownCallChannel() {
    for (final completer in _pendingCalls.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('engine disposed before response'));
      }
    }
    _pendingCalls.clear();
    if (_callPortRegistered) {
      _registerSendPortFn(0);
    }
    _callResponsePort.close();
    _callPortRegistered = false;
    _apiDlInitialized = false;
  }
}
