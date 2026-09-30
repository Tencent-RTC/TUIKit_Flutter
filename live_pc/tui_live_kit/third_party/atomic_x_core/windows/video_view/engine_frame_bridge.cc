// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include "video_view/engine_frame_bridge.h"

#include <windows.h>

namespace atomic_x_core {

namespace {

// 进程级单次解析：引擎 dll 与本插件由宿主 app 一并分发（exe 目录），
// 按标准搜索顺序加载。与 TrtcCApi 同一策略——有意不 FreeLibrary：引擎
// 与 liteav 内部含工作线程与全局状态，中途卸载不安全，进程退出由
// 操作系统统一回收。
struct EngineExports {
  HMODULE module = nullptr;
  void (*set_mixed_frame_handler)(void (*handler)(void*)) = nullptr;
  bool resolved = false;
};

EngineExports* ResolveEngineExports() {
  static EngineExports* exports = []() -> EngineExports* {
    auto* result = new EngineExports();
    result->module = ::LoadLibraryW(L"AtomicXCore_Win.dll");
    if (result->module == nullptr) {
      return result;
    }
    result->set_mixed_frame_handler =
        reinterpret_cast<void (*)(void (*)(void*))>(::GetProcAddress(
            result->module, "AtomicEngine_SetMediaMixingFrameHandler"));
    return result;
  }();
  return exports;
}

}  // namespace

// static
bool EngineFrameBridge::SetMixedFrameHandler(void (*handler)(void* frame)) {
  auto* exports = ResolveEngineExports();
  if (exports->set_mixed_frame_handler == nullptr) {
    return false;
  }
  exports->set_mixed_frame_handler(handler);
  return true;
}

}  // namespace atomic_x_core
