//
//  AlbumPickerAssetProcessor.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/22.
//  Copyright © 2025 Tencent. All rights reserved.
//

import SwiftUI
import Photos
import Combine
import AVFoundation
import UIKit

internal let ALBUM_PICKER_THUMBNAIL_MAX_EDGE: CGFloat = 540

internal enum MessageType {
    case image
    case video
}

// MARK: - Transcoding Queue Management
internal class AlbumPickerTranscodingManager: ObservableObject {
    @Published var currentTranscodingCount = 0
    var transcodingQueue: [(AlbumPickerAssetModel, PHAsset, Int)] = []
    let transcodingQueueLock = NSLock()
    
    static let shared = AlbumPickerTranscodingManager()
    private init() {}
}

// MARK: - Asset Processing Methods Extension
extension AlbumPicker {
    
    // MARK: - Asset Processing Methods
    internal func processSelectedAssetsWithProgress(_ validAssets: [(AlbumPickerAssetModel, PHAsset)]) {
        print("processSelectedAssetsWithProgress started. currentTime = \(Date())")
        
        transcodingManager.transcodingQueueLock.lock()
        transcodingManager.currentTranscodingCount = 0
        transcodingManager.transcodingQueue.removeAll()
        transcodingManager.transcodingQueueLock.unlock()
        
        for (index, (assetModel, asset)) in validAssets.enumerated() {
            if assetModel.type == .video {
                enqueueVideoProcessing(assetModel, asset: asset, index: index)
            } else {
                processImageAssetWithProgress(assetModel, asset: asset, index: index)
            }
        }
    }
    
    internal func processVideoAssetWithProgress(
        _ assetModel: AlbumPickerAssetModel,
        asset: PHAsset,
        index: Int,
        completion: @escaping (AlbumPickerModel) -> Void
    ) {
        let pickModel = AlbumPickerModel()
        
        DispatchQueue.main.async { self.onProgress?(pickModel, index, 0.0) }
        
        let resolvePreTranscodeURL: (@escaping (URL?) -> Void) -> Void = { done in
            if let editVideoUrl = assetModel.editVideoUrl {
                done(editVideoUrl)
            } else {
                self.imageManager.requestVideoURL(with: asset, success: { url in
                    done(url)
                }, failure: { _ in
                    print("Failed to get video URL for asset: \(asset.localIdentifier)")
                    done(nil)
                })
            }
        }
        
        resolvePreTranscodeURL { preUrl in
            guard let preUrl = preUrl else {
                DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                completion(pickModel)
                return
            }
            
            self.generateInitialThumbnailForVideo(videoUrl: preUrl, pickModel: pickModel) {
                if self.isSelectOriginalPhoto {
                    print("Original video selected, skipping transcoding")
                    pickModel.setMediaPath(preUrl.path)
                    pickModel.isOrigin = true
                    DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                    completion(pickModel)
                } else {
                    self.decideTranscodeAndProcess(preTranscodeUrl: preUrl, pickModel: pickModel, index: index, completion: completion)
                }
            }
        }
    }
    
    // Decide whether to transcode based on bitrate, then process
    internal func decideTranscodeAndProcess(
        preTranscodeUrl: URL,
        pickModel: AlbumPickerModel,
        index: Int,
        completion: @escaping (AlbumPickerModel) -> Void
    ) {
        let asset = AVAsset(url: preTranscodeUrl)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            pickModel.setMediaPath(preTranscodeUrl.path)
            pickModel.isOrigin = true
            DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
            completion(pickModel)
            return
        }
        
        let bitRate = Int(videoTrack.estimatedDataRate)
        let maxVideoBitrate: Int = {
            switch transcodeQuality {
            case .low: return 1_000_000
            case .medium: return 3_000_000
            case .high: return 5_000_000
            }
        }()
        print("Video bitrate: \(bitRate) bps, max allowed: \(maxVideoBitrate) bps")
        
        let isMp4 = preTranscodeUrl.pathExtension.lowercased() == "mp4"
        let needsTranscode = (bitRate > maxVideoBitrate) || (!isMp4)
        
