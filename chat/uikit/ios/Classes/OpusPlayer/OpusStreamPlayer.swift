import AVFoundation
import Foundation
import os.log

/// 新一轮播放开头淡入，压掉从静音拉起来的那一声「呲」。16kHz 下 160 样本 = 10ms。
private let fadeInSamples = 160

/// 收到最后一片后，若 `.dataPlayedBack` 回调一直不来（engine 被系统停掉等），
/// 最多在「剩余时长 + 这个余量」之后照常收尾，避免上层永久停在播报态。
private let finishFallbackMarginMs = 1000

/// TTS 流式播放：Opus packet 在解码队列上解码，PCM 以 AVAudioPlayerNode 排队播放。
///
/// 播放节点挂在 [SharedAudioEngine] 上，与通话采集同一个 engine，voice processing 才能拿
/// 播放信号做回声参考。
///
/// 除解码外所有状态只在主线程读写；[onChunkQueued] / [onFinished] 在主线程回调。
final class OpusStreamPlayer: SharedAudioEngineClient {
    private struct Segment {
        let start: AVAudioFramePosition
        let end: AVAudioFramePosition
        let level: Double
    }

    var onChunkQueued: ((_ durationMs: Int, _ isFinished: Bool) -> Void)?
    var onFinished: (() -> Void)?

