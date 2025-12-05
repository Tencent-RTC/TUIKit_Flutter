//
//  AlbumPickerPreviewView.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import SwiftUI
import Photos
import AVFoundation

struct AlbumPickerPreviewView: View {
    let showEditButton: Bool
    let showOriginalToggle: Bool
    let assetModels: [AlbumPickerAssetModel]
    @State private var currentIndex: Int
    @Binding var selectedAssets: [AlbumPickerAssetModel]
    @Binding var isSelectOriginalPhoto: Bool
    
    let maxImagesCount: Int
    let isPreviewingSelectedOnly: Bool
    let themeColor: Color
    let onDone: () -> Void
    let onBack: () -> Void
    
    init(
         showEditButton: Bool,
         showOriginalToggle: Bool,
         assetModels: [AlbumPickerAssetModel], 
         currentIndex: Int,
         selectedAssets: Binding<[AlbumPickerAssetModel]>,
         isSelectOriginalPhoto: Binding<Bool>,
         maxImagesCount: Int,
         isPreviewingSelectedOnly: Bool = false,
         themeColor: Color,
         onDone: @escaping () -> Void,
         onBack: @escaping () -> Void) {
        self.showEditButton = showEditButton
        self.showOriginalToggle = showOriginalToggle
        self.assetModels = assetModels
        self._currentIndex = State(initialValue: currentIndex)
        self._selectedAssets = selectedAssets
        self._isSelectOriginalPhoto = isSelectOriginalPhoto
        self.maxImagesCount = maxImagesCount
        self.isPreviewingSelectedOnly = isPreviewingSelectedOnly
        self.themeColor = themeColor
        self.onDone = onDone
        self.onBack = onBack
    }
    
    @State private var showingToolbar = true
    @State private var isZoomed = false
    @State private var showingVideoEditor = false
    @State private var videoSourceURL: URL?
    @State private var imageSourceForEdit: UIImage?
    @State private var refreshTrigger = UUID()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var currentSelectedIndex: Int {
        guard let currentAsset = currentAsset,
              let asset = currentAsset.asset else { return -1 }
        
        return selectedAssets.firstIndex { selectedAsset in
            selectedAsset.asset?.localIdentifier == asset.localIdentifier
        } ?? -1
    }
    
    var currentAsset: AlbumPickerAssetModel? {
        guard currentIndex >= 0 && currentIndex < assetModels.count else { return nil }
        return assetModels[currentIndex]
    }
    
