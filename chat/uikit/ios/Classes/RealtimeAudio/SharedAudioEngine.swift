import AVFoundation
import Foundation
import os.log

/// 挂在 [SharedAudioEngine] 上的节点持有者（实时采集、TTS 播放）。所有回调都在主线程。
protocol SharedAudioEngineClient: AnyObject {
    /// engine 新建好、尚未启动时回调：在这里 attach / connect 节点、装 tap。
    /// 返回 false 表示这个客户端在新 engine 上没能挂上。
    func sharedAudioEngine(attachTo engine: AVAudioEngine) -> Bool

    /// engine 即将停止并被丢弃：在这里拆 tap、detach 节点，丢掉已排队音频的状态。
    func sharedAudioEngine(willTearDown engine: AVAudioEngine)
}

/// 采集与播放共用的唯一 AVAudioEngine。
///
/// voice processing（AEC）挂在 engine 的 I/O 单元上，只有同一个 engine 输出的声音才会被当作
/// 回声参考信号消掉。TTS 播放如果走另一个 engine 或 AVAudioPlayer，回声会原样进麦克风，
/// 被 VAD / ASR 当成用户说话。
///
/// - 开关 voice processing 必须在 engine 停止时进行，而且会改变 inputNode / outputNode 的格式，
///   所以需要改变 voice processing 或者从「仅输出」变成「需要输入」时，整个 engine 重建，
///   各客户端在 [SharedAudioEngineClient.sharedAudioEngine(attachTo:)] 里重新挂节点。
/// - voice processing 一旦打开就保持到 engine 无人使用为止，不因采集停止而关掉：
///   通话里每轮识别都会 stop / start 采集，关掉就要重建，会打断正在播放的 TTS。
///
/// 只在主线程使用。
final class SharedAudioEngine {
    static let shared = SharedAudioEngine()

    private struct Requirement {
        var needsInput: Bool
        var voiceProcessing: Bool
    }

    private final class Entry {
        weak var client: SharedAudioEngineClient?
        var requirement: Requirement

        init(client: SharedAudioEngineClient, requirement: Requirement) {
            self.client = client
            self.requirement = requirement
        }
    }

    private let logger = Logger(subsystem: "RealtimeAudio", category: "SharedAudioEngine")
    private var entries: [ObjectIdentifier: Entry] = [:]
    private var idleCallbacks: [() -> Void] = []
    private var configurationObserver: NSObjectProtocol?
    private var sessionObservers: [NSObjectProtocol] = []
    private var rebuildScheduled = false
    private var recentAutoRebuilds: [Date] = []

    private(set) var engine: AVAudioEngine?
    private(set) var voiceProcessingEnabled = false
    private(set) var hasInput = false

    /// 当前 engine 构建时是否请求过 voice processing。开启失败（如模拟器）也算请求过，
    /// 否则之后每次 acquire 都会判定不一致而重建，打断正在播放的 TTS。
    private var builtForVoiceProcessing = false

    /// 处于通话音频模式时，新建的 engine 一律打开 voice processing，
    /// 这样先创建的播放器和后启动的采集不需要再重建一次。
    var voiceCallModeActive = false {
        didSet {
            guard voiceCallModeActive != oldValue, voiceCallModeActive, let engine = engine else { return }
            if !builtForVoiceProcessing || !engine.isRunning {
                rebuild()
            }
        }
    }

    var isIdle: Bool {
        pruneReleasedClients()
        return entries.isEmpty
    }

