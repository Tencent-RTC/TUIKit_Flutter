//
//  Generated file. Do not edit.
//
// Author: lanqiiliu

import FlutterMacOS
import Foundation

import file_selector_macos
import open_file_mac
import package_info_plus
import path_provider_foundation
import shared_preferences_foundation
import sqflite_darwin
import tencent_cloud_chat_sdk
import tencent_rtc_sdk
import url_launcher_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  OpenFilePlugin.register(with: registry.registrar(forPlugin: "OpenFilePlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  TencentCloudChatSdkPlugin.register(with: registry.registrar(forPlugin: "TencentCloudChatSdkPlugin"))
  TencentRTCCloud.register(with: registry.registrar(forPlugin: "TencentRTCCloud"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
}
