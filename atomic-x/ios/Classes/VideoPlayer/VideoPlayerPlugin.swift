import Flutter
import UIKit

public class VideoPlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register InlineVideoPlayer PlatformView (controls handled by Flutter)
        let inlineFactory = InlineVideoPlayerViewFactory(messenger: registrar.messenger())
        registrar.register(
            inlineFactory,
            withId: "io.trtc.tuikit.atomicx/inline_video_player"
        )
    }
}
