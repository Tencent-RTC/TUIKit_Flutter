import AVKit
import SwiftUI
import os.log

internal class AudioPlayerImpl: AudioPlayer, AVAudioPlayerDelegate {
    private let logger = Logger(subsystem: "AudioPlayer", category: "AudioPlayerControl")
    
    @Published public var isPlayingState: Bool = false
    @Published public var isPausedState: Bool = false
    @Published public var currentPlayingURL: URL? = nil
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    override public func play(filePath: String) {
        logger.info("play: \(filePath)")
        
        guard let url = URL(string: filePath) ?? URL(fileURLWithPath: filePath) as URL? else {
            logger.error("Invalid file path: \(filePath)")
            onError?("Invalid file path")
            return
        }
        
        if isPlayingState && currentPlayingURL == url {
            logger.info("Already playing same file, stopping")
            audioPlayer?.stop()
            audioPlayer = nil
            isPlayingState = false
            currentPlayingURL = nil
            return
        }
        
        if isPlayingState {
            logger.info("Stopping current playback")
            audioPlayer?.stop()
            audioPlayer = nil
            isPlayingState = false
            currentPlayingURL = nil
        }
        
        playInternal(url)
    }

    override public func pause() {
        logger.info("pause")
        guard let player = audioPlayer, isPlayingState else { return }
        player.pause()
        isPlayingState = false
        isPausedState = true
        stopProgressUpdates()
        onPause?()
    }

    override public func resume() {
        logger.info("resume")
        guard let player = audioPlayer, isPausedState else { return }
        if player.play() {
            isPlayingState = true
            isPausedState = false
            startProgressUpdates()
            onResume?()
        }
    }

    override public func stop() {
        logger.info("stop")
        guard let player = audioPlayer else { return }
        player.stop()
        audioPlayer = nil
        isPlayingState = false
        isPausedState = false
        currentPlayingURL = nil
        stopProgressUpdates()
    }

    override public func getCurrentPosition() -> Int {
        guard let player = audioPlayer else { return 0 }
        return Int(player.currentTime * 1000) // Return milliseconds
    }

    override public func getDuration() -> Int {
        guard let player = audioPlayer else { return 0 }
        return Int(player.duration * 1000) // Return milliseconds
    }
    
    override public func isPlaying() -> Bool {
        return isPlayingState
    }
    
    override public func isPaused() -> Bool {
        return isPausedState
    }

    private func playInternal(_ url: URL) {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            if audioPlayer?.play() == true {
                isPlayingState = true
                isPausedState = false
                currentPlayingURL = url
                startProgressUpdates()
                onPlay?()
                logger.info("Playback started successfully")
            } else {
                logger.error("Audio playback failed")
                audioPlayer = nil
                isPlayingState = false
                isPausedState = false
                currentPlayingURL = nil
                onError?("Audio playback failed")
            }
        } catch {
            logger.error("Audio playback error: \(error.localizedDescription)")
            audioPlayer = nil
            isPlayingState = false
            isPausedState = false
            currentPlayingURL = nil
            onError?("Audio playback error: \(error.localizedDescription)")
        }
    }
    
    private func startProgressUpdates() {
        stopProgressUpdates()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlayingState else { return }
            let currentPosition = self.getCurrentPosition()
            let duration = self.getDuration()
            self.onProgressUpdate?(currentPosition, duration)
        }
    }
    
    private func stopProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        logger.info("Playback finished successfully: \(flag)")
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingState = false
        isPausedState = false
        currentPlayingURL = nil
        stopProgressUpdates()
        onComplete?()
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        logger.error("Audio player decoding error: \(errorMessage)")
        audioPlayer = nil
        isPlayingState = false
        isPausedState = false
        currentPlayingURL = nil
        stopProgressUpdates()
        onError?("Decode error: \(errorMessage)")
    }
}
