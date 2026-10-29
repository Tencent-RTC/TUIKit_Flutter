import AVFoundation
import Foundation
import os.log

/// 实时采集通路：共享 engine 的 inputNode → 16kHz / 单声道 PCM16 → 每 20ms 一帧 → 系统 Opus 编码。
///
/// 输入栏场景下与 `audio_recorder`（AVAudioRecorder 录 m4a）并行。启动失败时调用方回落到
/// 「录完整段再上传识别」，不影响语音消息本身。
///
/// [start] / [stop] 只在主线程调用；[onFrames] 在采集队列上回调，每次带一批 20ms 帧。
final class RealtimeAudioCapture: SharedAudioEngineClient {
    enum Mode: String {
        case recognition
        case voiceCommunication
    }

    struct Frame {
        let packets: [Data]
        let rms: Double
    }

    private let logger = Logger(subsystem: "RealtimeAudio", category: "RealtimeAudioCapture")
    private let mode: Mode
    private let queue = DispatchQueue(label: "tencent_chat_uikit.realtime_audio.capture")
    private let onFrames: ([Frame]) -> Void
    private var pipeline: CapturePipeline?
    private weak var tappedEngine: AVAudioEngine?
    private var inputFormat: AVAudioFormat?

    private(set) var isRunning = false

    init(mode: Mode, onFrames: @escaping ([Frame]) -> Void) {
        self.mode = mode
        self.onFrames = onFrames
    }

    static func isSupported() -> Bool {
        SystemOpusEncoder.isSupported()
    }

    /// 调用前必须已获得麦克风权限。
    ///
    /// - Returns: 启动失败返回 false，调用方据此关掉实时识别，不要重试
    func start() -> Bool {
        if isRunning {
            return true
        }
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            logger.warning("startCapture without record permission")
            return false
        }
        guard let encoder = SystemOpusEncoder() else {
            return false
        }
        guard configureSession() else {
            return false
        }
        let newPipeline = CapturePipeline(encoder: encoder, onFrames: onFrames)
        pipeline = newPipeline
        let attached = SharedAudioEngine.shared.acquire(
            self, needsInput: true, voiceProcessing: mode == .voiceCommunication
        )
        guard attached, tappedEngine != nil else {
            SharedAudioEngine.shared.release(self)
            pipeline = nil
            return false
        }
        isRunning = true
        logger.info("capture started: \(self.effectSummary())")
        return true
    }

    /// 停止采集并释放编码器。可重复调用。
    func stop() {
        guard isRunning || pipeline != nil else { return }
        isRunning = false
        SharedAudioEngine.shared.release(self)
        if let closing = pipeline {
            queue.async { closing.close() }
        }
        pipeline = nil
    }

    /// 请求丢掉 Opus 帧间状态；在采集队列上处理下一帧之前生效。
    func requestEncoderReset() {
        guard let target = pipeline else { return }
        queue.async { target.requestEncoderReset() }
    }

    func effectSummary() -> String {
        let engine = SharedAudioEngine.shared
        let session = AVAudioSession.sharedInstance()
        let input = inputFormat.map { "\(Int($0.sampleRate))Hz/\($0.channelCount)ch" } ?? "-"
        return "mode=\(mode.rawValue) vp=\(engine.voiceProcessingEnabled ? "ON" : "off") " +
            "source=AVAudioEngine.inputNode input=\(input) tap=\(tappedEngine != nil) " +
            "session=\(session.category.rawValue)/\(session.mode.rawValue)"
    }

    // MARK: - SharedAudioEngineClient

    func sharedAudioEngine(attachTo engine: AVAudioEngine) -> Bool {
        guard let target = pipeline, SharedAudioEngine.shared.hasInput else { return false }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            logger.warning("invalid input format: \(format.description)")
            return false
        }
        let processingQueue = queue
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            guard let samples = CapturePipeline.firstChannelSamples(of: buffer) else { return }
            let sampleRate = buffer.format.sampleRate
            processingQueue.async { target.process(samples, sampleRate: sampleRate) }
        }
        tappedEngine = engine
        inputFormat = format
        return true
    }

    func sharedAudioEngine(willTearDown engine: AVAudioEngine) {
        guard tappedEngine === engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        tappedEngine = nil
    }

    // MARK: - Private

    /// 通话音频模式下 session 已由 [VoiceCallAudioMode] 配好，不再动它。
    ///
    /// 输入栏场景下 AVAudioRecorder 已先把 session 设成 playAndRecord 并在录音：
    /// 只切 mode，不改 category / options，也不反激活，避免打断那一路。
    private func configureSession() -> Bool {
        if SharedAudioEngine.shared.voiceCallModeActive {
            return true
        }
        let session = AVAudioSession.sharedInstance()
        do {
            switch mode {
            case .voiceCommunication:
                if session.category != .playAndRecord || session.mode != .voiceChat {
                    try session.setCategory(
                        .playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth]
                    )
                }
            case .recognition:
                if session.category != .playAndRecord {
                    try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth])
                } else if session.mode != .measurement && session.mode != .voiceChat {
                    try session.setMode(.measurement)
                }
            }
            try session.setActive(true)
            return true
        } catch {
            logger.error("configure audio session failed: \(error.localizedDescription)")
            return false
        }
    }
}