    private init() {
        let center = NotificationCenter.default
        sessionObservers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        })
        sessionObservers.append(center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleRebuild(reason: "media services reset")
        })
    }

    /// 让 [client] 挂到共享 engine 上，必要时新建或重建 engine 并启动。
    ///
    /// - Returns: engine 已在运行且 [client] 挂上成功
    func acquire(_ client: SharedAudioEngineClient, needsInput: Bool, voiceProcessing: Bool) -> Bool {
        pruneReleasedClients()
        let key = ObjectIdentifier(client)
        let requirement = Requirement(needsInput: needsInput, voiceProcessing: voiceProcessing)
        let isNewClient = entries[key] == nil
        entries[key] = Entry(client: client, requirement: requirement)

        if let engine = engine,
           engine.isRunning,
           builtForVoiceProcessing == wantsVoiceProcessing,
           hasInput || !wantsInput {
            if isNewClient && !client.sharedAudioEngine(attachTo: engine) {
                entries[key] = nil
                return false
            }
            return true
        }
        if !isNewClient, let engine = engine {
            client.sharedAudioEngine(willTearDown: engine)
        }
        let attached = rebuild(reportingFor: key)
        if !attached {
            entries[key] = nil
            if entries.isEmpty {
                tearDown()
            }
        }
        return attached
    }

    /// [client] 从 engine 上摘下。最后一个客户端离开时停止并丢弃 engine。可重复调用。
    func release(_ client: SharedAudioEngineClient) {
        let key = ObjectIdentifier(client)
        guard entries.removeValue(forKey: key) != nil else { return }
        if let engine = engine {
            client.sharedAudioEngine(willTearDown: engine)
        }
        pruneReleasedClients()
        if entries.isEmpty {
            tearDown()
        }
    }

    /// engine 被系统停掉（中断、路由变化）后尝试原地拉起；拉不起来就重建。
    @discardableResult
    func ensureRunning() -> Bool {
        guard let engine = engine else {
            return isIdle ? false : rebuild()
        }
        if engine.isRunning {
            return true
        }
        do {
            try engine.start()
            return true
        } catch {
            logger.warning("restart engine failed: \(error.localizedDescription), rebuilding")
            rebuild()
            return self.engine?.isRunning == true
        }
    }

    /// engine 无人使用时执行一次 [callback]；当前已空闲则立即执行。
    func whenIdle(_ callback: @escaping () -> Void) {
        if isIdle {
            callback()
        } else {
            idleCallbacks.append(callback)
        }
    }

    func cancelIdleCallbacks() {
        idleCallbacks.removeAll()
    }

    // MARK: - Private

    private var wantsVoiceProcessing: Bool {
        voiceCallModeActive || entries.values.contains { $0.client != nil && $0.requirement.voiceProcessing }
    }

    private var wantsInput: Bool {
        wantsVoiceProcessing || entries.values.contains { $0.client != nil && $0.requirement.needsInput }
    }

    private func pruneReleasedClients() {
        entries = entries.filter { $0.value.client != nil }
    }

    /// 重建 engine 并让全部客户端重新挂节点。
    ///
    /// - Returns: [reportingFor] 对应的客户端是否挂上成功且 engine 已启动；不指定时返回 engine 是否启动
    @discardableResult
    private func rebuild(reportingFor key: ObjectIdentifier? = nil) -> Bool {
        rebuildScheduled = false
        pruneReleasedClients()
        if let old = engine {
            for (entryKey, entry) in entries where entryKey != key {
                entry.client?.sharedAudioEngine(willTearDown: old)
            }
            stopAndDiscard(old)
        }
        guard !entries.isEmpty else {
            tearDown()
            return false
        }

        let newEngine = AVAudioEngine()
        let enableVoiceProcessing = wantsVoiceProcessing
        var inputAvailable = false
        voiceProcessingEnabled = false
        builtForVoiceProcessing = enableVoiceProcessing
        if wantsInput {
            let input = newEngine.inputNode
            if enableVoiceProcessing {
                do {
                    try input.setVoiceProcessingEnabled(true)
                    voiceProcessingEnabled = true
                } catch {
                    logger.warning("enable voice processing failed: \(error.localizedDescription)")
                }
            }
            let format = input.outputFormat(forBus: 0)
            inputAvailable = format.sampleRate > 0 && format.channelCount > 0
            if !inputAvailable {
                logger.warning("input node unavailable: \(format.description)")
            }
        }
        hasInput = inputAvailable
        // 只有输入的图启动不了，确保混音器→输出这条链存在
        _ = newEngine.mainMixerNode
        engine = newEngine

        var reportedAttached = key == nil
        for (entryKey, entry) in entries {
            guard let client = entry.client else { continue }
            let attached = client.sharedAudioEngine(attachTo: newEngine)
            if entryKey == key {
                reportedAttached = attached
            } else if !attached {
                logger.warning("client failed to re-attach after rebuild")
            }
        }

        newEngine.prepare()
        do {
            try newEngine.start()
        } catch {
            logger.error("start engine failed: \(error.localizedDescription)")
            for entry in entries.values {
                entry.client?.sharedAudioEngine(willTearDown: newEngine)
            }
            stopAndDiscard(newEngine)
            engine = nil
            voiceProcessingEnabled = false
            builtForVoiceProcessing = false
            hasInput = false
            return false
        }
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: newEngine, queue: .main
        ) { [weak self, weak newEngine] _ in
            guard let self = self, let changed = newEngine, changed === self.engine, !changed.isRunning else { return }
            self.scheduleRebuild(reason: "configuration change")
        }
        logger.info("engine started: vp=\(self.voiceProcessingEnabled) input=\(self.hasInput) clients=\(self.entries.count)")
        return reportedAttached
    }

    private func scheduleRebuild(reason: String) {
        guard engine != nil || !isIdle, !rebuildScheduled else { return }
        // 个别路由下重建本身又触发配置变化，限住频率，避免自激循环
        let now = Date()
        recentAutoRebuilds = recentAutoRebuilds.filter { now.timeIntervalSince($0) < 3 }
        guard recentAutoRebuilds.count < 5 else {
            logger.error("too many automatic rebuilds, skip: \(reason)")
            return
        }
        recentAutoRebuilds.append(now)
        rebuildScheduled = true
        logger.info("rebuild scheduled: \(reason)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.rebuildScheduled else { return }
            if self.isIdle {
                self.rebuildScheduled = false
                self.tearDown()
            } else {
                self.rebuild()
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw),
              type == .ended else { return }
        scheduleRebuild(reason: "interruption ended")
    }

    private func stopAndDiscard(_ old: AVAudioEngine) {
        if let observer = configurationObserver {
            NotificationCenter.default.removeObserver(observer)
            configurationObserver = nil
        }
        old.stop()
        if engine === old {
            engine = nil
        }
    }

    private func tearDown() {
        if let old = engine {
            stopAndDiscard(old)
        }
        engine = nil
        voiceProcessingEnabled = false
        builtForVoiceProcessing = false
        hasInput = false
        rebuildScheduled = false
        let callbacks = idleCallbacks
        idleCallbacks.removeAll()
        callbacks.forEach { $0() }
    }
}
