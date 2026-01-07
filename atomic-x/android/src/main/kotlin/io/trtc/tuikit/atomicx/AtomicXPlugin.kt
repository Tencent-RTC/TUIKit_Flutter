package io.trtc.tuikit.atomicx

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.trtc.tuikit.atomicx.permission.Permission
import io.trtc.tuikit.atomicx.device_info.Device
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerPlugin
import io.trtc.tuikit.atomicx.videorecorder.VideoRecorderPlugin
import io.trtc.tuikit.atomicx.audiorecorder.AudioRecorderPlugin
import io.trtc.tuikit.atomicx.audioplayer.AudioPlayerPlugin
import io.trtc.tuikit.atomicx.filepicker.FilePickerPlugin
import io.trtc.tuikit.atomicx.videoplayer.VideoPlayerPlugin

/** Atomic_xPlugin */
class AtomicXPlugin: FlutterPlugin, ActivityAware {
  companion object {
      private const val TAG = "AtomicXPlugin"
  }

  private var permission: Permission? = null
  private var device: Device? = null
  private var pipManager: PictureInPictureManager? = null
  private var albumPickerPlugin: AlbumPickerPlugin? = null
  private var videoRecorderPlugin: VideoRecorderPlugin? = null
  private var audioRecorderPlugin: AudioRecorderPlugin? = null
  private var audioPlayerPlugin: AudioPlayerPlugin? = null
  private var filePickerPlugin: FilePickerPlugin? = null
  private var videoPlayerPlugin: VideoPlayerPlugin? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Register permission module
    permission = Permission(flutterPluginBinding)
    device = Device(flutterPluginBinding)

    // Register picture in picture module
    pipManager = PictureInPictureManager(flutterPluginBinding)
    // Register AlbumPickerPlugin module
    albumPickerPlugin = AlbumPickerPlugin(flutterPluginBinding)
    // Register VideoRecorderPlugin module
    videoRecorderPlugin = VideoRecorderPlugin(flutterPluginBinding)
    // Register AudioRecorderPlugin module
    audioRecorderPlugin = AudioRecorderPlugin(flutterPluginBinding)
    // Register AudioPlayerPlugin module
    audioPlayerPlugin = AudioPlayerPlugin()
    audioPlayerPlugin?.onAttachedToEngine(flutterPluginBinding)
    // Register FilePickerPlugin module
    filePickerPlugin = FilePickerPlugin()
    filePickerPlugin?.onAttachedToEngine(flutterPluginBinding)
    // Register VideoPlayerPlugin module
    videoPlayerPlugin = VideoPlayerPlugin()
    videoPlayerPlugin?.onAttachedToEngine(flutterPluginBinding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    permission?.dispose()
    permission = null
    pipManager?.dispose()
    pipManager = null
    albumPickerPlugin?.dispose()
    albumPickerPlugin = null
    videoRecorderPlugin?.dispose()
    videoRecorderPlugin = null
    audioRecorderPlugin?.dispose()
    audioRecorderPlugin = null
    audioPlayerPlugin?.onDetachedFromEngine(binding)
    audioPlayerPlugin = null
    filePickerPlugin?.onDetachedFromEngine(binding)
    filePickerPlugin = null
    videoPlayerPlugin?.onDetachedFromEngine(binding)
    videoPlayerPlugin = null
    device?.dispose()
    device = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    pipManager?.attachToActivity(binding.activity)
    permission?.onAttachedToActivity(binding)
    audioRecorderPlugin?.attachToActivity(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    pipManager?.updateActivity(null)
    permission?.onDetachedFromActivityForConfigChanges()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    pipManager?.updateActivity(binding.activity)
    permission?.onReattachedToActivityForConfigChanges(binding)
  }

  override fun onDetachedFromActivity() {
    pipManager?.detachFromActivity()
    permission?.onDetachedFromActivity()
    audioRecorderPlugin?.detachFromActivity()
  }
}
