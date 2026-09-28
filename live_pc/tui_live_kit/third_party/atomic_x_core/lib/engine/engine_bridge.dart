// Copyright (c) 2026 Tencent. All rights reserved.
// Module:   EngineBridge
// Function: Dart 侧引擎桥接，封装单例 + 生命周期 + invoke/query 透传 + 被动回调订阅。
//
// 设计与 ArkTS / Swift 侧 `EngineBridge` 对齐：所有对外 API 均为 `static`，
// 内部通过 `_shared` 私有单例持有状态（ffi handle / 两张注册表 / 安装位）。

import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:typed_data';

import 'atomic_engine_ffi.dart';
import 'engine_call_result.dart';

/// 引擎 → Dart 的事件分发器（多播），接收 id 和 JSON 字符串，无返回值。
typedef EngineEventHandler = void Function(String id, String jsonData);

/// 引擎 → Dart 的二进制载荷事件分发器（多播），jsonData 为元数据，binaryData 为载荷。
typedef EngineBinaryEventHandler = void Function(String id, String jsonData, Uint8List binaryData);

/// 引擎 → Dart 的同步查询处理器（单播），接收 JSON 字符串，返回 JSON 字符串。
typedef EngineQueryHandler = String Function(String jsonData);

/// 订阅令牌，用于取消 [EngineBridge.subscribe] 注册的事件监听。
class SubscriptionToken {
  const SubscriptionToken(this.eventName, this.handler);

  final String eventName;
  final EngineEventHandler handler;
}

/// 订阅令牌，用于取消 [EngineBridge.subscribeBinary] 注册的二进制事件监听。
class BinarySubscriptionToken {
  const BinarySubscriptionToken(this.eventName, this.handler);

  final String eventName;
  final EngineBinaryEventHandler handler;
}

class EngineBridge {
  EngineBridge._() : _ffi = AtomicEngineFfi.load();

  static EngineBridge? _shared;

  final AtomicEngineFfi _ffi;
  Pointer<Void> _handle = nullptr;
  bool _inited = false;

  final Map<String, List<EngineEventHandler>> _eventHandlers = {};
  final Map<String, List<EngineBinaryEventHandler>> _binaryEventHandlers = {};
  final Map<String, EngineQueryHandler> _queryHandlers = {};
  bool _adapterInstalled = false;

  // MARK: - Shared singleton (internal)

  /// 获取内部单例；首次访问时自动触发 native 引擎创建与初始化。
  static EngineBridge _getShared() {
    if (_shared == null) {
      final inst = EngineBridge._();
      inst._ensureInited();
      _shared = inst;
    }
    return _shared!;
  }

  void _ensureInited() {
    if (_inited) return;
    // JNI g_jvm is already initialized by JNI_OnLoad triggered via
    // System.loadLibrary in AtomicEnginePlugin.kt companion init.
    _handle = _ffi.create();
    if (_handle == nullptr) {
      developer.log('AtomicEngine_Create returned nullptr', name: 'EngineBridge', level: 900);
      return;
    }
    _ffi.init(_handle);
    _inited = true;
    developer.log('EngineBridge initialized', name: 'EngineBridge');
  }

  // MARK: - Lifecycle

  /// 反初始化引擎，清空所有事件 / 查询处理器，并释放单例。
  static Future<void> dispose() async {
    final inst = _shared;
    if (inst == null) return;
    if (!inst._inited) {
      _shared = null;
      return;
    }
    try {
      // 先注销事件端口，避免 Uninit 期间引擎仍向已关闭的端口投递（port-based
      // 下投递失败会被丢弃，不再存在调用已删除 NativeCallable 的风险）。
      if (inst._adapterInstalled) {
        inst._ffi.shutdownEventChannel();
      }
      inst._ffi.uninit(inst._handle);
      inst._ffi.destroy(inst._handle);
    } finally {
      // 关闭 call 响应通道：以错误完成未决 completer、注销 send_port、关端口。
      inst._ffi.shutdownCallChannel();
      inst._eventHandlers.clear();
      inst._binaryEventHandlers.clear();
      inst._queryHandlers.clear();
      inst._adapterInstalled = false;
      inst._handle = nullptr;
      inst._inited = false;
      _shared = null;
    }
    developer.log('EngineBridge disposed', name: 'EngineBridge');
  }

  static Future<EngineCallResult> invoke(
    String eventName,
    String jsonData, {
    String id = '',
  }) async {
    final inst = _getShared();
    developer.log('EngineBridge.invoke api=$eventName', name: 'EngineBridge');
    try {
      final result = await inst._ffi.call(inst._handle, eventName, id, jsonData);
      if (result.isSuccess) {
        return EngineCallResult(code: 0, data: result.data);
      }
      developer.log(
        'EngineBridge.invoke failed api=$eventName code=${result.code}',
        name: 'EngineBridge',
        level: 800,
      );
      return EngineCallResult(
        code: result.code,
        message: result.message,
        data: result.data,
      );
    } catch (e, st) {
      developer.log(
        'EngineBridge.invoke exception api=$eventName error=$e',
        name: 'EngineBridge',
        level: 900,
        error: e,
        stackTrace: st,
      );
      return EngineCallResult(code: -1, message: 'invoke exception: $e');
    }
  }

