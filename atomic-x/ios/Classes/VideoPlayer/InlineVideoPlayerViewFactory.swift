import Flutter
import UIKit
import AVKit

/// Factory for creating inline video player views
/// This player only renders video - controls are handled by Flutter
class InlineVideoPlayerViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return InlineVideoPlayerPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Custom UIView that automatically updates AVPlayerLayer frame on layout changes
class PlayerContainerView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    func setPlayer(_ player: AVPlayer?) {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }
}

/// Inline video player that only renders video without any controls
/// All playback control is done via MethodChannel from Flutter
class InlineVideoPlayerPlatformView: NSObject, FlutterPlatformView {
    private var containerView: PlayerContainerView
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var methodChannel: FlutterMethodChannel?
    
    private var timeObserver: Any?
    private var isDisposed = false
    
    // Video dimensions for aspect ratio calculation
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        containerView = PlayerContainerView()
        containerView.backgroundColor = .black
        
        super.init()
        
        guard let args = args as? [String: Any],
              let videoPath = args["videoPath"] as? String else {
            return
        }
        
        // Setup method channel for Flutter communication
        if let messenger = messenger {
            methodChannel = FlutterMethodChannel(
                name: "io.trtc.tuikit.atomicx/inline_video_player_\(viewId)",
                binaryMessenger: messenger
            )
            methodChannel?.setMethodCallHandler { [weak self] call, result in
                self?.handleMethodCall(call, result: result)
            }
        }
        
        // Create player
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // Set player to container view (uses AVPlayerLayer as backing layer)
        containerView.setPlayer(player)
        
        // Setup observers
        setupObservers()
    }
    
    func view() -> UIView {
        return containerView
    }
    
    private func setupObservers() {
        guard let player = player, let playerItem = playerItem else { return }
        
        // Observe player item status
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // Observe video size
        playerItem.addObserver(self, forKeyPath: "presentationSize", options: [.new], context: nil)
        
        // Observe playback completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Observe rate changes for play/pause state
        player.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
        
        // Add periodic time observer for position updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isDisposed else { return }
            let positionMs = Int(CMTimeGetSeconds(time) * 1000)
            self.sendToFlutter("onPositionChanged", arguments: positionMs)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard !isDisposed else { return }
        
        if keyPath == "status" {
            if let playerItem = playerItem, playerItem.status == .readyToPlay {
                let durationMs = Int(CMTimeGetSeconds(playerItem.duration) * 1000)
                sendToFlutter("onReady", arguments: [
                    "duration": durationMs,
                    "videoWidth": videoWidth,
                    "videoHeight": videoHeight
                ])
                sendToFlutter("onDurationChanged", arguments: durationMs)
            }
        } else if keyPath == "presentationSize" {
            if let playerItem = playerItem {
                let size = playerItem.presentationSize
                if size.width > 0 && size.height > 0 {
                    videoWidth = Int(size.width)
                    videoHeight = Int(size.height)
                    sendToFlutter("onVideoSizeChanged", arguments: [
                        "width": videoWidth,
                        "height": videoHeight
                    ])
                }
            }
        } else if keyPath == "rate" {
            if let player = player {
                let isPlaying = player.rate > 0
                sendToFlutter("onPlayingChanged", arguments: isPlaying)
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        guard !isDisposed else { return }
        sendToFlutter("onCompleted", arguments: nil)
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let player = player else {
            result(FlutterError(code: "NO_PLAYER", message: "Player not initialized", details: nil))
            return
        }
        
        switch call.method {
        case "play":
            // If playback ended, seek to start before playing
            if let playerItem = playerItem,
               playerItem.status == .readyToPlay,
               CMTimeGetSeconds(player.currentTime()) >= CMTimeGetSeconds(playerItem.duration) - 0.1 {
                player.seek(to: .zero) { [weak player] _ in
                    player?.play()
                }
            } else {
                player.play()
            }
            result(nil)
            
        case "pause":
            player.pause()
            result(nil)
            
        case "seekTo":
            if let positionMs = call.arguments as? Int {
                let time = CMTime(seconds: Double(positionMs) / 1000.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            result(nil)
            
        case "getPosition":
            let positionMs = Int(CMTimeGetSeconds(player.currentTime()) * 1000)
            result(positionMs)
            
        case "getDuration":
            if let playerItem = playerItem {
                let durationMs = Int(CMTimeGetSeconds(playerItem.duration) * 1000)
                result(durationMs)
            } else {
                result(0)
            }
            
        case "isPlaying":
            result(player.rate > 0)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func sendToFlutter(_ method: String, arguments: Any?) {
        guard !isDisposed else { return }
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod(method, arguments: arguments)
        }
    }
    
    deinit {
        dispose()
    }
    
    private func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        
        // Remove time observer
        if let timeObserver = timeObserver, let player = player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        
        // Remove KVO observers
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "presentationSize")
        player?.removeObserver(self, forKeyPath: "rate")
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Stop and release player
        player?.pause()
        containerView.setPlayer(nil)
        player = nil
        playerItem = nil
        
        // Clear method channel
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
    }
}
