import Foundation


internal struct AudioRecorderListener {
    var onProgress: (Int) -> Void = { _ in }
    var onPower: (Int) -> Void = { _ in }
    var onComplete: (AudioRecordResultCode) -> Void = { _ in }
}

internal protocol AudioRecorderInternalProtocol: AnyObject {
    func startRecord(_ path : String, _ minDuration: Int, _ maxDuration: Int)
    func stopRecord()
    func setListener(_ listener: AudioRecorderListener)
    func enableAIDeNoise(_ enable : Bool)
}
