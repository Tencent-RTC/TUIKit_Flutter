import CoreVideo
import TEBeautyKit
import UIKit

/// Owns the SDK panel and one account's effect parameters.
final class BeautyProcessor: UIView, TEPanelViewDelegate {
    private let key: String
    // TEPanelView reads the global resource configuration during initialization.
    private lazy var panel = BeautySDKPanel()
    private var engine: TEBeautyKit?
    private let lock = NSRecursiveLock()
    private var active = false
    private var disposed = false
    private var panelHeight: CGFloat = 230
    var onHeightChanged: (() -> Void)?
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: panelHeight) }

    init(key: String, ready: @escaping (Bool) -> Void) {
        self.key = key
        super.init(frame: .zero)
        let modules = [
            ("BEAUTY_TEMPLATE", "beauty_template"), ("BEAUTY", "beauty"), ("BEAUTY_IMAGE", "beauty_image"),
            ("BEAUTY_SHAPE", "beauty_shape"), ("BEAUTY_MAKEUP", "beauty_makeup"), ("LUT", "lut"),
            ("BEAUTY_BODY", "beauty_body"), ("MOTION_2D", "motion_2d"), ("MOTION_3D", "motion_3d"),
            ("MOTION_GESTURE", "motion_gesture"), ("MAKEUP", "makeup"), ("LIGHT_MAKEUP", "light_makeup"),
        ]
        TEUIConfig.shareInstance().panelBackgroundColor = UIColor(
            red: 31 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1)
        TEUIConfig.shareInstance().setTEPanelViewResources(
            modules.compactMap { name, file in Bundle.main.path(forResource: file, ofType: "json").map { [name: $0] } })
        panel.delegate = self
        panel.isShowCompareBtn(false)
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)
        let initialHeight = panel.heightAnchor.constraint(equalToConstant: 230)
        initialHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor), panel.topAnchor.constraint(equalTo: topAnchor),
            initialHeight,
        ])
        panel.heightChanged = { [weak self] height in
            guard let self, height > 0, abs(height - self.panelHeight) > 0.5 else { return }
            self.panelHeight = height
            self.invalidateIntrinsicContentSize()
            DispatchQueue.main.async { [weak self] in self?.onHeightChanged?() }
        }
        TEBeautyKit.create { [weak self] kit in
            DispatchQueue.main.async {
                guard let self, !self.disposed else {
                    kit?.xmagicApi?.onPause()
                    kit?.xmagicApi?.clearListeners()
                    kit?.xmagicApi?.deinit()
                    return
                }
                guard let kit else {
                    ready(false);
                    return
                }
                self.lock.lock()
                self.engine = kit
                kit.xmagicApi?.setAudioMute(true)
                kit.setLogLevel(.YT_SDK_ERROR_LEVEL)
                self.panel.teBeautyKit = kit
                self.panel.beautyKitApi = kit.xmagicApi
                if let saved = UserDefaults.standard.string(forKey: key) {
                    self.panel.setExportParamList(
                        saved.replacingOccurrences(of: "__TUILiveKitBundle__", with: Bundle.main.bundlePath))
                } else {
                    self.panel.setDefaultBeauty()
                }
                self.active = true
                kit.onResume()
                self.lock.unlock()
                ready(true)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func process(_ buffer: CVPixelBuffer) -> CVPixelBuffer {
        lock.lock()
        defer { lock.unlock() }
        guard active, let engine else { return buffer }
        return engine.processPixelData(
            buffer, pixelDataWidth: Int32(CVPixelBufferGetWidth(buffer)),
            pixelDataHeight: Int32(CVPixelBufferGetHeight(buffer)), with: .topLeft, with: .cameraRotation0)?.pixelData?
            .data ?? buffer
    }

    func save() {
        lock.lock()
        defer { lock.unlock() }
        guard let engine else { return }
        UserDefaults.standard.set(
            (engine.exportInUseSDKParam() ?? "[]").replacingOccurrences(
                of: Bundle.main.bundlePath, with: "__TUILiveKitBundle__"), forKey: key)
    }

    func dispose() {
        lock.lock()
        defer { lock.unlock() }
        guard !disposed else { return }
        save()
        disposed = true
        active = false
        engine?.xmagicApi?.onPause()
        engine?.xmagicApi?.clearListeners()
        engine?.xmagicApi?.deinit()
        panel.teBeautyKit = nil
        panel.beautyKitApi = nil
        engine = nil
    }

    func setEffect() { save() }
    func showBeautyChanged(_ open: Bool) { engine?.enableBeauty(open) }
}

private final class BeautySDKPanel: TEPanelView {
    var heightChanged: ((CGFloat) -> Void)?
    override func layoutSubviews() {
        super.layoutSubviews()
        heightChanged?(bounds.height)
    }
}
