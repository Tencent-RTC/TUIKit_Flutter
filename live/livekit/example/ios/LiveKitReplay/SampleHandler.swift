//
//  SampleHandler.swift
//  LiveKitReplayExtension
//
//  Created by liuqi on 2026/2/27.
//

import ReplayKit
import TXLiteAVSDK_ReplayKitExt

private let APPGROUP = "group.com.tencent.fx.livekit"


class SampleHandler: RPBroadcastSampleHandler, TXReplayKitExtDelegate {

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        TXReplayKitExt.sharedInstance().setup(withAppGroup: APPGROUP, delegate: self)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        TXReplayKitExt.sharedInstance().broadcastFinished()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            TXReplayKitExt.sharedInstance().send(sampleBuffer, with: sampleBufferType)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
    
    // MARK: - TXReplayKitExtDelegate
    func broadcastFinished(_ broadcast: TXReplayKitExt, reason: TXReplayKitExtReason) {
        let tip: String
        switch reason {
        case .requestedByMain:
            tip = "liveStop"
        case .disconnected:
            tip = "appReset"
        case .versionMismatch:
            tip = "sdkError"
        @unknown default:
            tip = ""
        }
        
        let error = NSError(domain: NSStringFromClass(self.classForCoder), code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:tip])
        finishBroadcastWithError(error)
    }
}
