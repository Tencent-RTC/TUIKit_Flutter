//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <atomic_x_core/atomic_engine_plugin_c_api.h>
#include <file_selector_windows/file_selector_windows.h>
#include <tencent_cloud_chat_sdk/tencent_cloud_chat_sdk_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AtomicEnginePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AtomicEnginePluginCApi"));
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  TencentCloudChatSdkPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TencentCloudChatSdkPluginCApi"));
}
