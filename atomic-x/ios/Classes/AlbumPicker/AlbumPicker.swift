//
//  AlbumPickerView.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import SwiftUI
import Photos
import Combine
import AVFoundation
import UIKit

public enum AlbumMode {
    case images
    case videos
    case all
}

public enum AlbumTranscodeQuality: String {
    case low
    case medium
    case high
}

public enum PickMediaType {
    case image
    case video
    case gif
}

public class AlbumPickerModel: NSObject {
    public var id: Int = 0
    public var mediaPath: String? = nil
    public var mediaType: PickMediaType = .video
    public var videoThumbnailPath: String? = nil
    public var isOrigin: Bool = false
    
    public override init() {
        super.init()
        id = AlbumPickerModel.generateUniqueId(mediaPath: nil)
    }
}

public struct AlbumPickerConfig {
    public var maxImagesCount: Int
    public var columnNumber: Int
    public var showEditButton: Bool
    public var showOriginalToggle: Bool
    public var albumMode: AlbumMode
    public var primary: String?
    public var maxConcurrentTranscodingCount: Int
    public var transcodeQuality: AlbumTranscodeQuality
    
    public init(maxImagesCount: Int = 9,
                columnNumber: Int = 4,
                showEditButton: Bool = false,
                showOriginalToggle: Bool = false,
                albumMode: AlbumMode = .all,
                primary: String? = nil,
                maxConcurrentTranscodingCount: Int = 3,
                transcodeQuality: AlbumTranscodeQuality = .medium) {
        self.maxImagesCount = maxImagesCount
        self.columnNumber = columnNumber
        self.showEditButton = showEditButton
        self.showOriginalToggle = showOriginalToggle
        self.albumMode = albumMode
        self.primary = primary
        self.maxConcurrentTranscodingCount = maxConcurrentTranscodingCount
        self.transcodeQuality = transcodeQuality
    }
}

public struct AlbumPicker: View {
    @StateObject internal var imageManager = AlbumPickerImageManager.shared
    @StateObject internal var albumModel = AlbumPickerAlbumModel()
    @StateObject internal var previewState = PreviewState()
    @StateObject internal var transcodingManager = AlbumPickerTranscodingManager.shared
    @State internal var selectedAssets: [AlbumPickerAssetModel] = []
    @State internal var isSelectOriginalPhoto = false
    @State internal var showingAlbums = false
    @State internal var albums: [AlbumPickerAlbumModel] = []
    @State internal var isLoading = false
    @State internal var gridRefreshTrigger = UUID()
    @State internal var dragOffset: CGFloat = 0
    @State internal var isDragging = false
    
    let maxImagesCount: Int
    let columnNumber: Int
    let showEditButton: Bool
    let showOriginalToggle: Bool
    let onFinishedSelect: (Int) -> Void
    let onProgress: ((AlbumPickerModel, Int, Double) -> Void)?
    let albumMode: AlbumMode
    let primaryColor: Color
    let maxConcurrentTranscodingCount: Int

    let transcodeQuality: AlbumTranscodeQuality
    
    internal let itemSpacing: CGFloat = 5
    
    public init(config: AlbumPickerConfig,
                onFinishedSelect: @escaping (Int) -> Void,
                onProgress: ((AlbumPickerModel, Int, Double) -> Void)? = nil) {
        self.maxImagesCount = config.maxImagesCount
        self.columnNumber = config.columnNumber
        self.showEditButton = config.showEditButton
        self.showOriginalToggle = config.showOriginalToggle
        self.onFinishedSelect = onFinishedSelect
        self.onProgress = onProgress
        self.albumMode = config.albumMode
        self.primaryColor = Color(hexString: config.primary ?? "#147AFF")
        self.maxConcurrentTranscodingCount = config.maxConcurrentTranscodingCount
        self.transcodeQuality = config.transcodeQuality
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                RTLVStack(spacing: 0) {
                    photoGridView
                    bottomToolbar
                }
                
                if showingAlbums {
                    albumSelectionOverlay
                }
                
                RTLHStack {
                    if AlbumPickerRTLHelper.isRTL {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 2)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 2)
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: AlbumPickerRTLHelper.isRTL ? .navigationBarTrailing : .navigationBarLeading) {
                    Button(LocalizedAlbumPickerString("cancel")) {
                        DispatchQueue.main.async { onFinishedSelect(0) }
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    albumTitleView
                }
            }
            .background(NavigationBarConfigurator { nav in
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 34/255.0, green: 34/255.0, blue: 34/255.0, alpha: 1.0)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

                nav.navigationBar.standardAppearance = appearance
                nav.navigationBar.scrollEdgeAppearance = appearance
                nav.navigationBar.tintColor = .white
            })
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let isRTL = AlbumPickerRTLHelper.isRTL
                        let screenWidth = UIScreen.main.bounds.width
                        let edgeThreshold: CGFloat = 50
                        
                        if isRTL {
                            if value.startLocation.x > screenWidth - edgeThreshold && value.translation.width < 0 {
                                isDragging = true
                                dragOffset = max(value.translation.width * 0.3, -100)
                            }
                        } else {
                            if value.startLocation.x < edgeThreshold && value.translation.width > 0 {
                                isDragging = true
                                dragOffset = min(value.translation.width * 0.3, 100)
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        let isRTL = AlbumPickerRTLHelper.isRTL
                        let screenWidth = UIScreen.main.bounds.width
                        let edgeThreshold: CGFloat = 50
                        let swipeThreshold: CGFloat = 100
                        
                        if isRTL {
                            if value.startLocation.x > screenWidth - edgeThreshold && value.translation.width < -swipeThreshold {
                                DispatchQueue.main.async { onFinishedSelect(0) }
                            }
                        } else {
                            if value.startLocation.x < edgeThreshold && value.translation.width > swipeThreshold {
                                DispatchQueue.main.async { onFinishedSelect(0) }
                            }
                        }
                        
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .rtlLayout()
        .fullScreenCover(isPresented: $previewState.showing) {
            let (previewAssets, startIndex): ([AlbumPickerAssetModel], Int) = {
                if previewState.fromGrid {
                    let index = max(0, min(previewState.index, albumModel.assetModels.count - 1))
                    return (albumModel.assetModels, index)
                } else {
                    return (selectedAssets, 0)
                }
            }()
            
            AlbumPickerPreviewView(
                showEditButton: false,
                showOriginalToggle: showOriginalToggle,
                assetModels: previewAssets,
                currentIndex: startIndex,
                selectedAssets: $selectedAssets,
                isSelectOriginalPhoto: $isSelectOriginalPhoto,
                maxImagesCount: maxImagesCount,
                isPreviewingSelectedOnly: !previewState.fromGrid,
                themeColor: primaryColor,
                onDone: {
                    handleDoneButtonTap()
                },
                onBack: {
                    previewState.hidePreview()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        gridRefreshTrigger = UUID()
                    }
                }
            )
        }
        .onAppear {
            loadCameraRoll()
        }
    }
}

// MARK: - AlbumPickerModel ID Generation Extension
extension AlbumPickerModel {
    public func setMediaPath(_ path: String?) {
        mediaPath = path
        id = Self.generateUniqueId(mediaPath: mediaPath)
    }
    
    internal static func generateUniqueId(mediaPath: String?) -> Int {
        let time = DispatchTime.now().uptimeNanoseconds
        var hasher = Hasher()
        hasher.combine(mediaPath ?? "")
        hasher.combine(time)
        return hasher.finalize()
    }
}
