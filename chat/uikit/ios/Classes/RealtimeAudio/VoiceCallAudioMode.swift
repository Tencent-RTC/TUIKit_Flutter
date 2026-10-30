import AVFoundation
import Foundation
import os.log

/// 通话音频模式：AVAudioSession `.playAndRecord` + `.voiceChat`，外放、允许蓝牙。
///
/// [onFocusChange] 在主线程回调：中断开始为 false，中断结束为 true。
/// 只在主线程调用 [enter] / [exit]。
final class VoiceCallAudioMode {
    private let logger = Logger(subsystem: "RealtimeAudio", category: "VoiceCallAudioMode")
    private let onFocusChange: (Bool) -> Void
    private var interruptionObserver: NSObjectProtocol?
    private var active = false
    private var entered = false

    private var previousCategory: AVAudioSession.Category = .soloAmbient
    private var previousMode: AVAudioSession.Mode = .default
    private var previousOptions: AVAudioSession.CategoryOptions = []

    init(onFocusChange: @escaping (Bool) -> Void) {
        self.onFocusChange = onFocusChange
    }

    /// - Returns: session 是否配置并激活成功。失败时调用方不必中断通话
    func enter() -> Bool {
        if active {
            return entered
        }
        active = true
        let session = AVAudioSession.sharedInstance()
        SharedAudioEngine.shared.cancelIdleCallbacks()
        previousCategory = session.category
        previousMode = session.mode
        previousOptions = session.categoryOptions
        do {
            try session.setCategory(
                .playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth]
            )
            try session.setActive(true)
            entered = true
        } catch {
            logger.error("enter voice call mode failed: \(error.localizedDescription)")
            entered = false
        }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        // session 配好之后再要求 voice processing，engine 若已在跑会按新 session 重建
        SharedAudioEngine.shared.voiceCallModeActive = true
        return entered
    }

    /// 可重复调用。采集 / 播放还挂在 engine 上时，session 等它们都释放后再还原，
    /// 运行中改 category 会让 engine 因配置变化停掉。
    func exit() {
        guard active else { return }
        active = false
        entered = false
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        SharedAudioEngine.shared.voiceCallModeActive = false
        let category = previousCategory
        let mode = previousMode
        let options = previousOptions
        SharedAudioEngine.shared.whenIdle { [weak self] in
            self?.restoreSession(category: category, mode: mode, options: options)
        }
    }

    private func restoreSession(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        guard !active else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(category, mode: mode, options: options)
        } catch {
            logger.warning("restore audio session category failed: \(error.localizedDescription)")
        }
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.warning("deactivate audio session failed: \(error.localizedDescription)")
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard active,
              let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            if #available(iOS 14.5, *),
               notification.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt ==
                AVAudioSession.InterruptionReason.appWasSuspended.rawValue {
                return
            }
            onFocusChange(false)
        case .ended:
            onFocusChange(true)
        @unknown default:
            break
        }
    }
}
