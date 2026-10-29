import Flutter
import UIKit

public class AtomicOpusPlayerPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var handler: OpusPlayerHandler?

    init(registrar: FlutterPluginRegistrar) {
        super.init()

        methodChannel = FlutterMethodChannel(
            name: "tencent_chat_uikit/opus_player",
            binaryMessenger: registrar.messenger()
        )

        eventChannel = FlutterEventChannel(
            name: "tencent_chat_uikit/opus_player_events",
            binaryMessenger: registrar.messenger()
        )

        handler = OpusPlayerHandler()

        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handler?.handle(call, result: result)
        }

        eventChannel?.setStreamHandler(handler)
    }

    public func dispose() {
        handler?.dispose()
        handler = nil
        methodChannel?.setMethodCallHandler(nil)
        eventChannel?.setStreamHandler(nil)
        methodChannel = nil
        eventChannel = nil
    }
}
