/*
 * Copyright (c) 2025 Tencent
 * All rights reserved.
 *
 * Author: eddardliu
 */

import Flutter
import UIKit

class AtomicImageUploaderPlugin: NSObject, FlutterStreamHandler {
    private static let channelName = "atomic_x/image_uploader"
    private static let eventChannelName = "atomic_x/image_uploader_events"
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private let imageSource = SystemImageSource()

    init(registrar: FlutterPluginRegistrar) {
        super.init()

        methodChannel = FlutterMethodChannel(
            name: AtomicImageUploaderPlugin.channelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel = FlutterEventChannel(
            name: AtomicImageUploaderPlugin.eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel?.setStreamHandler(self)
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - MethodChannel
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pick":
            handlePick(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handlePick(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let source = args?["source"] as? String ?? "gallery"
        
        guard let presenter = topMostViewController() else {
            sendPickResult(nil)
            result(nil)
            return
        }
        
        imageSource.pick(source: source, from: presenter) { [weak self] localPath in
            self?.sendPickResult(localPath)
        }
        
        result(nil)
    }

    // MARK: - Result Handling
    
    private func sendPickResult(_ localPath: String?) {
        DispatchQueue.main.async { [weak self] in
            let event: [String: Any?] = [
                "type": "pickCompleted",
                "localPath": localPath
            ]
            self?.eventSink?(event)
        }
    }

    // MARK: - Utils
    
    private func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else { return nil }
        return topMost(rootVC)
    }
    
    private func topMost(_ vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return topMost(nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(selected)
        }
        if let presented = vc.presentedViewController {
            return topMost(presented)
        }
        return vc
    }
    
    func dispose() {
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        eventSink = nil
    }
}
