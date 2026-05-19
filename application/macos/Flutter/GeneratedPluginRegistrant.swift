//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import open_file_mac
import path_provider_foundation
import shared_preferences_foundation
import sqflite_darwin
import tencent_cloud_chat_sdk
import tencent_rtc_sdk
import url_launcher_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  OpenFilePlugin.register(with: registry.registrar(forPlugin: "OpenFilePlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  TencentCloudChatSdkPlugin.register(with: registry.registrar(forPlugin: "TencentCloudChatSdkPlugin"))
  TencentRTCCloud.register(with: registry.registrar(forPlugin: "TencentRTCCloud"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
}
