import Flutter
import UIKit

public class AudioPlayerPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var handler: AudioPlayerHandler?
    
    init(registrar: FlutterPluginRegistrar) {
        super.init()
        
        methodChannel = FlutterMethodChannel(
            name: "atomic_x/audio_player",
            binaryMessenger: registrar.messenger()
        )
        
        eventChannel = FlutterEventChannel(
            name: "atomic_x/audio_player_events",
            binaryMessenger: registrar.messenger()
        )
        
        handler = AudioPlayerHandler(
            methodChannel: methodChannel!,
            eventChannel: eventChannel!
        )
        
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
