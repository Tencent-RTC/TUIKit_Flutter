import Flutter
import UIKit

class ScreenCaptureManager: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onScreenCaptureStatusChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            events(self.isScreenCaptured)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    @objc private func onScreenCaptureStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let sink = self.eventSink {
                sink(self.isScreenCaptured)
            }
        }
    }

    private var isScreenCaptured: Bool {
        if #available(iOS 17.0, *) {
            return UITraitCollection.current.sceneCaptureState == .active
        } else {
            return UIScreen.main.isCaptured
        }
    }
}
