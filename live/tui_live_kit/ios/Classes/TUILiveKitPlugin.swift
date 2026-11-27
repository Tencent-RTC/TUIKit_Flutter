import Flutter
import Foundation
import Network
import UIKit

/// `tui_live_kit` 的 iOS 承载层。
///
/// 只封装 AtomicXCore 未覆盖、且当前产品范围实际需要的系统能力：
/// 系统热状态与网络类型，分别对应主播端「直播状态 → 设备状态」的温度行与网络行；
/// 以及观众上麦开麦期间的后台保活入口。
public class TUILiveKitPlugin: NSObject, FlutterPlugin {
    private static let thermalStateChannelName = "tui_live_kit/thermal_state"
    private static let networkTypeChannelName = "tui_live_kit/network_type"
    private static let audioForegroundServiceChannelName = "tui_live_kit/audio_foreground_service"

    private var screenAwakeChannel: FlutterMethodChannel?
    private var screenAwakeOwners = Set<String>()
    private var previousIdleTimerDisabled: Bool?

    private func setScreenAwake(owner: String, enabled: Bool) {
        if enabled {
            if screenAwakeOwners.isEmpty { previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled }
            screenAwakeOwners.insert(owner)
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            screenAwakeOwners.remove(owner)
            if screenAwakeOwners.isEmpty, let previousIdleTimerDisabled {
                UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
                self.previousIdleTimerDisabled = nil
            }
        }
    }

    private var advancedBeauty: AdvancedBeautyPlugin?
    private var thermalStateChannel: FlutterEventChannel?
    private var networkTypeChannel: FlutterEventChannel?
    private var audioForegroundServiceChannel: FlutterMethodChannel?
    private let thermalStateHandler = ThermalStateStreamHandler()
    private let networkTypeHandler = NetworkTypeStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TUILiveKitPlugin()
        instance.advancedBeauty = AdvancedBeautyPlugin(registrar: registrar)

        let thermalChannel = FlutterEventChannel(name: thermalStateChannelName, binaryMessenger: registrar.messenger())
        thermalChannel.setStreamHandler(instance.thermalStateHandler)
        instance.thermalStateChannel = thermalChannel

        let networkChannel = FlutterEventChannel(name: networkTypeChannelName, binaryMessenger: registrar.messenger())
        networkChannel.setStreamHandler(instance.networkTypeHandler)
        instance.networkTypeChannel = networkChannel

        let audioChannel = FlutterMethodChannel(
            name: audioForegroundServiceChannelName, binaryMessenger: registrar.messenger())
        audioChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "start":
                // iOS 由宿主 App 的 UIBackgroundModes = audio 提供保活，不启动任何服务。
                result(true)
            case "stop": result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        }
        instance.audioForegroundServiceChannel = audioChannel

        let awakeChannel = FlutterMethodChannel(
            name: "tui_live_kit/screen_awake", binaryMessenger: registrar.messenger())
        awakeChannel.setMethodCallHandler { [weak instance] call, result in
            guard call.method == "setEnabled" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let arguments = call.arguments as? [String: Any], let owner = arguments["owner"] as? String,
                let enabled = arguments["enabled"] as? Bool
            else {
                result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
                return
            }
            instance?.setScreenAwake(owner: owner, enabled: enabled)
            result(nil)
        }
        instance.screenAwakeChannel = awakeChannel
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        screenAwakeChannel?.setMethodCallHandler(nil)
        screenAwakeChannel = nil
        screenAwakeOwners.removeAll()
        if let previousIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
            self.previousIdleTimerDisabled = nil
        }
        advancedBeauty?.dispose()
        advancedBeauty = nil
        thermalStateChannel?.setStreamHandler(nil)
        thermalStateChannel = nil
        networkTypeChannel?.setStreamHandler(nil)
        networkTypeChannel = nil
        audioForegroundServiceChannel?.setMethodCallHandler(nil)
        audioForegroundServiceChannel = nil
    }
}

/// 用 `ProcessInfo.thermalState` 及其变更通知向 Dart 推送归一化档位。
private class ThermalStateStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        NotificationCenter.default.addObserver(
            self, selector: #selector(thermalStateDidChange), name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil)
        emitCurrentState()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(
            self, name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
        eventSink = nil
        return nil
    }

    @objc private func thermalStateDidChange() { emitCurrentState() }

    /// 通知可能来自非主线程，EventSink 统一切回主线程使用。
    private func emitCurrentState() {
        let level = Self.normalize(ProcessInfo.processInfo.thermalState)
        DispatchQueue.main.async { [weak self] in self?.eventSink?(level) }
    }

    /// 与 iOS `PusherStore.temperatureStatus(_:)` 相同的三档映射。
    private static func normalize(_ thermalState: ProcessInfo.ThermalState) -> Int {
        switch thermalState {
        case .nominal: return 0
        case .fair: return 1
        case .serious, .critical: return 2
        @unknown default: return 0
        }
    }
}

/// 用 `NWPathMonitor` 向 Dart 推送归一化的网络类型。
private class NetworkTypeStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.tencent.livekit.tui_live_kit.network_type")

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { [weak self] path in self?.emit(Self.normalize(path)) }
        pathMonitor.start(queue: queue)
        monitor = pathMonitor
        // `pathUpdateHandler` 首次回调有延迟，先按当前 path 立即上报一次。
        emit(Self.normalize(pathMonitor.currentPath))
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        monitor?.cancel()
        monitor = nil
        eventSink = nil
        return nil
    }

    /// 回调在自建串行队列，EventSink 统一切回主线程使用。
    private func emit(_ networkType: Int) { DispatchQueue.main.async { [weak self] in self?.eventSink?(networkType) } }

    /// 与 iOS `PusherStore` 的 `NetworkKind` 相同的三档映射。
    ///
    /// 以太网与其他链路归为未知，与 `NetworkKind` 只区分 Wi-Fi、蜂窝、未知的语义一致。
    private static func normalize(_ path: NWPath) -> Int {
        guard path.status == .satisfied else { return 0 }
        if path.usesInterfaceType(.wifi) { return 1 }
        if path.usesInterfaceType(.cellular) { return 2 }
        return 0
    }
}
