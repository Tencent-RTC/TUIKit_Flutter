//
//  AlbumPickerImp.swift
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

// MARK: - Helper Classes
internal final class _AlbumExportTickTarget: NSObject {
    weak var session: AVAssetExportSession?
    var onProgress: ((Double) -> Void)?
    var onFinish: (() -> Void)?

    init(session: AVAssetExportSession, onProgress: ((Double) -> Void)?, onFinish: (() -> Void)?) {
        self.session = session
        self.onProgress = onProgress
        self.onFinish = onFinish
    }

    @objc func tick(_ timer: Timer) {
        guard let session = session else {
            timer.invalidate()
            onFinish?()
            return
        }
        let adjusted = 0.3 + Double(session.progress) * 0.4
        onProgress?(adjusted)
        switch session.status {
        case .waiting, .exporting:
            break
        default:
            timer.invalidate()
            onFinish?()
        }
    }
}

internal class PreviewState: ObservableObject {
    @Published var index = 0
    @Published var fromGrid = false
    @Published var showing = false
    
    func showPreviewFromGrid(at index: Int) {
        self.index = index
        self.fromGrid = true
        self.showing = true
    }
    
    func showPreviewFromButton() {
        self.fromGrid = false
        self.showing = true
    }
    
    func hidePreview() {
        self.showing = false
        self.fromGrid = false
    }
}

// MARK: - AlbumPickerView Implementation
extension AlbumPicker {
    
