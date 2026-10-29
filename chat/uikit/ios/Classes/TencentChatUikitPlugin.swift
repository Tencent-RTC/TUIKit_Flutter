import Flutter
import UIKit

/// TencentChatUikitPlugin
///
/// Hosts the chat-business native handlers that previously lived in
/// AtomicXPlugin. Module/handler ownership matches the Dart-side migration:
///   audio_player, audio_recoder, file_picker, video_player, video_recorder.
public class TencentChatUikitPlugin: NSObject, FlutterPlugin {
  private var videoRecorder: AtomicVideoRecorderPlugin?
  private var audioRecorder: AtomicAudioRecorderPlugin?
  private var audioPlayer: AtomicAudioPlayerPlugin?
  private var filePicker: AtomicFilePickerPlugin?
  private var videoPlayer: AtomicVideoPlayerPlugin?
  private var realtimeAudio: AtomicRealtimeAudioPlugin?
  private var opusPlayer: AtomicOpusPlayerPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "tencent_chat_uikit",
      binaryMessenger: registrar.messenger()
    )
    let instance = TencentChatUikitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    instance.videoRecorder = AtomicVideoRecorderPlugin(registrar: registrar)
    instance.audioRecorder = AtomicAudioRecorderPlugin(registrar: registrar)
    instance.audioPlayer = AtomicAudioPlayerPlugin(registrar: registrar)
    instance.filePicker = AtomicFilePickerPlugin(registrar: registrar)
    instance.videoPlayer = AtomicVideoPlayerPlugin.register(with: registrar) as? AtomicVideoPlayerPlugin
    instance.realtimeAudio = AtomicRealtimeAudioPlugin(registrar: registrar)
    instance.opusPlayer = AtomicOpusPlayerPlugin(registrar: registrar)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    realtimeAudio?.dispose()
    realtimeAudio = nil
    opusPlayer?.dispose()
    opusPlayer = nil
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
    videoRecorder?.dispose()
    audioRecorder?.dispose()
    audioPlayer?.dispose()
    filePicker?.dispose()
    realtimeAudio?.dispose()
    opusPlayer?.dispose()
  }
}
