package io.trtc.tuikit.atomicx.audiorecorder

import android.app.Activity
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class AudioRecorderPlugin(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    
    companion object {
        private const val TAG = "AudioRecorderPlugin"
        private const val METHOD_CHANNEL_NAME = "atomic_x/audio_recorder"
        private const val EVENT_CHANNEL_NAME = "atomic_x/audio_recorder_events"
    }

    private val methodChannel: MethodChannel = MethodChannel(
        flutterPluginBinding.binaryMessenger,
        METHOD_CHANNEL_NAME
    )
    
    private val eventChannel: EventChannel = EventChannel(
        flutterPluginBinding.binaryMessenger,
        EVENT_CHANNEL_NAME
    )
    
    private var handler: AudioRecorderHandler? = null

    init {
        // Note: Activity will be set when available through ActivityAware
        Log.d(TAG, "AudioRecorderPlugin initialized")
    }

    fun attachToActivity(activity: Activity) {
        handler = AudioRecorderHandler(activity, methodChannel, eventChannel)
        methodChannel.setMethodCallHandler(handler)
        eventChannel.setStreamHandler(handler)
        Log.d(TAG, "AudioRecorderPlugin attached to activity")
    }

    fun detachFromActivity() {
        handler?.dispose()
        handler = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        Log.d(TAG, "AudioRecorderPlugin detached from activity")
    }

    fun dispose() {
        detachFromActivity()
    }
}
