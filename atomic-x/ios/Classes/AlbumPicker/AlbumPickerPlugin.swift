import Flutter
import UIKit

/**
 * AlbumPickerPlugin
 * 
 * AlbumPickerPlugin 作为 AtomicXPlugin 和 AlbumPickerHandler 之间的中间层，管理 MethodChannel 和 EventChannel
 * 
 * 注意：这与 iOS SwiftUI 的 AlbumPicker 不同；此类专门为 Flutter Plugin 层设计
 */
class AlbumPickerPlugin: NSObject, FlutterStreamHandler {
    private static let channelName = "atomic_x/album_picker"
    private static let eventChannelName = "atomic_x/album_picker_events"
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var albumPickerHandler: AlbumPickerHandler?
    private var eventSink: FlutterEventSink?
    
    init(registrar: FlutterPluginRegistrar, viewController: UIViewController?) {
        super.init()
        
        methodChannel = FlutterMethodChannel(
            name: AlbumPickerPlugin.channelName,
            binaryMessenger: registrar.messenger()
        )
        
        eventChannel = FlutterEventChannel(
            name: AlbumPickerPlugin.eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        
        eventChannel?.setStreamHandler(self)
        
        albumPickerHandler = AlbumPickerHandler(viewController: viewController, eventSink: { [weak self] event in
            self?.eventSink?(event)
        })
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("[AlbumPickerPlugin] EventChannel onListen")
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("[AlbumPickerPlugin] EventChannel onCancel")
        self.eventSink = nil
        return nil
    }
    
    // MARK: - MethodChannel Handler
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickMedia":
            albumPickerHandler?.handlePickMedia(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func dispose() {
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        albumPickerHandler = nil
        eventSink = nil
    }
}
