package io.trtc.tuikit.atomicx

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.trtc.tuikit.atomicx.permission.Permission
import io.trtc.tuikit.atomicx.device_info.Device
import io.trtc.tuikit.atomicx.albumpicker.AtomicAlbumPickerPlugin
import io.trtc.tuikit.atomicx.videorecorder.AtomicVideoRecorderPlugin
import io.trtc.tuikit.atomicx.audiorecorder.AtomicAudioRecorderPlugin
import io.trtc.tuikit.atomicx.audioplayer.AtomicAudioPlayerPlugin
import io.trtc.tuikit.atomicx.filepicker.AtomicFilePickerPlugin
import io.trtc.tuikit.atomicx.videoplayer.AtomicVideoPlayerPlugin
import io.trtc.tuikit.atomicx.imageuploader.AtomicImageUploaderPlugin

/** Atomic_xPlugin */
class AtomicXPlugin: FlutterPlugin, ActivityAware {
  companion object {
      private const val TAG = "AtomicXPlugin"
  }

  private var permission: Permission? = null
  private var device: Device? = null
  private var pipManager: PictureInPictureManager? = null
  private var albumPickerPlugin: AtomicAlbumPickerPlugin? = null
  private var videoRecorderPlugin: AtomicVideoRecorderPlugin? = null
  private var audioRecorderPlugin: AtomicAudioRecorderPlugin? = null
  private var audioPlayerPlugin: AtomicAudioPlayerPlugin? = null
  private var filePickerPlugin: AtomicFilePickerPlugin? = null
  private var videoPlayerPlugin: AtomicVideoPlayerPlugin? = null
  private var imageUploaderPlugin: AtomicImageUploaderPlugin? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Register permission module
    permission = Permission(flutterPluginBinding)
    device = Device(flutterPluginBinding)

    // Register picture in picture module
    pipManager = PictureInPictureManager(flutterPluginBinding)
    // Register AtomicAlbumPickerPlugin module
    albumPickerPlugin = AtomicAlbumPickerPlugin(flutterPluginBinding)
    // Register AtomicVideoRecorderPlugin module
    videoRecorderPlugin = AtomicVideoRecorderPlugin(flutterPluginBinding)
    // Register AtomicAudioRecorderPlugin module
    audioRecorderPlugin = AtomicAudioRecorderPlugin(flutterPluginBinding)
    // Register AtomicAudioPlayerPlugin module
    audioPlayerPlugin = AtomicAudioPlayerPlugin()
    audioPlayerPlugin?.onAttachedToEngine(flutterPluginBinding)
    // Register AtomicFilePickerPlugin module
    filePickerPlugin = AtomicFilePickerPlugin()
    filePickerPlugin?.onAttachedToEngine(flutterPluginBinding)
    // Register AtomicVideoPlayerPlugin module
    videoPlayerPlugin = AtomicVideoPlayerPlugin()
    videoPlayerPlugin?.onAttachedToEngine(flutterPluginBinding)
    // Register AtomicImageUploaderPlugin module
    imageUploaderPlugin = AtomicImageUploaderPlugin(flutterPluginBinding)
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
    imageUploaderPlugin?.dispose()
    imageUploaderPlugin = null
    device?.dispose()
    device = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    pipManager?.attachToActivity(binding.activity)
    permission?.onAttachedToActivity(binding)
    audioRecorderPlugin?.attachToActivity(binding.activity)
    imageUploaderPlugin?.onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    pipManager?.updateActivity(null)
    permission?.onDetachedFromActivityForConfigChanges()
    imageUploaderPlugin?.onDetachedFromActivityForConfigChanges()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    pipManager?.updateActivity(binding.activity)
    permission?.onReattachedToActivityForConfigChanges(binding)
    imageUploaderPlugin?.onReattachedToActivityForConfigChanges(binding)
  }

  override fun onDetachedFromActivity() {
    pipManager?.detachFromActivity()
    permission?.onDetachedFromActivity()
    audioRecorderPlugin?.detachFromActivity()
    imageUploaderPlugin?.onDetachedFromActivity()
  }
}
