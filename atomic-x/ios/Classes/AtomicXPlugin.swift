import Flutter
import UIKit

public class AtomicXPlugin: NSObject, FlutterPlugin {
  private var permission: Permission?
  private var albumPicker: AlbumPickerPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tuikit_atomic_x", binaryMessenger: registrar.messenger())
    let instance = AtomicXPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Get root view controller
    let viewController = UIApplication.shared.delegate?.window??.rootViewController
    
    // Register permission module
    instance.permission = Permission(registrar: registrar)
    
    // Register album picker module
    instance.albumPicker = AlbumPickerPlugin(registrar: registrar, viewController: viewController)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  deinit {
    albumPicker?.dispose()
  }
}
