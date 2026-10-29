package com.tencent.cloud.tuikit.flutter.tuichatkit.realtimeaudio

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `tencent_chat_uikit/realtime_audio` 的实现。
 *
 * 方法调用、EventSink 都在主线程；采集线程上的帧通过 [mainHandler] 投递过来。
 */
class RealtimeAudioHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var capture: RealtimeAudioCapture? = null

    /**
     * 每次 start / stop 自增。采集线程投递到主线程的帧带着当时的值，
     * 对不上说明是已停掉那一路的残留，不再发给 Dart。
     */
    private var captureSession = 0

    private val voiceCallMode = VoiceCallAudioMode(context) { gained ->
        eventSink?.success(
            mapOf(
                "type" to "focus",
                "state" to if (gained) "gain" else "loss"
            )
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(RealtimeAudioCapture.isSupported())
            "startCapture" -> result.success(startCapture(call))
            "stopCapture" -> {
                stopCapture()
                result.success(null)
            }
            "requestEncoderReset" -> {
                capture?.requestEncoderReset()
                result.success(null)
            }
            "effectSummary" -> result.success(capture?.effectSummary() ?: "capture=idle")
            "enterVoiceCallMode" -> result.success(voiceCallMode.enter())
            "exitVoiceCallMode" -> {
                voiceCallMode.exit()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startCapture(call: MethodCall): Boolean {
        stopCapture()
        if (!RealtimeAudioCapture.isSupported()) {
            return false
        }
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "startCapture without RECORD_AUDIO permission")
            return false
        }
        val base = when (call.argument<String>("mode")) {
            MODE_VOICE_COMMUNICATION -> RealtimeAudioCapture.Config.VoiceCommunication
            else -> RealtimeAudioCapture.Config.Recognition
        }
        val minBufferFrames = call.argument<Number>("minBufferFrames")?.toInt()
            ?.takeIf { it > 0 } ?: base.minBufferFrames
        val config = RealtimeAudioCapture.Config(
            audioSources = base.audioSources,
            attachVoiceEffects = base.attachVoiceEffects,
            minBufferFrames = minBufferFrames,
            threadName = base.threadName,
        )
        val session = ++captureSession
        val newCapture = RealtimeAudioCapture(
            onFrame = { packets, rms ->
                mainHandler.post {
                    if (session != captureSession) {
                        return@post
                    }
                    eventSink?.success(
                        mapOf(
                            "type" to "frame",
                            "packets" to packets,
                            "rms" to rms
                        )
                    )
                }
            },
            config = config,
        )
        if (!newCapture.start()) {
            captureSession++
            return false
        }
        capture = newCapture
        return true
    }

    private fun stopCapture() {
        captureSession++
        capture?.stop()
        capture = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun dispose() {
        stopCapture()
        voiceCallMode.exit()
        mainHandler.removeCallbacksAndMessages(null)
        eventSink = null
    }

    private companion object {
        const val TAG = "RealtimeAudioHandler"
        const val MODE_VOICE_COMMUNICATION = "voiceCommunication"
    }
}
