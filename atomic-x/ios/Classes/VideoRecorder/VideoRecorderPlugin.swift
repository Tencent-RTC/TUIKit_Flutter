import Flutter
import Foundation
import UIKit

class VideoRecorderPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel
    private var videoRecorderHandler: VideoRecorderHandler
    
    init(registrar: FlutterPluginRegistrar) {
        self.methodChannel = FlutterMethodChannel(
            name: "atomic_x/video_recorder",
            binaryMessenger: registrar.messenger()
        )
        
        // 获取根视图控制器
        var rootViewController: UIViewController?
        if #available(iOS 13.0, *) {
            rootViewController = UIApplication.shared.windows.first?.rootViewController
        } else {
            rootViewController = UIApplication.shared.keyWindow?.rootViewController
        }
        
        self.videoRecorderHandler = VideoRecorderHandler(viewController: rootViewController)
        
        super.init()
        
        registrar.addMethodCallDelegate(self, channel: methodChannel)
    }
    
    func dispose() {
        methodChannel.setMethodCallHandler(nil)
    }
}

extension VideoRecorderPlugin: FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        // This is handled in the main plugin
    }
}

extension VideoRecorderPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecord":
            videoRecorderHandler.handleStartRecord(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
