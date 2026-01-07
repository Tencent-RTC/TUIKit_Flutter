import Flutter
import UIKit
import AVFoundation

class AudioPlayerHandler: NSObject, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    
    init(methodChannel: FlutterMethodChannel, eventChannel: FlutterEventChannel) {
        self.methodChannel = methodChannel
        self.eventChannel = eventChannel
        super.init()
        
        setupAudioPlayerCallbacks()
    }
    
    private func setupAudioPlayerCallbacks() {
        AudioPlayer.shared.onComplete = { [weak self] in
            self?.eventSink?([
                "type": "onComplete"
            ])
        }
        
        AudioPlayer.shared.onProgressUpdate = { [weak self] currentPosition, duration in
            self?.eventSink?([
                "type": "onProgressUpdate",
                "currentPosition": currentPosition,
                "duration": duration
            ])
        }
        
        AudioPlayer.shared.onPlay = { [weak self] in
            self?.eventSink?([
                "type": "onPlay"
            ])
        }
        
        AudioPlayer.shared.onPause = { [weak self] in
            self?.eventSink?([
                "type": "onPause"
            ])
        }
        
        AudioPlayer.shared.onResume = { [weak self] in
            self?.eventSink?([
                "type": "onResume"
            ])
        }
        
        AudioPlayer.shared.onError = { [weak self] errorMessage in
            self?.eventSink?([
                "type": "onError",
                "errorMessage": errorMessage
            ])
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            play(call, result: result)
        case "pause":
            pause(result)
        case "resume":
            resume(result)
        case "stop":
            stop(result)
        case "getCurrentPosition":
            getCurrentPosition(result)
        case "getDuration":
            getDuration(result)
        case "isPlaying":
            isPlaying(result)
        case "isPaused":
            isPaused(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func play(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        AudioPlayer.shared.play(filePath: filePath)
        result(nil)
    }
    
    private func pause(_ result: @escaping FlutterResult) {
        AudioPlayer.shared.pause()
        result(nil)
    }
    
    private func resume(_ result: @escaping FlutterResult) {
        AudioPlayer.shared.resume()
        result(nil)
    }
    
    private func stop(_ result: @escaping FlutterResult) {
        AudioPlayer.shared.stop()
        result(nil)
    }
    
    private func getCurrentPosition(_ result: @escaping FlutterResult) {
        let position = AudioPlayer.shared.getCurrentPosition()
        result(position)
    }
    
    private func getDuration(_ result: @escaping FlutterResult) {
        let duration = AudioPlayer.shared.getDuration()
        result(duration)
    }
    
    private func isPlaying(_ result: @escaping FlutterResult) {
        let playing = AudioPlayer.shared.isPlaying()
        result(playing)
    }
    
    private func isPaused(_ result: @escaping FlutterResult) {
        let paused = AudioPlayer.shared.isPaused()
        result(paused)
    }
    
    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func dispose() {
        eventSink = nil
        AudioPlayer.shared.onComplete = nil
        AudioPlayer.shared.onProgressUpdate = nil
        AudioPlayer.shared.onPlay = nil
        AudioPlayer.shared.onPause = nil
        AudioPlayer.shared.onResume = nil
        AudioPlayer.shared.onError = nil
    }
}
