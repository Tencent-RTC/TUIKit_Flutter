// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_H_
#define FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_H_

#include <memory>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

namespace atomic_x_core {

// 对齐 macOS 侧 AtomicEnginePlugin.swift：
// 注册 "atomic_engine" MethodChannel（目前仅 getPlatformVersion）。
// 视频渲染（对齐 macOS PlatformView / OHOS Texture 通道）在 Windows 上
// 暂未接入——Flutter Windows 无稳定 PlatformView，后续按 Texture 方案
// （TRTC 自定义渲染回调）实现，见工作计划第 3 项。
class AtomicEnginePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AtomicEnginePlugin();
  virtual ~AtomicEnginePlugin();

  AtomicEnginePlugin(const AtomicEnginePlugin &) = delete;
  AtomicEnginePlugin &operator=(const AtomicEnginePlugin &) = delete;

 private:
  // Called when a method call is received from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace atomic_x_core

#endif  // FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_H_