    private let logger = Logger(subsystem: "OpusPlayer", category: "OpusStreamPlayer")
    private let decodeQueue = DispatchQueue(label: "tencent_chat_uikit.opus_player.decode")
    private let playerNode = AVAudioPlayerNode()
    private let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: RealtimeAudioSpec.sampleRate,
        channels: AVAudioChannelCount(RealtimeAudioSpec.channelCount),
        interleaved: false
    )!

    /// 只在解码队列上读写。第一次真正播放时才创建。
    private var decoder: SystemOpusDecoder?

    /// 每次 beginStream / flush / release 自增：解码结果带着投递时的值，回到主线程对不上就丢弃。
    /// 主线程写，解码队列只读来提前跳过注定被丢弃的解码。
    private let generationLock = NSLock()
    private var generationValue = 0

    /// 每次 flush / engine 重建 / release 自增：已调度 buffer 的播放完成回调带着调度时的值，
    /// 对不上说明那段音频已被清掉。beginStream 不动它，上一段还在放的尾音照常走完。
    private var playbackEpoch = 0

    private weak var attachedEngine: AVAudioEngine?
    private var started = false
    private var outstandingBuffers = 0
    private var endOfStream = false
    private var fadeInPending = true
    private var segments: [Segment] = []
    private var nextSegmentStart: AVAudioFramePosition = 0
    private var finishFallback: DispatchWorkItem?

    var isPlaying: Bool {
        outstandingBuffers > 0
    }

    /// 当前正在播放那一包的音量，0...1
    var currentLevel: Double {
        guard outstandingBuffers > 0, let first = segments.first else { return 0 }
        guard let position = currentSamplePosition() else { return first.level }
        if let playing = segments.first(where: { position >= $0.start && position < $0.end }) {
            return playing.level
        }
        return position < first.start ? first.level : (segments.last?.level ?? 0)
    }

    static func isSupported() -> Bool {
        SystemOpusDecoder.isSupported()
    }

    /// - Returns: false 表示 engine 没能启动或节点没挂上，调用方必须据此降级
    func start() -> Bool {
        if started {
            return true
        }
        guard SharedAudioEngine.shared.acquire(self, needsInput: false, voiceProcessing: false),
              attachedEngine != nil else {
            SharedAudioEngine.shared.release(self)
            return false
        }
        started = true
        fadeInPending = true
        return true
    }

    /// 新一段 TTS 音频流开始：作废上一段在途的解码结果，丢掉解码器状态。已排队的音频不清。
    func beginStream() {
        bumpGeneration()
        decodeQueue.async { [weak self] in
            guard let self = self else { return }
            if let decoder = self.decoder {
                decoder.reset()
            } else {
                self.decoder = SystemOpusDecoder()
            }
        }
    }

    func feed(_ packets: [Data], isFinished: Bool) {
        guard started else { return }
        let generation = currentGeneration()
        decodeQueue.async { [weak self] in
            guard let self = self, self.currentGeneration() == generation else { return }
            if self.decoder == nil {
                self.decoder = SystemOpusDecoder()
            }
            var pcm: [Float] = []
            var levels: [(frames: Int, level: Double)] = []
            for packet in packets {
                // 单包解码失败就丢弃这一包继续，不中断整段播放
                guard let decoded = self.decoder?.decode(packet), !decoded.isEmpty else { continue }
                pcm.reserveCapacity(pcm.count + decoded.count)
                for sample in decoded {
                    pcm.append(Float(sample) / 32768)
                }
                let rms = decoded.withUnsafeBufferPointer { RealtimeAudioSpec.rms($0) }
                // 6000 是 TTS 输出上的经验满量程参考值，只用来驱动动画
                levels.append((decoded.count, min(max(rms / 6000, 0), 1)))
            }
            DispatchQueue.main.async { [weak self] in
                self?.enqueueDecoded(pcm, levels: levels, isFinished: isFinished, generation: generation)
            }
        }
    }

    /// 立即停止出声并清空已排队音频，丢弃在途解码结果。用于说话打断。
    func flush() {
        bumpGeneration()
        decodeQueue.async { [weak self] in
            self?.decoder?.reset()
        }
        clearPlayback()
    }

    /// 停止播放、摘下节点、释放解码器。可重复调用。
    func stop() {
        bumpGeneration()
        endOfStream = false
        clearPlayback()
        if started {
            started = false
            SharedAudioEngine.shared.release(self)
        }
        decodeQueue.async { [weak self] in
            self?.decoder = nil
        }
    }

    // MARK: - SharedAudioEngineClient

    func sharedAudioEngine(attachTo engine: AVAudioEngine) -> Bool {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        attachedEngine = engine
        fadeInPending = true
        return true
    }

    func sharedAudioEngine(willTearDown engine: AVAudioEngine) {
        guard attachedEngine === engine else { return }
        let wasEnding = endOfStream
        clearPlayback()
        engine.detach(playerNode)
        attachedEngine = nil
        // 重建把排队音频连同完成回调一起丢了，收到过最后一片就按播完处理
        if wasEnding && started {
            onFinished?()
        }
    }

    // MARK: - Private

    private func currentGeneration() -> Int {
        generationLock.lock()
        defer { generationLock.unlock() }
        return generationValue
    }

    private func bumpGeneration() {
        generationLock.lock()
        generationValue += 1
        generationLock.unlock()
    }

    private func clearPlayback() {
        playbackEpoch += 1
        if attachedEngine != nil {
            playerNode.stop()
        }
        outstandingBuffers = 0
        segments.removeAll()
        nextSegmentStart = 0
        endOfStream = false
        fadeInPending = true
        finishFallback?.cancel()
        finishFallback = nil
    }

    private func enqueueDecoded(
        _ pcm: [Float],
        levels: [(frames: Int, level: Double)],
        isFinished: Bool,
        generation: Int
    ) {
        guard started, generation == currentGeneration() else { return }
        if !pcm.isEmpty {
            schedule(pcm, levels: levels)
        }
        onChunkQueued?(pcm.count * 1000 / Int(RealtimeAudioSpec.sampleRate), isFinished)
        guard isFinished, started, generation == currentGeneration() else { return }
        if outstandingBuffers == 0 {
            finish()
        } else {
            endOfStream = true
            armFinishFallback()
        }
    }

    private func schedule(_ pcm: [Float], levels: [(frames: Int, level: Double)]) {
        guard attachedEngine != nil, SharedAudioEngine.shared.ensureRunning(), let engine = attachedEngine,
              engine.isRunning else {
            logger.warning("engine not running, drop \(pcm.count) samples")
            return
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(pcm.count)),
              let channel = buffer.floatChannelData?[0] else { return }
        for index in 0..<pcm.count {
            channel[index] = pcm[index]
        }
        if fadeInPending {
            fadeInPending = false
            let fadeCount = min(pcm.count, fadeInSamples)
            if fadeCount > 1 {
                for index in 0..<fadeCount {
                    channel[index] *= Float(index) / Float(fadeCount)
                }
            }
        }
        buffer.frameLength = AVAudioFrameCount(pcm.count)

        if !playerNode.isPlaying {
            nextSegmentStart = 0
        } else if outstandingBuffers == 0 {
            nextSegmentStart = max(nextSegmentStart, currentSamplePosition() ?? nextSegmentStart)
        }
        for item in levels {
            let end = nextSegmentStart + AVAudioFramePosition(item.frames)
            segments.append(Segment(start: nextSegmentStart, end: end, level: item.level))
            nextSegmentStart = end
        }

        outstandingBuffers += 1
        let epoch = playbackEpoch
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                self?.bufferPlayedBack(epoch: epoch)
            }
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func bufferPlayedBack(epoch: Int) {
        guard epoch == playbackEpoch, outstandingBuffers > 0 else { return }
        outstandingBuffers -= 1
        if let position = currentSamplePosition() {
            segments.removeAll { $0.end <= position }
        }
        guard outstandingBuffers == 0 else { return }
        segments.removeAll()
        if endOfStream {
            finish()
        }
    }

    private func finish() {
        endOfStream = false
        finishFallback?.cancel()
        finishFallback = nil
        onFinished?()
    }

    private func armFinishFallback() {
        finishFallback?.cancel()
        let position = currentSamplePosition() ?? segments.first?.start ?? 0
        let remainingFrames = max(0, (segments.last?.end ?? 0) - position)
        let remainingMs = Int(remainingFrames * 1000 / AVAudioFramePosition(RealtimeAudioSpec.sampleRate))
        let epoch = playbackEpoch
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, epoch == self.playbackEpoch, self.endOfStream else { return }
            self.logger.warning("playback completion timeout, finishing anyway")
            self.outstandingBuffers = 0
            self.segments.removeAll()
            self.finish()
        }
        finishFallback = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(remainingMs + finishFallbackMarginMs), execute: work
        )
    }

    /// 播放头位置（16kHz 样本）。播放器没在播或拿不到渲染时间时返回 nil。
    private func currentSamplePosition() -> AVAudioFramePosition? {
        guard attachedEngine?.isRunning == true,
              playerNode.isPlaying,
              let nodeTime = playerNode.lastRenderTime,
              nodeTime.isSampleTimeValid,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              playerTime.sampleRate > 0 else { return nil }
        return AVAudioFramePosition(Double(playerTime.sampleTime) * RealtimeAudioSpec.sampleRate / playerTime.sampleRate)
    }
}
