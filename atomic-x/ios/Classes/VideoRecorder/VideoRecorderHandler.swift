import Flutter
import UIKit
import SwiftUI

/**
 * VideoRecorderHandler
 * 处理 Flutter 层的 VideoRecorder 调用
 */
class VideoRecorderHandler: NSObject {
    private weak var viewController: UIViewController?
    private var pendingResult: FlutterResult?
    private let languageState = LanguageState()
    private let themeState = ThemeState()
    
    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
    }
    
    func handleStartRecord(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[VideoRecorderHandler] handleStartRecord called")
        
        guard pendingResult == nil else {
            print("[VideoRecorderHandler] VideoRecorder is already active")
            result(FlutterError(code: "ALREADY_ACTIVE",
                              message: "VideoRecorder is already active",
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
        let recordModeInt = args["recordMode"] as? Int
        let videoQualityInt = args["videoQuality"] as? Int
        let minDurationMs = args["minDurationMs"] as? Int
        let maxDurationMs = args["maxDurationMs"] as? Int
        let isDefaultFrontCamera = args["isDefaultFrontCamera"] as? Bool
        let isSupportEdit = args["isSupportEdit"] as? Bool
        let isSupportBeauty = args["isSupportBeauty"] as? Bool
        let isSupportTorch = args["isSupportTorch"] as? Bool
        let isSupportAspect = args["isSupportAspect"] as? Bool
        let primaryColorHex = args["primaryColor"] as? String
        let languageCode = args["languageCode"] as? String
        let countryCode = args["countryCode"] as? String
        let scriptCode = args["scriptCode"] as? String
        
        print("[VideoRecorderHandler] Config - recordMode: \(recordModeInt ?? -1), videoQuality: \(videoQualityInt ?? -1), primaryColor: \(primaryColorHex ?? "nil"), language: \(languageCode ?? "nil")")
        
        // 设置语言
        if let languageCode = languageCode {
            setupLanguage(languageCode: languageCode, countryCode: countryCode, scriptCode: scriptCode)
        }
        
        // 设置主题色
        if let primaryColorHex = primaryColorHex, !primaryColorHex.isEmpty {
            print("[VideoRecorderHandler] Primary color: \(primaryColorHex)")
            themeState.setPrimaryColor(primaryColorHex)
        }
        
        // 创建配置
        let config = VideoRecorderConfig(
            recordMode: recordModeInt != nil ? RecordMode(rawValue: recordModeInt!) : nil,
            videoQuality: videoQualityInt != nil ? VideoQuality(rawValue: videoQualityInt! + 1) : nil,
            minDurationMs: minDurationMs,
            maxDurationMs: maxDurationMs,
            isDefaultFrontCamera: isDefaultFrontCamera,
            isSupportEdit: isSupportEdit,
            isSupportBeauty: isSupportBeauty,
            isSupportTorch: isSupportTorch,
            isSupportAspect: isSupportAspect
        )
        
        // 展示录制界面
        presentVideoRecorder(config: config)
    }
    
    private func setupLanguage(languageCode: String, countryCode: String?, scriptCode: String?) {
        // 规范化语言代码以匹配 .lproj 目录名
        var normalizedLanguage: String
        
        if languageCode.hasPrefix("zh") {
            // 中文需要 scriptCode 来区分简繁体
            if let scriptCode = scriptCode, !scriptCode.isEmpty {
                if scriptCode == "Hans" {
                    normalizedLanguage = "zh-Hans"  // 简体中文
                } else if scriptCode == "Hant" {
                    normalizedLanguage = "zh-Hant"  // 繁体中文
                } else {
                    normalizedLanguage = "zh-Hans"  // 默认简体
                }
            } else {
                normalizedLanguage = "zh-Hans"  // 默认简体
            }
        } else if languageCode.hasPrefix("en") {
            normalizedLanguage = "en"
        } else if languageCode.hasPrefix("ar") {
            normalizedLanguage = "ar"
        } else {
            normalizedLanguage = "en"  // 默认英文
        }
        
        print("[VideoRecorderHandler] Language set to: \(normalizedLanguage)")
        
        languageState.setLanguage(normalizedLanguage)
    }
    
    private func presentVideoRecorder(config: VideoRecorderConfig?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let viewController = self.viewController else {
                self?.pendingResult?(FlutterError(code: "NO_VIEW_CONTROLLER",
                                                 message: "No view controller available",
                                                 details: nil))
                self?.pendingResult = nil
                return
            }
            
            let videoRecorderView = VideoRecorder(
                config: config,
                onVideoCaptured: { [weak self] filePath, durationMs, thumbnailPath in
                    self?.handleVideoCaptured(filePath: filePath, durationMs: durationMs, thumbnailPath: thumbnailPath)
                },
                onPhotoCaptured: { [weak self] filePath in
                    self?.handlePhotoCaptured(filePath: filePath)
                }
            )
            .environmentObject(self.themeState)
            
            let hostingController = UIHostingController(rootView: videoRecorderView)
            hostingController.modalPresentationStyle = .fullScreen
            
            viewController.present(hostingController, animated: true)
        }
    }
    
    private func handlePhotoCaptured(filePath: String?) {
        print("[VideoRecorderHandler] onPhotoCaptured: \(filePath ?? "nil")")
        
        // 销毁界面
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
        
        let resultMap: [String: Any] = [
            "type": "photo",
            "filePath": filePath ?? ""
        ]
        
        pendingResult?(resultMap)
        pendingResult = nil
    }
    
    private func handleVideoCaptured(filePath: String?, durationMs: Int, thumbnailPath: String?) {
        print("[VideoRecorderHandler] onVideoCaptured: path=\(filePath ?? "nil"), duration=\(durationMs), thumbnail=\(thumbnailPath ?? "nil")")
        
        // 销毁界面
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
        
        let resultMap: [String: Any] = [
            "type": "video",
            "filePath": filePath ?? "",
            "durationMs": durationMs,
            "thumbnailPath": thumbnailPath ?? ""
        ]
        
        pendingResult?(resultMap)
        pendingResult = nil
    }
}
