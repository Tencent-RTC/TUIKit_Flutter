//
//  AlbumPickerVideoPlayerView.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import SwiftUI
import AVKit
import AVFoundation
import Photos

// MARK: - Notification Names
extension Notification.Name {
    static let albumPickerShouldPauseVideo = Notification.Name("AlbumPickerShouldPauseVideo")
}

// MARK: - Player state manager
class VideoPlayerManager: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var isPlaying = false
    
    private var playerObservers: [NSKeyValueObservation] = []
    
    override init() {
        super.init()
    }
    
    func setupPlayer(with playerItem: AVPlayerItem) {
        player = AVPlayer(playerItem: playerItem)
        isLoading = false
        setupPlayerObservers()
        setupLoopPlayback()
        player?.play()
        isPlaying = true
    }
    
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        let timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }
        
        let rateObserver = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = player.rate > 0
            }
        }
        
        playerObservers.append(timeControlStatusObserver)
        playerObservers.append(rateObserver)
    }
    
    private func setupLoopPlayback() {
        guard let player = player else { return }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            player.seek(to: .zero)
            player.play()
            self?.isPlaying = true
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func cleanup() {
        player?.pause()
        isPlaying = false

        playerObservers.forEach { $0.invalidate() }
        playerObservers.removeAll()
        
        if let player = player {
            NotificationCenter.default.removeObserver(
                self, 
                name: .AVPlayerItemDidPlayToEndTime, 
                object: player.currentItem
            )
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        cleanup()
    }
}

struct AlbumPickerVideoPlayerView: View {
    let asset: PHAsset?
    let videoURL: URL?
    @StateObject private var playerManager = VideoPlayerManager()
    
    init(asset: PHAsset) {
        self.asset = asset
        self.videoURL = nil
    }
    
    init(videoURL: URL) {
        self.asset = nil
        self.videoURL = videoURL
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            if let player = playerManager.player {
                AVPlayerViewRepresentable(player: player)
            } else if playerManager.isLoading {
                ProgressView(LocalizedAlbumPickerString("loading"))
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(LocalizedAlbumPickerString("video_load_failed"))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            loadVideo()
            setupAppLifecycleObservers()
            setupPauseObserver()
        }
        .onDisappear {
            playerManager.cleanup()
            NotificationCenter.default.removeObserver(self, name: .albumPickerShouldPauseVideo, object: nil)
            NotificationCenter.default.removeObserver(self,name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self,name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    
    private func loadVideo() {
        playerManager.isLoading = true
        
        if let videoURL = videoURL {
            let playerItem = AVPlayerItem(url: videoURL)
            DispatchQueue.main.async {
                self.playerManager.setupPlayer(with: playerItem)
            }
        } else if let asset = asset {
            AlbumPickerImageManager.shared.getVideo(with: asset) { playerItem, info in
                DispatchQueue.main.async {
                    if let playerItem = playerItem {
                        self.playerManager.setupPlayer(with: playerItem)
                    } else {
                        self.playerManager.isLoading = false
                    }
                }
            }
        } else {
            playerManager.isLoading = false
        }
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak playerManager] _ in
            playerManager?.pause()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak playerManager] _ in
            if playerManager?.player != nil {
                playerManager?.play()
            }
        }
    }
    
    private func setupPauseObserver() {
        NotificationCenter.default.addObserver(
            forName: .albumPickerShouldPauseVideo,
            object: nil,
            queue: .main
        ) { [weak playerManager] _ in
            playerManager?.pause()
        }
    }
}

struct AVPlayerViewRepresentable: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        return playerView
    }
    
    func updateUIView(_ uiView: AVPlayerView, context: Context) {
        uiView.player = player
    }
}

class AVPlayerView: UIView {
    var player: AVPlayer? {
        didSet {
            playerLayer.player = player
        }
    }
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspect
    }
}

struct AlbumPickerVideoThumbnailView: View {
    let asset: PHAsset
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        AlbumPickerImageManager.shared.getPhoto(with: asset, photoWidth: 200) { image, _, _ in
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }
}
