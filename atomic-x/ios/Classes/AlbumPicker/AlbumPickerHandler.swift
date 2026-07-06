import Flutter
import UIKit
import AlbumPicker
import Photos
import AVFoundation

/// Bridges Flutter method calls to the AlbumPicker Pod library,
/// and relays delegate callbacks back via EventChannel.
class AlbumPickerHandler: NSObject {
    fileprivate weak var registrar: FlutterPluginRegistrar?
    private var eventSink: ((Any) -> Void)?
    private var pendingResult: FlutterResult?
    private var delegateProxies: [String: AlbumPickerDelegateProxy] = [:]

    /// Supports both traditional AppDelegate.window and UIScene lifecycle.
    fileprivate var viewController: UIViewController? {
        var rootVC: UIViewController?
        if #available(iOS 15.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   let keyWindow = windowScene.keyWindow {
                    rootVC = keyWindow.rootViewController
                    break
                }
            }
        }
        if rootVC == nil {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
                    rootVC = window.rootViewController
                    break
                }
            }
        }
        if rootVC == nil {
            rootVC = UIApplication.shared.delegate?.window??.rootViewController
        }
        guard var topVC = rootVC else { return nil }
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }

    init(registrar: FlutterPluginRegistrar?, eventSink: @escaping (Any) -> Void) {
        self.registrar = registrar
        self.eventSink = eventSink
        super.init()
    }

    // MARK: - Public Entry

    func handlePickMedia(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[AlbumPickerHandler] handlePickMedia called")

        completePreviousSessionIfNeeded()

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }

        pendingResult = result

        let config = buildConfig(from: args)
        let theme = buildTheme(from: args)
        let sessionId = args["sessionId"] as? String ?? ""

        print("[AlbumPickerHandler] Config - style: \(config.style),"
              + " mediaFilter: \(config.mediaFilter),"
              + " maxCount: \(config.maxSelectionCount ?? 0),"
              + " gridCount: \(config.itemsPerRow ?? 0),"
              + " sessionId: \(sessionId)")

        presentAlbumPicker(config: config, theme: theme, sessionId: sessionId)
    }

    // MARK: - Argument Parsing

    private func buildConfig(from args: [String: Any]) -> AlbumPickerConfig {
        var config = AlbumPickerConfig()

        if let pickModeInt = args["pickMode"] as? Int {
            switch pickModeInt {
            case 0:  config.mediaFilter = .imageOnly
            case 1:  config.mediaFilter = .videoOnly
            default: config.mediaFilter = .imageAndVideo
            }
        }
        if let styleInt = args["style"] as? Int {
            config.style = (styleInt == 1) ? .likeWhatsApp : .likeWeChat
        }
        if let maxCount = args["maxCount"] as? Int {
            config.maxSelectionCount = maxCount
        }
        if let gridCount = args["gridCount"] as? Int {
            config.itemsPerRow = gridCount
        }
        if let showsCameraItem = args["showsCameraItem"] as? Bool {
            config.showsCameraItem = showsCameraItem
        }
        if let language = parseLanguage(args["language"] as? Int) {
            config.language = language
        }
        if let compressQualityInt = args["compressQuality"] as? Int {
            config.compressQuality = (compressQualityInt == 1) ? .high : .standard
        }
        if let maxVideoDuration = args["maxVideoDurationInSeconds"] as? Int {
            config.maxVideoDurationInSeconds = maxVideoDuration
        }
        if let maxOutputFileSize = args["maxOutputFileSizeInMB"] as? Int {
            config.maxOutputFileSizeInMB = maxOutputFileSize
        }

        return config
    }

    private func buildTheme(from args: [String: Any]) -> AlbumPickerTheme {
        return AlbumPickerTheme(
            currentPrimaryColor: parseColor(args["primaryColor"] as? String),
            backgroundColor: parseColor(args["backgroundColor"] as? String),
            backgroundColorSecondary: parseColor(args["backgroundColorSecondary"] as? String),
            textColor: parseColor(args["textColor"] as? String),
            textColorSecondary: parseColor(args["textColorSecondary"] as? String),
            confirmButtonIcon: loadFlutterAssetImage(args["confirmButtonIconAsset"] as? String),
            bigFontSize: (args["bigFontSize"] as? Double).map { CGFloat($0) },
            normalFontSize: (args["normalFontSize"] as? Double).map { CGFloat($0) },
            smallFontSize: (args["smallFontSize"] as? Double).map { CGFloat($0) },
            bigRadius: (args["bigRadius"] as? Double).map { CGFloat($0) },
            normalRadius: (args["normalRadius"] as? Double).map { CGFloat($0) },
            smallRadius: (args["smallRadius"] as? Double).map { CGFloat($0) }
        )
    }

    // MARK: - Presentation

    private func presentAlbumPicker(config: AlbumPickerConfig, theme: AlbumPickerTheme, sessionId: String) {
        print("[AlbumPickerHandler] presentAlbumPicker sessionId=\(sessionId)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let viewController = self.viewController else {
                self?.completeWithError(code: "NO_VIEW_CONTROLLER", message: "No view controller available")
                return
            }

            if Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") == nil {
                let alert = UIAlertController(
                    title: "Configuration Error",
                    message: "NSPhotoLibraryUsageDescription is not declared in Info.plist. Please add this key with a usage description to access the photo library.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(alert, animated: true)
                self.completeWithError(code: "MISSING_PERMISSION_DESCRIPTION",
                                       message: "NSPhotoLibraryUsageDescription is not declared in Info.plist")
                return
            }

            let albumPickerView = AlbumPickerView()

            let proxy = AlbumPickerDelegateProxy(
                sessionId: sessionId,
                handler: self
            )
            self.delegateProxies[sessionId] = proxy
            albumPickerView.delegate = proxy

            albumPickerView.initialize(config: config, theme: theme)

            let hostVC = AlbumPickerHostViewController(albumPickerView: albumPickerView)
            hostVC.modalPresentationStyle = .fullScreen
            viewController.present(hostVC, animated: true)
        }
    }

    // MARK: - Session Lifecycle

    private func completePreviousSessionIfNeeded() {
        guard let oldResult = pendingResult else { return }
        print("[AlbumPickerHandler] Completing previous pending result before starting new session")
        oldResult(nil)
        pendingResult = nil
    }

    fileprivate func completeSession(sessionId: String) {
        delegateProxies.removeValue(forKey: sessionId)
        let resultToComplete = pendingResult
        pendingResult = nil
        DispatchQueue.main.async {
            resultToComplete?(nil)
        }
    }

    private func completeWithError(code: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.pendingResult?(FlutterError(code: code, message: message, details: nil))
            self?.pendingResult = nil
        }
    }

    // MARK: - Event Sending

    fileprivate func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }

    fileprivate func buildMediaDataDict(albumMedia: AlbumMedia) -> [String: Any] {
        let mediaPath = albumMedia.mediaPath ?? ""
        let mediaTypeInt = (albumMedia.mediaType == .video) ? 1 : 0
        let fileExtension = mediaPath.isEmpty ? "" : (mediaPath as NSString).pathExtension.lowercased()

        var fileSize: Int64 = 0
        if !mediaPath.isEmpty,
           let attributes = try? FileManager.default.attributesOfItem(atPath: mediaPath),
           let size = attributes[.size] as? Int64 {
            fileSize = size
        }

        var dict: [String: Any] = [
            "id": Int(albumMedia.id),
            "uri": albumMedia.asset?.localIdentifier ?? "",
            "mediaType": mediaTypeInt,
            "mediaPath": mediaPath,
            "fileExtension": fileExtension,
            "fileSize": fileSize,
            "duration": Int(albumMedia.duration),
        ]
        if let thumbnail = albumMedia.videoThumbnailPath {
            dict["videoThumbnailPath"] = thumbnail
        }
        return dict
    }

    // MARK: - Thumbnail Generation

    fileprivate func generateThumbnailForMedia(_ media: AlbumMedia) -> String? {
        if let mediaPath = media.mediaPath, !mediaPath.isEmpty {
            let result: String?
            if media.mediaType == .video {
                result = generateThumbnailFromVideoFile(at: mediaPath)
            } else {
                result = generateThumbnailFromImageFile(at: mediaPath)
            }
            if result != nil { return result }
        }

        if let asset = media.asset {
            if let path = generateThumbnailFromAsset(asset) {
                return path
            }
        }

        return nil
    }

    private func generateThumbnailFromImageFile(at path: String) -> String? {
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        let thumbnailImage = scaledImage(image, maxEdge: 540)
        guard let data = thumbnailImage.jpegData(compressionQuality: 0.8) else { return nil }
        return saveThumbnailToCache(data: data, identifier: "\(path.hashValue)")
    }

    private func generateThumbnailFromVideoFile(at path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 540, height: 540)

        let time = CMTime(seconds: 0, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        let image = UIImage(cgImage: cgImage)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        return saveThumbnailToCache(data: data, identifier: "\(path.hashValue)")
    }

    private func generateThumbnailFromAsset(_ asset: PHAsset) -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var resultPath: String?

        let targetSize = CGSize(width: 540, height: 540)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            defer { semaphore.signal() }
            guard let self = self,
                  let image = image,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            resultPath = self.saveThumbnailToCache(data: data, identifier: "\(asset.localIdentifier.hashValue)")
        }

        semaphore.wait()
        return resultPath
    }

    private func scaledImage(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        guard maxDimension > maxEdge else { return image }

        let scale = maxEdge / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return scaledImage
    }

    private func saveThumbnailToCache(data: Data, identifier: String) -> String? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("album_picker_thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let fileName = "\(identifier)_\(Int(Date().timeIntervalSince1970 * 1000))_thumb.jpg"
        let filePath = cacheDir.appendingPathComponent(fileName)

        do {
            try data.write(to: filePath)
            return filePath.path
        } catch {
            print("[AlbumPickerHandler] Failed to save thumbnail: \(error)")
            return nil
        }
    }

    // MARK: - Utilities

    private func parseLanguage(_ value: Int?) -> AlbumPickerLanguage? {
        guard let value = value else { return nil }
        switch value {
        case 0: return .system
        case 1: return .en
        case 2: return .zhHans
        case 3: return .zhHant
        case 4: return .ar
        default: return nil
        }
    }

    private func parseColor(_ colorStr: String?) -> UIColor? {
        guard let colorStr = colorStr, !colorStr.isEmpty else { return nil }

        var hex = colorStr
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")
            .replacingOccurrences(of: "#", with: "")

        if hex.count == 8 {
            hex = String(hex.dropFirst(2))
        }

        guard hex.count == 6, let rgbValue = UInt64(hex, radix: 16) else {
            print("[AlbumPickerHandler] Failed to parse color: \(colorStr)")
            return nil
        }

        return UIColor(
            red: CGFloat((rgbValue >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgbValue >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    private func loadFlutterAssetImage(_ assetPath: String?) -> UIImage? {
        guard let assetPath = assetPath, !assetPath.isEmpty,
              let registrar = self.registrar else { return nil }
        let key = registrar.lookupKey(forAsset: assetPath)
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

// MARK: - AlbumPickerDelegateProxy

class AlbumPickerDelegateProxy: NSObject, AlbumPickerDelegate {
    let sessionId: String
    private weak var handler: AlbumPickerHandler?

    private let serialQueue: DispatchQueue

    init(sessionId: String, handler: AlbumPickerHandler) {
        self.sessionId = sessionId
        self.handler = handler
        self.serialQueue = DispatchQueue(label: "com.albumpicker.event-queue.\(sessionId)", qos: .userInitiated)
        super.init()
    }

    func onPickConfirm(pickedAlbumMedias: [AlbumMedia], textMessage: String?) {
        print("[AlbumPickerHandler] onPickConfirm: \(pickedAlbumMedias.count) items, sessionId=\(sessionId)")

        DispatchQueue.main.async { [weak handler] in
            handler?.viewController?.dismiss(animated: true)
        }

        serialQueue.async { [weak self] in
            guard let self = self else { return }

            for media in pickedAlbumMedias {
                guard media.videoThumbnailPath == nil else { continue }
                if let path = self.handler?.generateThumbnailForMedia(media) {
                    media.videoThumbnailPath = path
                }
            }

            var event: [String: Any] = [
                "type": "onPickConfirm",
                "sessionId": self.sessionId,
                "pickedAlbumMedias": pickedAlbumMedias.map { self.handler?.buildMediaDataDict(albumMedia: $0) ?? [:] },
            ]
            if let textMessage = textMessage {
                event["textMessage"] = textMessage
            }
            print("[AlbumPickerHandler] onPickConfirm dispatching to Flutter, sessionId=\(self.sessionId)")
            self.handler?.sendEvent(event)

            if pickedAlbumMedias.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.handler?.completeSession(sessionId: self.sessionId)
                }
            }
        }
    }

    func onMediaProcessing(albumMedia: AlbumMedia, progress: Float, error: Bool) {
        print("[AlbumPickerHandler] onMediaProcessing:"
              + " progress=\(progress),"
              + " error=\(error),"
              + " path=\(albumMedia.mediaPath ?? "nil"),"
              + " sessionId=\(sessionId)")

        serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.handler?.sendEvent([
                "type": "onMediaProcessing",
                "sessionId": self.sessionId,
                "data": self.handler?.buildMediaDataDict(albumMedia: albumMedia) ?? [:],
                "progress": Double(progress),
                "error": error,
            ])
        }
    }

    func onMediaProcessed() {
        print("[AlbumPickerHandler] onMediaProcessed, sessionId=\(sessionId)")

        serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.handler?.sendEvent([
                "type": "onMediaProcessed",
                "sessionId": self.sessionId,
            ])
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.handler?.completeSession(sessionId: self.sessionId)
            }
        }
    }

    func onCancel() {
        print("[AlbumPickerHandler] onCancel, sessionId=\(sessionId)")
        handler?.sendEvent([
            "type": "onCancel",
            "sessionId": sessionId,
        ])

        DispatchQueue.main.async { [weak handler] in
            handler?.viewController?.dismiss(animated: true)
        }
        handler?.completeSession(sessionId: sessionId)
    }
}

// MARK: - AlbumPickerHostViewController

private class AlbumPickerHostViewController: UIViewController {
    private let albumPickerView: AlbumPickerView

    init(albumPickerView: AlbumPickerView) {
        self.albumPickerView = albumPickerView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(albumPickerView)
        albumPickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumPickerView.topAnchor.constraint(equalTo: view.topAnchor),
            albumPickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            albumPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            albumPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
