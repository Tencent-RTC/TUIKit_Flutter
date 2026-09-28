// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include <atomic_x_core/atomic_engine_plugin_c_api.h>

#include <flutter/plugin_registrar_windows.h>

#include "atomic_engine_plugin.h"

void AtomicEnginePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  atomic_x_core::AtomicEnginePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
