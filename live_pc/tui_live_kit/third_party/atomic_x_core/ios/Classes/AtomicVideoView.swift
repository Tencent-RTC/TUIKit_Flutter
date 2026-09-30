import Flutter
import UIKit

final class AtomicVideoView: NSObject, FlutterPlatformView {
    static let channelPrefix: String = "atomic_engine_video_view_"
    static let methodGetNativeViewPtr: String = "getNativeViewPtr"

    private let surfaceView: UIView
    private let channel: FlutterMethodChannel

    init(frame: CGRect,
         viewId: Int64,
         messenger: FlutterBinaryMessenger,
         arguments args: Any?) {
        self.surfaceView = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "\(AtomicVideoView.channelPrefix)\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        if let borderRadius = args as? Int {
            self.surfaceView.layer.cornerRadius = CGFloat(borderRadius)
            self.surfaceView.layer.masksToBounds = true
        }

        self.channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            self.onMethodCall(call: call, result: result)
        }
    }

    deinit {
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        return surfaceView
    }

    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case AtomicVideoView.methodGetNativeViewPtr:
            let opaque = Unmanaged.passUnretained(surfaceView).toOpaque()
            let ptr = Int64(bitPattern: UInt64(UInt(bitPattern: opaque)))
            result(ptr)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