        if needsTranscode {
            DispatchQueue.main.async { self.onProgress?(pickModel, index, 0.3) }
            self.transcodeVideo(videoUrl: preTranscodeUrl, pickModel: pickModel, index: index, completion: completion)
        } else {
            pickModel.setMediaPath(preTranscodeUrl.path)
            pickModel.isOrigin = true
            DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
            completion(pickModel)
        }
    }
    
    internal func transcodeVideo(
        videoUrl: URL,
        pickModel: AlbumPickerModel,
        index: Int,
        completion: @escaping (AlbumPickerModel) -> Void
    ) {
        // Prefer using VideoEditor for transcoding; fallback to system transcoding if unavailable or failed
        func systemTranscode() {
            let asset = AVAsset(url: videoUrl)
            let outputPath = generateVideoOutputPath()
            let outputUrl = URL(fileURLWithPath: outputPath)
            let presetName: String = {
                switch transcodeQuality {
                case .low: return AVAssetExportPresetLowQuality
                case .medium: return AVAssetExportPresetMediumQuality
                case .high: return AVAssetExportPresetHighestQuality
                }
            }()
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
                print("Failed to create export session")
                pickModel.setMediaPath(videoUrl.path)
                DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                completion(pickModel)
                return
            }

            exportSession.outputURL = outputUrl
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true

            if FileManager.default.fileExists(atPath: outputPath) {
                try? FileManager.default.removeItem(atPath: outputPath)
            }

            let tickTarget = _AlbumExportTickTarget(
                session: exportSession,
                onProgress: { adjusted in
                    DispatchQueue.main.async { self.onProgress?(pickModel, index, adjusted) }
                },
                onFinish: { }
            )
            let progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: tickTarget, selector: #selector(_AlbumExportTickTarget.tick(_:)), userInfo: nil, repeats: true)

            tickTarget.onFinish = {
                DispatchQueue.main.async {
                    progressTimer.invalidate()
                    switch exportSession.status {
                    case .completed:
                        print("Video transcoding completed: \(outputPath)")
                        pickModel.setMediaPath(outputUrl.path)
                        pickModel.isOrigin = false
                        DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                        completion(pickModel)
                    case .failed:
                        print("Video transcoding failed: \(exportSession.error?.localizedDescription ?? "Unknown error"), using original video")
                        pickModel.setMediaPath(videoUrl.path)
                        pickModel.isOrigin = true
                        DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                        completion(pickModel)
                    case .cancelled:
                        print("Video transcoding cancelled, using original video")
                        pickModel.setMediaPath(videoUrl.path)
                        pickModel.isOrigin = true
                        DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                        completion(pickModel)
                    default:
                        print("Video transcoding status: \(exportSession.status.rawValue), using original video")
                        pickModel.setMediaPath(videoUrl.path)
                        pickModel.isOrigin = true
                        DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                        completion(pickModel)
                    }
                }
            }

            exportSession.exportAsynchronously {}
        }

        systemTranscode()
    }
    
    internal func generateInitialThumbnailForVideo(
        videoUrl: URL,
        pickModel: AlbumPickerModel,
        ready: @escaping () -> Void
    ) {
        let asset = AVAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        // Keep aspect ratio consistent with source video; cap max edge to ALBUM_PICKER_THUMBNAIL_MAX_EDGE
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let naturalSize = videoTrack.naturalSize
            let maxEdge = ALBUM_PICKER_THUMBNAIL_MAX_EDGE
            let maxDimension = max(naturalSize.width, naturalSize.height)
            let scale = maxDimension > 0 ? min(1.0, maxEdge / maxDimension) : 1.0
            let targetSize = CGSize(width: max(1, naturalSize.width * scale),
                                    height: max(1, naturalSize.height * scale))
            imageGenerator.maximumSize = targetSize
        } else {
            imageGenerator.maximumSize = CGSize(width: ALBUM_PICKER_THUMBNAIL_MAX_EDGE, height: ALBUM_PICKER_THUMBNAIL_MAX_EDGE)
        }
        print("Thumbnail size: \(imageGenerator.maximumSize)")
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
            DispatchQueue.main.async {
                if let cgImage = cgImage, result == .succeeded {
                    let thumbnail = UIImage(cgImage: cgImage)
                    
                    let thumbnailPath = self.generateThumbnailOutputPath()
                    let thumbnailUrl = URL(fileURLWithPath: thumbnailPath)
                    
                    if let imageData = thumbnail.jpegData(compressionQuality: 0.7) {
                        do {
                            try imageData.write(to: thumbnailUrl)
                            pickModel.videoThumbnailPath = thumbnailUrl.path
                            print("Thumbnail saved: \(thumbnailPath)")
                        } catch {
                            print("Failed to save thumbnail: \(error)")
                        }
                    }
                } else {
                    print("Failed to generate thumbnail: \(error?.localizedDescription ?? "Unknown error")")
                }
                
                ready()
            }
        }
    }
    
    internal func generateVideoOutputPath() -> String {
        let videoPath = generateMediaPath(messageType: .video, withExtension: "mp4")
        let directory = (videoPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        return videoPath
    }
    
    internal func generateThumbnailOutputPath() -> String {
        let thumbnailPath = generateMediaPath(messageType: .image, withExtension: nil)
        let directory = (thumbnailPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        return thumbnailPath
    }
    
    internal func processImageAssetWithProgress(
        _ assetModel: AlbumPickerAssetModel,
        asset: PHAsset,
        index: Int
    ) {
        let pickModel = AlbumPickerModel()
        
        DispatchQueue.main.async { self.onProgress?(pickModel, index, 0.0) }
        pickModel.isOrigin = isSelectOriginalPhoto
        if let editImage = assetModel.editImage {
            pickModel.isOrigin = isSelectOriginalPhoto
            pickModel.setMediaPath(saveImageToTempPath(editImage))
            pickModel.mediaType = .image
            DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
        } else {
            onProgress?(pickModel, index, 0.3)
            
            let targetWidth = isSelectOriginalPhoto ? CGFloat.greatestFiniteMagnitude : imageManager.photoPreviewMaxWidth
            imageManager.getPhoto(with: asset, photoWidth: targetWidth) { image, info, isDegraded in
                let shouldProcess = !isDegraded || (info?[PHImageResultIsDegradedKey] as? Bool == false)
                
                if shouldProcess {
                    guard let image = image else {
                        return
                    }
                    pickModel.setMediaPath(saveImageToTempPath(image))
                    pickModel.mediaType = .image
                    DispatchQueue.main.async { self.onProgress?(pickModel, index, 1.0) }
                }
            }
        }
    }
    
    fileprivate func saveImageToTempPath(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }

        let path = generateMediaPath(messageType: .image, withExtension: "jpg")
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)

        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
            return path
        } catch {
            print("ImagePickerView: failed to write image to path: \(path), error: \(error)")
            return nil
        }
    }
    
    // MARK: - Transcoding queue management methods
    internal func enqueueVideoProcessing(
        _ assetModel: AlbumPickerAssetModel,
        asset: PHAsset,
        index: Int) {
        transcodingManager.transcodingQueueLock.lock()
        defer { transcodingManager.transcodingQueueLock.unlock() }
        
        print("[Transcoding Queue] Add video processing task - Current: \(transcodingManager.currentTranscodingCount)/\(maxConcurrentTranscodingCount), Queue: \(transcodingManager.transcodingQueue.count)")
        
        if transcodingManager.currentTranscodingCount < maxConcurrentTranscodingCount {
            transcodingManager.currentTranscodingCount += 1
            print("[Transcoding Queue] Start processing video immediately - Current: \(transcodingManager.currentTranscodingCount)")
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.processVideoAssetWithProgress(assetModel, asset: asset, index: index) { result in
                    DispatchQueue.main.async {
                        self.onVideoProcessingCompleted()
                    }
                }
            }
        } else {
            transcodingManager.transcodingQueue.append((assetModel, asset, index))
            print("[Transcoding Queue] Video added to waiting queue - Queue length: \(transcodingManager.transcodingQueue.count)")
        }
    }
    
    internal func onVideoProcessingCompleted() {
        transcodingManager.transcodingQueueLock.lock()
        defer { transcodingManager.transcodingQueueLock.unlock() }
        
        transcodingManager.currentTranscodingCount = max(0, transcodingManager.currentTranscodingCount - 1)
        print("[Transcoding Queue] Video processing completed - Current: \(transcodingManager.currentTranscodingCount), Queue: \(transcodingManager.transcodingQueue.count)")
        
        if !transcodingManager.transcodingQueue.isEmpty && transcodingManager.currentTranscodingCount < maxConcurrentTranscodingCount {
            let (assetModel, asset, index) = transcodingManager.transcodingQueue.removeFirst()
            transcodingManager.currentTranscodingCount += 1
            
            print("[Transcoding Queue] Start processing queued video - Current: \(transcodingManager.currentTranscodingCount), Remaining queue: \(transcodingManager.transcodingQueue.count)")
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.processVideoAssetWithProgress(assetModel, asset: asset, index: index) { result in
                    DispatchQueue.main.async {
                        self.onVideoProcessingCompleted()
                    }
                }
            }
        }
    }
    
    internal func getHomePath() -> String {
        return NSHomeDirectory() + "/Documents/atomicx_core_data"
    }
        
    internal func getMediaHomePath(messageType: MessageType) -> String {
        if messageType == .image {
            return getHomePath() + "/image/"
        } else if messageType == .video {
            return getHomePath() + "/video/"
        }else {
            return ""
        }
    }
        
    internal func generateMediaPath(messageType: MessageType, withExtension: String?) -> String {
        let uuid = "\(Int(Date().timeIntervalSince1970))_\(arc4random() % UInt32.max)"
        var mediaExtension = ""
        if let withExtension = withExtension {
            mediaExtension = ".\(withExtension)"
        }
        if messageType == .image {
            return getMediaHomePath(messageType: .image) + "\(uuid)\(mediaExtension)"
        } else if messageType == .video {
            return getMediaHomePath(messageType: .video) + "\(uuid)\(mediaExtension)"
        }
        return ""
    }
}
