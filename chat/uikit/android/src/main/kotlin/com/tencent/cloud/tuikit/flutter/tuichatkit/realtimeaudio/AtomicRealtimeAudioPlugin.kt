package com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class AtomicRealtimeAudioPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var handler: RealtimeAudioHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "tencent_chat_uikit/realtime_audio")
        eventChannel = EventChannel(binding.binaryMessenger, "tencent_chat_uikit/realtime_audio_events")

        handler = RealtimeAudioHandler(binding.applicationContext)

        methodChannel?.setMethodCallHandler(handler)
        eventChannel?.setStreamHandler(handler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        handler?.dispose()
        handler = null
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }
}
