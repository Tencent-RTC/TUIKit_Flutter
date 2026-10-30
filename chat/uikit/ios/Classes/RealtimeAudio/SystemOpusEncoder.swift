import AudioToolbox
import Foundation
import os.log

private struct EncoderInput {
    var data: UnsafeMutableRawPointer?
    var byteCount: UInt32
    var frameCount: UInt32
    var consumed: Bool
}

private let encoderInputProc: AudioConverterComplexInputDataProc = { _, ioPacketCount, ioData, _, userData in
    guard let input = userData?.assumingMemoryBound(to: EncoderInput.self), !input.pointee.consumed else {
        ioPacketCount.pointee = 0
        return RealtimeAudioSpec.noMoreInputStatus
    }
    ioData.pointee.mNumberBuffers = 1
    ioData.pointee.mBuffers.mData = input.pointee.data
    ioData.pointee.mBuffers.mDataByteSize = input.pointee.byteCount
    ioData.pointee.mBuffers.mNumberChannels = RealtimeAudioSpec.channelCount
    ioPacketCount.pointee = input.pointee.frameCount
    input.pointee.consumed = true
    return noErr
}

/// 系统 AudioConverter 裸 Opus 编码器：16kHz / 单声道 PCM16，每 320 样本一包，24kbps。
///
/// 输出不带 Ogg 封装，也没有配置包；magic cookie 走属性，不混进包流。
/// 非线程安全，只在采集队列上使用。
final class SystemOpusEncoder {
    private static let logger = Logger(subsystem: "RealtimeAudio", category: "SystemOpusEncoder")
    private static let lock = NSLock()
    private static var cachedSupported: Bool?

    private let converter: AudioConverterRef
    private let maxPacketSize: Int
    private let outputBuffer: UnsafeMutableRawPointer

    /// 能否创建 16k mono Opus 编码器。结果缓存。
    static func isSupported() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedSupported {
            return cached
        }
        let supported = SystemOpusEncoder() != nil
        cachedSupported = supported
        return supported
    }

    init?() {
        var inputFormat = RealtimeAudioSpec.pcm16Format
        var outputFormat = RealtimeAudioSpec.opusFormat(framesPerPacket: UInt32(RealtimeAudioSpec.frameSamples))
        var newConverter: AudioConverterRef?
        let status = AudioConverterNew(&inputFormat, &outputFormat, &newConverter)
        guard status == noErr, let created = newConverter else {
            SystemOpusEncoder.logger.error("create opus encoder failed: \(status)")
            return nil
        }
        var bitRate = RealtimeAudioSpec.opusBitRate
        let bitRateStatus = AudioConverterSetProperty(
            created, kAudioConverterEncodeBitRate, UInt32(MemoryLayout<UInt32>.size), &bitRate
        )
        if bitRateStatus != noErr {
            SystemOpusEncoder.logger.warning("set opus bitrate failed: \(bitRateStatus)")
        }
        var packetSize: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        AudioConverterGetProperty(
            created, kAudioConverterPropertyMaximumOutputPacketSize, &propertySize, &packetSize
        )
        converter = created
        maxPacketSize = max(Int(packetSize), 1500)
        outputBuffer = UnsafeMutableRawPointer.allocate(byteCount: maxPacketSize, alignment: 16)
    }

    deinit {
        AudioConverterDispose(converter)
        outputBuffer.deallocate()
    }

    /// 编码一帧（必须正好 320 样本）。编码器可能暂不出包，返回空数组。
    func encode(_ frame: UnsafeBufferPointer<Int16>) -> [Data] {
        guard let base = frame.baseAddress, !frame.isEmpty else { return [] }
        var input = EncoderInput(
            data: UnsafeMutableRawPointer(mutating: base),
            byteCount: UInt32(frame.count * MemoryLayout<Int16>.size),
            frameCount: UInt32(frame.count),
            consumed: false
        )
        var packetDescription = AudioStreamPacketDescription()
        var bufferList = AudioBufferList(
            mNumberBuffers: 1,
            mBuffers: AudioBuffer(
                mNumberChannels: RealtimeAudioSpec.channelCount,
                mDataByteSize: UInt32(maxPacketSize),
                mData: outputBuffer
            )
        )
        var packetCount: UInt32 = 1
        let status = AudioConverterFillComplexBuffer(
            converter, encoderInputProc, &input, &packetCount, &bufferList, &packetDescription
        )
        if status != noErr && status != RealtimeAudioSpec.noMoreInputStatus {
            SystemOpusEncoder.logger.warning("opus encode failed: \(status)")
            return []
        }
        guard packetCount > 0, packetDescription.mDataByteSize > 0 else { return [] }
        return [Data(
            bytes: outputBuffer.advanced(by: Int(packetDescription.mStartOffset)),
            count: Int(packetDescription.mDataByteSize)
        )]
    }

    /// 丢弃帧间状态，不重建编码器。
    func reset() {
        AudioConverterReset(converter)
    }
}
