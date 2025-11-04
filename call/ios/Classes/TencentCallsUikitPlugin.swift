import Flutter
import UIKit
import RTCRoomEngine

public class TencentCallsUikitPlugin: NSObject, FlutterPlugin, VoIPDataSyncHandlerDelegate {
    let voIPDataSyncHandler: VoIPDataSyncHandler
    let channel: FlutterMethodChannel
    
    init(channel: FlutterMethodChannel) {
        voIPDataSyncHandler = VoIPDataSyncHandler()
        self.channel = channel
        super.init()
        voIPDataSyncHandler.voipDataSyncHandlerDelegate = self
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tencent_calls_uikit", binaryMessenger: registrar.messenger())
        let instance = TencentCallsUikitPlugin(channel: channel)
                
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startVibration":
            startVibration(call, result: result)
        case "stopVibration":
            stopVibration(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startVibration(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        CallingVibrator.startVibration()
        result(nil)
    }
    
    private func stopVibration(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        CallingVibrator.stopVibration()
        result(nil)
    }
}


// MARK: VoIPDataSyncHandlerDelegate
extension TencentCallsUikitPlugin {
    func callMethodVoipChangeMute(mute: Bool) {
        channel.invokeMethod("voipMute", arguments: ["mute": mute])
    }
    
    func callMethodVoipChangeAudioPlaybackDevice(audioPlaybackDevice: TUIAudioPlaybackDevice) {
        channel.invokeMethod("voipAudioPlaybackDevice", arguments: ["audioPlaybackDevice": audioPlaybackDevice.rawValue])
    }
    
    func callMethodVoipHangup() {
        channel.invokeMethod("voipHangup", arguments: [:])
    }
    
    func callMethodVoipAccept() {
        channel.invokeMethod("voipAccept", arguments: [:])
    }
}
