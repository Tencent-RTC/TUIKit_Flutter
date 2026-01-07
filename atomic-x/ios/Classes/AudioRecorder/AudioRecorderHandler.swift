import Flutter
import UIKit
import AVFoundation

class AudioRecorderHandler: NSObject, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    
    init(methodChannel: FlutterMethodChannel, eventChannel: FlutterEventChannel) {
        self.methodChannel = methodChannel
        self.eventChannel = eventChannel
        super.init()
        
        setupAudioRecorderCallbacks()
    }
    
    private func setupAudioRecorderCallbacks() {
        AudioRecorder.shared.onRecordingComplete = { [weak self] resultCode, filePath, durationMs in
            guard let self = self else { return }
            
            let result: [String: Any] = [
                "resultCode": resultCode.rawValue,
                "filePath": filePath,
                "durationMs": durationMs
            ]
            
            // Return result to Flutter through method channel result
            // Note: This will be handled in the startRecord method
        }
        
        AudioRecorder.shared.onRecordTime = { [weak self] timeMs in
            self?.eventSink?([
                "type": "recordTime",
                "timeMs": timeMs
            ])
        }
        
        AudioRecorder.shared.onPowerLevel = { [weak self] powerLevel in
            self?.eventSink?([
                "type": "powerLevel",
                "powerLevel": powerLevel
            ])
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecord":
            startRecord(call, result: result)
        case "stopRecord":
            stopRecord(result)
        case "cancelRecord":
            cancelRecord(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startRecord(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let filepath = args["filepath"] as? String
        let enableAIDeNoise = args["enableAIDeNoise"] as? Bool ?? false
        let minDurationMs = args["minDurationMs"] as? Int ?? 1000
        let maxDurationMs = args["maxDurationMs"] as? Int ?? 60000
        
        // Setup completion handler
        var completionCalled = false
        AudioRecorder.shared.onRecordingComplete = { [weak self] resultCode, filePath, durationMs in
            guard !completionCalled else { return }
            completionCalled = true
            
            let resultMap: [String: Any] = [
                "resultCode": resultCode.rawValue,
                "filePath": filePath,
                "durationMs": durationMs
            ]
            
            DispatchQueue.main.async {
                result(resultMap)
            }
        }
        
        // Start recording
        AudioRecorder.shared.startRecord(
            filepath: filepath,
            enableAIDeNoise: enableAIDeNoise,
            minDurationMs: minDurationMs,
            maxDurationMs: maxDurationMs
        )
    }
    
    private func stopRecord(_ result: @escaping FlutterResult) {
        AudioRecorder.shared.stopRecord()
        result(nil)
    }
    
    private func cancelRecord(_ result: @escaping FlutterResult) {
        AudioRecorder.shared.cancelRecord()
        result(nil)
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
        AudioRecorder.shared.onRecordingComplete = nil
        AudioRecorder.shared.onRecordTime = nil
        AudioRecorder.shared.onPowerLevel = nil
    }
}
