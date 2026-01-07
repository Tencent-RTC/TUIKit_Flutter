package io.trtc.tuikit.atomicx.videorecorder

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoRecorderPlugin(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) : 
    MethodChannel.MethodCallHandler {
    
    companion object {
        private const val TAG = "VideoRecorderPlugin"
        private const val METHOD_CHANNEL_NAME = "atomic_x/video_recorder"
    }

    private val methodChannel: MethodChannel = MethodChannel(
        flutterPluginBinding.binaryMessenger,
        METHOD_CHANNEL_NAME
    )
    
    private var videoRecorderHandler: VideoRecorderHandler? = null

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecord" -> {
                if (videoRecorderHandler == null) {
                    videoRecorderHandler = VideoRecorderHandler()
                }
                videoRecorderHandler?.handleStartRecord(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        videoRecorderHandler = null
    }
}
