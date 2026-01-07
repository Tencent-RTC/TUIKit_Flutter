import Foundation

public enum MessageType {
    case image
    case video
    case sound
}

public class ChatUtils {
    public static func getHomePath() -> String {
        return NSHomeDirectory() + "/Documents/atomicx_core_data"
    }

    public static func getMediaHomePath(messageType: MessageType) -> String {
        switch messageType {
        case .image:
            return getHomePath() + "/image/"
        case .video:
            return getHomePath() + "/video/"
        case .sound:
            return getHomePath() + "/sound/"
        }
    }

    public static func generateMediaPath(messageType: MessageType, withExtension: String? = nil) -> String {
        let uuid = "\(Int(Date().timeIntervalSince1970))_\(arc4random() % UInt32.max)"
        var mediaExtension = ""
        if let withExtension = withExtension {
            mediaExtension = ".\(withExtension)"
        }
        return getMediaHomePath(messageType: messageType) + "\(uuid)\(mediaExtension)"
    }
}
