import Flutter
import Foundation

/// `tencent_chat_uikit/realtime_audio` 的实现。
///
/// 方法调用、EventSink 都在主线程；采集队列上的帧切回主线程后再发出。
class RealtimeAudioHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var capture: RealtimeAudioCapture?

    /// 每次 start / stop 自增。采集队列投递到主线程的帧带着当时的值，
    /// 对不上说明是已停掉那一路的残留，不再发给 Dart。
    private var captureSession = 0

    private lazy var voiceCallMode = VoiceCallAudioMode { [weak self] gained in
        self?.eventSink?([
            "type": "focus",
            "state": gained ? "gain" : "loss"
        ])
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            result(RealtimeAudioCapture.isSupported())
        case "startCapture":
            result(startCapture(call))
        case "stopCapture":
            stopCapture()
            result(nil)
        case "requestEncoderReset":
            capture?.requestEncoderReset()
            result(nil)
        case "effectSummary":
            result(capture?.effectSummary() ?? "capture=idle")
        case "enterVoiceCallMode":
            result(voiceCallMode.enter())
        case "exitVoiceCallMode":
            voiceCallMode.exit()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// iOS 由系统决定采集缓冲大小，忽略 `minBufferFrames`。
    private func startCapture(_ call: FlutterMethodCall) -> Bool {
        stopCapture()
        guard RealtimeAudioCapture.isSupported() else {
            return false
        }
        let args = call.arguments as? [String: Any]
        let mode = (args?["mode"] as? String).flatMap(RealtimeAudioCapture.Mode.init(rawValue:)) ?? .recognition
        captureSession += 1
        let session = captureSession
        let newCapture = RealtimeAudioCapture(mode: mode) { [weak self] frames in
            DispatchQueue.main.async {
                guard let self = self, session == self.captureSession else { return }
                for frame in frames {
                    self.eventSink?([
                        "type": "frame",
                        "packets": frame.packets.map { FlutterStandardTypedData(bytes: $0) },
                        "rms": frame.rms
                    ])
                }
            }
        }
        guard newCapture.start() else {
            captureSession += 1
            return false
        }
        capture = newCapture
        return true
    }

    private func stopCapture() {
        captureSession += 1
        capture?.stop()
        capture = nil
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
        stopCapture()
        voiceCallMode.exit()
        eventSink = nil
    }
}
