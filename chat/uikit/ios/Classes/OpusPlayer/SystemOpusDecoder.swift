import AudioToolbox
import Foundation
import os.log

private struct DecoderInput {
    var data: UnsafeMutableRawPointer?
    var packetDescription: AudioStreamPacketDescription
    var consumed: Bool
}

private let decoderInputProc: AudioConverterComplexInputDataProc = { _, ioPacketCount, ioData, outPacketDescription, userData in
    guard let input = userData?.assumingMemoryBound(to: DecoderInput.self), !input.pointee.consumed else {
        ioPacketCount.pointee = 0
        return RealtimeAudioSpec.noMoreInputStatus
    }
    ioData.pointee.mNumberBuffers = 1
    ioData.pointee.mBuffers.mData = input.pointee.data
    ioData.pointee.mBuffers.mDataByteSize = input.pointee.packetDescription.mDataByteSize
    ioData.pointee.mBuffers.mNumberChannels = RealtimeAudioSpec.channelCount
    ioPacketCount.pointee = 1
    if let outPacketDescription = outPacketDescription,
       let offset = MemoryLayout<DecoderInput>.offset(of: \DecoderInput.packetDescription) {
        outPacketDescription.pointee = UnsafeMutableRawPointer(input)
            .advanced(by: offset)
            .assumingMemoryBound(to: AudioStreamPacketDescription.self)
    }
    input.pointee.consumed = true
    return noErr
}

/// 系统 AudioConverter 裸 Opus 解码器：TTS 下行 packet → 16kHz / 单声道 PCM16。
///
/// 后台分片帧长不保证是 20ms：输入格式声明为可变帧长，并给 OpusHead cookie，
/// 否则帧长与声明不符的包会整包解码失败。
/// 非线程安全，只在解码队列上使用。
final class SystemOpusDecoder {
    private static let logger = Logger(subsystem: "OpusPlayer", category: "SystemOpusDecoder")
    private static let lock = NSLock()
    private static var cachedSupported: Bool?

    /// Opus 单包最长 120ms
    private static let maxFramesPerPacket = 1920

    private let converter: AudioConverterRef
    private var outputBuffer = [Int16](repeating: 0, count: SystemOpusDecoder.maxFramesPerPacket)

    static func isSupported() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedSupported {
            return cached
        }
        let supported = SystemOpusDecoder() != nil
        cachedSupported = supported
        return supported
    }

    init?() {
        var created: AudioConverterRef?
        for framesPerPacket: UInt32 in [0, UInt32(RealtimeAudioSpec.frameSamples)] {
            var inputFormat = RealtimeAudioSpec.opusFormat(framesPerPacket: framesPerPacket)
            var outputFormat = RealtimeAudioSpec.pcm16Format
            var newConverter: AudioConverterRef?
            let status = AudioConverterNew(&inputFormat, &outputFormat, &newConverter)
            if status == noErr, let converter = newConverter {
                created = converter
                break
            }
            SystemOpusDecoder.logger.warning("create opus decoder failed, framesPerPacket=\(framesPerPacket): \(status)")
        }
        guard let converter = created else { return nil }
        var cookie = SystemOpusDecoder.opusHead()
        let cookieStatus = AudioConverterSetProperty(
            converter, kAudioConverterDecompressionMagicCookie, UInt32(cookie.count), &cookie
        )
        if cookieStatus != noErr {
            SystemOpusDecoder.logger.warning("set OpusHead cookie failed: \(cookieStatus)")
        }
        self.converter = converter
    }

    deinit {
        AudioConverterDispose(converter)
    }

    /// - Returns: 解出的 PCM；packet 损坏或解码失败返回 nil
    func decode(_ packet: Data) -> [Int16]? {
        guard !packet.isEmpty else { return nil }
        var bytes = [UInt8](packet)
        var produced: UInt32 = 0
        var status: OSStatus = noErr
        bytes.withUnsafeMutableBytes { packetBytes in
            outputBuffer.withUnsafeMutableBytes { output in
                var input = DecoderInput(
                    data: packetBytes.baseAddress,
                    packetDescription: AudioStreamPacketDescription(
                        mStartOffset: 0,
                        mVariableFramesInPacket: 0,
                        mDataByteSize: UInt32(packetBytes.count)
                    ),
                    consumed: false
                )
                var bufferList = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: AudioBuffer(
                        mNumberChannels: RealtimeAudioSpec.channelCount,
                        mDataByteSize: UInt32(output.count),
                        mData: output.baseAddress
                    )
                )
                var frameCount = UInt32(SystemOpusDecoder.maxFramesPerPacket)
                status = AudioConverterFillComplexBuffer(
                    converter, decoderInputProc, &input, &frameCount, &bufferList, nil
                )
                produced = frameCount
            }
        }
        if status != noErr && status != RealtimeAudioSpec.noMoreInputStatus {
            SystemOpusDecoder.logger.warning("opus decode failed: \(status), bytes=\(packet.count)")
            return nil
        }
        guard produced > 0 else { return nil }
        return Array(outputBuffer[0..<Int(produced)])
    }

    /// 丢弃解码器状态。每段 TTS 播报开始前调一次。
    func reset() {
        AudioConverterReset(converter)
    }

    /// 19 字节 OpusHead：版本 1、单声道、pre-skip 0、16000Hz、增益 0、映射族 0。
    private static func opusHead() -> [UInt8] {
        var head = Array("OpusHead".utf8)
        head += [1, UInt8(RealtimeAudioSpec.channelCount), 0, 0]
        let rate = UInt32(RealtimeAudioSpec.sampleRate)
        head += [UInt8(rate & 0xFF), UInt8((rate >> 8) & 0xFF), UInt8((rate >> 16) & 0xFF), UInt8((rate >> 24) & 0xFF)]
        head += [0, 0, 0]
        return head
    }
}
