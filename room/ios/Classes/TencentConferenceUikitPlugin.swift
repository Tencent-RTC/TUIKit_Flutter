import Flutter
import UIKit

public class TencentConferenceUikitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tencent_conference_uikit", binaryMessenger: registrar.messenger())
    let instance = TencentConferenceUikitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "enableWakeLock":
      enableWakeLock(call, result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func enableWakeLock(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let enable = arguments["enable"] as? Bool
    else {
      result(nil)
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.isIdleTimerDisabled = enable
      result(nil)
    }
  }
}
