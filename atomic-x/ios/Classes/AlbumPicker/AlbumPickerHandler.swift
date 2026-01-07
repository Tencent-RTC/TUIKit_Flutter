import Flutter
import UIKit
import Photos
import SwiftUI

/**
 * AlbumPickerHandler
 * 处理 Flutter 层的 AlbumPicker 调用
 */
class AlbumPickerHandler: NSObject {
    private weak var viewController: UIViewController?
    private var pendingResult: FlutterResult?
    private var eventSink: ((Any) -> Void)?
    private let languageState = LanguageState()
    private let themeState = ThemeState()
    
    init(viewController: UIViewController?, eventSink: @escaping (Any) -> Void) {
        self.viewController = viewController
        self.eventSink = eventSink
        super.init()
    }
    
    func handlePickMedia(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[AlbumPickerHandler] handlePickMedia called")
        
        guard pendingResult == nil else {
            print("[AlbumPickerHandler] AlbumPicker is already active")
            result(FlutterError(code: "ALREADY_ACTIVE",
                              message: "AlbumPicker is already active",
                              details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments",
                              details: nil))
            return
        }
        
        pendingResult = result
        
        // 解析参数
        let pickModeInt = args["pickMode"] as? Int ?? 2
        let maxCount = args["maxCount"] as? Int ?? 9
        let gridCount = args["gridCount"] as? Int ?? 4
        let primaryColorHex = args["primaryColor"] as? String
        let languageCode = args["languageCode"] as? String
        let countryCode = args["countryCode"] as? String
        let scriptCode = args["scriptCode"] as? String
        
        print("[AlbumPickerHandler] Config - pickMode: \(pickModeInt), maxCount: \(maxCount), gridCount: \(gridCount), primaryColor: \(primaryColorHex ?? "nil"), language: \(languageCode ?? "nil")")
        
        // 设置语言
        if let languageCode = languageCode {
            setupLanguage(languageCode: languageCode, countryCode: countryCode, scriptCode: scriptCode)
        }
        
        // 转换 pickMode
        let albumMode: AlbumMode
        switch pickModeInt {
        case 0:
            albumMode = .images
        case 1:
            albumMode = .videos
        case 2:
            albumMode = .all
        default:
            albumMode = .all
        }
        
        // 设置主题色
        if let primaryColorHex = primaryColorHex, !primaryColorHex.isEmpty {
            print("[VideoRecorderHandler] Primary color: \(primaryColorHex)")
            themeState.setPrimaryColor(primaryColorHex)
        }
        
        // 创建配置
        let config = AlbumPickerConfig(
            maxImagesCount: maxCount,
            columnNumber: gridCount,
            showEditButton: false,
            showOriginalToggle: false,
            albumMode: albumMode,
            primary: primaryColorHex,
            maxConcurrentTranscodingCount: 3,
            transcodeQuality: .medium
        )
        
        // 检查权限
        checkPhotoLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.presentAlbumPicker(config: config)
            } else {
                showAuthorizationAlert()
                self.pendingResult?(FlutterError(code: "PERMISSION_DENIED",
                                                message: "Photo library permission denied",
                                                details: nil))
                self.pendingResult = nil
            }
        }
    }
    
    private func showAuthorizationAlert() {
        let title: String = LocalizedAlbumPickerString("no_permission")
        let message: String = LocalizedAlbumPickerString("no_permission_message")
        let laterMessage: String = LocalizedAlbumPickerString("cancel")
        let openSettingMessage: String = LocalizedAlbumPickerString("go_to_settings")

        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert )
        alertController.addAction(UIAlertAction(title: laterMessage, style: .cancel, handler:  { action in }))
        alertController.addAction(UIAlertAction(title: openSettingMessage, style: .default, handler: { action in
            let app = UIApplication.shared
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if app.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    app.open(url)
                } else {
                    app.openURL(url)
                }
            }
        }))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let window = getAvailableWindow(),
               let rootVC = window.rootViewController {
                rootVC.present(alertController, animated: true)
            }
        }
    }
    
    private func getAvailableWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let allWindows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .filter { $0.rootViewController != nil }
            
            let foregroundKeyWindow = allWindows.first { window in
                window.isKeyWindow &&
                (window.windowScene?.activationState == .foregroundActive)
            }
            if let window = foregroundKeyWindow { return window }
            
            let foregroundWindow = allWindows.first { window in
                window.windowScene?.activationState == .foregroundActive
            }
            if let window = foregroundWindow { return window }
            
            let anyKeyWindow = allWindows.first { $0.isKeyWindow }
            if let window = anyKeyWindow { return window }
            
            return allWindows.first
        } else {
            return UIApplication.shared.keyWindow?.rootViewController != nil ?
                   UIApplication.shared.keyWindow :
                   UIApplication.shared.windows.first { $0.rootViewController != nil }
        }
    }
    
    private func setupLanguage(languageCode: String, countryCode: String?, scriptCode: String?) {
        var normalizedLanguage: String
        
        if languageCode.hasPrefix("zh") {
            if let scriptCode = scriptCode, !scriptCode.isEmpty {
                if scriptCode == "Hans" {
                    normalizedLanguage = "zh-Hans"
                } else if scriptCode == "Hant" {
                    normalizedLanguage = "zh-Hant"
                } else {
                    normalizedLanguage = "zh-Hans"
                }
            } else {
                normalizedLanguage = "zh-Hans"
            }
        } else if languageCode.hasPrefix("en") {
            normalizedLanguage = "en"
        } else if languageCode.hasPrefix("ar") {
            normalizedLanguage = "ar"
        } else {
            normalizedLanguage = "en"
        }
        
        languageState.setLanguage(normalizedLanguage)
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func presentAlbumPicker(config: AlbumPickerConfig) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let viewController = self.viewController else {
                self?.pendingResult?(FlutterError(code: "NO_VIEW_CONTROLLER",
                                                 message: "No view controller available",
                                                 details: nil))
                self?.pendingResult = nil
                return
            }
            
            let albumPickerView = AlbumPicker(
                config: config,
                onFinishedSelect: { [weak self] selectedCount in
                    self?.handleFinishedSelect(selectedCount: selectedCount)
                },
                onProgress: { [weak self] model, index, progress in
                    self?.handleProgress(model: model, index: index, progress: progress)
                }
            )
            
            let hostingController = UIHostingController(rootView: albumPickerView)
            hostingController.modalPresentationStyle = .fullScreen
            
            viewController.present(hostingController, animated: true)
        }
    }
    
    private func handleFinishedSelect(selectedCount: Int) {
        print("[AlbumPickerHandler] onFinishedSelect: \(selectedCount) items")
        
        // 销毁界面
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
        
        if selectedCount == 0 {
            // 用户取消
            pendingResult?(nil)
            pendingResult = nil
        }
    }
    
    private func handleProgress(model: AlbumPickerModel, index: Int, progress: Double) {
        print("[AlbumPickerHandler] onProgress: index=\(index), progress=\(progress)")
        
        // 转换并发送进度事件
        convertAndSendProgress(model: model, index: index, progress: progress)
        
        // 当处理完成时，结束
        if progress >= 1.0 {
            pendingResult?(nil)
            pendingResult = nil
        }
    }
    
    private func convertAndSendProgress(model: AlbumPickerModel, index: Int, progress: Double) {
        print("[AlbumPickerHandler] Converting asset at index \(index)")
        
        guard let mediaPath = model.mediaPath else {
            print("[AlbumPickerHandler] mediaPath is nil")
            return
        }
        
        // 确定类型
        let mediaType: Int
        switch model.mediaType {
        case .image:
            mediaType = 0
        case .video:
            mediaType = 1
        case .gif:
            mediaType = 2
        }
        
        // 获取文件扩展名和大小
        let fileExtension = (mediaPath as NSString).pathExtension.lowercased()
        var fileSize: Int64 = 0
        if let attributes = try? FileManager.default.attributesOfItem(atPath: mediaPath),
           let size = attributes[.size] as? Int64 {
            fileSize = size
        }
        
        print("[AlbumPickerHandler] Processed file: path=\(mediaPath), size=\(fileSize), type=\(mediaType)")
        
        // 构建数据字典
        var dataDict: [String: Any] = [
            "id": model.id,
            "mediaType": mediaType,
            "mediaPath": mediaPath,
            "fileExtension": fileExtension,
            "fileSize": fileSize,
            "isOrigin": model.isOrigin
        ]
        
        // 如果是视频且有缩略图，添加缩略图路径
        if mediaType == 1, let videoThumbnailPath = model.videoThumbnailPath {
            dataDict["videoThumbnailPath"] = videoThumbnailPath
            print("[AlbumPickerHandler] Video thumbnail path: \(videoThumbnailPath)")
        }
        
        // 发送进度事件
        let event: [String: Any] = [
            "type": "progress",
            "index": index,
            "progress": progress,
            "data": dataDict
        ]
        
        eventSink?(event)
    }
    

}

