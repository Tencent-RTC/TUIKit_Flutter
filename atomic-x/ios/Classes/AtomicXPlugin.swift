import Flutter
import UIKit

public class AtomicXPlugin: NSObject, FlutterPlugin {
  private var permission: Permission?
  private var device: Device?
  private var albumPicker: AtomicAlbumPickerPlugin?
  private var videoRecorder: AtomicVideoRecorderPlugin?
  private var audioRecorder: AtomicAudioRecorderPlugin?
  private var audioPlayer: AtomicAudioPlayerPlugin?
  private var filePicker: AtomicFilePickerPlugin?
  private var videoPlayer: AtomicVideoPlayerPlugin?
  private var imageUploader: AtomicImageUploaderPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "atomic_x", binaryMessenger: registrar.messenger())
    let instance = AtomicXPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    instance.permission = Permission(registrar: registrar)
    instance.device = Device(registrar: registrar)
    instance.albumPicker = AtomicAlbumPickerPlugin(registrar: registrar)
    instance.videoRecorder = AtomicVideoRecorderPlugin(registrar: registrar)
    
    // Register audio recorder module
    instance.audioRecorder = AtomicAudioRecorderPlugin(registrar: registrar)
    
    // Register audio player module
    instance.audioPlayer = AtomicAudioPlayerPlugin(registrar: registrar)
    
    // Register file picker module
    instance.filePicker = AtomicFilePickerPlugin(registrar: registrar)
    
    // Register video player module
    instance.videoPlayer = AtomicVideoPlayerPlugin.register(with: registrar) as? AtomicVideoPlayerPlugin
    
    // Register image uploader module
    instance.imageUploader = AtomicImageUploaderPlugin(registrar: registrar)
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
    imageUploader?.dispose()
  }
}
