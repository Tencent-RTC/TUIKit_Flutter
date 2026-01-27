import Flutter
import UIKit

class ThermalManager: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateDidChange),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        // initial state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            events(ProcessInfo.processInfo.thermalState.rawValue)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    @objc private func thermalStateDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let sink = eventSink {
                sink(ProcessInfo.processInfo.thermalState.rawValue)
            }
        }
    }
}