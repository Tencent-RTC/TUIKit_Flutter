import Flutter
import UIKit

final class LogShareBridge {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.tencent.app_uikit/logs", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "list":
        DispatchQueue.global(qos: .utility).async {
          let entries = logs().map { ["name": $0.lastPathComponent, "path": $0.path] }
          DispatchQueue.main.async { result(entries) }
        }
      case "share":
        guard let path = call.arguments as? String, let file = logs().first(where: { $0.path == path }) else {
          result(FlutterError(code: "missing", message: "Log file no longer available", details: nil)); return
        }
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
          .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }), var presenter = window.rootViewController else {
          result(FlutterError(code: "window", message: "No active window", details: nil)); return
        }
        while let presented = presenter.presentedViewController { presenter = presented }
        let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = presenter.view
        controller.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        presenter.present(controller, animated: true) { result(nil) }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
  private static func logs() -> [URL] {
    let manager = FileManager.default
    let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let caches = manager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let roots = [documents.appendingPathComponent("log"), caches.appendingPathComponent("com_tencent_imsdk_log")]
    return roots.flatMap { (try? manager.contentsOfDirectory(at: $0, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])) ?? [] }
      .filter { ["log", "clog", "xlog"].contains($0.pathExtension.lowercased()) }
      .sorted { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
  }
}