  static String query(String eventName, String jsonData, {String id = ''}) {
    final inst = _getShared();
    try {
      return inst._ffi.query(inst._handle, eventName, id, jsonData);
    } catch (e, st) {
      developer.log(
        'EngineBridge.query exception api=$eventName error=$e',
        name: 'EngineBridge',
        level: 900,
        error: e,
        stackTrace: st,
      );
      return '';
    }
  }

  /// 订阅引擎 → Dart 的事件（被动回调，多播）。
  ///
  /// 同一个 eventName 可多次订阅，多个 handler 按注册顺序被依次调用。
  ///
  /// @param eventName 事件名称
  /// @param handler   接收 JSON 字符串的处理器
  /// @returns 订阅令牌，用于后续 [unsubscribe] 取消订阅
  static SubscriptionToken subscribe(String eventName, EngineEventHandler handler) {
    final inst = _getShared();
    inst._installAdapter();
    final list = inst._eventHandlers.putIfAbsent(eventName, () => []);
    list.add(handler);
    return SubscriptionToken(eventName, handler);
  }

  /// 取消由 [subscribe] 注册的事件监听。
  ///
  /// @param token [subscribe] 返回的订阅令牌
  static void unsubscribe(SubscriptionToken token) {
    final inst = _shared;
    if (inst == null) return;
    final list = inst._eventHandlers[token.eventName];
    if (list == null) return;
    list.remove(token.handler);
    if (list.isEmpty) {
      inst._eventHandlers.remove(token.eventName);
    }
  }

  /// 订阅引擎 → Dart 的二进制载荷事件（多播）。语义同 [subscribe]。
  static BinarySubscriptionToken subscribeBinary(String eventName, EngineBinaryEventHandler handler) {
    final inst = _getShared();
    inst._installAdapter();
    final list = inst._binaryEventHandlers.putIfAbsent(eventName, () => []);
    list.add(handler);
    return BinarySubscriptionToken(eventName, handler);
  }

  /// 取消由 [subscribeBinary] 注册的二进制事件监听。
  static void unsubscribeBinary(BinarySubscriptionToken token) {
    final inst = _shared;
    if (inst == null) return;
    final list = inst._binaryEventHandlers[token.eventName];
    if (list == null) return;
    list.remove(token.handler);
    if (list.isEmpty) {
      inst._binaryEventHandlers.remove(token.eventName);
    }
  }

  /// 注册引擎 → Dart 的同步查询处理器（单播，覆盖写入）。
  ///
  /// @param eventName 事件名称
  /// @param handler   接收 JSON 字符串并返回 JSON 字符串的处理器
  static void setQueryHandler(String eventName, EngineQueryHandler handler) {
    final inst = _getShared();
    inst._installAdapter();
    inst._queryHandlers[eventName] = handler;
  }

  /// 清空所有订阅与查询处理器。
  ///
  /// 只清空 Dart 侧注册表，不解除 native 层已安装的分发器（幂等）。
  static void removeAll() {
    final inst = _shared;
    if (inst == null) return;
    inst._eventHandlers.clear();
    inst._binaryEventHandlers.clear();
    inst._queryHandlers.clear();
  }

  void _installAdapter() {
    if (_adapterInstalled) return;
    if (_handle == nullptr) {
      // 还没 Init 不装；等到 Init 之后由调用方再次触发 _installAdapter。
      return;
    }

    _ffi.onEvent = _onNativeCall;
    _ffi.onBinaryEvent = _onNativeBinaryCall;
    _ffi.installEventHandler();
    _adapterInstalled = true;
    developer.log('EngineBridge adapter installed', name: 'EngineBridge');
  }

  void _onNativeCall(String eventName, String id, String jsonData) {
    final handlers = _eventHandlers[eventName];
    if (handlers == null || handlers.isEmpty) {
      return;
    }
    // 复制一份再迭代，避免 handler 内调用 subscribe/removeAll 改写原 list
    // 触发 ConcurrentModificationError。
    final snapshot = List<EngineEventHandler>.of(handlers);
    for (final h in snapshot) {
      try {
        h(id, jsonData);
      } catch (e, st) {
        developer.log(
          'EngineBridge onCall handler threw event=$eventName error=$e',
          name: 'EngineBridge',
          level: 900,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  void _onNativeBinaryCall(String eventName, String id, String jsonData, Uint8List binaryData) {
    final handlers = _binaryEventHandlers[eventName];
    if (handlers == null || handlers.isEmpty) {
      return;
    }
    // 同 _onNativeCall：复制快照再迭代，防止 handler 内改写注册表。
    final snapshot = List<EngineBinaryEventHandler>.of(handlers);
    for (final h in snapshot) {
      try {
        h(id, jsonData, binaryData);
      } catch (e, st) {
        developer.log(
          'EngineBridge binary handler threw event=$eventName error=$e',
          name: 'EngineBridge',
          level: 900,
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
