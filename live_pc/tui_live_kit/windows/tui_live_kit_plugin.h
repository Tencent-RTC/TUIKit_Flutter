#ifndef FLUTTER_PLUGIN_TUI_LIVE_KIT_PLUGIN_H_
#define FLUTTER_PLUGIN_TUI_LIVE_KIT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace tui_live_kit {

class TuiLiveKitPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  TuiLiveKitPlugin();

  virtual ~TuiLiveKitPlugin();

  // Disallow copy and assign.
  TuiLiveKitPlugin(const TuiLiveKitPlugin&) = delete;
  TuiLiveKitPlugin& operator=(const TuiLiveKitPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace tui_live_kit

#endif  // FLUTTER_PLUGIN_TUI_LIVE_KIT_PLUGIN_H_
