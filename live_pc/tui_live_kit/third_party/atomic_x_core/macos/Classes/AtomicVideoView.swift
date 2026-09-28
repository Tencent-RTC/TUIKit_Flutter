import Cocoa
import FlutterMacOS

// macOS platform view directly subclasses NSView (unlike iOS which wraps a
// UIView via the FlutterPlatformView protocol). The Flutter engine retains the
// returned NSView, so the embedded method-channel handler stays alive with it.
final class AtomicVideoView: NSView {
    static let channelPrefix: String = "atomic_engine_video_view_"
    static let methodGetNativeViewPtr: String = "getNativeViewPtr"

    private let channel: FlutterMethodChannel

    init(viewIdentifier viewId: Int64,
         arguments args: Any?,
         binaryMessenger messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(
            name: "\(AtomicVideoView.channelPrefix)\(viewId)",
            binaryMessenger: messenger
        )
        super.init(frame: .zero)

        if let borderRadius = args as? Int {
            self.wantsLayer = true
            self.layer?.cornerRadius = CGFloat(borderRadius)
            self.layer?.masksToBounds = true
        }

        self.channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            self.onMethodCall(call: call, result: result)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        channel.setMethodCallHandler(nil)
    }

    private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case AtomicVideoView.methodGetNativeViewPtr:
            let opaque = Unmanaged.passUnretained(self).toOpaque()
            let ptr = Int64(bitPattern: UInt64(UInt(bitPattern: opaque)))
            result(ptr)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
