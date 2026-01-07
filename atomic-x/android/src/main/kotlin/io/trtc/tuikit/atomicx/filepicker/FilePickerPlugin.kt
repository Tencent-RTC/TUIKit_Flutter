package io.trtc.tuikit.atomicx.filepicker

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class FilePickerPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var handler: FilePickerHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "atomic_x/file_picker")

        handler = FilePickerHandler(
            context = binding.applicationContext,
            methodChannel = methodChannel!!
        )

        methodChannel?.setMethodCallHandler(handler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        handler?.dispose()
        handler = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}
