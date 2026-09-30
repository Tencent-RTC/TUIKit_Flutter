// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include "atomic_engine_plugin.h"

#include <VersionHelpers.h>

#include <sstream>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "video_view/video_view_manager.h"

namespace atomic_x_core {

namespace {

// 返回 "Windows 10+" / "Windows 8" / "Windows 7" 形式的系统版本描述，
// 与 macOS 侧 AtomicEnginePlugin（"macOS <ver>"）的格式约定对应。
std::string GetWindowsVersionString() {
  std::ostringstream version_stream;
  version_stream << "Windows ";
  if (IsWindows10OrGreater()) {
    version_stream << "10+";
  } else if (IsWindows8OrGreater()) {
    version_stream << "8";
  } else if (IsWindows7OrGreater()) {
    version_stream << "7";
  }
  return version_stream.str();
}

}  // namespace

// static
void AtomicEnginePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "atomic_engine",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AtomicEnginePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));

  VideoViewManager::GetInstance()->RegisterWithRegistrar(registrar);
}

AtomicEnginePlugin::AtomicEnginePlugin() = default;

AtomicEnginePlugin::~AtomicEnginePlugin() = default;

void AtomicEnginePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "getPlatformVersion") {
    result->Success(flutter::EncodableValue(GetWindowsVersionString()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace atomic_x_core
