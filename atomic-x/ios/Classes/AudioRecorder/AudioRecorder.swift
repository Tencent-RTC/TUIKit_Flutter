import AVFoundation
import AVKit
import SwiftUI

public class AudioRecorder: NSObject, ObservableObject {
    static let shared = AudioRecorderImpl()
    
    public var onRecordingComplete: ((_ resultCode: AudioRecordResultCode, _ filePath: String, _ durationMs: Int) -> Void)?
    public var onRecordTime: ((_ timeMs: Int) -> Void)?
    public var onPowerLevel: ((_ powerLevel: Int) -> Void)?
    
    public func startRecord(filepath: String? = nil, enableAIDeNoise: Bool = false, minDurationMs: Int = 1000, maxDurationMs: Int = 60000) {}
    
    public func stopRecord() {}
    
    public func cancelRecord() {}

    override internal init() {
        super.init()
    }
}

public enum AudioRecordResultCode: Int {
    case exceedMaxDuration = 1
    case success = 0
    case errorCancel = -1
    case errorRecording = -2
    case errorStorageUnavailable = -3
    case errorLessThanMinDuration = -4
    case errorRecordInnerFail = -5
    case errorRecordPermissionDenied = -6
}
