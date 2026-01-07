import AVKit
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
struct VideoRecorderViewWrapper: UIViewControllerRepresentable {
    let config: VideoRecorderConfig?
    let onVideoCaptured: (String?, Int, String?) -> Void
    let onPhotoCaptured: (String?) -> Void
    var primaryColor: String?

    func makeUIViewController(context: Context) -> UIViewController {
        fetchVideoRecorderSignature()
        
        if let config = buildConfigJSON(from: config) {
            VideoRecorderConfigInternal.sharedInstance().setCustomConfig(config)
        }
        
        let videoRecorderControll = VideoRecorderController()
        
        let recordVCEditCallback: VideoRecorderRecordResultCallback = { videoPath, photo, duration in
            videoRecorderControll.dismiss(animated: true)
            var finalPath: String?
            if let finalPath = videoPath {
                onVideoCaptured(videoPath, Int(duration), getThumbnail(finalPath))
                return
            }
            
            if let photo = photo {
                finalPath = saveImage(photo)
                onPhotoCaptured(finalPath)
                return
            }
            
            onPhotoCaptured(nil)
        }
    
        videoRecorderControll.resultCallback = recordVCEditCallback
        videoRecorderControll.recordFilePath = createRecordedFilePath(messageType: .video, withExtension: "mov")
        return videoRecorderControll
    }
    
    private func saveImage(_ image: UIImage) -> String? {
        
        if let imageData = image.jpegData(compressionQuality: 0.8)
        {
            let path = createRecordedFilePath(messageType: .image, withExtension: "png")
            let fileURL = URL(fileURLWithPath: path)
            try? imageData.write(to: fileURL)
            return path
        }
        return nil
    }
    
    private func createRecordedFilePath(messageType: MessageType, withExtension: String?) -> String {
        let path = ChatUtils.generateMediaPath(messageType: messageType, withExtension: withExtension)
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        return path
    }
    
    private func getThumbnail(_ videoPath: String) -> String? {
        let thumbnail = createThumbnail(from: URL(fileURLWithPath: videoPath))
        if let thumbnail = thumbnail {
            return saveImage(thumbnail)
        }
        return nil
    }

    private func createThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        } catch {
            return nil
        }
    }
    
    func buildConfigJSON(from config: VideoRecorderConfig?) -> String? {
        guard let config = config else {
            return nil;
        }
        
        var configDict: [String: Any] = [:]
        if let maxDuration = config.maxDurationMs {
            configDict["max_record_duration_ms"] = maxDuration
        }
        
        if let minDuration = config.minDurationMs {
            configDict["min_record_duration_ms"] = minDuration
        }
        
        if let quality = config.videoQuality {
            configDict["video_quality"] = quality.rawValue
        }
        
        if let mode = config.recordMode {
            configDict["record_mode"] = mode.rawValue
        }
        
        if let color = primaryColor {
            configDict["primary_theme_color"] = color
        }
        
        if let isFrontCamera = config.isDefaultFrontCamera {
            configDict["is_default_front_camera"] = isFrontCamera ? "true" : "false"
        }
                
        if let isSupportEdit = config.isSupportEdit {
            configDict["support_edit"] = isSupportEdit ? "true" : "false"
        }
        
        if let isSupportAspect = config.isSupportAspect {
            configDict["support_record_aspect"] = isSupportAspect ? "true" : "false"
        }
        
        if let isSupportBeauty = config.isSupportBeauty {
            configDict["support_record_beauty"] = isSupportBeauty ? "true" : "false"
        }
        
        if let isSupportTorch = config.isSupportTorch {
            configDict["support_record_torch"] = isSupportTorch ? "true" : "false"
        }
        
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: configDict,
                options: [.prettyPrinted, .withoutEscapingSlashes]
            )
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("JSON builder fail: \(error)")
            return nil
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#endif

public func fetchVideoRecorderSignature() {
    if (VideoRecordSignatureChecker.shareInstance().getSetSignatureResult() == .VIDEO_RECORD_SIGNATURE_SUCCESS) {
        return
    }
}
