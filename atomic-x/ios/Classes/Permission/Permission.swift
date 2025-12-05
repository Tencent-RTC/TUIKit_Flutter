import Flutter

/// Manages MethodChannel communication and delegates to PermissionHandler.
class Permission {
  private static let channelName = "atomic_x/permission"
  private let methodChannel: FlutterMethodChannel
  private let registrar: FlutterPluginRegistrar
  private let handler: PermissionHandler

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    self.handler = PermissionHandler()
    self.methodChannel = FlutterMethodChannel(
      name: Permission.channelName,
      binaryMessenger: registrar.messenger()
    )
    
    // Set method call handler
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      guard let args = call.arguments as? [String: Any],
            let permissions = args["permissions"] as? [String] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Permissions are required", details: nil))
        return
      }
      handler.requestPermissions(permissions, result: result)

    case "openAppSettings":
      result(handler.openAppSettings())

    case "getPermissionStatus":
      guard let args = call.arguments as? [String: Any],
            let permission = args["permission"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Permission is required", details: nil))
        return
      }
      result(handler.getPermissionStatus(permission))

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
