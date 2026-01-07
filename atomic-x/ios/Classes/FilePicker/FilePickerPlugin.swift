import Flutter
import UIKit

public class FilePickerPlugin: NSObject {
    private var methodChannel: FlutterMethodChannel?
    private var handler: FilePickerHandler?
    
    init(registrar: FlutterPluginRegistrar) {
        super.init()
        
        methodChannel = FlutterMethodChannel(
            name: "atomic_x/file_picker",
            binaryMessenger: registrar.messenger()
        )
        
        handler = FilePickerHandler(methodChannel: methodChannel!)
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handler?.handle(call, result: result)
        }
    }
    
    public func dispose() {
        handler?.dispose()
        handler = nil
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
    }
}
