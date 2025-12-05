//
//  AlbumPickerAsset.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import Foundation
import UIKit
import Photos

enum AlbumPickerMediaType: UInt {
    case photo = 0
    case livePhoto
    case photoGif
    case video
    case audio
}

class AlbumPickerAssetModel: NSObject, ObservableObject {
    @Published var asset: PHAsset?
    @Published var selectImage: UIImage?
    @Published var isSelected: Bool = false
    @Published var type: AlbumPickerMediaType = .photo
    @Published var timeLength: String?
    @Published var iCloudFailed: Bool = false
    
    @Published var editAsset: PHAsset?
    @Published var editImage: UIImage?
    @Published var editVideoUrl: URL?
    
    static func model(with asset: PHAsset, type: AlbumPickerMediaType) -> AlbumPickerAssetModel {
        let model = AlbumPickerAssetModel()
        model.asset = asset
        model.isSelected = false
        model.type = type
        return model
    }
    
    static func model(with asset: PHAsset, type: AlbumPickerMediaType, timeLength: String) -> AlbumPickerAssetModel {
        let model = self.model(with: asset, type: type)
        model.timeLength = timeLength
        return model
    }
}

class AlbumPickerAlbumModel: NSObject, ObservableObject {
    @Published var name: String = ""
    @Published var photoCount: Int = 0
    @Published var result: PHFetchResult<PHAsset>?
    @Published var collection: PHAssetCollection?
    @Published var options: PHFetchOptions?
    
    @Published var assetModels: [AlbumPickerAssetModel] = []
    @Published var selectedModels: [AlbumPickerAssetModel] = []
    @Published var selectedCount: Int = 0
    
    @Published var isCameraRoll: Bool = false
    @Published var isSelected: Bool = false
    
    func setResult(_ result: PHFetchResult<PHAsset>, needFetchAssets: Bool = true) {
        self.result = result
        if needFetchAssets {
            AlbumPickerImageManager.shared.getAssets(from: result) { [weak self] models in
                DispatchQueue.main.async {
                    self?.assetModels = models
                    if let selectedModels = self?.selectedModels, !selectedModels.isEmpty {
                        self?.checkSelectedModels()
                    }
                }
            }
        }
    }
    
    func refreshFetchResult() {
        guard let collection = collection, let options = options else { return }
        let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        self.photoCount = fetchResult.count
        setResult(fetchResult)
    }
    
    func setSelectedModels(_ selectedModels: [AlbumPickerAssetModel]) {
        self.selectedModels = selectedModels
        if !assetModels.isEmpty {
            checkSelectedModels()
        }
    }
    
    private func checkSelectedModels() {
        selectedCount = 0
        let selectedAssets = Set(selectedModels.compactMap { $0.asset })
        
        for model in assetModels {
            if let asset = model.asset, selectedAssets.contains(asset) {
                selectedCount += 1
            }
        }
    }
}
