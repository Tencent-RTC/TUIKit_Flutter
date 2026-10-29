import Flutter
import Foundation

/// `tencent_chat_uikit/opus_player` 的实现。
///
/// 方法调用、EventSink 都在主线程；解码队列 / 播放回调由 [OpusStreamPlayer] 切回主线程。
class OpusPlayerHandler: NSObject, FlutterStreamHandler {
    private static let levelInterval: TimeInterval = 0.05

    private var eventSink: FlutterEventSink?
    private var player: OpusStreamPlayer?
    private var levelTimer: Timer?
    private var lastSentLevel = 0.0

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            result(OpusStreamPlayer.isSupported())
        case "create":
            result(create())
        case "beginStream":
            player?.beginStream()
            result(nil)
        case "feed":
            feed(call)
            result(nil)
        case "flush":
            flush()
            result(nil)
        case "release":
            release()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func create() -> Bool {
        if player != nil {
            return true
        }
        guard OpusStreamPlayer.isSupported() else {
            return false
        }
        let newPlayer = OpusStreamPlayer()
        newPlayer.onChunkQueued = { [weak self, weak newPlayer] durationMs, isFinished in
            guard let self = self, self.player === newPlayer else { return }
            self.eventSink?([
                "type": "chunk",
                "durationMs": durationMs,
                "isFinished": isFinished
            ])
        }
        newPlayer.onFinished = { [weak self, weak newPlayer] in
            guard let self = self, self.player === newPlayer else { return }
            self.eventSink?(["type": "finished"])
        }
        guard newPlayer.start() else {
            return false
        }
        player = newPlayer
        lastSentLevel = 0
        startLevelTimer()
        return true
    }

    private func feed(_ call: FlutterMethodCall) {
        guard let player = player else { return }
        let args = call.arguments as? [String: Any]
        let packets = (args?["packets"] as? [Any] ?? [])
            .compactMap { ($0 as? FlutterStandardTypedData)?.data }
            .filter { !$0.isEmpty }
        let isFinished = args?["isFinished"] as? Bool ?? false
        player.feed(packets, isFinished: isFinished)
    }

    private func flush() {
        player?.flush()
        if lastSentLevel != 0 {
            sendLevel(0)
        }
    }

    private func release() {
        stopLevelTimer()
        player?.stop()
        player = nil
        if lastSentLevel != 0 {
            sendLevel(0)
        }
    }

    /// 播放器存在期间每 50ms 看一次：播放中上报音量，停下来时补一个 0 后不再上报。
    private func startLevelTimer() {
        stopLevelTimer()
        let timer = Timer(timeInterval: OpusPlayerHandler.levelInterval, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            if player.isPlaying {
                self.sendLevel(player.currentLevel)
            } else if self.lastSentLevel != 0 {
                self.sendLevel(0)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        levelTimer = timer
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func sendLevel(_ value: Double) {
        lastSentLevel = value
        eventSink?(["type": "level", "value": value])
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func dispose() {
        eventSink = nil
        release()
    }
}