    // MARK: - View Components
    internal var photoGridView: some View {
        GeometryReader { geometry in
            let itemSize = (geometry.size.width - CGFloat(columnNumber + 1) * itemSpacing) / CGFloat(columnNumber)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(itemSize), spacing: itemSpacing), count: columnNumber), spacing: itemSpacing) {
                    ForEach(Array(albumModel.assetModels.enumerated()), id: \.offset) { index, assetModel in
                        AlbumPickerAssetCell(
                            assetModel: assetModel,
                            itemSize: itemSize,
                            isSelected: selectedAssets.contains { $0.asset?.localIdentifier == assetModel.asset?.localIdentifier },
                            selectionNumber: getSelectionNumber(for: assetModel),
                            refreshTrigger: gridRefreshTrigger,
                            themeColor: primaryColor,
                            onTap: { handleAssetTap(at: index) },
                            onSelect: { handleAssetSelection(assetModel) }
                        )
                    }
                }
                .padding(itemSpacing)
            }
            .rtlLayout()
        }
    }
    
    internal var bottomToolbar: some View {
        RTLVStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            RTLHStack {
                Button(LocalizedAlbumPickerString("preview")) {
                    if !selectedAssets.isEmpty {
                        previewState.showPreviewFromButton()
                    }
                }
                .foregroundColor(selectedAssets.isEmpty ? .gray : .white)
                .disabled(selectedAssets.isEmpty)
                
                Spacer()
                
                RTLHStack {
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
                                    .foregroundColor(selectedAssets.isEmpty ? .gray : (isSelectOriginalPhoto ? primaryColor : .gray))
                                Text(LocalizedAlbumPickerString("original"))
                                    .foregroundColor(selectedAssets.isEmpty ? .gray : .white)
                            }
                        }
                        .disabled(selectedAssets.isEmpty)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                RTLHStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(selectedAssets.isEmpty ? Color.clear : primaryColor)
                            .frame(width: 22, height: 22)
                        
                        if !selectedAssets.isEmpty {
                            Text("\(selectedAssets.count)")
                                .foregroundColor(.white)
                                .font(.system(size: 15))
                        }
                    }
                    .frame(width: 22, height: 22)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Button(LocalizedAlbumPickerString("done")) {
                            handleDoneButtonTap()
                        }
                        .foregroundColor(selectedAssets.isEmpty ? .gray : primaryColor)
                        .disabled(selectedAssets.isEmpty)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.9))
        }
    }
    
    internal var albumTitleView: some View {
        Button(action: {
            showingAlbums.toggle()
        }) {
            RTLHStack(spacing: 4) {
                Text(albumModel.name.isEmpty ? LocalizedAlbumPickerString("camera_roll") : albumModel.name)
                    .foregroundColor(.white)
                    .font(.headline)
                
                Image(systemName: showingAlbums ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
    }
    
    internal var albumSelectionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showingAlbums = false
                }
            
            RTLVStack {
                RTLVStack(spacing: 0) {
                    ForEach(Array(albums.enumerated()), id: \.offset) { index, album in
                        AlbumPickerAlbumRow(
                            album: album,
                            isSelected: album.name == albumModel.name,
                            themeColor: primaryColor
                        ) {
                            selectAlbum(album)
                        }
                        
                        if index < albums.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                }
                .background(Color.black.opacity(0.9))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Business Logic Methods
    internal func loadCameraRoll() {
        imageManager.getCameraRollAlbum(needFetchAssets: true, filter: albumMode) { model in
            if let model = model {
                DispatchQueue.main.async {
                    self.albumModel.name = model.name
                    self.albumModel.result = model.result
                    self.albumModel.collection = model.collection
                    self.albumModel.options = model.options
                    self.albumModel.isCameraRoll = model.isCameraRoll
                    
                    if let result = model.result {
                        self.imageManager.getAssets(from: result) { assetModels in
                            DispatchQueue.main.async {
                                self.albumModel.assetModels = assetModels
                            }
                        }
                    }
                }
            }
        }
        
        imageManager.getAllAlbums(needFetchAssets: false, filter: albumMode) { albums in
            DispatchQueue.main.async {
                self.albums = albums
            }
        }
    }
    
    internal func selectAlbum(_ album: AlbumPickerAlbumModel) {
        albumModel.name = album.name
        albumModel.assetModels = album.assetModels
        albumModel.result = album.result
        albumModel.collection = album.collection
        albumModel.options = album.options
        albumModel.isCameraRoll = album.isCameraRoll
        
        showingAlbums = false
        
        if album.assetModels.isEmpty, let result = album.result {
            imageManager.getAssets(from: result) { models in
                DispatchQueue.main.async {
                    self.albumModel.assetModels = models
                }
            }
        }
    }
    
    internal func handleAssetTap(at index: Int) {
        previewState.showPreviewFromGrid(at: index)
    }
    
    internal func handleAssetSelection(_ assetModel: AlbumPickerAssetModel) {
        if let existingIndex = selectedAssets.firstIndex(where: { $0.asset?.localIdentifier == assetModel.asset?.localIdentifier }) {
            selectedAssets.remove(at: existingIndex)
            assetModel.isSelected = false
        } else if selectedAssets.count < maxImagesCount {
            selectedAssets.append(assetModel)
            assetModel.isSelected = true
        }
    }
    
    internal func getSelectionNumber(for assetModel: AlbumPickerAssetModel) -> Int? {
        guard let index = selectedAssets.firstIndex(where: { $0.asset?.localIdentifier == assetModel.asset?.localIdentifier }) else {
            return nil
        }
        return index + 1
    }
    
    internal func handleDoneButtonTap() {
        guard !selectedAssets.isEmpty else { return }
        
        let validAssets = selectedAssets.compactMap { assetModel -> (AlbumPickerAssetModel, PHAsset)? in
            guard let asset = assetModel.asset else { return nil }
            return (assetModel, asset)
        }
        
        guard !validAssets.isEmpty else {
            DispatchQueue.main.async { onFinishedSelect(0) }
            return
        }
        
        DispatchQueue.main.async { onFinishedSelect(validAssets.count) }
        processSelectedAssetsWithProgress(validAssets)
    }
}

// MARK: - UI Components
internal struct AlbumPickerAssetCell: View {
    let assetModel: AlbumPickerAssetModel
    let itemSize: CGFloat
    let isSelected: Bool
    let selectionNumber: Int?
    let refreshTrigger: UUID
    let themeColor: Color
    let onTap: () -> Void
    let onSelect: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: itemSize, height: itemSize)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemSize, height: itemSize)
                    .clipped()
                    .allowsHitTesting(false)
            }
            
            if isSelected {
                Rectangle()
                    .fill(themeColor.opacity(0.3))
                    .frame(width: itemSize, height: itemSize)
                    .allowsHitTesting(false)
            }
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: itemSize, height: itemSize)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            
            RTLVStack {
                RTLHStack {
                    Spacer()
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect()
                            }
                        
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                .background(Circle().fill(isSelected ? themeColor : Color.clear))
                                .frame(width: 22, height: 22)
                            
                            if let number = selectionNumber {
                                Text("\(number)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(width: 30, height: 30)
                        .zIndex(10)
                        .highPriorityGesture(TapGesture().onEnded {
                            onSelect()
                        })
                    }
                }
                Spacer()
                
                if assetModel.type == .video, let timeLength = assetModel.timeLength {
                    RTLHStack {
//                        Image(systemName: "play.fill")
//                            .foregroundColor(.white)
//                            .font(.caption2)
//                        Spacer()
                        Text(timeLength)
                            .foregroundColor(.white)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.0))
                    .cornerRadius(4)
                    .padding(2)
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onReceive(assetModel.$editImage) { _ in
            DispatchQueue.main.async {
                self.image = nil
                self.loadImage()
            }
        }
        .onChange(of: refreshTrigger) { _ in
            DispatchQueue.main.async {
                self.image = nil
                self.loadImage()
            }
        }
    }
    
    private func loadImage() {
        if let editImage = assetModel.editImage {
            DispatchQueue.main.async {
                self.image = editImage
            }
            return
        }
        
        guard let asset = assetModel.asset else { return }
        
        AlbumPickerImageManager.shared.getPhoto(with: asset, photoWidth: itemSize * 2) { image, _, _ in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}

internal struct AlbumPickerAlbumRow: View {
    let album: AlbumPickerAlbumModel
    let isSelected: Bool
    let themeColor: Color
    let onTap: () -> Void
    
    @State private var coverImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            RTLHStack(spacing: 12) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 54, height: 54)
                    
                    if let image = coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 54, height: 54)
                            .clipped()
                    }
                }
                .cornerRadius(4)
                
                RTLVStack(alignment: AlbumPickerRTLHelper.isRTL ? .trailing : .leading, spacing: 4) {
                    Text(album.name)
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Text("\(album.photoCount)")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(themeColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        AlbumPickerImageManager.shared.getCoverImage(with: album) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }
}

// MARK: - View Extensions
public struct NavigationBarConfigurator: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIViewController
    public let configure: (UINavigationController) -> Void

    public init(configure: @escaping (UINavigationController) -> Void) {
        self.configure = configure
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let nav = uiViewController.navigationController {
            configure(nav)
        }
    }
}
