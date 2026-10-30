import AudioToolbox
import Foundation

/// 实时采集与 TTS 播放共用的音频参数，与 Android `RealtimeAudioSpec` 一致。
enum RealtimeAudioSpec {
    static let sampleRate: Double = 16000
    static let channelCount: UInt32 = 1

    /// 20ms @ 16kHz
    static let frameSamples = 320
    static let opusBitRate: UInt32 = 24000

    /// AudioConverter 输入回调用这个状态表示「这一轮没有更多数据」，不是错误。
    static let noMoreInputStatus: OSStatus = 0x6e6f6d64 // 'nomd'

    static var pcm16Format: AudioStreamBasicDescription {
        AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: channelCount,
            mBitsPerChannel: 16,
            mReserved: 0
        )
    }

    static func opusFormat(framesPerPacket: UInt32) -> AudioStreamBasicDescription {
        AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatOpus,
            mFormatFlags: 0,
            mBytesPerPacket: 0,
            mFramesPerPacket: framesPerPacket,
            mBytesPerFrame: 0,
            mChannelsPerFrame: channelCount,
            mBitsPerChannel: 0,
            mReserved: 0
        )
    }

    static func rms(_ samples: UnsafeBufferPointer<Int16>) -> Double {
        guard !samples.isEmpty else { return 0 }
        var sum = 0.0
        for s in samples {
            let v = Double(s)
            sum += v * v
        }
        return (sum / Double(samples.count)).squareRoot()
    }
}
