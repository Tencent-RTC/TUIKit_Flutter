//
//  Generated file. Do not edit.
//

// clang-format off
// Author: lanqiiliu

#include "generated_plugin_registrant.h"

#include <file_selector_windows/file_selector_windows.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <tencent_cloud_chat_sdk/tencent_cloud_chat_sdk_plugin_c_api.h>
#include <tencent_rtc_sdk/trtc_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  TencentCloudChatSdkPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TencentCloudChatSdkPluginCApi"));
  TrtcPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TrtcPluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
