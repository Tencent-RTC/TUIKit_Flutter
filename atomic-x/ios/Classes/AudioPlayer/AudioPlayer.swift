import AVFoundation
import AVKit
import SwiftUI

public class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayerImpl()
    
    public var onComplete: (() -> Void)?
    public var onProgressUpdate: ((_ currentPosition: Int, _ duration: Int) -> Void)?
    public var onPlay: (() -> Void)?
    public var onPause: (() -> Void)?
    public var onResume: (() -> Void)?
    public var onError: ((_ errorMessage: String) -> Void)?
    
    public func play(filePath: String) {}
    
    public func pause() {}
    
    public func resume() {}
    
    public func stop() {}
    
    public func getCurrentPosition() -> Int { return 0 }
    
    public func getDuration() -> Int { return 0 }
    
    public func isPlaying() -> Bool { return false }
    
    public func isPaused() -> Bool { return false }
    
    override internal init() {
        super.init()
    }
}
