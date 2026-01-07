//  Created by eddardliu on 2025/7/2.

import Foundation
import ObjectiveC

internal class TXUGCAudioRecorderReflector {
    public enum TXUGCRecordResultCode: Int {
        case ok = 0
        case okInterrupt = 1
        case okUnreachMinDuration = 2
        case okBeyondMaxDuration = 3
        case failed = 1001
    }
    
    @objc public enum TXUGCStartAudioRecordResultCode: Int {
        case success = 0
        case pathEmpty = -2
        case micUnavailable = -4
        case licenseFailed = -5
        case noliteavsdk = -6
    }
    
    enum TXAudioSampleRate: Int {
        case rate44100 = 44100
        case rate48000 = 48000
    }
    
    enum TXAudioChannel: Int {
        case mono = 1
        case stereo = 2
    }
    
    
    private var recorderInstance: AnyObject?
    private var recorderClass: AnyClass?
    private var configClass: AnyClass?
    
    init?() {
        recorderClass = NSClassFromString("TXUGCAudioRecorder")
        configClass = NSClassFromString("TXUGCAudioConfig")
        
        guard let recorderClass = recorderClass as? NSObject.Type,
              let configClass = configClass as? NSObject.Type else {
            return nil
        }
        
        let shareInstanceSelector = NSSelectorFromString("shareInstance")
        if recorderClass.responds(to: shareInstanceSelector) {
            let result = recorderClass.perform(shareInstanceSelector)
            recorderInstance = result?.takeUnretainedValue()
        }
        
        if recorderInstance == nil {
            return nil
        }
    }
    
    func setRecordDelegate(_ delegate: AnyObject) -> Bool{
        guard let recorder = recorderInstance else { return false}
        
        let selector = NSSelectorFromString("setRecordDelegate:")
        if recorder.responds(to: selector) {
            _ = recorder.perform(selector, with: delegate)?.takeUnretainedValue()
            return true
        }
        return false
    }
    
    func startRecord(videoPath: String, config: [String: Any]) -> TXUGCStartAudioRecordResultCode {
        if recorderClass == nil {
            return .noliteavsdk
        }
        
        guard let recorder = recorderInstance,
              let configObj = createConfigObject(with: config) else {
            return .noliteavsdk
        }
        
        let selector = NSSelectorFromString("startRecord:config:")
        let methodSignature = recorder.method(for: selector)
        typealias StartRecordFunction = @convention(c) (AnyObject, Selector, NSString, AnyObject) -> Int
        let function = unsafeBitCast(methodSignature, to: StartRecordFunction.self)
        let resultCode = function(recorder, selector, videoPath as NSString, configObj)
        return TXUGCStartAudioRecordResultCode(rawValue: resultCode) ?? .success
    }
    
    func stopRecord() {
        print("stopRecord")
        guard let recorder = recorderInstance else { return }
        
        let selector = NSSelectorFromString("stopRecord")
        if recorder.responds(to: selector) {
           _ = recorder.perform(selector)?.takeUnretainedValue()
        }
    }
    
    private func createConfigObject(with config: [String: Any]) -> AnyObject? {
        guard let configClass = configClass else { return nil }
        let configInstance = configClass.alloc()
        config.forEach { key, value in
            configInstance.setValue(value, forKey: key)
        }
        return configInstance
    }
}

// MARK: - AudioRecorderListenerProxy
class AudioRecorderListenerProxy: NSObject {
    var recordProgressCallback: ((Int) -> Void)?
    var recordCompleteCallback: ((Int, String, String) -> Void)?
    
    @objc func onRecordProgress(_ milliSecond: Int) {
        recordProgressCallback?(milliSecond)
    }
    
    @objc func onRecordComplete(_ result: AnyObject) {
        var retCode = -1
        var descMsg = ""
        var videoPath = ""
        
        retCode = result.value(forKey: "retCode") as? Int ?? 0
        descMsg = result.value(forKey: "descMsg") as? String ?? ""
        videoPath = result.value(forKey: "videoPath") as? String ?? ""
        print("on record complete. retcode:\(retCode) descMsg:\(descMsg) videoPath:\(videoPath)")
        recordCompleteCallback?(retCode, descMsg, videoPath)
    }
}
