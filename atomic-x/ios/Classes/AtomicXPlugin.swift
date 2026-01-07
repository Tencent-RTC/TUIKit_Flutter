import Flutter
import UIKit

public class AtomicXPlugin: NSObject, FlutterPlugin {
  private var permission: Permission?
  private var device: Device?
  private var albumPicker: AlbumPickerPlugin?
  private var videoRecorder: VideoRecorderPlugin?
  private var audioRecorder: AudioRecorderPlugin?
  private var audioPlayer: AudioPlayerPlugin?
  private var filePicker: FilePickerPlugin?
  private var videoPlayer: VideoPlayerPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "atomic_x", binaryMessenger: registrar.messenger())
    let instance = AtomicXPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Get root view controller
    let viewController = UIApplication.shared.delegate?.window??.rootViewController

    // Register permission module
    instance.permission = Permission(registrar: registrar)
    instance.device = Device(registrar: registrar)

    // Register album picker module
    instance.albumPicker = AlbumPickerPlugin(registrar: registrar, viewController: viewController)
    
    // Register video recorder module
    instance.videoRecorder = VideoRecorderPlugin(registrar: registrar)
    
    // Register audio recorder module
    instance.audioRecorder = AudioRecorderPlugin(registrar: registrar)
    
    // Register audio player module
    instance.audioPlayer = AudioPlayerPlugin(registrar: registrar)
    
    // Register file picker module
    instance.filePicker = FilePickerPlugin(registrar: registrar)
    
    // Register video player module
    instance.videoPlayer = VideoPlayerPlugin.register(with: registrar) as? VideoPlayerPlugin
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  deinit {
    albumPicker?.dispose()
    videoRecorder?.dispose()
    audioRecorder?.dispose()
    audioPlayer?.dispose()
    filePicker?.dispose()
  }
}
