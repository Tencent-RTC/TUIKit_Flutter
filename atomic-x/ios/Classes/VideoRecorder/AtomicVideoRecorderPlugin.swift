import Flutter
import Foundation
import UIKit

class AtomicVideoRecorderPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel
    private var videoRecorderHandler: VideoRecorderHandler
    
    init(registrar: FlutterPluginRegistrar) {
        self.methodChannel = FlutterMethodChannel(
            name: "atomic_x/video_recorder",
            binaryMessenger: registrar.messenger()
        )

        self.videoRecorderHandler = VideoRecorderHandler()

        super.init()

        registrar.addMethodCallDelegate(self, channel: methodChannel)
    }
    
    func dispose() {
        methodChannel.setMethodCallHandler(nil)
    }
}

extension AtomicVideoRecorderPlugin: FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        // This is handled in the main plugin
    }
}

extension AtomicVideoRecorderPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecord":
            videoRecorderHandler.handleStartRecord(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
