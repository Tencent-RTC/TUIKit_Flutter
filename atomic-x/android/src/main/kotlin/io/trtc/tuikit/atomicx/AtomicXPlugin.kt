package io.trtc.tuikit.atomicx

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.trtc.tuikit.atomicx.permission.Permission
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerPlugin

/** Atomic_xPlugin */
class AtomicXPlugin: FlutterPlugin, ActivityAware {
  companion object {
      private const val TAG = "AtomicXPlugin"
  }

  private var permission: Permission? = null
  private var pipManager: PictureInPictureManager? = null
  private var albumPickerPlugin: AlbumPickerPlugin? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Register permission module
    permission = Permission(flutterPluginBinding)

    // Register picture in picture module
    pipManager = PictureInPictureManager(flutterPluginBinding)
    // Register AlbumPickerPlugin module
    albumPickerPlugin = AlbumPickerPlugin(flutterPluginBinding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    permission?.dispose()
    permission = null
    pipManager?.dispose()
    pipManager = null
    albumPickerPlugin?.dispose()
    albumPickerPlugin = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    pipManager?.attachToActivity(binding.activity)
    permission?.onAttachedToActivity(binding)
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
  }
}
