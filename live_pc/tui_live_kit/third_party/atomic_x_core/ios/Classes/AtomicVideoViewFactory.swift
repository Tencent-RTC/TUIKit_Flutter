import Flutter
import UIKit

final class AtomicVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType: String = "atomic_engine/video_view"

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        return AtomicVideoView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            arguments: args
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
