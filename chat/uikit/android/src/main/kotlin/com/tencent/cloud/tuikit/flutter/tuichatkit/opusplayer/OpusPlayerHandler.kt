package com.tencent.cloud.tuikit.flutter.tuichatkit.opusplayer

import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `tencent_chat_uikit/opus_player` 的实现。
 *
 * 方法调用、EventSink 都在主线程；解码线程 / 播放线程的回调通过 [mainHandler] 投递过来。
 */
class OpusPlayerHandler : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var playback: OpusPlaybackEngine? = null
    private var decodeWorker: OpusDecodeWorker? = null
    private var lastSentLevel = 0.0

    /** 播放器存在期间每 50ms 看一次：播放中上报音量，停下来时补一个 0 后不再上报。 */
    private val levelTicker = object : Runnable {
        override fun run() {
            val engine = playback ?: return
            if (engine.isPlaying) {
                sendLevel(engine.currentLevel.toDouble())
            } else if (lastSentLevel != 0.0) {
                sendLevel(0.0)
            }
            mainHandler.postDelayed(this, LEVEL_INTERVAL_MS)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(SystemOpusDecoder.isSupported())
            "create" -> result.success(create())
            "beginStream" -> {
                decodeWorker?.beginStream()
                result.success(null)
            }
            "feed" -> {
                feed(call)
                result.success(null)
            }
            "flush" -> {
                flush()
                result.success(null)
            }
            "release" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun create(): Boolean {
        if (playback != null) {
            return true
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return false
        }
        var engineRef: OpusPlaybackEngine? = null
        val engine = OpusPlaybackEngine(onFinished = {
            mainHandler.post {
                if (playback === engineRef) {
                    eventSink?.success(mapOf("type" to "finished"))
                }
            }
        })
        engineRef = engine
        if (!engine.start()) {
            return false
        }
        playback = engine
        var workerRef: OpusDecodeWorker? = null
        val worker = OpusDecodeWorker(engine) { generation, decodedMs, isFinished ->
            mainHandler.post {
                val current = decodeWorker
                if (current !== workerRef || generation != current?.generation) {
                    return@post
                }
                eventSink?.success(
                    mapOf(
                        "type" to "chunk",
                        "durationMs" to decodedMs.toInt(),
                        "isFinished" to isFinished
                    )
                )
            }
        }
        workerRef = worker
        decodeWorker = worker
        lastSentLevel = 0.0
        mainHandler.removeCallbacks(levelTicker)
        mainHandler.postDelayed(levelTicker, LEVEL_INTERVAL_MS)
        return true
    }

    private fun feed(call: MethodCall) {
        val worker = decodeWorker ?: return
        val packets = call.argument<List<*>>("packets").orEmpty()
            .mapNotNull { it as? ByteArray }
            .filter { it.isNotEmpty() }
        val isFinished = call.argument<Boolean>("isFinished") ?: false
        worker.decode(packets, isFinished)
    }

    /** 顺序不能反：先作废在途解码，再清播放队列，见 [OpusDecodeWorker.invalidate]。 */
    private fun flush() {
        decodeWorker?.invalidate()
        playback?.flush()
    }

    private fun release() {
        mainHandler.removeCallbacks(levelTicker)
        decodeWorker?.release()
        decodeWorker = null
        playback?.stop()
        playback = null
        if (lastSentLevel != 0.0) {
            sendLevel(0.0)
        }
    }

    private fun sendLevel(value: Double) {
        lastSentLevel = value
        eventSink?.success(mapOf("type" to "level", "value" to value))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun dispose() {
        eventSink = null
        release()
        mainHandler.removeCallbacksAndMessages(null)
    }

    private companion object {
        const val LEVEL_INTERVAL_MS = 50L
    }
}
