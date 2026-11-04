import Flutter
import TEBeautyKit
import TXLiteAVSDK_Professional
import UIKit

final class AdvancedBeautyPlugin: NSObject, TRTCVideoFrameDelegate {
    private let channel: FlutterMethodChannel
    // The engine can attach its view controller after plugin registration.
    private weak var registrar: FlutterPluginRegistrar?
    private var controller: UIViewController? { registrar?.viewController }
    private var licenseGeneration = 0
    private var generation = 0
    private var authorized = false
    private var licensePending = false
    private var licenseResult: FlutterResult?
    private var enabled = false
    private var key: String?
    private var processor: BeautyProcessor?
    private var processing = false
    private var creating = false
    private var session = 0
    private var disposed = false
    private let frameLock = NSRecursiveLock()
    private var overlay: UIView?
    private var presentation: Int?
    private var closedPresentation = -1

    init(registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "tui_live_kit/advanced_beauty", binaryMessenger: registrar.messenger())
        self.registrar = registrar
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        NotificationCenter.default.addObserver(
            self, selector: #selector(background), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "setLicense":
            licenseResult?(-2)
            licenseResult = result
            licensePending = true
            licenseGeneration += 1
            let request = licenseGeneration
            TEBeautyKit.setTELicense(args["url"] as? String ?? "", key: args["key"] as? String ?? "") {
                [weak self] code, _ in
                DispatchQueue.main.async {
                    guard let self, !self.disposed, self.licenseGeneration == request else { return }
                    self.authorized = code == 0
                    self.licensePending = false
                    NSLog("LiveKitBeauty license result=%ld", code)
                    self.licenseResult?(code)
                    self.licenseResult = nil
                    if !self.authorized { self.stop() }
                    self.channel.invokeMethod("license", arguments: ["code": code])
                    self.refresh()
                }
            }
        case "configure":
            let nextKey = args["key"] as? String
            let nextEnabled = args["enabled"] as? Bool == true
            if nextKey != key || !nextEnabled { stop() }
            key = nextKey
            enabled = nextEnabled
            generation = args["generation"] as? Int ?? 0
            refresh()
            result(nil)
        case "status":
            let status = processing ? "ready" : (enabled && (licensePending || creating) ? "pending" : "unavailable")
            NSLog(
                "LiveKitBeauty status=%@ authorized=%d enabled=%d host=%d", status, authorized, enabled,
                controller != nil)
            result(status)
        case "show": result(show(args["presentation"] as? Int ?? -1))
        case "dismiss":
            let id = args["presentation"] as? Int ?? -1
            closedPresentation = max(closedPresentation, id)
            if presentation == id { dismiss() }
            result(nil)
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func refresh() {
        guard enabled, authorized, let key, !disposed, UIApplication.shared.applicationState != .background else {
            emitReady()
            return
        }
        guard !processing, !creating else {
            emitReady();
            return
        }
        creating = true
        session += 1
        let token = session
        processor = BeautyProcessor(key: key) { [weak self] ready in
            guard let self, self.session == token, !self.disposed else { return }
            self.creating = false
            if ready {
                self.frameLock.lock()
                self.processing = true
                self.frameLock.unlock()
                let code = TRTCCloud.sharedInstance().setLocalVideoProcessDelegete(
                    self, pixelFormat: ._32BGRA, bufferType: .pixelBuffer)
                if code != 0 { self.stop() }
            } else {
                self.stop()
            }
            self.emitReady()
        }
        emitReady()
    }

    private func emitReady() {
        guard !disposed else { return }
        channel.invokeMethod("processing", arguments: ["generation": generation, "ready": processing])
    }

    private func stop() {
        dismiss()
        session += 1
        creating = false
        frameLock.lock()
        let registered = processing
        processing = false
        frameLock.unlock()
        if registered {
            TRTCCloud.sharedInstance().setLocalVideoProcessDelegete(
                nil, pixelFormat: ._32BGRA, bufferType: .pixelBuffer)
        }
        frameLock.lock()
        processor?.dispose()
        processor = nil
        frameLock.unlock()
    }

    func onProcessVideoFrame(_ srcFrame: TRTCVideoFrame, dstFrame: TRTCVideoFrame) -> UInt32 {
        frameLock.lock()
        defer { frameLock.unlock() }
        dstFrame.pixelBuffer = srcFrame.pixelBuffer
        if processing, let buffer = srcFrame.pixelBuffer { dstFrame.pixelBuffer = processor?.process(buffer) ?? buffer }
        return 0
    }

    private func show(_ id: Int) -> Bool {
        guard id > closedPresentation, overlay == nil, processing, let processor else {
            NSLog(
                "LiveKitBeauty panel rejected: stale=%d visible=%d processing=%d", id <= closedPresentation,
                overlay != nil, processing)
            return false
        }
        guard let host = controller?.viewIfLoaded, host.window != nil else {
            NSLog("LiveKitBeauty panel host is not attached")
            return false
        }
        let root = UIView(frame: host.bounds)
        root.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let outside = UIButton(frame: root.bounds)
        outside.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        outside.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        root.addSubview(outside)
        let safeFill = UIView()
        safeFill.backgroundColor = UIColor(red: 31 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1)
        safeFill.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(safeFill)
        processor.removeFromSuperview()
        processor.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(processor)
        NSLayoutConstraint.activate([
            processor.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor),
            processor.trailingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.trailingAnchor),
            processor.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor),
            safeFill.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            safeFill.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            safeFill.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor),
            safeFill.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        processor.onHeightChanged = { [weak root] in root?.setNeedsLayout() }
        host.addSubview(root)
        root.layoutIfNeeded()
        presentation = id
        overlay = root
        NSLog("LiveKitBeauty SDK panel presented")
        return true
    }

    @objc private func dismiss() {
        guard let id = presentation else { return }
        processor?.save()
        processor?.removeFromSuperview()
        overlay?.removeFromSuperview()
        overlay = nil
        presentation = nil
        closedPresentation = max(closedPresentation, id)
        if !disposed { channel.invokeMethod("dismissed", arguments: ["presentation": id]) }
    }

    @objc private func background() {
        stop();
        emitReady()
    }

    func dispose() {
        stop()
        disposed = true
        licenseGeneration += 1
        licenseResult?(-2)
        licenseResult = nil
        NotificationCenter.default.removeObserver(self)
        channel.setMethodCallHandler(nil)
    }
}
