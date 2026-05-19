import Flutter
import UIKit
// import tencent_effect_flutter
// import tencent_rtc_sdk

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
//     let instance = XmagicProcesserFactory()
//     TencentRTCCloud.setBeautyProcesserFactory(factory: instance)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
