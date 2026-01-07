//  Created by eddardliu on 2025/7/4.
import os.log

internal class AudioRecorderTXUGC: AudioRecorderInternalProtocol {
    let logger = Logger(subsystem: "AudioRecoder", category: "AudioRecorderTXUGC")
    
    static let AUDIO_SAMPLE_RATE: Int = 48000
    static let AUDIO_CHANNEL: Int = 2
    static let AUDIO_BITRATE_BPS: Int = 50 * 1024
    
    static let ERROR_LESS_THAN_MIN_DURATION = 2
    static let RECORD_RESULT_OK_BEYOND_MAX_DURATION = 3
    static let START_RECORD_ERR_LICENCE_VERIFICATION_FAILED = -5
    
    private var minDurationMs : Int = 1000
    private var maxDurationMs : Int = 6000
    private var recorder: TXUGCAudioRecorderReflector?
    private var ugcRecoderReflectorListener: AudioRecorderListenerProxy?
    private var listener: AudioRecorderListener?
    private var path: String = "local"
    private var isUseAiDeNoise: Bool
    
    init?() {
        recorder = TXUGCAudioRecorderReflector()
        guard let recorder = recorder else {
            logger.error("TXUGCAudioRecorderReflector init fail.")
            return nil
        }
        
        ugcRecoderReflectorListener = AudioRecorderListenerProxy()
        guard let ugcRecoderReflectorListener = ugcRecoderReflectorListener else {
            return nil
        }
        
        listener = nil
        isUseAiDeNoise = true;
        
        ugcRecoderReflectorListener.recordProgressCallback =  self.onRecordProgress
        ugcRecoderReflectorListener.recordCompleteCallback = self.onRecordComplete
        if !recorder.setRecordDelegate(ugcRecoderReflectorListener) {
            logger.error("set record delegate fail.")
            return nil
        }
    }
    
    func startRecord(_ path : String, _ minDuration: Int, _ maxDuration: Int) {
        self.path = path
        self.minDurationMs = minDuration
        self.maxDurationMs = maxDuration
        
        guard let recorder = recorder else {
            logger.error("start recoder fail. recoder is nil")
            return;
        }
        
        let config: [String: Any] = [
            "audioSampleRate": AudioRecorderTXUGC.AUDIO_SAMPLE_RATE,
            "audioChannel": AudioRecorderTXUGC.AUDIO_CHANNEL,
            "audioBitrateBps": AudioRecorderTXUGC.AUDIO_BITRATE_BPS,
            "minDurationMs": minDuration,
            "maxDurationMs": maxDuration,
            "enableAIDeNoise": isUseAiDeNoise
        ]
        
        let result = recorder.startRecord(videoPath: path, config: config)
        logger.info("start record. result:\(result.rawValue)")
        if (result == .success) {
            return
        }
        
        if (result == .licenseFailed) {
            handleLicenceVerificationFailed()
        } else {
            listener?.onComplete(.errorRecordInnerFail)
        }
    }
    
    private func handleLicenceVerificationFailed() {
        logger.info("handle licence verification failed.");
        
        // Note: WindowToastManager is not available in Flutter plugin
        // For debugging, check logs instead
        #if DEBUG
          logger.warning("AI DeNoise license verification failed. Falling back to standard recording.")
        #endif
        
        if (isUseAiDeNoise) {
            isUseAiDeNoise = false
            startRecord(self.path, minDurationMs, maxDurationMs)
        }
    }
    
    func stopRecord() {
        if let recorder = recorder {
            recorder.stopRecord();
        }
    }
    
    func setListener(_ listener: AudioRecorderListener) {
        self.listener = listener;
    }
    
    private func onRecordProgress(milliSecond:Int) {
        if let listener = listener {
            listener.onProgress(milliSecond)
        }
    }
    
    func enableAIDeNoise(_ enable : Bool) {
        isUseAiDeNoise = enable
    }
    
    private func onRecordComplete(_ retCode :Int, _ msg : String, _ videoPath :String) {
        if (retCode == 0) {
            listener?.onComplete(.success)
        } else if (retCode == AudioRecorderTXUGC.ERROR_LESS_THAN_MIN_DURATION) {
            listener?.onComplete(.errorLessThanMinDuration)
        } else if (retCode == AudioRecorderTXUGC.RECORD_RESULT_OK_BEYOND_MAX_DURATION) {
            listener?.onComplete(.exceedMaxDuration)
        } else {
            listener?.onComplete(.errorRecordInnerFail)
        }
    }
}
