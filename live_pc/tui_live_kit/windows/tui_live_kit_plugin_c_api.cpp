#include "include/tui_live_kit/tui_live_kit_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "tui_live_kit_plugin.h"

void TuiLiveKitPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  tui_live_kit::TuiLiveKitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
