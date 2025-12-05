//
//  AlbumPickerImageManager.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import CoreLocation

class AlbumPickerImageManager: NSObject, ObservableObject {
    static let shared = AlbumPickerImageManager()
    
    @Published var cachingImageManager: PHCachingImageManager
    @Published var shouldFixOrientation: Bool = false
    @Published var isPreviewNetworkImage: Bool = false
    @Published var photoPreviewMaxWidth: CGFloat = 600
    @Published var columnNumber: Int = 4 {
        didSet {
            configScreenWidth()
        }
    }
    
    private var screenWidth: CGFloat = 0
    private var screenScale: CGFloat = 2.0
    private var assetGridThumbnailSize: CGSize = .zero
    
    override init() {
        self.cachingImageManager = PHCachingImageManager()
        super.init()
        configScreenWidth()
    }
    
    private func configScreenWidth() {
        screenWidth = UIScreen.main.bounds.size.width
        screenScale = screenWidth > 700 ? 1.5 : 2.0
        
        let margin: CGFloat = 4
        let itemWH = (screenWidth - 2 * margin - 4) / CGFloat(columnNumber) - margin
        assetGridThumbnailSize = CGSize(width: itemWH * screenScale, height: itemWH * screenScale)
    }
    
    func authorizationStatusAuthorized() -> Bool {
        if isPreviewNetworkImage {
            return true
        }
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            requestAuthorization(completion: nil)
        }
        return status == .authorized
    }
    
    func requestAuthorization(completion: (() -> Void)?) {
        DispatchQueue.global(qos: .default).async {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    func isPHAuthorizationStatusLimited() -> Bool {
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return status == .limited
        }
        return false
    }
    
    func getCameraRollAlbum(needFetchAssets: Bool, filter: AlbumMode, completion: @escaping (AlbumPickerAlbumModel?) -> Void) {
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        
        smartAlbums.enumerateObjects { collection, _, stop in
            if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                let model = AlbumPickerAlbumModel()
                model.name = self.getLocalizedAlbumName(for: collection)
                model.collection = collection
                model.isCameraRoll = true
                
                let options = PHFetchOptions()
                switch filter {
                case .images:
                    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                case .videos:
                    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
                case .all:
                    options.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
                }
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                let result = PHAsset.fetchAssets(in: collection, options: options)
                model.photoCount = result.count
                model.result = result
                model.options = options
                
                if needFetchAssets {
                    model.setResult(result, needFetchAssets: true)
                }
                
                completion(model)
                stop.pointee = true
            }
        }
    }
    
    func getAllAlbums(needFetchAssets: Bool, filter: AlbumMode, completion: @escaping ([AlbumPickerAlbumModel]) -> Void) {
        var albumModels: [AlbumPickerAlbumModel] = []
        
        getCameraRollAlbum(needFetchAssets: needFetchAssets, filter: filter) { cameraRollModel in
            if let model = cameraRollModel {
                albumModels.append(model)
            }
            
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            
            let processAlbums = { (collections: PHFetchResult<PHAssetCollection>) in
                collections.enumerateObjects { collection, _, _ in
                    if collection.assetCollectionSubtype != .smartAlbumUserLibrary {
                        let options = PHFetchOptions()
                        switch filter {
                        case .images:
                            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                        case .videos:
                            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
                        case .all:
                            options.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
                        }
                        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                        
                        let result = PHAsset.fetchAssets(in: collection, options: options)
                        if result.count > 0 {
                            let model = AlbumPickerAlbumModel()
                            model.name = self.getLocalizedAlbumName(for: collection)
                            model.collection = collection
                            model.photoCount = result.count
                            model.result = result
                            model.options = options
                            
                            if needFetchAssets {
                                model.setResult(result, needFetchAssets: true)
                            }
                            
                            albumModels.append(model)
                        }
                    }
                }
            }
            
            processAlbums(userAlbums)
            processAlbums(smartAlbums)
            
            albumModels.sort { $0.photoCount > $1.photoCount }
            
            completion(albumModels)
        }
    }
    
    func getAssets(from result: PHFetchResult<PHAsset>, completion: @escaping ([AlbumPickerAssetModel]) -> Void) {
        DispatchQueue.global(qos: .default).async {
            var models: [AlbumPickerAssetModel] = []
            
            result.enumerateObjects { asset, _, _ in
                let type = self.getAssetMediaType(asset)
                let model = AlbumPickerAssetModel.model(with: asset, type: type)
                
                if type == .video {
                    model.timeLength = self.getNewTimeFromDurationSecond(Int(asset.duration))
                }
                
                models.append(model)
            }
            
            DispatchQueue.main.async {
                completion(models)
            }
        }
    }
    
    @discardableResult
    func getPhoto(with asset: PHAsset, completion: @escaping (UIImage?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        return getPhoto(with: asset, photoWidth: photoPreviewMaxWidth, completion: completion)
    }
    
    @discardableResult
    func getPhoto(with asset: PHAsset, photoWidth: CGFloat, completion: @escaping (UIImage?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        let targetSize: CGSize
        if photoWidth == CGFloat.greatestFiniteMagnitude {
            targetSize = PHImageManagerMaximumSize
        } else {
            targetSize = CGSize(width: photoWidth, height: photoWidth)
        }
        
        return cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            completion(image, info, isDegraded)
        }
    }
    
    @discardableResult
    func getPhoto(with asset: PHAsset, photoWidth: CGFloat, completion: @escaping (UIImage?, [AnyHashable: Any]?, Bool) -> Void, progressHandler: @escaping (Double, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void, networkAccessAllowed: Bool) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = networkAccessAllowed
        options.deliveryMode = .opportunistic
        options.progressHandler = progressHandler
        
        let targetSize: CGSize
        if photoWidth == CGFloat.greatestFiniteMagnitude {
            targetSize = PHImageManagerMaximumSize
        } else {
            targetSize = CGSize(width: photoWidth, height: photoWidth)
        }
        
        return cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            completion(image, info, isDegraded)
        }
    }
    
    @discardableResult
    func getCoverImage(with albumModel: AlbumPickerAlbumModel, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        guard let result = albumModel.result, result.count > 0 else {
            completion(nil)
            return PHInvalidImageRequestID
        }
        
        let asset = result.object(at: 0)
        return getPhoto(with: asset, photoWidth: 80) { image, _, _ in
            completion(image)
        }
    }
    
    @discardableResult
    func getOriginalPhotoData(with asset: PHAsset, progressHandler: @escaping (Double, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void, completion: @escaping (Data?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.progressHandler = progressHandler
        
        return cachingImageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            completion(data, info, isDegraded)
        }
    }
    
    func getVideo(with asset: PHAsset, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        cachingImageManager.requestPlayerItem(forVideo: asset, options: options) { playerItem, info in
            DispatchQueue.main.async {
                completion(playerItem, info)
            }
        }
    }
    
    func getVideo(with asset: PHAsset, progressHandler: @escaping (Double, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        options.progressHandler = progressHandler
        
        cachingImageManager.requestPlayerItem(forVideo: asset, options: options) { playerItem, info in
            DispatchQueue.main.async {
                completion(playerItem, info)
            }
        }
    }
    
    func requestVideoURL(with asset: PHAsset, success: @escaping (URL) -> Void, failure: @escaping ([AnyHashable: Any]?) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .original
        options.isNetworkAccessAllowed = true
        
        cachingImageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
            DispatchQueue.main.async {
                if let urlAsset = avAsset as? AVURLAsset {
                    success(urlAsset.url)
                } else {
                    failure(info)
                }
            }
        }
    }
    
    func getAssetBytes(_ asset: PHAsset, completion: @escaping (Int) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        
        if asset.mediaType == .image {
            cachingImageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                DispatchQueue.main.async {
                    completion(data?.count ?? 0)
                }
            }
        } else if asset.mediaType == .video {
            let videoOptions = PHVideoRequestOptions()
            videoOptions.isNetworkAccessAllowed = false
            
            cachingImageManager.requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, _, _ in
                DispatchQueue.main.async {
                    if let urlAsset = avAsset as? AVURLAsset {
                        do {
                            let resourceValues = try urlAsset.url.resourceValues(forKeys: [.fileSizeKey])
                            completion(resourceValues.fileSize ?? 0)
                        } catch {
                            completion(0)
                        }
                    } else {
                        completion(0)
                    }
                }
            }
        }
    }
    
    func getPhotosTotalBytes(_ photos: [AlbumPickerAssetModel], completion: @escaping (String) -> Void) {
        let group = DispatchGroup()
        var totalBytes = 0
        
        for model in photos {
            guard let asset = model.asset else { continue }
            group.enter()
            
            getAssetBytes(asset) { bytes in
                totalBytes += bytes
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let sizeString = formatter.string(fromByteCount: Int64(totalBytes))
            completion(sizeString)
        }
    }
    
    func getAssetMediaType(_ asset: PHAsset) -> AlbumPickerMediaType {
        switch asset.mediaType {
        case .image:
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            } else {
                return .photo
            }
        case .video:
            return .video
        case .audio:
            return .audio
        default:
            return .photo
        }
    }
    
    func isVideo(_ asset: PHAsset) -> Bool {
        return asset.mediaType == .video
    }
    
    func getNewTimeFromDurationSecond(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func createModel(with asset: PHAsset) -> AlbumPickerAssetModel {
        let type = getAssetMediaType(asset)
        return AlbumPickerAssetModel.model(with: asset, type: type)
    }
    
    func isCameraRollAlbum(_ collection: PHAssetCollection) -> Bool {
        return collection.assetCollectionSubtype == .smartAlbumUserLibrary
    }
    
    func fixOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    func savePhoto(with image: UIImage, meta: [AnyHashable: Any]?, location: CLLocation?, completion: @escaping (PHAsset?, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.location = location
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(nil, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
    
    func saveVideo(with url: URL, location: CLLocation?, completion: @escaping (PHAsset?, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            request?.location = location
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(nil, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
}
