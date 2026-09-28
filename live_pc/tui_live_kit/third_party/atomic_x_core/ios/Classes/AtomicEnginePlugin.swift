import Flutter
import UIKit

public class AtomicEnginePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: "atomic_engine", binaryMessenger: messenger)
    let instance = AtomicEnginePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = AtomicVideoViewFactory(messenger: messenger)
    registrar.register(factory, withId: AtomicVideoViewFactory.viewType)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
