//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<atomic_x_core/AtomicXCorePlugin.h>)
#import <atomic_x_core/AtomicXCorePlugin.h>
#else
@import atomic_x_core;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<rtc_room_engine_impl/RtcRoomEngine.h>)
#import <rtc_room_engine_impl/RtcRoomEngine.h>
#else
@import rtc_room_engine_impl;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

#if __has_include(<tencent_cloud_chat_sdk/TencentCloudChatSdkPlugin.h>)
#import <tencent_cloud_chat_sdk/TencentCloudChatSdkPlugin.h>
#else
@import tencent_cloud_chat_sdk;
#endif

#if __has_include(<tencent_conference_uikit/TencentConferenceUikitPlugin.h>)
#import <tencent_conference_uikit/TencentConferenceUikitPlugin.h>
#else
@import tencent_conference_uikit;
#endif

#if __has_include(<tencent_rtc_sdk/TencentRTCCloud.h>)
#import <tencent_rtc_sdk/TencentRTCCloud.h>
#else
@import tencent_rtc_sdk;
#endif

#if __has_include(<tuikit_atomic_x/AtomicXPlugin.h>)
#import <tuikit_atomic_x/AtomicXPlugin.h>
#else
@import tuikit_atomic_x;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AtomicXCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"AtomicXCorePlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [RtcRoomEngine registerWithRegistrar:[registry registrarForPlugin:@"RtcRoomEngine"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [TencentCloudChatSdkPlugin registerWithRegistrar:[registry registrarForPlugin:@"TencentCloudChatSdkPlugin"]];
  [TencentConferenceUikitPlugin registerWithRegistrar:[registry registrarForPlugin:@"TencentConferenceUikitPlugin"]];
  [TencentRTCCloud registerWithRegistrar:[registry registrarForPlugin:@"TencentRTCCloud"]];
  [AtomicXPlugin registerWithRegistrar:[registry registrarForPlugin:@"AtomicXPlugin"]];
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
}

@end