/// 采集队列上的处理链：重采样到 16kHz PCM16、切 20ms 帧、编码。只在采集队列上使用。
private final class CapturePipeline {
    private let encoder: SystemOpusEncoder
    private let onFrames: ([RealtimeAudioCapture.Frame]) -> Void
    private let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: RealtimeAudioSpec.sampleRate,
        channels: AVAudioChannelCount(RealtimeAudioSpec.channelCount),
        interleaved: true
    )!
    private var resampler: AVAudioConverter?
    private var resamplerInputFormat: AVAudioFormat?
    private var pending: [Int16] = []
    private var encoderResetRequested = false
    private var closed = false

    init(encoder: SystemOpusEncoder, onFrames: @escaping ([RealtimeAudioCapture.Frame]) -> Void) {
        self.encoder = encoder
        self.onFrames = onFrames
    }

    /// 只取第 0 声道：开了 voice processing 的 inputNode 在部分机型上报多声道，
    /// 处理后的人声在第 0 声道。
    static func firstChannelSamples(of buffer: AVAudioPCMBuffer) -> [Float]? {
        let count = Int(buffer.frameLength)
        guard count > 0 else { return nil }
        if let channels = buffer.floatChannelData {
            return Array(UnsafeBufferPointer(start: channels[0], count: count))
        }
        if let channels = buffer.int16ChannelData {
            let stride = buffer.format.isInterleaved ? Int(buffer.format.channelCount) : 1
            return (0..<count).map { Float(channels[0][$0 * stride]) / 32768 }
        }
        return nil
    }

    func requestEncoderReset() {
        encoderResetRequested = true
    }

    func close() {
        closed = true
        pending.removeAll()
        resampler = nil
    }

    func process(_ samples: [Float], sampleRate: Double) {
        guard !closed, !samples.isEmpty else { return }
        appendResampled(samples, sampleRate: sampleRate)

        let frameSamples = RealtimeAudioSpec.frameSamples
        var frames: [RealtimeAudioCapture.Frame] = []
        var offset = 0
        pending.withUnsafeBufferPointer { all in
            while all.count - offset >= frameSamples {
                if encoderResetRequested {
                    encoderResetRequested = false
                    encoder.reset()
                }
                let frame = UnsafeBufferPointer(rebasing: all[offset..<(offset + frameSamples)])
                frames.append(RealtimeAudioCapture.Frame(
                    packets: encoder.encode(frame),
                    rms: RealtimeAudioSpec.rms(frame)
                ))
                offset += frameSamples
            }
        }
        if offset > 0 {
            pending.removeFirst(offset)
        }
        if !frames.isEmpty {
            onFrames(frames)
        }
    }

    private func appendResampled(_ samples: [Float], sampleRate: Double) {
        if sampleRate == RealtimeAudioSpec.sampleRate {
            pending.append(contentsOf: samples.map { Int16(max(-1, min(1, $0)) * 32767) })
            return
        }
        guard let converter = resamplerFor(sampleRate: sampleRate),
              let inputFormat = resamplerInputFormat,
              let input = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(samples.count)),
              let inputChannel = input.floatChannelData?[0] else { return }
        for index in 0..<samples.count {
            inputChannel[index] = samples[index]
        }
        input.frameLength = AVAudioFrameCount(samples.count)

        let capacity = AVAudioFrameCount(Double(samples.count) * RealtimeAudioSpec.sampleRate / sampleRate) + 64
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return }
        var supplied = false
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, inputStatus in
            if supplied {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return input
        }
        guard status != .error, let channel = output.int16ChannelData?[0] else { return }
        pending.append(contentsOf: UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
    }

    private func resamplerFor(sampleRate: Double) -> AVAudioConverter? {
        if let existing = resampler, resamplerInputFormat?.sampleRate == sampleRate {
            return existing
        }
        guard let inputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false
        ) else { return nil }
        resamplerInputFormat = inputFormat
        resampler = AVAudioConverter(from: inputFormat, to: outputFormat)
        return resampler
    }
}
