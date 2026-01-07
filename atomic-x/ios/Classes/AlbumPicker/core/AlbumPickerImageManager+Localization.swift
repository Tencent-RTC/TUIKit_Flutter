//
//  AlbumPickerImageManager+Localization.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import Foundation
import Photos

@inline(__always)
public func LocalizedAlbumPickerString(_ key: String) -> String {
    let currentLanguage = LanguageHelper.getCurrentLanguage()
    let result = LanguageHelper.getLocalizedString(forKey: key, bundle: "AlbumPickerLocalizable", classType: LanguageHelper.self, frameworkName: "AtomicXBundle")
    
    // 如果标准方法失败，尝试备用方法
    if result == key {
        let pluginBundle = Bundle(for: AlbumPickerImageManager.self)
        if let bundlePath = pluginBundle.path(forResource: "AlbumPickerLocalizable", ofType: "bundle"),
           let resourceBundle = Bundle(path: bundlePath),
           let lprojPath = resourceBundle.path(forResource: "Localizable/\(currentLanguage)", ofType: "lproj"),
           let lprojBundle = Bundle(path: lprojPath) {
            return lprojBundle.localizedString(forKey: key, value: key, table: nil)
        }
    }
    
    return result
}

extension AlbumPickerImageManager {
    
    func getLocalizedAlbumName(for collection: PHAssetCollection) -> String {
        
        print("assetCollectionSubtype = \(collection.assetCollectionSubtype)")
        
        // Handle specific Photos subtype raw value introduced/changed in certain iOS versions
        let kPHAssetCollectionSubtypeRecentlyAddedRawValue = 1000000218
        if collection.assetCollectionSubtype.rawValue == kPHAssetCollectionSubtypeRecentlyAddedRawValue {
            return LocalizedAlbumPickerString("recently_added")
        }
        
        switch collection.assetCollectionSubtype {
        case .smartAlbumUserLibrary:
            return LocalizedAlbumPickerString("user_library")
        case .smartAlbumRecentlyAdded:
            return LocalizedAlbumPickerString("recently_added")
        case .smartAlbumFavorites:
            return LocalizedAlbumPickerString("favorites")
        case .smartAlbumSelfPortraits:
            return LocalizedAlbumPickerString("self_portraits")
        case .smartAlbumScreenshots:
            return LocalizedAlbumPickerString("screenshots")
        case .smartAlbumPanoramas:
            return LocalizedAlbumPickerString("panoramas")
        case .smartAlbumVideos:
            return LocalizedAlbumPickerString("videos")
        case .smartAlbumSlomoVideos:
            return LocalizedAlbumPickerString("slomo_videos")
        case .smartAlbumTimelapses:
            return LocalizedAlbumPickerString("timelapses")
        case .smartAlbumBursts:
            return LocalizedAlbumPickerString("bursts")
        case .smartAlbumLivePhotos:
            return LocalizedAlbumPickerString("live_photos")
        case .smartAlbumDepthEffect:
            return LocalizedAlbumPickerString("depth_effect")
        case .albumCloudShared:
            return LocalizedAlbumPickerString("cloud_shared")
        default:
            if let localizedTitle = collection.localizedTitle {
                return localizedTitle
            }
            return collection.localizedTitle ?? LocalizedAlbumPickerString("unknown_album")
        }
    }
}
