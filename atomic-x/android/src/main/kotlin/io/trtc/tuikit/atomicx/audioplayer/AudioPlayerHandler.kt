package io.trtc.tuikit.atomicx.audioplayer

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AudioPlayerHandler(
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    init {
        setupAudioPlayerCallbacks()
    }

    private fun setupAudioPlayerCallbacks() {
        AudioPlayer.shared.setListener(object : AudioPlayerListener {
            override fun onPlay() {
                eventSink?.success(
                    mapOf(
                        "type" to "onPlay"
                    )
                )
            }

            override fun onPause() {
                eventSink?.success(
                    mapOf(
                        "type" to "onPause"
                    )
                )
            }

            override fun onResume() {
                eventSink?.success(
                    mapOf(
                        "type" to "onResume"
                    )
                )
            }

            override fun onProgressUpdate(currentPosition: Int, duration: Int) {
                eventSink?.success(
                    mapOf(
                        "type" to "onProgressUpdate",
                        "currentPosition" to currentPosition,
                        "duration" to duration
                    )
                )
            }

            override fun onCompletion() {
                eventSink?.success(
                    mapOf(
                        "type" to "onComplete"
                    )
                )
            }

            override fun onError(errorMessage: String) {
                eventSink?.success(
                    mapOf(
                        "type" to "onError",
                        "errorMessage" to errorMessage
                    )
                )
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> play(call, result)
            "pause" -> pause(result)
            "resume" -> resume(result)
            "stop" -> stop(result)
            "getCurrentPosition" -> getCurrentPosition(result)
            "getDuration" -> getDuration(result)
            "isPlaying" -> isPlaying(result)
            "isPaused" -> isPaused(result)
            else -> result.notImplemented()
        }
    }

    private fun play(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (filePath == null) {
            result.error("INVALID_ARGUMENTS", "filePath is required", null)
            return
        }

        AudioPlayer.shared.play(filePath)
        result.success(null)
    }

    private fun pause(result: MethodChannel.Result) {
        AudioPlayer.shared.pause()
        result.success(null)
    }

    private fun resume(result: MethodChannel.Result) {
        AudioPlayer.shared.resume()
        result.success(null)
    }

    private fun stop(result: MethodChannel.Result) {
        AudioPlayer.shared.stop()
        result.success(null)
    }

    private fun getCurrentPosition(result: MethodChannel.Result) {
        val position = AudioPlayer.shared.getCurrentPosition()
        result.success(position)
    }

    private fun getDuration(result: MethodChannel.Result) {
        val duration = AudioPlayer.shared.getDuration()
        result.success(duration)
    }

    private fun isPlaying(result: MethodChannel.Result) {
        val playing = AudioPlayer.shared.isPlaying()
        result.success(playing)
    }

    private fun isPaused(result: MethodChannel.Result) {
        val paused = AudioPlayer.shared.isPaused()
        result.success(paused)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun dispose() {
        eventSink = null
        AudioPlayer.shared.setListener(null)
    }
}
