import Flutter
import Foundation
import UIKit

public class Device {
    private static let channelName = "atomic_x/device_info"
    private let methodChannel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
      self.registrar = registrar
      self.methodChannel = FlutterMethodChannel(
        name: Device.channelName,
        binaryMessenger: registrar.messenger()
      )
      
      methodChannel.setMethodCallHandler { [weak self] (call, result) in
        self?.handleMethodCall(call, result: result)
      }
    }
    
    public func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDeviceInfo":
            getDeviceInfo(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getDeviceInfo(_ result: @escaping FlutterResult) {
        let device = UIDevice.current
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let info: [String: Any] = [
            "version": device.systemVersion,
            "manufacturer": "Apple",
            "model": identifier,
        ]
        result(info)
    }
}
