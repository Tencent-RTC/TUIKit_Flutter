import Flutter
import UIKit

public class AtomicRealtimeAudioPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var handler: RealtimeAudioHandler?

    init(registrar: FlutterPluginRegistrar) {
        super.init()

        methodChannel = FlutterMethodChannel(
            name: "tencent_chat_uikit/realtime_audio",
            binaryMessenger: registrar.messenger()
        )

        eventChannel = FlutterEventChannel(
            name: "tencent_chat_uikit/realtime_audio_events",
            binaryMessenger: registrar.messenger()
        )

        handler = RealtimeAudioHandler()

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
