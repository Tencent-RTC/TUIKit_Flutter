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
    return LanguageHelper.getLocalizedString(forKey: key, bundle: "AlbumPickerLocalizable", classType: LanguageHelper.self, frameworkName: "tuikit_atomic_x")
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
