package io.trtc.tuikit.atomicx.audiorecorder

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AudioRecorderHandler(
    private val activity: Activity,
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "AudioRecorderHandler"
    }

    private var eventSink: EventChannel.EventSink? = null

    init {
        setupAudioRecorderCallbacks()
    }

    private fun setupAudioRecorderCallbacks() {
        AudioRecorder.onRecordTime = { timeMs ->
            eventSink?.success(
                mapOf(
                    "type" to "recordTime",
                    "timeMs" to timeMs
                )
            )
        }

        AudioRecorder.onPowerLevel = { powerLevel ->
            eventSink?.success(
                mapOf(
                    "type" to "powerLevel",
                    "powerLevel" to powerLevel
                )
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecord" -> startRecord(call, result)
            "stopRecord" -> stopRecord(result)
            "cancelRecord" -> cancelRecord(result)
            else -> result.notImplemented()
        }
    }

    private fun startRecord(call: MethodCall, result: MethodChannel.Result) {
        try {
            val filepath = call.argument<String?>("filepath")
            val enableAIDeNoise = call.argument<Boolean>("enableAIDeNoise") ?: false
            val minDurationMs = call.argument<Int>("minDurationMs") ?: 1000
            val maxDurationMs = call.argument<Int>("maxDurationMs") ?: 60000

            // Start recording with listener for completion
            var completionCalled = false
            AudioRecorder.startRecord(
                filepath = filepath,
                enableAIDeNoise = enableAIDeNoise,
                minDurationMs = minDurationMs,
                maxDurationMs = maxDurationMs,
                listener = object : AudioRecorderListener {
                    override fun onCompleted(
                        resultCode: ResultCode,
                        path: String?,
                        durationMs: Int
                    ) {
                        if (completionCalled) return
                        completionCalled = true

                        Handler(Looper.getMainLooper()).post {
                            val resultMap = mapOf(
                                "resultCode" to resultCode.code,
                                "filePath" to path,
                                "durationMs" to durationMs
                            )
                            result.success(resultMap)
                        }
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "startRecord error", e)
            result.error("RECORD_ERROR", e.message, null)
        }
    }

    private fun stopRecord(result: MethodChannel.Result) {
        try {
            AudioRecorder.stopRecord()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "stopRecord error", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }

    private fun cancelRecord(result: MethodChannel.Result) {
        try {
            AudioRecorder.cancelRecord()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "cancelRecord error", e)
            result.error("CANCEL_ERROR", e.message, null)
        }
    }

    // MARK: - FlutterStreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun dispose() {
        eventSink = null
        AudioRecorder.onRecordTime = null
        AudioRecorder.onPowerLevel = null
    }
}
