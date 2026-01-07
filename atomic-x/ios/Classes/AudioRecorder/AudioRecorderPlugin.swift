import Flutter
import UIKit

public class AudioRecorderPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var handler: AudioRecorderHandler?
    
    init(registrar: FlutterPluginRegistrar) {
        super.init()
        
        methodChannel = FlutterMethodChannel(
            name: "atomic_x/audio_recorder",
            binaryMessenger: registrar.messenger()
        )
        
        eventChannel = FlutterEventChannel(
            name: "atomic_x/audio_recorder_events",
            binaryMessenger: registrar.messenger()
        )
        
        handler = AudioRecorderHandler(
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