    var isCurrentAssetSelected: Bool {
        return currentSelectedIndex >= 0
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RTLVStack(spacing: 0) {
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(assetModels.enumerated()), id: \.offset) { index, assetModel in
                            EnhancedAlbumPickerMediaView(
                                assetModel: assetModel,
                                isZoomed: $isZoomed,
                                showingToolbar: $showingToolbar,
                                refreshTrigger: refreshTrigger
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _ in
                        // Reset zoom state when switching media to avoid stutter
                        isZoomed = false
                    }
                }
                
                if !selectedAssets.isEmpty && showingToolbar && !isZoomed {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        AlbumPickerThumbnailScrollView(
                            selectedAssets: selectedAssets,
                            currentIndex: .constant(currentSelectedIndex),
                            refreshTrigger: refreshTrigger,
                            themeColor: themeColor,
                            onThumbnailTap: { thumbnailIndex in
                                if thumbnailIndex < selectedAssets.count {
                                    let selectedAsset = selectedAssets[thumbnailIndex]
                                    if let targetIndex = assetModels.firstIndex(where: { model in
                                        model.asset?.localIdentifier == selectedAsset.asset?.localIdentifier
                                    }) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentIndex = targetIndex
                                        }
                                    }
                                }
                            }
                        )
                        .background(Color.black.opacity(0.9))
                    }
                    .transition(.move(edge: .bottom))
                }
                
                if showingToolbar && !isZoomed {
                    bottomToolbar
                        .transition(.move(edge: .bottom))
                }
            }
            
            if showingToolbar && !isZoomed {
                VStack {
                    topToolbar
                        .transition(.move(edge: .top))
                    Spacer()
                }
            }
            
            if showingToolbar && !isZoomed {
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 2)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(!showingToolbar)
        .animation(.easeInOut(duration: 0.3), value: showingToolbar)
        .animation(.easeInOut(duration: 0.3), value: isZoomed)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isZoomed {
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
                }
                .onEnded { value in
                    isDragging = false
                    if !isZoomed {
                        let isRTL = AlbumPickerRTLHelper.isRTL
                        let screenWidth = UIScreen.main.bounds.width
                        let edgeThreshold: CGFloat = 50
                        let swipeThreshold: CGFloat = 100
                        
                        if isRTL {
                            if value.startLocation.x > screenWidth - edgeThreshold && value.translation.width < -swipeThreshold {
                                onBack()
                            }
                        } else {
                            if value.startLocation.x < edgeThreshold && value.translation.width > swipeThreshold {
                                onBack()
                            }
                        }
                    }
                    
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
        .rtlLayout()
        .fullScreenCover(isPresented: $showingVideoEditor) {
            videoEditorOverlay
        }
    }
    
    private var videoEditorOverlay: AnyView {
        return AnyView(EmptyView())
    }
    
    private var topToolbar: some View {
        RTLHStack {
            Button(LocalizedAlbumPickerString("back")) {
                onBack()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("\(currentIndex + 1) / \(assetModels.count)")
                .foregroundColor(.white)
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                toggleCurrentAssetSelection()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(Circle().fill(isCurrentAssetSelected ? themeColor : Color.clear))
                        .frame(width: 22, height: 22)
                    
                    if isCurrentAssetSelected {
                        Text("\(currentSelectedIndex + 1)")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 44)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var bottomToolbar: some View {
        RTLVStack(spacing: 0) {
            if !selectedAssets.isEmpty {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            RTLHStack {
                if showEditButton {
                    Button(LocalizedAlbumPickerString("edit")) {
                        handleEditButtonTap()
                    }
                    .foregroundColor(.white)
                } else {
                    Spacer()
                        .frame(maxWidth: 50)
                }
                
                Spacer()

                if showOriginalToggle {
                    Button(action: {
                        if !selectedAssets.isEmpty {
                            isSelectOriginalPhoto.toggle()
                        }
                    }) {
                        RTLHStack(spacing: 8) {
                            Image(systemName: isSelectOriginalPhoto ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedAssets.isEmpty ? .gray : (isSelectOriginalPhoto ? themeColor : .gray))
                            Text(LocalizedAlbumPickerString("original"))
                                .foregroundColor(selectedAssets.isEmpty ? .gray : .white)
                        }
                    }
                    .disabled(selectedAssets.isEmpty)
                }
                
                Spacer()
                
                RTLHStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(selectedAssets.isEmpty ? Color.clear : themeColor)
                            .frame(width: 22, height: 22)
                        
                        if !selectedAssets.isEmpty {
                            Text("\(selectedAssets.count)")
                                .foregroundColor(.white)
                                .font(.system(size: 15))
                        }
                    }
                    .frame(width: 22, height: 22)
                    
                    Button(LocalizedAlbumPickerString("done")) {
                        onDone()
                    }
                    .foregroundColor(selectedAssets.isEmpty ? .gray : themeColor)
                    .disabled(selectedAssets.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func toggleCurrentAssetSelection() {
        guard let currentAsset = currentAsset else { return }
        
        if isPreviewingSelectedOnly {
            if let existingIndex = selectedAssets.firstIndex(where: { $0.asset?.localIdentifier == currentAsset.asset?.localIdentifier }) {
                selectedAssets.remove(at: existingIndex)
                currentAsset.isSelected = false
                
                if selectedAssets.isEmpty {
                    onBack()
                    return
                }
                
                if currentIndex >= selectedAssets.count {
                    currentIndex = selectedAssets.count - 1
                }
            }
        } else {
            if let existingIndex = selectedAssets.firstIndex(where: { $0.asset?.localIdentifier == currentAsset.asset?.localIdentifier }) {
                selectedAssets.remove(at: existingIndex)
                currentAsset.isSelected = false
            } else if selectedAssets.count < maxImagesCount {
                selectedAssets.append(currentAsset)
                currentAsset.isSelected = true
            }
        }
    }
    
    private func handleEditButtonTap() {
        guard let currentAsset = currentAsset,
              let asset = currentAsset.asset else { return }
        
        // Stop video playback before entering editor
        if currentAsset.type == .video {
            NotificationCenter.default.post(name: .albumPickerShouldPauseVideo, object: nil)
        }
        
        self.showingVideoEditor = true
    }
    
    private func getVideoURL(from asset: PHAsset, completion: @escaping (URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                completion(urlAsset.url)
            } else {
                completion(nil)
            }
        }
    }
    
    private func getImageForEdit(from asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    private func forceRefreshUI() {
        refreshTrigger = UUID()
    }
    
    private func generateThumbnailForEditedVideo(url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } catch {
                print("Generate video thumbnail failed: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

struct EnhancedAlbumPickerMediaView: View {
    let assetModel: AlbumPickerAssetModel
    @Binding var isZoomed: Bool
    @Binding var showingToolbar: Bool
    let refreshTrigger: UUID
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black
            
            if isLoading {
                ProgressView(LocalizedAlbumPickerString("loading"))
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            } else if assetModel.type == .video {
                if let editVideoUrl = assetModel.editVideoUrl {
                    AlbumPickerVideoPlayerView(videoURL: editVideoUrl)
                        .id("edited-video-\(editVideoUrl.absoluteString)")
                        .onTapGesture {
                            withAnimation {
                                showingToolbar.toggle()
                            }
                        }
                } else if let asset = assetModel.asset {
                    AlbumPickerVideoPlayerView(asset: asset)
                        .id("original-video-\(asset.localIdentifier)-\(refreshTrigger.uuidString)")
                        .onTapGesture {
                            withAnimation {
                                showingToolbar.toggle()
                            }
                        }
                }
            } else if let image = image {
                AlbumPickerZoomableImageView(image: image, isZoomed: $isZoomed)
                    .onTapGesture {
                        withAnimation {
                            showingToolbar.toggle()
                        }
                    }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(LocalizedAlbumPickerString("load_failed"))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            loadMedia()
        }
        .onReceive(assetModel.$editImage) { _ in
            if assetModel.type != .video {
                loadMedia()
            }
        }
        .onReceive(assetModel.$editVideoUrl) { _ in
            if assetModel.type == .video {
                loadMedia()
            }
        }
        .onChange(of: refreshTrigger) { _ in
            if assetModel.type != .video {
                image = nil
                isLoading = true
                loadMedia()
            }
        }
    }
    
    private func loadMedia() {
        guard let asset = assetModel.asset else { return }
        
        isZoomed = false
        
        if assetModel.type == .video {
            isLoading = false
        } else {
            loadHighQualityImage(asset: asset)
        }
    }
    
    private func loadHighQualityImage(asset: PHAsset) {
        if let editImage = assetModel.editImage {
            DispatchQueue.main.async {
                self.image = editImage
                self.isLoading = false
            }
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: screenSize.width * scale * 0.3,
            height: screenSize.height * scale * 0.3
        )
        
        AlbumPickerImageManager.shared.cachingImageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            DispatchQueue.main.async {
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isDegraded, let image = image {
                    self.image = image
                    self.isLoading = false
                } else if isDegraded {
                    if self.image == nil, let image = image {
                        self.image = image
                    }
                }
            }
        }
    }
}

struct AlbumPickerThumbnailScrollView: View {
    let selectedAssets: [AlbumPickerAssetModel]
    @Binding var currentIndex: Int
    let refreshTrigger: UUID
    let themeColor: Color
    let onThumbnailTap: (Int) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                RTLHStack(spacing: 8) {
                    ForEach(Array(selectedAssets.enumerated()), id: \.offset) { index, assetModel in
                        AlbumPickerThumbnailItemView(
                            assetModel: assetModel,
                            isCurrent: index == currentIndex,
                            refreshTrigger: refreshTrigger,
                            themeColor: themeColor,
                            onTap: {
                                onThumbnailTap(index)
                            }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(height: 80)
            .onChange(of: currentIndex) { newIndex in
                if newIndex >= 0 && newIndex < selectedAssets.count {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .onAppear {
                if currentIndex >= 0 && currentIndex < selectedAssets.count {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
}

struct AlbumPickerThumbnailItemView: View {
    let assetModel: AlbumPickerAssetModel
    let isCurrent: Bool
    let refreshTrigger: UUID
    let themeColor: Color
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                }
                
                if assetModel.type == .video {
                    VStack {
                        Spacer()
                        HStack {
//                            Image(systemName: "play.fill")
//                                .foregroundColor(.white)
//                                .font(.caption2)
                            //Spacer()
                            if let timeLength = assetModel.timeLength {
                                Text(timeLength)
                                    .foregroundColor(.white)
                                    .font(.caption)

                            }
                            Spacer()
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.0))
                    }
                }
                
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(themeColor, lineWidth: 2)
                        .frame(width: 60, height: 60)
                }
            }
        }
        .cornerRadius(8)
        .onAppear {
            loadThumbnail()
        }
        .onReceive(assetModel.$editImage) { _ in
            loadThumbnail()
        }
        .onChange(of: refreshTrigger) { _ in
            thumbnailImage = nil
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        if let editImage = assetModel.editImage {
            DispatchQueue.main.async {
                self.thumbnailImage = editImage
            }
            return
        }
        
        guard let asset = assetModel.asset else { return }
        
        AlbumPickerImageManager.shared.getPhoto(with: asset, photoWidth: 120) { image, _, _ in
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }
}
