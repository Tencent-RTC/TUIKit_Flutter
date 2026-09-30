// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define ATOMIC_X_CORE_PLUGIN_EXPORT __declspec(dllexport)
#else
#define ATOMIC_X_CORE_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// Registers the plugin with the Flutter engine.
//
// The generated plugin registrant includes this header as
// <atomic_x_core/atomic_engine_plugin_c_api.h> and calls
// AtomicEnginePluginCApiRegisterWithRegistrar. The function name is derived
// from the pluginClass declared in pubspec.yaml suffixed with
// "WithRegistrar", following the Flutter Windows plugin convention.
//
// NOTE: Keep this public header ASCII-only. It is compiled inside the host
// app's runner target (generated_plugin_registrant.cc) whose compiler
// options are not controlled by this plugin.
ATOMIC_X_CORE_PLUGIN_EXPORT void AtomicEnginePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_ATOMIC_ENGINE_PLUGIN_C_API_H_
