package com.tencent.cloud.tuikit.flutter.tuichatkit.opusplayer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class AtomicOpusPlayerPlugin : FlutterPlugin {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var handler: OpusPlayerHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "tencent_chat_uikit/opus_player")
        eventChannel = EventChannel(binding.binaryMessenger, "tencent_chat_uikit/opus_player_events")

        handler = OpusPlayerHandler()

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
