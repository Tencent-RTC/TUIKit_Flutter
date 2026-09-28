import Cocoa
import FlutterMacOS

final class AtomicVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType: String = "atomic_engine/video_view"

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withViewIdentifier viewId: Int64,
                arguments args: Any?) -> NSView {
        return AtomicVideoView(
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
